#!/usr/bin/env python3
"""
chat.py  —  interactive terminal chat against poc/server.py

Usage:
  python poc/chat.py                     # free chat, lists programs
  python poc/chat.py CBACT01C            # pre-load a program's facts

Commands during chat:
  load <PROG>   switch active program, clears history
  facts <PROG>  dump raw facts JSON to terminal
  quit          exit
"""

import sys, json, httpx

BASE    = "http://localhost:8000"
history = []


def chat(question: str, program: str | None = None) -> str:
    history.append({"role": "user", "content": question})
    r = httpx.post(
        f"{BASE}/chat",
        json={"program": program, "messages": history},
        timeout=120,
    )
    r.raise_for_status()
    msg = r.json()
    history.append(msg)
    return msg["content"]


def main():
    programs_arg = sys.argv[1:]
    active_program = programs_arg[0].upper() if programs_arg else None

    if active_program:
        print(f"\nCOBOL Oracle  —  program: {active_program}")
    else:
        try:
            avail = httpx.get(f"{BASE}/programs", timeout=5).json()
            print(f"\nCOBOL Oracle  —  {len(avail)} programs cached")
            print("  " + "  ".join(avail[:10]) + ("..." if len(avail) > 10 else ""))
        except Exception:
            print("\nCOBOL Oracle  —  (server not reachable, check uvicorn)")
        print("  Type 'load PROGNAME' to focus on a program\n")

    print("  Commands: load <PROG> | facts <PROG> | quit\n")

    while True:
        try:
            user_in = input("you> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nbye")
            break

        if not user_in:
            continue
        if user_in.lower() in ("quit", "exit", "q"):
            break
        if user_in.lower().startswith("load "):
            active_program = user_in.split()[1].upper()
            history.clear()
            print(f"  -> loaded {active_program}\n")
            continue
        if user_in.lower().startswith("facts "):
            prog = user_in.split()[1].upper()
            try:
                r = httpx.get(f"{BASE}/facts/{prog}", timeout=10)
                print(json.dumps(r.json(), indent=2)[:2000])
            except Exception as e:
                print(f"  ERROR: {e}")
            continue

        try:
            response = chat(user_in, active_program)
            print(f"\noracle> {response}\n")
        except Exception as e:
            print(f"  ERROR: {e}\n")


if __name__ == "__main__":
    main()
