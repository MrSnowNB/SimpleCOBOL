#!/usr/bin/env python3
"""
server.py  —  FastAPI COBOL Oracle
The LLM (gemma3:latest via Ollama) ONLY sees structured_facts.json — never raw COBOL.

Endpoints:
  POST /query         single-shot question about one program
  POST /chat          multi-turn conversation
  GET  /facts/{prog}  raw structured_facts.json (for outside SOTA LLMs)
  GET  /md/{prog}     assembled markdown document
  GET  /programs      list all cached programs
"""

import json
from pathlib import Path
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx

app       = FastAPI(title="COBOL Oracle POC")
FACTS_DIR = Path("poc/facts")
MD_DIR    = Path("poc/md")
OLLAMA_URL = "http://localhost:11434/api/chat"
MODEL      = "gemma3:latest"

SYSTEM_PROMPT = """You are a COBOL program analyst for the AWS CardDemo system.
You answer questions ONLY from the verified structural facts provided.
Rules:
1. Never reference raw COBOL syntax or source lines.
2. If the answer is not in the facts, say exactly: NOT IN EXTRACTED FACTS
3. Never infer or guess beyond the provided data.
4. Be concise. Cite the field names from the facts when referencing evidence.
5. If asked about a program not in cache, say: PROGRAM NOT CACHED"""


class QueryRequest(BaseModel):
    program: str
    question: str


class ChatRequest(BaseModel):
    program: str | None = None
    messages: list[dict]  # full conversation history for multi-turn


def load_facts(prog: str) -> dict:
    p = FACTS_DIR / f"{prog}.json"
    if not p.exists():
        raise HTTPException(
            404, f"{prog} not in facts cache. Run: python poc/extract_facts.py {prog}"
        )
    return json.loads(p.read_text())


def load_md(prog: str) -> str:
    p = MD_DIR / f"{prog}.md"
    return p.read_text(encoding="utf-8") if p.exists() else "MD not yet generated."


# -- Single-shot query -------------------------------------------------------
@app.post("/query")
async def query(req: QueryRequest):
    facts = load_facts(req.program)
    payload = {
        "model": MODEL,
        "stream": False,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    f"VERIFIED FACTS FOR {req.program}:\n```json\n"
                    f"{json.dumps(facts, indent=2)}\n```\n\n"
                    f"QUESTION: {req.question}"
                ),
            },
        ],
    }
    async with httpx.AsyncClient(timeout=120) as client:
        r = await client.post(OLLAMA_URL, json=payload)
    r.raise_for_status()
    answer = r.json()["message"]["content"]
    return {
        "program": req.program,
        "answer": answer,
        "rekt_available": facts["rekt_available"],
        "para_count": facts["para_count"],
    }


# -- Multi-turn chat ---------------------------------------------------------
@app.post("/chat")
async def chat(req: ChatRequest):
    context = ""
    if req.program:
        facts = load_facts(req.program)
        context = (
            f"VERIFIED FACTS FOR {req.program}:\n```json\n"
            f"{json.dumps(facts, indent=2)}\n```\n\n"
        )

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    if context:
        messages.append({"role": "user", "content": context})
        messages.append(
            {
                "role": "assistant",
                "content": f"Facts for {req.program} loaded. Ask your question.",
            }
        )
    messages.extend(req.messages)

    payload = {"model": MODEL, "stream": False, "messages": messages}
    async with httpx.AsyncClient(timeout=120) as client:
        r = await client.post(OLLAMA_URL, json=payload)
    r.raise_for_status()
    return r.json()["message"]


# -- Raw facts endpoint (for outside SOTA LLMs) ------------------------------
@app.get("/facts/{program}")
async def facts(program: str):
    return load_facts(program)


@app.get("/md/{program}")
async def md(program: str):
    return {"program": program, "content": load_md(program)}


@app.get("/programs")
async def programs():
    return sorted([p.stem for p in FACTS_DIR.glob("*.json")])
