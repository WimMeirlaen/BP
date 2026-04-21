# Figurenoverzicht voor de bachelorproef

Hieronder staat welke figuren je best invoegt, met bestandsnaam, caption en label. De LaTeX-figuurblokken in [methodologie.tex](methodologie.tex) zijn al voorbereid met dezelfde namen.

| # | Figuurbestand in `graphics/` | Caption | Label | Plaats in tekst |
|---|---|---|---|---|
| 1 | `fig-01-fuzzy-vault-selectie.png` | Geanonimiseerde voorbeeldoutput of schema van vaultnaam-naar-site-matching in de exportqueue | `fig:fuzzy-top5` | In de sectie over fuzzy matching, direct na de code van `Score-Match` |
| 2a | `fig-02a-unattended-export-run.png` | Procesflow onbewaakte export-run | `fig:unattended-export-run` | In de sectie over unattended batch processing en resilience (exportscript) |
| 2b | `fig-02b-unattended-import-run.png` | Procesflow onbewaakte import-run | `fig:unattended-import-run` | In de sectie over unattended batch processing en resilience (importscript) |
| 3 | `fig-03-duplicate-detectie-exportqueue.png` | Duplicate-detectie in de exportqueue | `fig:duplicate-retry-summary` | In de sectie over data integrity en duplicate detection |
| 4 | `fig-04-throttle-cooldown.png` | Throttle-afhandeling | `fig:throttle-cooldown` | In de sectie over API rate limiting en intelligent backoff |
| 5 | `fig-05-config-validatie.png` | Configuratievalidatie bij opstart | `fig:config-validation` | In de sectie over configuration-driven architecture |
| 6 | `fig-06-two-phase-architectuur.png` | Twee-fasen architectuur | `fig:two-phase-architecture` | In de sectie over export + import als twee aparte fases |
| 7 | `fig-07-magic-bytes-before-after.png` | Detectie via magic bytes | `fig:magic-bytes-before-after` | In de sectie over HTML reconstruction en image magic bytes |
| 8 | `fig-08-scriptstructuur-batchpipeline.png` | Scriptstructuur van de batchpipeline | `fig:batch-script-structuur` | In de sectie over de productiegerichte batchpipeline en aanroepketen |
| 9 | `fig-09-boomstructuur-onenote-rdm.jpg` | Behoud van de OneNote-boomstructuur in RDM | `fig:boomstructuur-rdm` | In de sectie over boomstructuur en parent-entiteiten |

## Opmerking

De figuren zijn in de tekst al voorzien van een veilige placeholder. Als een png-bestand nog ontbreekt, compileert de bachelorproef toch, en verschijnt er een kader met de naam van het ontbrekende bestand.

Voor figuur 1 is het best om geen echte klantgegevens te tonen. Een geanonimiseerde voorbeeldoutput of een schematische voorstelling van de scoringstappen is beter geschikt voor de bachelorproef. De figuur moet tonen dat de vaultnaam uit de exportqueue als zoekterm dient voor site-matching, niet dat een klantnaam handmatig wordt ingevoerd.

## Aanbevolen volgorde om in te voegen

1. Eerst de figuren 1, 4 en 7, omdat die het sterkst aan de technische uitleg hangen.
2. Daarna figuur 8 en 9 voor de batchscript-structuur en de boomstructuur, en figuren 2a, 2b, 3 en 5 voor de operationele en configuratie-aspecten.
3. Tot slot figuur 6 voor de architectuur.
