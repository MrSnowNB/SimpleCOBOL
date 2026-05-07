#!/usr/bin/env python3
"""
chat.py  —  terminal chat client for poc/server.py

Usage:
  python poc/chat.py                  # lists cached programs
  python poc/chat.py CBACT01C         # pre-load a program

Commands:
  load <PROG>   switch active program, clears history
  facts <PROG>  dump raw facts JSON
  health        ping the model
  quit
"""

import sys, json, httpx

BASE    = "http://localhost:8000"
history = []

def chat(question: str, program: str | None) -> str:
    history.append({"role": "user", "content": question})
    r = httpx.post(f"{BASE}/chat",
                   json={"program": program, "messages": history}, timeout=120)
    r.raise_for_status()
    msg = r.json()
    history.append(msg)
    return msg["content"]

def main():
    active = sys.argv[1].upper() if len(sys.argv) > 1 else None
    if active:
        print(f"\nCOBOL Oracle  —  {active}")
    else:
        try:
            avail = httpx.get(f"{BASE}/programs", timeout=5).json()
            print(f"\nCOBOL Oracle  —  {len(avail)} programs cached")
            print("  " + "  ".join(avail[:10]) + ("..." if len(avail) > 10 else ""))
        except Exception:
            print("\nCOBOL Oracle  —  (start server: uvicorn poc.server:app --port 8000)")
    print("  Commands: load <PROG> | facts <PROG> | health | quit\n")

    while True:
        try:
            line = input("you> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nbye"); break
        if not line: continue
        if line.lower() in ("quit", "exit", "q"): break
        if line.lower().startswith("load "):
            active = line.split()[1].upper()
            history.clear()
            print(f"  -> {active} loaded\n"); continue
        if line.lower().startswith("facts "):
            prog = line.split()[1].upper()
            r = httpx.get(f"{BASE}/facts/{prog}", timeout=10)
            print(json.dumps(r.json(), indent=2)[:2000]); continue
        if line.lower() == "health":
            r = httpx.get(f"{BASE}/health", timeout=15)
            print(r.json()); continue
        print(f"\noracle> {chat(line, active)}\n")

if __name__ == "__main__":
    main()
