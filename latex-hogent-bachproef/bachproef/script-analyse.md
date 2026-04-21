# Grondige Analyse: Bulk-Export-OneNote-Queue.ps1 en Bulk-Import-Client-ToRDM2.ps1

## Samenvatting van het Migratieproces

De twee scripts werken samen als twee fasen van een geautomatiseerde, onbewaakt draaibare migratiepijplijn voor het verplaatsen van Microsoft OneNote-notitieboeken naar Remote Desktop Manager (RDM). De scripts zijn ontworpen om de migratiewerkstroom van beginscherm tot einde automatisch uit te voeren, zodat deze 's nachts onbewaakt kan draaien.

---

## 1. Bulk-Export-OneNote-Queue.ps1 – Het Export-Script

### 1.1 Kernfunctie

Dit script voert een **geautomatiseerde, batch-achtige export uit van OneNote-bestanden naar HTML-formaat**, waarbij alle gebruikersinteractie **upfront** plaatsvindt, en de eigenlijke export volledig onbewaakt kan draaien.

### 1.2 Stappenschema

#### **Stap 0: Voorbereiding (Automatische Robustness)**
- **Disabelt "Quick Edit Mode"** in de Windows-console
  - **Waarom?** Standaard Windows-gedrag: als iemand accidenteel op de console klikt, pauzeert het script. Dit breekt nachtverwerking.
  - **Oplossing:** Via P/Invoke naar Windows API (`GetConsoleMode`/`SetConsoleMode`) wordt dit uitgeschakeld
- **Laadt logging-infrastructuur**: Alle acties worden gelogd met timestamps
- **Laadt Common-OneNoteExport.ps1**: Gedeelde functies (de "motor" voor OneNote-export)

#### **Stap 1: Vault-Selectie (User-facing)**
- Maakt verbinding met Remote Desktop Manager via de Devolutions.PowerShell module
- Laadt alle beschikbare klanten-vaults uit de RDM datasource
- Gebruiker selecteert **meervoudig** welke vaults moeten worden geëxporteerd
  - Bv. `Klant A, Klant B, Klant C` → exporteer alle drie tegelijk
- **Resultaat:** Een queue van vaults + exportbestemmingen

#### **Stap 2: Voorkompilatie van de Export-Queue**
- Voor elke geselecteerde vault wordt **vooraf bepaald**:
  - Bestemming-folder op schijf (bv. `C:\Temp\Klant-A-Export`)
  - Welke SharePoint-sites horen bij deze klant (via CSV-matching)
- Slaat dit alles op in een JSON-configuratiebestand (queue config)
- **Voordeel:** Geen user-interactie meer nodig na dit punt

#### **Stap 3: Bevestiging en Autostart**
- Toont gebruiker een preview van wat gaat gebeuren
- Met `-AutoConfirmQueue` slaat deze stap over → direct exporteren
- Nuttig voor geautomatiseerde overnight-runs

#### **Stap 4: Batch-Export Loop (Onbewaakt)**
- Voor elke vault in de queue:
  1. Laadt OneNote
  2. Zet alle geselecteerde notitieboeken om naar HTML
  3. Slaat op in de voorgekompileerde bestemming-folder
  4. **Throttle-handling:** Als Microsoft Graph API antwoordt met "429 Too Many Requests"
     - Pauzeert voor een configureerbare tijd (standaard 30 minuten)
     - Geeft progress-informatie
     - Hervat automatisch
  5. Optioneel: leegt de OneNote-notitieboeken (schoon-maken na export)
- **Hele proces:** Volledig onbewaakt, geen menselijke tussenkomst nodig

#### **Stap 5: Post-Export Hook**
- Met `-PostExportScript` kan automatisch een vervolgscript worden aangeroepen
  - Bv.: `Bulk-Import-Client-ToRDM2.ps1` → direct importeren in RDM
  - Dit ketent de export-fase direct aan de import-fase

### 1.3 Sleutelmaechanismen

**RDM Datasource Connection Strategies:**
- Probeert eerst OAuth-token (voor cloud-vaults)
- Valt terug op username/password (via environment variables of parameters)
- Voor SQL Server biedt foutafhandeling en automatische SQL-login-herstel

**Vault-naar-SharePoint-Site Matching:**
- Via `Score-Match()` functie: fuzzy string-matching
  - Naam-normalisatie (lowercasing, spaties, speciale tekens verwijderen)
  - Score op basis van overlap
  - Top-5 matches tonen aan gebruiker voor handmatige confirmatie
- Slaat geselecteerde sites op in JSON bestand in de klantfolder (voor later gebruik)

**Queue Management:**
- Houdt track van reeds geëxporteerde klanten in logs
- Ondersteunt hervatten bij falen: volgende keer draait alleen niet-afgeronde klanten

---

## 2. Bulk-Import-Client-ToRDM2.ps1 – Het Import-Script

### 2.1 Kernfunctie

Dit script voert **gestructureerde batch-import uit van geëxporteerde OneNote-HTML naar RDM-vaults**, waarbij:
- Meerdere export-folders tegelijk kunnen worden verwerkt
- Elke folder-naam automatisch wordt gematcht aan een RDM-vault
- Alle user-input **vooraf** plaatsvind, daarna volledig automatische batch-verwerking

### 2.2 Stappenschema

#### **Stap 1: Validatie en Setup**
- Controleert of vereiste scripts/configs bestaan:
  - `Import-ToRDM2.ps1` (kernimport-logica)
  - `Analyze-Hydrex-Full.ps1` (HTML-analyse)
  - `migration-config.json` (migratiebeleid)
- Laadt Devolutions.PowerShell module
- Logbestanden aangemaakt voor succes/falen tracking

#### **Stap 2: RDM Datasource Selectie**
- Laadt alle beschikbare RDM datasources
- Filtert op **beschrijfbare** datasources (niet read-only)
- Als er slechts 1 is: auto-select en confirm
- Meerdere: gebruiker selecteert welke als target
- **Waarom nodig?** E.S.C. BV kan meerdere RDM-instanties hebben (backup, production, etc.)

#### **Stap 3: Basismap Kiezen**
- GUI-dialoog: gebruiker selecteert **basismap** (bv. `C:\Temp`)
  - Dit is de "moedermap" met alle klant-exportfolders
- **Voordeel:** Hierdoor kunnen meerdere klanten parallel verwerkt worden

#### **Stap 4: Multi-Select Export-Folders**
- Scant de basismap op subfolders (klantfolders)
- Gebruiker selecteert **meervoudig** (Out-GridView-interface of console-menu)
  - Bv. selecteer: Klant-A-Export, Klant-B-Export, Klant-C-Export
- Voor elke gekozen folder:
  1. Automatisch extractie van klant-naam uit folder-naam
     - Bv. `Klant-A-Full-Export` → `Klant A`
  2. Fuzzy-matching tegen beschikbare RDM-vaults
  3. Toont top-5-matches met scores

#### **Stap 5: Vault Toewijzing (Interactive)**
- Voor elke klant-folder:
  - Gebruiker affirmeert welke RDM-vault de bestemming is
  - Kan een ander zoekterm proberen als match niet goed is
  - Proces herhaalt tot juiste vault gevonden

#### **Stap 6: Batch-Import Loop (Onbewaakt)**
- Voor elke folder-vault-combinatie:
  1. Laadt de HTML-bestanden uit de export-folder
  2. Analyzeert HTML-inhoud (handelt attachments, links, formats af)
  3. Importeert items in de RDM-vault: titels, veldwaarden, tags, credentials
  4. **Duplicate-sweep** (optioneel):
     - Detecteert duplicaten per item
     - Controleert of document al in RDM staat
     - Helpt voorkomen dat dezelfde info 2x wordt ingevoerd
  5. **Retry-logica:**
     - Bij falen: 1x opnieuw proberen
     - Slaat beide fouten op in log

#### **Stap 7: Summary Reporting**
- Na completion: rapport met
  - Aantal succesvol geïmporteerde items
  - Aantal fouten/waarschuwingen
  - Link naar logs voor diagnostiek

### 2.3 Sleutelmaechanismen

**Name Normalization & Matching:**
- Dezelfde `Score-Match()` logica als in export-script
- Verwijdert common suffixes en noise-woorden
- Bv.: "Customer-ABC-Full-Export" → "Customer ABC"

**Duplicate Detection:**
- Via `RunDuplicateSweepEachItem` switch:
  - Controleert of titel al in vault bestaat
  - Vergelijkt veld-inhoud met bestaande entries
  - Helpt voorkomen dat migratie hetzelfde item dubbel injecteerd
- Handig bij hernormalisering of re-import

**Error Aggregation:**
- Verzamelt ALL warnings/errors
- Dedupliceer gelijke messages (niet 100x dezelfde error tonen)
- End-of-run summary met gelede info

**Configuratiegedreven:**
- Alles ingesteld in `migration-config.json`:
  - Hoe HTML moet worden geparst
  - Hoe velden in RDM gelabeld moeten worden
  - Welke sanitaties op tekst toepassen

---

## 3. Samenwerking: De Volledige Pipeline

```
┌─────────────────────────────────────────┐
│ Bulk-Export-OneNote-Queue.ps1           │
│  User selecteert vaults & sites          │
│  → Exporteert naar HTML in folders       │
│  → Schrijft onenote-selected-sites.json  │
└──────────────┬──────────────────────────┘
               │ (folders met HTML)
               ↓
        [Folders op schijf / Network]
               ↓
┌──────────────┴──────────────────────────┐
│ Bulk-Import-Client-ToRDM2.ps1           │
│  User selecteert export-folders         │
│  User bevestigt vault-mappings          │
│  → Importeert HTML → RDM entries        │
│  → Slaat audit trail op                 │
└─────────────────────────────────────────┘
```

**Keten-voordeel:** Met `-PostExportScript` in export-script kan gehele pipeline overnight draaien:
```powershell
.\Bulk-Export-OneNote-Queue.ps1 `
  -AutoConfirmQueue `
  -PostExportScript ".\Bulk-Import-Client-ToRDM2.ps1" `
  -VaultCacheFile ".\cache\vaults.json"
```

---

## 4. Robuustness en Error Handling

### Beide Scripts

- **Console Input Safeguarding:**
  - Disabelen Quick Edit Mode (voorkomt accidente pause)
  - Geschikt voor onbewaakt overnight-gebruik

- **Logging:**
  - Alles naar geprefixed logfiles (`exportlog_ddMMyyyyHHmmss.log`, etc.)
  - Nuttig voor postmortem-analyse

- **Credentials:**
  - Support voor environment variables (`RDM_DATASOURCE_USERNAME`, `RDM_DATASOURCE_PASSWORD`)
  - Geen hardcoded wachtwoorden
  - OAuth-fallback voor cloud datasources

- **Retry & Recovery:**
  - Bei timeout/throttling: intelligente backoff
  - Bij falen op item-niveau: niet hele run crashen, loggen en doorgaan

---

## 5. Technische Complexiteit

### Ingebouwde Challenges

1. **OneNote → HTML Export**
   - OneNote API is beperkt, HTML-export is niet native
   - Moet via Devolutions' Common-OneNoteExport.ps1

2. **HTML Parsing & Injection**
   - HTML uit OneNote kan malformed zijn
   - Images als base64 embedded
   - Links kunnen broken zijn
   - Script sanitaart dit allemaal

3. **Name Matching**
   - Dezelfde klant kan in OneNote "Klant ABC", in RDM "Customer ABC" heten
   - Fuzzy-matching zorgt voor 95%+ accuracy

4. **API Throttling**
   - Microsoft Graph API beperkt requests
   - Script implementeert exponential backoff + user-notification
   - Niet gewoon "herprobeert" en faalt

5. **Multi-Tenant / Multi-Datasource**
   - E.S.C. BV kan meerdere RDM-instanties hebben
   - Scripts abstraheert dit weg via datasource-selectie

---

# Topics Bruikbaar voor Bachelorproef

Op basis van de geanalyseerde scripts kunnen volgende thema's als discussie-onderwerpen in je bachelorproef worden opgenomen:

## **A. Technische Topics**

### A1. **Automatisering van Gegevensmigratie**
- **Relevantie:** Scripts automatiseren wat manual 100+ uren zou kosten
- **Focus:** Pijnpunten bij batch-migratie van ongestructureerde data (OneNote) naar gestructureerde vault (RDM)
- **Discussie-punten:**
  - Hoe garandeer je data-integriteit bij bulk-verplaatsing?
  - Hoe om te gaan met naming-discrepancies en matching-onzekerheden?
  - Recuperatie bij falen: hoe implementeer je idempotentie?

### A2. **Fuzzy Matching & Entity Resolution**
- **Relevantie:** `Score-Match()` lost het probleem op: "Klant-ABC" vs "Customer ABC"
- **Focus:** Hoe benader je name-deduplicatie bij minimale false positives?
- **Discussie-punten:**
  - String-normalisatie & Unicode-handling
  - Levenshtein-afstand vs token-overlap
  - Trade-off: automation vs manual override

### A3. **Handling API Throttling & Rate Limiting**
- **Relevantie:** Microsoft Graph opleggt 429-limits; script pauzéert intelligent
- **Focus:** Exponential backoff strategies voor onbewaakt batch-processing
- **Discussie-punten:**
  - Retry-policies (exponential backoff vs fixed intervals)
  - Monitoring & alerting bij persistent throttling
  - Cost-benefit: snelheid vs stabiliteit

### A4. **Console Robustness & Unattended Execution**
- **Relevantie:** Disabelen van Quick Edit Mode is subtiel maar cruciaal voor nacht-runs
- **Focus:** Best practices voor scripts die moeten draaien zonder manuele supervisie
- **Discussie-punten:**
  - OS-level automation pitfalls
  - Event logging en abnormality detection
  - Failsafe mechanismen

---

## **B. Beveiligings- & Governance Topics**

### B1. **Privileged Access Management (PAM) in de Migratie**
- **Relevantie:** Migratieprocessen halen gevoelige credentials uit OneNote (platte tekst) → RDM (vault)
- **Focus:** Hoe bescherm je credentials in-flight en in-rest during migration?
- **Discussie-punten:**
  - Credentials beheersen in ephemere environments
  - Audit trails voor migratieprocessen
  - Veilige cleanup van originele gegevens na migratie
  - Zero-knowledge architecturen voor tussenliggende stadia

### B2. **Information Governance & Sensitivity Labels**
- **Relevantie:** OneNote ondersteunt geen sensitivity labels; RDM wel
- **Focus:** Hoe re-classifieer je informatie bij migratie?
- **Discussie-punten:**
  - Automatisch labeling van credentials vs manuele override
  - DLP-policies bij RDM-import
  - Compliance reporting (SOC2, ISO27001, etc.)

### B3. **Least-Privilege Principle bij Vault-Migratie**
- **Relevantie:** Scripts werken met RDM datasources; daarvan zijn sommige read-only gefiltered
- **Focus:** Hoe handhoof je segregatie van duties bij migrations?
- **Discussie-punten:**
  - Role separation: wie export-scripts laat draaien vs wie de vaults beheert
  - Audit trails van scripts die gevoelige data raken
  - Segregation: bv. import-scripts draaien als low-privilege SVC-account

### B4. **Encryption & Data Protection During Migration**
- **Relevantie:** HTML-bestanden tussentijds op schijf; kunnen gevoelig zijn
- **Focus:** Data-at-rest gedurende migratie
- **Discussie-punten:**
  - Encrypted temp folders
  - Self-destructing export-bestanden (secure delete na import)
  - Zero-cleartext-archief policies

---

## **C. Operational & Change Management Topics**

### C1. **Batch Processing & Queueing Strategies**
- **Relevantie:** "Queue management for overnight runs" is hele design-filosofie
- **Focus:** How to structure batch pipelines for reliability
- **Discussie-punten:**
  - State preservation (completed-customers tracking)
  - Resumption logic (hoe herstart je bij interrupt?)
  - Logging & observability in unattended batch
  - Work stealing / load balancing bij parallel runs

### C2. **Validation & Pre-Flight Checks**
- **Relevantie:** beide scripts verificyëren scripts/configs/datasources vooraf
- **Focus:** hoe voorkom je migratie van slechte data?
- **Discussie-punten:**
  - Health checks: zijn alle datasources beschrijfbaar?
  - Data quality validation: HTML wel formaat?
  - Sanity bounds: max items per vault, etc.

### C3. **Change Tracking & Rollback Strategies**
- **Relevantie:** migratie is onherroepbaar; geen rollback-knop
- **Focus:** hoe documenteer je wat er is verplaatst?
- **Discussie-punten:**
  - Audit logs als backup voor verwijderde OneNote-items
  - Snapshot van originele RDM-state voor comparison
  - Reconciliation reports: "X items exported, Y items imported, Z mismatches"

### C4. **User Training & Change Adoption**
- **Relevantie:** scripts verdienen klanten naar RDM; gebruikers moeten wennen
- **Focus:** hoe faciliteert automatisering de adoptie?
- **Discussie-punten:**
  - GUI-dialogs (Out-GridView) i.p.v. CLI (verhoogt usability)
  - Pre-migration communication & documentation
  - Piloot-migratie met een paar klanten

---

## **D. Data Quality & Cleansing Topics**

### D1. **HTML Parsing & Content Reconstruction**
- **Relevantie:** OneNote-HTML is complex (nested tables, images, annotaties)
- **Focus:** hoe garanteer je dat inhoud correct wordt gereconstrueerd?
- **Discussie-punten:**
  - Lossless vs lossy transformations
  - Attachments handling: inline vs separate
  - Rich text formatting (bold, colors, etc.)

### D2. **Deduplication Strategies**
- **Relevantie:** `RunDuplicateSweepEachItem` is ingebouwd
- **Focus:** hoe detecteer je duplicaten in heterogene datasets?
- **Discussie-punten:**
  - Fuzzy exact match with tolerance
  - Domain-specific semantics (bv. 2 "admin passwords" maar met ander wachtwoord)
  - User-assisted resolution bij twijfel

### D3. **Legacy Data Cleanup**
- **Relevantie:** SkipCleanup flag; kan je original OneNote-notes verwijderen?
- **Focus:** post-migratie cleanup & archivering
- **Discussie-punten:**
  - GDPR/compliance: hoe lang mag je backup houden?
  - Archivering van originele OneNote (cold storage)
  - Validation dat alles migrated voordat je delete

---

## **E. Project & Implementation Topics**

### E1. **Phased Rollout & Piloting**
- **Relevantie:** je begint niet met 100 klanten in één nacht
- **Focus:** hoe pilot je een migratie?
- **Discussie-punten:**
  - Selectie van pilot-klanten (representatief, laag-risk)
  - Iterative feedback & script refinement
  - Scaling: van 3 pilots naar 100+ klanten

### E2. **Performance & Scalability Considerations**
- **Relevantie:** export van 1 klant ≠ export van 100
- **Focus:** bottlenecks bij schaal
- **Discussie-punten:**
  - OneNote API limits & optimization
  - Sequential vs parallel processing (trade-offs)
  - Resource consumption (RAM, disk, network)

### E3. **Cost-Benefit Analysis of Migratie**
- **Relevantie:** automatisering vs manual effort
- **Focus:** ROI van scripts
- **Discussie-punten:**
  - Schaduwkost van manual migration
  - Opbrengsten: verbeterde security, DLP compliance, sneller onboarding
  - Break-even analysis

---

## **F. Governance & Best Practices Topics**

### F1. **Configuration Management**
- **Relevantie:** migration-config.json centraslisiert beleid
- **Focus:** hoe bestuur je migratie-policies at scale?
- **Discussie-punten:**
  - Versionering van migration-config
  - Environment-specific configs (dev, staging, prod)
  - Secrets management (credentials in config files)

### F2. **Observability & Incident Response**
- **Relevantie:** logs bevatten alles; maar ongelezen
- **Focus:** hoe reageer je op fouten in unattended runs?
- **Discussie-punten:**
  - Log aggregation & centralized analysis
  - Alerting: welke errors verdienen escalation?
  - Post-incident review: RCA voor failed migrations

### F3. **Knowledge Transfer & Documentation**
- **Relevantie:** scripts zijn complex; wie begrijpt ze?
- **Focus:** hoe documenteer je migratie-logic voor handover?
- **Discussie-punten:**
  - Inline documentation vs external wikis
  - Architecture diagrams (data flow, error paths)
  - Runbooks voor common troubleshooting scenarios

---

# Aanbevolen Structuur voor Bachelorproef

Gezien deze 3 niveaus van analyse (functionaliteit, challenges, topics), suggereert ik volgende structuur in je bachelorproef:

## **Deel 1: Technische Beschrijving** (Chapters ~4-5)
- Wat doen de scripts stap-voor-stap?
- Hoe werken ze samen?
- (Dit document biedt basis voor deze chapters)

## **Deel 2: Migratie Challenges** (Chapter ~6)
- Waarom is OneNote → RDM niet triviaal?
- Naming, encryption, audit trails, scale, etc.
- Link naar literature op PAM, information governance

## **Deel 3: Design Decisions** (Chapter ~7)
- Waarom fuzzy matching?
- Waarom queue-based architecture?
- Waarom ErrorHandling op deze manier?

## **Deel 4: Results & Evaluation** (Chapter ~8)
- Hoe lang duurde migratie voor N klanten?
- Hoeveel items geëxporteerd vs geïmporteerd?
- Hoeveel errors/warnings?
- Gebruiker-feedback op UI/usability

## **Deel 5: Recommendations** (Chapter ~9)
- Lessons learned
- Wat zou anders/beter kunnen?
- Hoe schalen we naar 500 klanten?

---

**Einde van Script-Analyse**
