# validation/rekt/ - COBOL-REKT Report Output Zone

## Overview

The `validation/rekt/` directory contains the output of the `smojol-cli --reportDir` tool, which generates COBOL REKT (REview, Knowledge, Translation) reports. This is the authoritative zone for structured COBOL program analysis.

## Data Flow

```
scripts/run_rekt_all.py
    ↓
validation/rekt/ (smojol-cli --reportDir output)
    ↓
extract_cfg_summary.py → validation/structure/
```

### Pipeline Stages

1. **run_rekt_all.py** - Executes smojol-cli across all 31 COBOL programs
2. **rekt/** - Stores raw smojol-cli report output (CFG JSON files)
3. **extract_cfg_summary.py** - Processes rekt/ output into structure/ CFG files

## Contents

### File Pattern

- `{PROG}.cbl.report/cfg/cfg-{PROG}.cbl.json` - CFG report for each program

### Directory Structure

```
validation/rekt/
├── CBACT01C.cbl.report/
│   └── cfg/
│       └── cfg-CBACT01C.cbl.json
├── CBACT02C.cbl.report/
│   └── cfg/
│       └── cfg-CBACT02C.cbl.json
├── CBACT03C.cbl.report/
│   └── cfg/
│       └── cfg-CBACT03C.cbl.json
├── CBACT04C.cbl.report/
│   └── cfg/
│       └── cfg-CBACT04C.cbl.json
├── CBCUS01C.cbl.report/
│   └── cfg/
│       └── cfg-CBCUS01C.cbl.json
├── CBEXPORT.cbl.report/
│   └── cfg/
│       └── cfg-CBEXPORT.cbl.json
├── CBIMPORT.cbl.report/
│   └── cfg/
│       └── cfg-CBIMPORT.cbl.json
├── CBSTM03A.cbl.report/
│   └── cfg/
│       └── cfg-CBSTM03A.cbl.json
├── CBSTM03B.cbl.report/
│   └── cfg/
│       └── cfg-CBSTM03B.cbl.json
├── CBTRN01C.cbl.report/
│   └── cfg/
│       └── cfg-CBTRN01C.cbl.json
├── CBTRN02C.cbl.report/
│   └── cfg/
│       └── cfg-CBTRN02C.cbl.json
├── CBTRN03C.cbl.report/
│   └── cfg/
│       └── cfg-CBTRN03C.cbl.json
├── COACTUPC.cbl.report/
│   └── cfg/
│       └── cfg-COACTUPC.cbl.json
├── COACTVWC.cbl.report/
│   └── cfg/
│       └── cfg-COACTVWC.cbl.json
├── COADM01C.cbl.report/
│   └── cfg/
│       └── cfg-COADM01C.cbl.json
├── COBIL00C.cbl.report/
│   └── cfg/
│       └── cfg-COBIL00C.cbl.json
├── COBSWAIT.cbl.report/
│   └── cfg/
│       └── cfg-COBSWAIT.cbl.json
├── COCRDLIC.cbl.report/
│   └── cfg/
│       └── cfg-COCRDLIC.cbl.json
├── COCRDSLC.cbl.report/
│   └── cfg/
│       └── cfg-COCRDSLC.cbl.json
├── COCRDUPC.cbl.report/
│   └── cfg/
│       └── cfg-COCRDUPC.cbl.json
├── COMEN01C.cbl.report/
│   └── cfg/
│       └── cfg-COMEN01C.cbl.json
├── CORPT00C.cbl.report/
│   └── cfg/
│       └── cfg-CORPT00C.cbl.json
├── COSGN00C.cbl.report/
│   └── cfg/
│       └── cfg-COSGN00C.cbl.json
├── COTRN00C.cbl.report/
│   └── cfg/
│       └── cfg-COTRN00C.cbl.json
├── COTRN01C.cbl.report/
│   └── cfg/
│       └── cfg-COTRN01C.cbl.json
├── COTRN02C.cbl.report/
│   └── cfg/
│       └── cfg-COTRN02C.cbl.json
├── COUSR00C.cbl.report/
│   └── cfg/
│       └── cfg-COUSR00C.cbl.json
├── COUSR01C.cbl.report/
│   └── cfg/
│       └── cfg-COUSR01C.cbl.json
├── COUSR02C.cbl.report/
│   └── cfg/
│       └── cfg-COUSR02C.cbl.json
├── COUSR03C.cbl.report/
│   └── cfg/
│       └── cfg-COUSR03C.cbl.json
└── CSUTLDTC.cbl.report/
    └── cfg/
        └── cfg-CSUTLDTC.cbl.json
```

**Total:** 31 programs × 1 CFG file = 31 files

## Regeneration Instructions

To regenerate all REKT reports:

```bash
cd validation
py run_rekt_all.py
```

This will:
1. Execute `smojol-cli --reportDir rekt` for each COBOL program
2. Create/replace `{PROG}.cbl.report/cfg/cfg-{PROG}.cbl.json` files
3. Update the rekt/ directory with fresh analysis

## 31-Program Inventory

The rekt/ directory covers these COBOL programs:

| Program | Purpose | Status |
|---------|---------|--------|
| CBACT01C | Account Management | ✅ Complete |
| CBACT02C | Account Update | ✅ Complete |
| CBACT03C | Account Inquiry | ✅ Complete |
| CBACT04C | Account Closure | ✅ Complete |
| CBCUS01C | Customer Management | ✅ Complete |
| CBEXPORT | Export Processing | ✅ Complete |
| CBIMPORT | Import Processing | ✅ Complete |
| CBSTM03A | Statement Generation | ✅ Complete |
| CBSTM03B | Statement Inquiry | ✅ Complete |
| CBTRN01C | Transaction Processing | ✅ Complete |
| CBTRN02C | Transaction Update | ✅ Complete |
| CBTRN03C | Transaction Inquiry | ✅ Complete |
| COACTUPC | Account Updater | ✅ Complete |
| COACTVWC | Account Validator | ✅ Complete |
| COADM01C | Admin Services | ✅ Complete |
| COBIL00C | Billing Processing | ✅ Complete |
| COBSWAIT | Wait Processing | ✅ Complete |
| COCRDLIC | Credit Limit Check | ✅ Complete |
| COCRDSLC | Credit Score Check | ✅ Complete |
| COCRDUPC | Credit Duplicate Check | ✅ Complete |
| COMEN01C | Menu Services | ✅ Complete |
| CORPT00C | Report Processing | ✅ Complete |
| COSGN00C | Signon Processing | ✅ Complete |
| COTRN00C | Transaction Loader | ✅ Complete |
| COTRN01C | Transaction Maintenance | ✅ Complete |
| COTRN02C | Transaction Inquiry | ✅ Complete |
| COUSR00C | User Loader | ✅ Complete |
| COUSR01C | User Maintenance | ✅ Complete |
| COUSR02C | User Inquiry | ✅ Complete |
| COUSR03C | User Validation | ✅ Complete |
| CSUTLDTC | Settlement Data | ✅ Complete |

## Do Not Edit Policy

**The files in validation/rekt/ are auto-generated and should NOT be manually edited.**

- **Source of truth:** COBOL source files in `app/cbl/`
- **Generator:** `smojol-cli --reportDir rekt`
- **Consumer:** `extract_cfg_summary.py` → `validation/structure/`

Manual edits will be overwritten on next regeneration and cause data inconsistency.

## Relationship to validation/structure/

The `rekt/` directory feeds into `validation/structure/`:

```
rekt/{PROG}.cbl.report/cfg/cfg-{PROG}.cbl.json
    ↓ (extract_cfg_summary.py)
validation/structure/{PROG}_cfg.json
```

- **rekt/:** Raw smojol-cli output (preserved for audit)
- **structure/:** Processed CFG files for validation pipeline

Both directories coexist to maintain audit trail while providing clean validation inputs.