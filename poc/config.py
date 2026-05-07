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
OLLAMA_URL = "http://localhost:11434/api/chat"
MODEL      = "gemma3:latest"
