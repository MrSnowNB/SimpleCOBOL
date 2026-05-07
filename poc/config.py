from pathlib import Path

# All input data — raw COBOL source + pre-run REKT outputs
DATA_DIR  = Path("data")
SRC_DIR   = DATA_DIR / "cbl"        # .cbl source files
CPY_DIR   = DATA_DIR / "cpy"        # copybook files
REKT_DIR  = DATA_DIR / "rekt"       # REKT CFG JSON outputs

# All generated output — gitignored, never committed
OUT_DIR   = Path("output")
FACTS_DIR = OUT_DIR / "facts"       # structured_facts.json per program
MD_DIR    = OUT_DIR / "md"          # assembled .md files

# Ollama config
OLLAMA_URL   = "http://localhost:11434/api/chat"
MODEL        = "gemma3:latest"
OLLAMA_TIMEOUT = 180          # seconds — large programs need more time

# Pipeline caps — keep LLM payloads manageable
MAX_REKT_SENTENCES = 20       # sentences sent to server.py query endpoint
MAX_01_ITEMS       = 30       # working-storage 01-levels kept in facts
