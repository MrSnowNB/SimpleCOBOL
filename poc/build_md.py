#!/usr/bin/env python3
"""
build_md.py  —  structured_facts.json -> <PROG>.md with YAML front-matter
No LLM. Pure template assembly from verified facts.
The 'purpose' field is the one blank left for the LLM narration step.
"""

import json, sys
from pathlib import Path

FACTS_DIR = Path("poc/facts")
MD_DIR    = Path("poc/md")
MD_DIR.mkdir(parents=True, exist_ok=True)

STUB_PURPOSE = "TODO: run narration step (poc/narrate.py)"

def build_md(prog: str) -> str:
    f = json.loads((FACTS_DIR / f"{prog}.json").read_text())

    # -- YAML front-matter ---------------------------------------------------
    para_yaml = "\n".join(
        f"  - name: {p['name']}\n"
        f"    lines: {p['line_start']}-{p['line_end']}\n"
        f"    performs: {[x['target'] for x in p['performs']]}\n"
        f"    gotos: {p['gotos']}\n"
        f"    terminator: {p['terminator']}"
        for p in f["paragraphs"]
    )
    files_yaml = "\n".join(
        f"  - logical: {s['logical']}\n    ddname: {s['ddname']}"
        for s in f["data"]["select_files"]
    )
    calls_yaml = json.dumps(f["external_calls"])
    cics_yaml  = "\n".join(
        f"  - verb: {c['verb']}\n    text: \"{c['text'][:80]}\""
        for c in f["cics_verbs"]
    )

    yaml_block = f"""---
program: {prog}
source_lines: {f['source_lines']}
para_count: {f['para_count']}
rekt_nodes: {f['rekt_node_count']}
rekt_edges: {f['rekt_edge_count']}
external_calls: {calls_yaml}
purpose: "{STUB_PURPOSE}"
paragraphs:
{para_yaml if para_yaml else '  []'}
data_files:
{files_yaml if files_yaml else '  []'}
cics_verbs:
{cics_yaml if cics_yaml else '  []'}
---"""

    # -- Markdown body -------------------------------------------------------
    para_table = "| Paragraph | Lines | Performs | Terminator |\n|---|---|---|---|\n"
    for p in f["paragraphs"]:
        perfs = ", ".join(x["target"] for x in p["performs"]) or "—"
        para_table += f"| `{p['name']}` | {p['line_start']}–{p['line_end']} | {perfs} | `{p['terminator']}` |\n"

    data_table = "| 01-Level Item | PIC |\n|---|---|\n"
    for item in f["data"]["working_storage_01s"][:20]:
        data_table += f"| `{item['name']}` | {item['pic'] or '—'} |\n"

    cics_section = ""
    if f["cics_verbs"]:
        cics_section = "\n## CICS Interface\n\n"
        for c in f["cics_verbs"]:
            cics_section += f"- **{c['verb']}**: `{c['text'][:100]}`\n"

    ext_section = ""
    if f["external_calls"]:
        ext_section = f"\n## External CALLs\n\n" + \
                      "\n".join(f"- `{c}`" for c in f["external_calls"])

    body = f"""# {prog}

> {STUB_PURPOSE}

## Paragraph Flow

{para_table}
## Working Storage (Top 01-Levels)

{data_table}{cics_section}{ext_section}

## REKT Execution Order (first 10 sentences)

| # | Type | Text |
|---|---|---|
""" + "\n".join(
        f"| {i+1} | `{s['type']}` | `{s['text'][:80]}` |"
        for i, s in enumerate(f["rekt_sentences"][:10])
    )

    out = MD_DIR / f"{prog}.md"
    content = yaml_block + "\n\n" + body
    out.write_text(content, encoding="utf-8")
    print(f"  [{prog}] -> {out}")
    return content

if __name__ == "__main__":
    progs = sys.argv[1:] if len(sys.argv) > 1 else [
        p.stem for p in FACTS_DIR.glob("*.json")
    ]
    for prog in sorted(progs):
        try:
            build_md(prog)
        except Exception as e:
            print(f"  [{prog}] ERROR: {e}")
