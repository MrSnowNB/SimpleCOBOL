# SimpleCOBOL — COBOL Oracle POC

Fully self-contained COBOL static analysis + scoped LLM oracle.
Clone, install, run. No external repo dependencies.

## What It Does

Takes raw COBOL source files, runs deterministic static analysis
(`cobc -E` + Cobol-REKT CFG), builds a `structured_facts.json` per program,
assembles a `.md` document per program, then serves a scoped chat API where
**gemma3:latest answers only from verified facts — never from raw COBOL**.

## Repo Structure

```
SimpleCOBOL/
├── data/
│   ├── cbl/        ← raw .cbl source files (30 CardDemo programs)
│   ├── cpy/        ← COBOL copybooks
│   └── rekt/       ← pre-run Cobol-REKT CFG JSON outputs
├── poc/
│   ├── config.py       ← single source of truth for all paths + model
│   ├── extract_facts.py ← Stage 0: deterministic extraction
│   ├── build_md.py      ← Stage 1a: assemble .md (zero LLM)
│   ├── narrate.py       ← Stage 1b: bounded LLM narration (1 call/program)
│   ├── server.py        ← FastAPI oracle (gemma3 sees facts only)
│   └── chat.py          ← terminal test client
├── output/             ← GITIGNORED — generated at runtime
│   ├── facts/            ← structured_facts.json per program
│   └── md/               ← assembled .md files
├── tools/
│   └── README.md         ← REKT re-run instructions
├── requirements.txt
└── .gitignore
```

## Prerequisites

```bash
pip install -r requirements.txt
ollama pull gemma3:latest
# GnuCOBOL optional (fallback to raw source if not present)
```

## Run

```bash
# 1. Extract deterministic facts for all programs
python -m poc.extract_facts

# 2. Build MD files
python -m poc.build_md

# 3. (Optional) Fill purpose field via LLM
python -m poc.narrate

# 4. Start the oracle server
uvicorn poc.server:app --port 8000

# 5. Chat (second terminal)
python -m poc.chat CBACT01C
```

## The One LLM Rule

gemma3:latest receives **only `output/facts/<PROG>.json`**, never raw COBOL.
When it cannot answer from the facts it responds `NOT IN EXTRACTED FACTS`.
This keeps the LLM as a narration layer, not a reasoning or inference layer.

## Pipeline Architecture

```
data/cbl/<PROG>.cbl
       |
       +-- cobc -E          -> copybook-expanded source
       +-- data/rekt/ JSON  -> sentence originalText + exec order
       +-- regex            -> paragraph names, PERFORM/GOTO map
       +-- regex            -> DATA DIVISION 01-levels, SELECT/FD
       v
output/facts/<PROG>.json     <- deterministic ground truth
       |
       +-- build_md.py      -> output/md/<PROG>.md
       +-- narrate.py       -> patches purpose field (1 LLM call)
       v
poc/server.py  (FastAPI :8000)
  POST /query          single question -> gemma3 answer from facts
  POST /chat           multi-turn
  GET  /facts/{prog}   raw JSON for SOTA LLM consumption
  GET  /md/{prog}      assembled markdown
  GET  /programs       list cached programs
  GET  /health         model ping
```
