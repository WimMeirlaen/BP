# Visuele Workflow & Snelle Reference

## Script-Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│               USER INTERACTION PHASE (GUI-basd)                  │
│                                                                  │
│   ┌──────────────────────────────────────────────────────────┐ │
│   │  Bulk-Export-OneNote-Queue.ps1 - STAP 1-3               │ │
│   │  ═══════════════════════════════════════════════════════ │ │
│   │  ✓ Vault discovery: RDM datasource → laad alle klanten  │ │
│   │  ✓ User selecteert vaults (multi-select)               │ │
│   │  ✓ SharePoint site matching (fuzzy match)              │ │
│   │  ✓ Queue compilation: JSON vooraf genereren             │ │
│   │  ✓ User review & confirm (-AutoConfirmQueue skip)      │ │
│   │  → QUEUE GECOMPILEERD + READY                          │ │
│   └──────────────────────────────────────────────────────────┘ │
│                           ↓                                    │
│   ┌──────────────────────────────────────────────────────────┐ │
│   │  Bulk-Import-Client-ToRDM2.ps1 - STAP 1-5              │ │
│   │  ═══════════════════════════════════════════════════════ │ │
│   │  ✓ Datasource selector (multi-option)                  │ │
│   │  ✓ Base-folder picker (GUI dialoog)                    │ │
│   │  ✓ Multi-select export-folders                         │ │
│   │  ✓ Smart vault-matching (top-5 scores)                 │ │
│   │  ✓ User affirmeert mappings                            │ │
│   │  → IMPORT QUEUE GECOMPILEERD + READY                   │ │
│   └──────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│    BATCH PROCESSING PHASE (Onbewaakt - Loop per klant)         │
│                                                                  │
│   EXPORT-LOOP (Bulk-Export)                                     │
│   ═════════════════════For each vault in queue:                │
│   ┌──────────────────────────────────────────────────────────┐ │
│   │  1. Open OneNote notitieboeken                          │ │
│   │  2. Export naar HTML per site                           │ │
│   │  3. Slaat op in klant-folder: C:\Temp\Klant-ABC-HTML   │ │
│   │  4. THROTTLING HANDLER:                                 │ │
│   │     ├─ HTTP 429? → Pa use 30 minuten                   │ │
│   │     └─ Log & progress-bar → automatisch hervatten     │ │
│   │  5. Optioneel: cleanup OneNote na export               │ │
│   │  6. Schrijf audit log: timestamp, items count, status  │ │
│   └──────────────────────────────────────────────────────────┘ │
│                           ↓ (Folders op disk)                  │
│   IMPORT-LOOP (Bulk-Import)                                     │
│   ═════════════════════ For each export-folder:                │
│   ┌──────────────────────────────────────────────────────────┐ │
│   │  1. Read HTML-files uit C:\Temp\Klant-ABC-HTML         │ │
│   │  2. Parse & analyze HTML                               │ │
│   │  3. Duplicate-sweep (optioneel):                       │ │
│   │     ├─ Bestaat item al in RDM-vault?                  │ │
│   │     └─ Skip als duplicate, log warning                │ │
│   │  4. Import items in RDM-vault:                        │ │
│   │     ├─ Title, fields, tags, credentials              │ │
│   │     └─ Sanitize/encode voor RDM-format               │ │
│   │  5. ERROR-HANDLING:                                    │
│   │     ├─ Per-item error? Log & continue                │ │
│   │     └─ Retry 1x bei transient failure                │ │
│   │  6. Schrijf audit log + summary                        │ │
│   └──────────────────────────────────────────────────────────┘ │
│                           ↓                                     │
│   COMPLETION                                                    │
│   ═════════════════════                                        │
│   ✓ Alle items geïmporteerd (of gefaald)                     │
│   ✓ Audit logs geschreven                                     │
│   ✓ Summary-rapport: success/fail/warning counts             │
│   ✓ Cleanup: temp HTML-files (optioneel)                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Challenges Map

```
┌────────────────────────────────────────────────────────────────┐
│                   DATA MIGRATION CHALLENGES                     │
└────────────────────────────────────────────────────────────────┘

MATCHING & NAMING
├─ Challenge: "Klant ABC" ≠ "Customer ABC"
├─ Score: Fuzzy string-matching + user confirmation
├─ Risk: Auto-mismatch → wrong vault, data loss
└─ Solution: Fuzzy scoring, top-5 candidates


CONTENT TRANSFORMATION
├─ Challenge: OneNote-HTML ≠ RDM-import-format
├─ Scope: Tables, images, links, attachments
├─ Risk: Lossy conversion, formatting loss, broken refs
└─ Solution: Analyze-Hydrex-Full.ps1 + quality validation


DUPLICATE HANDLING
├─ Challenge: "Copy of Klant ABC" in both folders
├─ Definition: Exact title? Content hash? Semantic?
├─ Risk: Double-imports, audit confusion
└─ Solution: RunDuplicateSweepEachItem flag


API RATE LIMITING
├─ Challenge: Microsoft Graph limits (429)
├─ Impact: Unpredictable delays during night runs
├─ Risk: Silent failures, incomplete exports
└─ Solution: Exponential backoff + user notification


CREDENTIALS IN TRANSIT
├─ Challenge: Passwords plaintext in HTML during export
├─ Compliance: GDPR, ISO27001 violations
├─ Risk: Data breach if temp folders compromised
└─ Solution: Encrypt temp, cleanup after import


INFRASTRUCTURE DEPENDENCIES
├─ Challenge: RDM datasource not accessible
├─ SQL vs Cloud variants have different auth
├─ Risk: Script fails entirely
└─ Solution: Multi-auth strategy (OAuth, pwd, token)
```

---

## Key Mechanisms Reference Table

| Mechanism | Used By | Purpose | Example/Parameter |
|-----------|---------|---------|-------------------|
| **Fuzzy Matching** | Both | Name de-duplication | `Score-Match "Klant-ABC" "Customer ABC"` → 90 |
| **Quick Edit Disable** | Both | Unattended safety | P/Invoke `SetConsoleMode` |
| **Queue Compilation** | Export | Upfront planning | `QueueConfigPath` → JSON |
| **Multi-Auth** | Export | Connection resilience | OAuth token → pwd → SQL repair |
| **Throttle Backoff** | Export | API rate handling | HTTP 429 → pause 30min → retry |
| **Duplicate Sweep** | Import | Quality check | `RunDuplicateSweepEachItem` flag |
| **Audit Logging** | Both | Traceability | `logs/exportlog_*.log` + timestamps |
| **Datasource Filter** | Import | RBAC | Only writable datasources shown |
| **State Tracking** | Export | Resumability | `CompletedCustomersFile` |
| **Error Aggregation** | Import | Summary reporting | RunWarnings, RunErrors dedup |

---

## Configuration Points (Customization Vectors)

### **Bulk-Export-OneNote-Queue.ps1**

```powershell
# TOP-LEVEL KNOBS (Parameter-driven)
-DataSourceName              # RDM datasource selection
-DefaultExportRoot           # Base folder (default: C:\Temp)
-SkipCleanup                 # Don't empty OneNote after export
-AutoConfirmQueue            # Skip review prompt
-PostExportScript            # Chain to import script
-VaultCacheFile              # Cache vaults for reuse

# FILE-BASED CONFIG
common-onenote-export.ps1    # Shared export logic (external dep)
SharePoint-Projecten-VOLLEDIG.csv  # Site-to-vault mapping table
```

### **Bulk-Import-Client-ToRDM2.ps1**

```powershell
# TOP-LEVEL KNOBS
migration-config.json        # Central policy (HTML parsing rules)
-UpdateHtmlIfExists
-MaxItems                    # Batch limit
-RunDuplicateSweepEachItem
-FailFastOnDocMismatch

# FILE-BASED DEPENDENCIES
Import-ToRDM2.ps1            # Core import logic
Analyze-Hydrex-Full.ps1      # HTML analysis
migration-config.json        # Policy engine
```

---

## Error Handling Strategy

```
EXPORT SCRIPT ERROR HANDLING
├─ Pre-flight Checks:
│  ├─ RDM module available?
│  ├─ Common-OneNoteExport.ps1 loadable?
│  └─ Datasource accessible?
├─ During Export Loop:
│  ├─ HTTP 429? → smart backoff (30 min pause)
│  ├─ OneNote timeout? → log warning, continue
│  ├─ Datasource disconnect? → try reconnect
│  └─ Disk full? → stop & alert
└─ Recovery:
   ├─ CompletedCustomersFile tracks progress
   ├─ Re-run skips completed items
   └─ Logs enable fault analysis

IMPORT SCRIPT ERROR HANDLING
├─ Pre-flight Checks:
│  ├─ Import-ToRDM2.ps1 loadable?
│  ├─ Config valid JSON?
│  ├─ Target datasource writable?
│  └─ Source folders readable?
├─ During Import Loop:
│  ├─ Per-item failure? → Add to RunErrors
│  ├─ Duplicate detected? → Add to RunWarnings
│  ├─ HTML malformed? → Skip / log
│  └─ RDM connection lost? → Try reconnect
└─ Recovery:
   ├─ Partial import OK (not atomic)
   ├─ Success/failure files track state
   └─ Retry once on transient failure
```

---

## Tech Stack Dependencies

```
PowerShell 7+
├─ Devolutions.PowerShell module
│  ├─ Get-RDMDataSource
│  ├─ Get-RDMRepository (vaults)
│  ├─ Get-RDMOAuthToken
│  ├─ Set-RDMCurrentDataSource
│  └─ Import-RDMEntry (custom in Import-ToRDM2.ps1)
├─ System.Windows.Forms (GUI dialogs)
│  ├─ FolderBrowserDialog
│  ├─ Out-GridView
│  └─ Form.ShowDialog()
└─ System P/Invoke for console control
   └─ kernel32.dll (Console quick-edit disable)

OneNote Access
├─ OneNote COM API (legacy but works)
├─ Via Common-OneNoteExport.ps1 wrapper
└─ HTML export (not native, via COM→HTML conversion)

File System
├─ Share Point-Projecten-VOLLEDIG.csv
├─ Migration-config.json
├─ Export folders (HTML artifacts)
└─ Log directory (/logs/)
```

---

## Success Metrics to Measure

```
EXPORT SUCCESS
├─ Vaults attempted: N
├─ Vaults completed: M (aim: M ≥ N)
├─ Items exported: X
├─ HTML files generated: Y
├─ Throttling events: Z (monitor for trends)
├─ Average time per vault: T minutes
└─ Error rate: (N-M)/N * 100%

IMPORT SUCCESS
├─ Folders processed: N
├─ Items imported: X (vs Y exported: ratio %)
├─ Duplicates detected & skipped: D
├─ Import errors: E
├─ Retry successes: R
└─ Success rate: X/(X+E) * 100%

OVERALL PIPELINE
├─ End-to-end time: Total hours
├─ Data loss: Items exported vs imported
├─ Manual interventions needed: count
├─ Logs volume: MB/run
└─ User satisfaction: post-pilot survey
```

---

## Troubleshooting Quick Reference

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Script hangs unexpectedly | User clicked on console? | Not possible (Quick Edit disabled) |
| Export times out at clieant N | OneNote notitieboeken zeer groot | Split export, add -MaxItems |
| Import matches wrong vault | Fuzzy matching score too lax | Review top-5, manually override |
| RDM connection refused | Datasource not accessible | Check network, credentials, SQL |
| HTTP 429 errors every 10 min | API rate limit hit | Increase backoff, reduce batch size |
| Duplicates not detected | Duplicate-sweep disabled | Use `-RunDuplicateSweepEachItem` |
| Logs missing or empty | Logging not initialized | Check `/logs/` folder exists (created auto) |

---

## File Outputs Summary

```
AFTER EXPORT RUN:
├─ logs/exportlog_ddMMyyyyHHmmss.log
│  └─ Timestamps of all actions, errors, throttling
├─ logs/bulk-export-completed-customers.txt
│  └─ List of vaults already processed
├─ [ClantFolder]/onenote-selected-sites.json
│  └─ Which SharePoint sites exported for this klant
├─ C:\Temp\Klant-A\
│  └─ *.html files (OneNote pages as HTML)
└─ [optionally] cache/rdm-vaults.json
   └─ Cached vault list (for reuse)

AFTER IMPORT RUN:
├─ logs/bulk-importlog_ddMMyyyyHHmmss.log
│  └─ All import actions + warnings/errors
├─ logs/import-success.txt
│  └─ List of successfully imported items
├─ logs/import-failed.txt
│  └─ List of items that failed
└─ [RDM Vault]
   └─ New entries, folders, credentials, documents
```

---

## Aanbevolen Leesevolgorde voor Dieping

1. **Start met `script-analyse.md`** → Begrijpen wat scripts doen
2. **Lees `thesis-topics-guide.md`** → Identificeer interessante topics
3. **Kies 2-3 topics** voor diepere research
4. **Dit document (visueel)** → Quick reference terwijl je schrijft
5. **Raadpleeg originele scripts** als je specific code-details nodig hebt
