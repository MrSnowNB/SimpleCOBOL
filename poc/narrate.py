#!/usr/bin/env python3
"""
narrate.py  —  Fill the 'purpose' field in facts + MD using one bounded LLM call.
This is the ONLY LLM-touching step in Stage 1.
The LLM sees structured_facts.json only — never raw COBOL source.

Usage:
  python poc/narrate.py CBACT01C
  python poc/narrate.py               # all cached programs
"""

import json, sys, httpx
from pathlib import Path

FACTS_DIR  = Path("poc/facts")
MD_DIR     = Path("poc/md")
OLLAMA_URL = "http://localhost:11434/api/chat"
MODEL      = "qwen3:4b"

NARRATE_SYSTEM = """You are a COBOL technical writer.
Given a structured facts JSON about a COBOL program, write:
1. A single sentence (max 25 words) stating what the program does.
2. One sentence per paragraph (max 15 words each) stating what it does.

Output ONLY valid JSON in this exact schema:
{
  "program_purpose": "<one sentence>",
  "paragraph_summaries": {
    "PARA-NAME": "<one sentence>"
  }
}

Rules:
- Use only information present in the facts.
- Never mention COBOL syntax.
- Never infer logic not explicitly in the facts.
- If you cannot determine something, use: "Purpose unclear from extracted facts."
"""


def narrate(prog: str):
    facts_path = FACTS_DIR / f"{prog}.json"
    if not facts_path.exists():
        print(f"  [{prog}] No facts found — run extract_facts.py first")
        return

    facts = json.loads(facts_path.read_text())

    # Build a compact facts summary (strip rekt_sentences bulk to save tokens)
    compact = {k: v for k, v in facts.items() if k != "rekt_sentences"}

    payload = {
        "model": MODEL,
        "stream": False,
        "format": "json",
        "messages": [
            {"role": "system", "content": NARRATE_SYSTEM},
            {
                "role": "user",
                "content": (
                    f"FACTS:\n```json\n{json.dumps(compact, indent=2)}\n```\n\n"
                    "Write the narration JSON now."
                ),
            },
        ],
    }

    print(f"  [{prog}] calling LLM...", end="", flush=True)
    r = httpx.post(OLLAMA_URL, json=payload, timeout=120)
    r.raise_for_status()
    content = r.json()["message"]["content"]

    try:
        narration = json.loads(content)
    except json.JSONDecodeError:
        print(f" JSON parse failed. Raw output saved.")
        (FACTS_DIR / f"{prog}_narration_raw.txt").write_text(content)
        return

    # Patch facts JSON with narration
    facts["program_purpose"] = narration.get("program_purpose", "")
    facts["paragraph_summaries"] = narration.get("paragraph_summaries", {})
    facts_path.write_text(json.dumps(facts, indent=2))

    # Patch MD purpose stub
    md_path = MD_DIR / f"{prog}.md"
    if md_path.exists():
        md = md_path.read_text(encoding="utf-8")
        md = md.replace(
            "TODO: run narration step (poc/narrate.py)",
            narration.get("program_purpose", "Purpose not determined.")
        )
        md_path.write_text(md, encoding="utf-8")

    print(f" OK  purpose: {facts['program_purpose'][:80]}")


if __name__ == "__main__":
    progs = sys.argv[1:] if len(sys.argv) > 1 else [
        p.stem for p in FACTS_DIR.glob("*.json")
        if "_narration_raw" not in p.stem
    ]
    for prog in sorted(progs):
        narrate(prog.upper())
