#!/usr/bin/env python3
"""
extract_facts.py  — COBOL -> structured_facts.json
Reads:  data/cbl/<PROG>.cbl
        data/rekt/<PROG>.cbl.report/**/cfg/cfg-<PROG>.cbl.json
Writes: output/facts/<PROG>.json

What each section uniquely contributes:
  cobc_expand()   -> inlines copybooks (REKT does NOT expand copybooks)
  rekt_load()     -> sentence-level originalText + execution order
  para_extract()  -> paragraph names + PERFORM/GOTO map
  data_extract()  -> DATA DIVISION byte layout
  assemble()      -> merges all four into one facts JSON
"""

import re, json, subprocess, sys
from pathlib import Path
from poc.config import SRC_DIR, CPY_DIR, REKT_DIR, FACTS_DIR, MAX_REKT_SENTENCES, MAX_01_ITEMS

FACTS_DIR.mkdir(parents=True, exist_ok=True)

# -- 1. cobc -E: copybook expansion ------------------------------------------
def cobc_expand(prog: str) -> list:
    src = SRC_DIR / f"{prog}.cbl"
    if not src.exists():
        src = SRC_DIR / f"{prog}.CBL"
    if not src.exists():
        raise FileNotFoundError(f"No source file for {prog} in {SRC_DIR}")
    try:
        r = subprocess.run(
            ["cobc", "-E", "-I", str(CPY_DIR), str(src)],
            capture_output=True, text=True, timeout=60
        )
        lines = r.stdout.splitlines()
    except FileNotFoundError:
        lines = src.read_text(encoding="utf-8", errors="replace").splitlines()
    return [l for l in lines if not l.startswith("#")]

# -- 2. REKT: sentence originalText + exec order ------------------------------
def rekt_load(prog: str) -> dict:
    # 1. Standard flat path
    p = REKT_DIR / f"{prog}.cbl.report/cfg/cfg-{prog}.cbl.json"
    # 2. Double-nested path (actual structure on most machines)
    if not p.exists():
        p = REKT_DIR / f"{prog}.cbl.report/{prog}.cbl.report/cfg/cfg-{prog}.cbl.json"
    # 3. Uppercase .CBL nested variants
    if not p.exists():
        p = REKT_DIR / f"{prog}.cbl.report/{prog}.CBL.report/cfg/cfg-{prog}.Cbl.json"
    if not p.exists():
        p = REKT_DIR / f"{prog}.cbl.report/{prog}.CBL.report/cfg/cfg-{prog}.cbl.json"
    # 4. Recursive glob fallback
    if not p.exists():
        matches = list(REKT_DIR.glob(f"**/{prog}.*.report/**/cfg-{prog}.*.json"))
        if matches:
            p = matches[0]
    if not p.exists() or not p.is_file():
        return {"nodes": [], "edges": [], "rekt_available": False}
    raw = json.loads(p.read_text(encoding="utf-8"))
    raw["rekt_available"] = True
    return raw

def rekt_sentences(rekt: dict) -> list:
    return [
        {"id": n["id"], "type": n.get("type", ""), "text": n.get("originalText", "").strip()}
        for n in rekt.get("nodes", [])
        if n.get("nodeType") == "CODE_VERTEX" and n.get("originalText", "").strip()
    ]

def rekt_calls(sentences: list) -> list:
    calls = []
    for s in sentences:
        m = re.search(r"\bCALL\s+['\"]([A-Z0-9]+)['\"]", s["text"], re.IGNORECASE)
        if m:
            calls.append(m.group(1))
    return list(dict.fromkeys(calls))

def rekt_cics(sentences: list) -> list:
    hits = []
    for s in sentences:
        m = re.match(r"EXEC\s+CICS\s+(\w+)", s["text"].upper())
        if m:
            hits.append({"verb": m.group(1), "text": s["text"][:120]})
    return hits

# -- 3. Paragraph extraction -------------------------------------------------
# Lenient: 0-7 leading spaces to handle cobc -E output
PARA_RE = re.compile(r'^[ ]{0,7}([A-Z0-9][A-Z0-9\-]{2,})\.\s*$')
PERF_RE = re.compile(r'\bPERFORM\s+([A-Z0-9][A-Z0-9\-]+)(?:\s+THRU\s+([A-Z0-9][A-Z0-9\-]+))?')
GOTO_RE = re.compile(r'\bGO\s+TO\s+((?:[A-Z0-9][A-Z0-9\-]+\s*)+?)(?:\s+DEPENDING|\.)', re.IGNORECASE)
TERM_RE = re.compile(r'\b(STOP\s+RUN|GOBACK|EXIT\s+PROGRAM)\b', re.IGNORECASE)
CICS_RETURN_RE = re.compile(r'EXEC\s+CICS\s+RETURN', re.IGNORECASE)

# CICS pseudo-paragraph starters — treated as implicit paragraph boundaries
CICS_PARA_RE = re.compile(
    r'^\s{0,7}(EXEC\s+CICS|EVALUATE\s+TRUE|WHEN\s+OTHER|END-EXEC)',
    re.IGNORECASE
)

# Words that look like paragraph names but aren't
PARA_EXCLUDE = frozenset([
    "SECTION", "DIVISION", "PROGRAM", "AUTHOR", "DATE", "REMARKS",
    "ENVIRONMENT", "CONFIGURATION", "INPUT", "OUTPUT", "FILE",
    "WORKING", "LINKAGE", "LOCAL", "SCREEN", "REPORT",
])

def para_extract(lines: list) -> list:
    paragraphs = []
    in_procedure = False
    current = None

    for i, raw in enumerate(lines):
        upper = raw.strip().upper()
        if "PROCEDURE DIVISION" in upper:
            in_procedure = True
            continue
        if not in_procedure:
            continue

        m = PARA_RE.match(raw)
        if m:
            name = m.group(1).upper()
            if name not in PARA_EXCLUDE:
                if current:
                    paragraphs.append(current)
                current = {"name": name, "line_start": i + 1,
                           "performs": [], "gotos": [], "terminator": "implicit"}
                continue

        if current is None:
            continue

        for pm in PERF_RE.finditer(upper):
            tgt = pm.group(1)
            if tgt not in ("UNTIL", "VARYING", "TIMES", "WITH", "TEST", "THRU"):
                entry = {"target": tgt}
                if pm.group(2):
                    entry["thru"] = pm.group(2)
                if entry not in current["performs"]:
                    current["performs"].append(entry)
        for gm in GOTO_RE.finditer(upper):
            for tgt in gm.group(1).split():
                tgt = tgt.strip()
                if tgt and tgt not in current["gotos"]:
                    current["gotos"].append(tgt)
        if TERM_RE.search(upper):
            current["terminator"] = TERM_RE.search(upper).group(0).upper().replace("  ", " ")
        if CICS_RETURN_RE.search(upper):
            current["terminator"] = "EXEC CICS RETURN"

    if current:
        paragraphs.append(current)
    for i, p in enumerate(paragraphs):
        p["line_end"] = paragraphs[i + 1]["line_start"] - 1 if i + 1 < len(paragraphs) else len(lines)
    return paragraphs

# -- 4. Data item extraction -------------------------------------------------
DATA_RE   = re.compile(r'^\s+(\d{2})\s+([A-Z0-9][A-Z0-9\-]*)\s*(?:PIC\S*\s+(\S+))?', re.IGNORECASE)
FD_RE     = re.compile(r'^\s+FD\s+([A-Z0-9][A-Z0-9\-]+)', re.IGNORECASE)
SELECT_RE = re.compile(r'SELECT\s+([A-Z0-9][A-Z0-9\-]+)\s+ASSIGN\s+TO\s+(\S+)', re.IGNORECASE)

def data_extract(lines: list) -> dict:
    in_data = False
    items_01, files, selects = [], [], []
    for raw in lines:
        upper = raw.strip().upper()
        if "DATA DIVISION" in upper:
            in_data = True
        if "PROCEDURE DIVISION" in upper:
            in_data = False
        m = SELECT_RE.search(raw)
        if m:
            selects.append({"logical": m.group(1).upper(), "ddname": m.group(2).upper().strip('.')})
        m2 = FD_RE.match(raw)
        if m2:
            files.append(m2.group(1).upper())
        if in_data:
            m3 = DATA_RE.match(raw)
            if m3 and m3.group(1) == "01" and m3.group(2).upper() not in ("FILLER",):
                items_01.append({"name": m3.group(2).upper(), "pic": m3.group(3)})
    return {"select_files": selects, "fd_names": files,
            "working_storage_01s": items_01[:MAX_01_ITEMS]}

# -- 5. Assemble and write ---------------------------------------------------
def assemble(prog: str):
    print(f"  [{prog}] expanding...", end="", flush=True)
    lines     = cobc_expand(prog)
    print(f" {len(lines)} lines | REKT...", end="", flush=True)
    rekt      = rekt_load(prog)
    sentences = rekt_sentences(rekt)
    print(f" {len(sentences)} sentences | extracting...", end="", flush=True)
    paras     = para_extract(lines)
    data      = data_extract(lines)
    facts = {
        "program":         prog,
        "source_lines":    len(lines),
        "rekt_available":  rekt["rekt_available"],
        "rekt_node_count": len(rekt.get("nodes", [])),
        "rekt_edge_count": len(rekt.get("edges", [])),
        "paragraphs":      paras,
        "para_count":      len(paras),
        "data":            data,
        "external_calls":  rekt_calls(sentences),
        "cics_verbs":      rekt_cics(sentences),
        # Capped: full list available in REKT JSON if needed
        "rekt_sentences":  sentences[:MAX_REKT_SENTENCES],
        "rekt_sentence_total": len(sentences),
    }
    out = FACTS_DIR / f"{prog}.json"
    out.write_text(json.dumps(facts, indent=2))
    print(f" {len(paras)} paras | OK -> {out}")
    return facts

# -- CLI ---------------------------------------------------------------------
if __name__ == "__main__":
    progs = sys.argv[1:] if len(sys.argv) > 1 else [
        p.stem.upper() for p in SRC_DIR.glob("*.[cC][bB][lL]")
    ]
    for prog in sorted(progs):
        try:
            assemble(prog.upper())
        except Exception as e:
            print(f"  [{prog}] ERROR: {e}")
