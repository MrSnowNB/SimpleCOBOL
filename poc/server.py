#!/usr/bin/env python3
"""
server.py  —  FastAPI COBOL Oracle
gemma3:latest via Ollama sees output/facts/<PROG>.json only — never raw COBOL.

Endpoints:
  POST /query              single-shot question about one program
  POST /chat               multi-turn conversation
  GET  /facts/{program}    raw structured_facts.json
  GET  /md/{program}       assembled markdown
  GET  /programs           list all cached programs
  GET  /health             model ping
"""

import json
from pathlib import Path
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
from poc.config import FACTS_DIR, MD_DIR, OLLAMA_URL, MODEL

app = FastAPI(title="COBOL Oracle")

SYSTEM_PROMPT = """You are a COBOL program analyst for the AWS CardDemo system.
You answer questions ONLY from the verified structural facts provided.
Rules:
1. Never reference raw COBOL syntax or source lines.
2. If the answer is not in the facts, say exactly: NOT IN EXTRACTED FACTS
3. Never infer or guess beyond the provided data.
4. Be concise. Cite field names from the facts when referencing evidence.
5. If asked about a program not in cache, say: PROGRAM NOT CACHED"""


class QueryRequest(BaseModel):
    program: str
    question: str

class ChatRequest(BaseModel):
    program: str | None = None
    messages: list[dict]


def load_facts(prog: str) -> dict:
    p = FACTS_DIR / f"{prog}.json"
    if not p.exists():
        raise HTTPException(404, f"{prog} not cached. Run: python poc/extract_facts.py {prog}")
    return json.loads(p.read_text())

def load_md(prog: str) -> str:
    p = MD_DIR / f"{prog}.md"
    return p.read_text(encoding="utf-8") if p.exists() else "MD not yet generated."


@app.post("/query")
async def query(req: QueryRequest):
    facts = load_facts(req.program)
    payload = {
        "model": MODEL, "stream": False,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content":
                f"VERIFIED FACTS FOR {req.program}:\n```json\n{json.dumps(facts, indent=2)}\n```\n\n"
                f"QUESTION: {req.question}"},
        ],
    }
    async with httpx.AsyncClient(timeout=120) as client:
        r = await client.post(OLLAMA_URL, json=payload)
    r.raise_for_status()
    answer = r.json()["message"]["content"]
    return {"program": req.program, "answer": answer,
            "rekt_available": facts["rekt_available"], "para_count": facts["para_count"]}


@app.post("/chat")
async def chat(req: ChatRequest):
    context = ""
    if req.program:
        facts = load_facts(req.program)
        context = f"VERIFIED FACTS FOR {req.program}:\n```json\n{json.dumps(facts, indent=2)}\n```\n\n"
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    if context:
        messages.append({"role": "user", "content": context})
        messages.append({"role": "assistant", "content": f"Facts for {req.program} loaded. Ask your question."})
    messages.extend(req.messages)
    payload = {"model": MODEL, "stream": False, "messages": messages}
    async with httpx.AsyncClient(timeout=120) as client:
        r = await client.post(OLLAMA_URL, json=payload)
    r.raise_for_status()
    return r.json()["message"]


@app.get("/facts/{program}")
async def facts(program: str):
    return load_facts(program)

@app.get("/md/{program}")
async def md(program: str):
    return {"program": program, "content": load_md(program)}

@app.get("/programs")
async def programs():
    return sorted([p.stem for p in FACTS_DIR.glob("*.json")])

@app.get("/health")
async def health():
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.post(OLLAMA_URL,
                json={"model": MODEL, "stream": False,
                      "messages": [{"role": "user", "content": "ping"}]})
        return {"status": "ok", "model": MODEL, "ollama_rc": r.status_code}
    except Exception as e:
        return {"status": "error", "model": MODEL, "detail": str(e)}
