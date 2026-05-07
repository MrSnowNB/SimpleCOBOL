# SimpleCOBOL — COBOL Oracle POC

Minimal proof-of-concept: deterministic COBOL static analysis + scoped LLM oracle.

Takes AWS CardDemo `.cbl` source files, runs `cobc -E` + Cobol-REKT CFG extraction,
builds a `structured_facts.json` per program, assembles a `.md` document per program,
then serves a scoped chat API where **Qwen3:4b answers only from verified facts**.

## What Each Script Does (No Redundancy)

| Script | Unique Job | LLM? |
|---|---|---|
| `poc/extract_facts.py` | `cobc -E` copybook expansion + REKT CFG load + paragraph/data regex | No |
| `poc/build_md.py` | Assembles `.md` + YAML front-matter from facts JSON | No |
| `poc/narrate.py` | Fills `purpose` field via one bounded Qwen3 call | **Yes — 1 call/program** |
| `poc/server.py` | FastAPI chat server — Qwen3 sees facts JSON only, never raw COBOL | Yes — 1 call/query |
| `poc/chat.py` | Terminal chat client | No |

## Prerequisites

```bash
# Python deps
pip install -r requirements.txt

# Ollama + model
ollama pull qwen3:4b

# GnuCOBOL (optional — fallback to raw source if not present)
# Ubuntu/Debian: sudo apt install gnucobol
# Windows: https://sourceforge.net/projects/gnucobol/
```

## Setup

This POC expects the following layout (point it at your CardDemo repo):
```
app/
  cbl/      <- .cbl source files
  cpy/      <- copybook files
validation/
  rekt/     <- Cobol-REKT output dirs (<PROG>.cbl.report/cfg/cfg-<PROG>.cbl.json)
```

If you have the CardDemo repo locally, run from its root. Otherwise symlink or copy.

## Run

```bash
# Step 1: Extract deterministic facts for all programs (~2 min)
python poc/extract_facts.py

# Step 2: Build MD files (instant)
python poc/build_md.py

# Step 3 (optional): Fill purpose field via LLM narration
python poc/narrate.py

# Step 4: Start the oracle server
uvicorn poc.server:app --port 8000

# Step 5: Chat (in a second terminal)
python poc/chat.py CBACT01C
```

## Sample Chat Session

```
you> What files does this program read?
oracle> CBACT01C reads ACCT-FILE (ddname: ACCTFILE) assigned via SELECT...

you> How many paragraphs?
oracle> CBACT01C has 8 paragraphs: 0000-MAIN, 1000-READ-FILE...

you> What is the EVALUATE logic in 3000-PROCESS?
oracle> NOT IN EXTRACTED FACTS

you> load CBTRN01C
  -> loaded CBTRN01C

you> What external programs does it call?
oracle> CBTRN01C calls: CBTRN02C, CSUTLDTC
```

`NOT IN EXTRACTED FACTS` is a correct answer — it means the question requires
reasoning beyond static structure. Use `facts <PROG>` to get raw JSON and pass
to a SOTA model for deeper analysis.

## Architecture

```
app/cbl/<PROG>.cbl
       |
       +-- cobc -E       -> copybook-expanded source
       +-- REKT CFG JSON -> sentence originalText + exec order edges
       +-- regex         -> paragraph names, PERFORM/GOTO map
       +-- regex         -> DATA DIVISION 01-levels, SELECT/FD
       |
       v
poc/facts/<PROG>.json    <- structured_facts.json (deterministic)
       |
       +-- build_md.py  -> poc/md/<PROG>.md  (deterministic)
       +-- narrate.py   -> adds purpose field (1 LLM call)
       |
       v
poc/server.py  (FastAPI)
  POST /query   <- single question, Qwen3 answers from facts only
  POST /chat    <- multi-turn conversation
  GET  /facts/<PROG>  <- raw JSON for SOTA LLM consumption
  GET  /md/<PROG>     <- assembled markdown
  GET  /programs      <- list cached programs
       |
       v
poc/chat.py  <- terminal test client
```

## The One LLM Rule

Qwen3:4b inside the server receives **only `structured_facts.json`**, never raw COBOL.
If it cannot answer from the facts, it responds `NOT IN EXTRACTED FACTS`.
This keeps the LLM as a narration layer, not a reasoning or inference layer.
