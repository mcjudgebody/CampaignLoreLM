___
# Document Metadata

**Document Title:** PC Lore — [Character Name]  
**Document ID (UUID):** `13da7f2f-f8a7-4a1d-97e7-004153ddc373`  
**Version (SemVer):** `1.0.0`  
**Status:** Canon  
**Canonical Scope:** [CAMPAIGN/STORY/PCS/CHARACTER-NAME]  
**Last Updated (YYYY-MM-DD):** `YYYY-MM-DD`  
**Checksum:** `0f08e4b4f55e8b1fef26f440ebe82313bc0755f41b52a7f7bc268c7cc09bbbc5`  

## Versioning Notes
- **MAJOR** (`X.0.0`): Breaking canon changes (alters character identity, core background, or established connections)
- **MINOR** (`0.X.0`): Additive content — new connections, expanded background, arc additions, session lore
- **PATCH** (`0.0.X`): Corrections/typos/minor clarifications with no semantic change

## Release Notes (from N/A → 1.0.0)
- Initial PC lore file created from CampaignLoreLM PC template
___

## At a Glance
- [Player name] playing [Character name]; [archetype / role in one phrase]
- [Most defining character trait or disadvantage — what drives their behavior]
- [Key mechanical stats or advantages relevant to narrative]
- [Current home base or operational range]
- **Character sheet:** `[path/to/sheet]` ([format — e.g. HTML, PDF])

---

## Background

[Who this character is, where they came from, what shaped them. Written from the
GM's perspective — includes information the player may not have canonized yet.
This file is the GM's narrative source of truth for this PC.]

[Keep to 2–4 paragraphs. Full backstory depth should be earned through play.]

---

## Mechanical Profile

**Character sheet:** `[path/to/character/sheet/]` — [format]; canonical mechanical record.

**Key stats:** [System-appropriate stat line — e.g. ST 10, DX 11, IQ 14, HT 12]

**Narrative-relevant advantages:**
- **[Advantage]:** [What it means at the table — mechanical + narrative function]
- **[Advantage]:** [What it means at the table]

**Narrative-relevant disadvantages:**
- **[Disadvantage]:** [How the GM should use this — frequency, triggers, escalation]
- **[Disadvantage]:** [How the GM should use this]

**Key skills:** [Skills relevant to investigative or social play]

**Quirks:** [List of distinctive behavioral quirks from the sheet]

---

## NPC Connections

| NPC | Relationship | Location Reference |
|---|---|---|
| [NPC name] | [Nature of connection] | [File reference or UUID] |

*Note on connection design: [Optional — note on how isolated or connected this PC is by design, and what that means for play.]*

---

## GM-Only: Campaign Hooks

> [Hidden from players. Mechanical hooks, Mythos/plot escalation, backstory
> reveals the GM controls. These are not established facts — they are tools.]

> **[Hook name]:** [Description of how to deploy this hook, when, and what it should accomplish in the campaign arc]

> **[Hook name]:** [Description]

---

## Lore Notes

*(No session lore recorded yet. Update most-recent-first as campaign progresses.)*

---

> **Usage note (delete before publishing):**
> 1. Copy this file to your `Story/PCs/` directory with the character's name.
> 2. Replace the UUID with a new one: `uuidgen | tr '[:upper:]' '[:lower:]'`
> 3. Fill in metadata and document content. PC lore files default to Status: Canon.
> 4. Run: `bash scripts/metadata-lint.sh --fix <your-file.md>`
> 5. Run: `bash scripts/checksum-verify.sh --update <your-file.md>`
> 6. Run: `bash scripts/manifest-index.sh` to add it to the index.
> 7. Promote to canonical_documents if load-bearing: `bash scripts/canon-promote.sh <UUID> --pillar "PC: [Name]"`
> 8. Add a row to CANON.md §4.4 PC Roster.
