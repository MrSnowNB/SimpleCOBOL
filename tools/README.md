# Tools

This directory is for the Cobol-REKT static analysis tool (smojol-cli).
The `data/rekt/` outputs are pre-committed so you do NOT need to run REKT
to use the POC pipeline.

Only re-run REKT if `.cbl` source files change.

## Download REKT

```bash
# Download smojol-cli from:
https://github.com/avishek-sen-gupta/cobol-rekt/releases

# Run against a single program:
java -jar tools/smojol-cli.jar export-unified \
  --source-dir data/cbl \
  --copybook-dir data/cpy \
  --program CBACT01C.cbl \
  --output-dir data/rekt \
  --dialect IBMCOBOL
```
