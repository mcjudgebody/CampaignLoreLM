___
# Document Metadata

**Document Title:** NPC — [Character Full Name]  
**Document ID (UUID):** `49c9b705-e729-4981-a6be-fe19d574fc49`  
**Version (SemVer):** `1.0.0`  
**Status:** Draft  
**Canonical Scope:** [CAMPAIGN/NPCS/NAME-OR-CATEGORY]  
**Last Updated (YYYY-MM-DD):** `YYYY-MM-DD`  
**Checksum:** `d2525d8f8daf673db508dacd98a0927a675ec242a1ac5164ed09c625e38094a2`  

## Versioning Notes
- **MAJOR** (`X.0.0`): Breaking canon changes (alters identity, core relationships, or established history)
- **MINOR** (`0.X.0`): Additive content — new connections, expanded background, session lore
- **PATCH** (`0.0.X`): Corrections/typos/minor clarifications with no semantic change

## Release Notes (from N/A → 1.0.0)
- Initial NPC profile created from CampaignLoreLM NPC template
___

## At a Glance
- [Name, role, and one-line identity anchor]
- [Most important relationship or allegiance]
- [Key personality trait or behavioral note for the GM]
- [One mechanical fact relevant to play — skill, advantage, or secret]

---

## Identity

**Full name:** [Name]
**Age:** [Age or approximate — e.g. "mid-forties"]
**Occupation / Role:** [What they do; their function in the setting]
**Location:** [Where they live or operate]
**Appearance:** [Brief physical description — what a player sees on first meeting]

---

## Background

[Who they are, where they came from, what shaped them. Keep to what's relevant
for play — the GM doesn't need a life history unless it has hooks.]

---

## Personality and Behavior

[How they talk, what they want, what they fear, how they treat strangers vs. allies.
Write this so the GM can pick up the character immediately at the table.]

- **Voice / mannerisms:** [Distinctive speech pattern, verbal tic, or physical habit]
- **Motivation:** [What they want — the driving force behind their decisions]
- **Fear / weakness:** [What they avoid, what they're hiding, what can be used against them]
- **Disposition toward PCs:** [Helpful / Neutral / Suspicious / Hostile — and why]

---

## Mechanical Profile

> [Optional — include key stats, skills, or advantages if mechanically relevant.]
> [If using a full character sheet, reference its path here instead of duplicating.]

**Key stats:** [ST/DX/IQ/WI/HT or equivalent system stats]
**Relevant skills:** [Skills relevant to likely interactions]
**Relevant advantages/disadvantages:** [Mechanical traits that affect roleplay or conflict]

---

## Relationships

| Connected to | Relationship | Notes |
|---|---|---|
| [Name / Faction] | [Nature of connection] | [One-line note] |

---

## Known Locations

| Location | Context |
|----------|---------|
| [Location] | [When/why they're found here] |

---

## GM-Only Notes

> [Hidden information the players should not see. Secrets, true motivations, plot
> roles, reveal timing. Mark clearly if this document is ever shared with players.]

- **True motivation:** [What they actually want, vs. what they claim to want]
- **Secret:** [What they are hiding — and who else knows]
- **Plot role:** [How this NPC serves the campaign structure]
- **Escalation:** [How they change as the campaign progresses]

---

## Interaction Notes

*(Record significant PC interactions here, most-recent-first, as campaign progresses.)*

---

> **Usage note (delete before publishing):**
> 1. Copy this file to your `NPCs/` directory with a descriptive filename.
> 2. Replace the UUID with a new one: `uuidgen | tr '[:upper:]' '[:lower:]'`
> 3. Fill in the metadata fields and document content.
> 4. Run: `bash scripts/metadata-lint.sh --fix <your-file.md>`
> 5. Run: `bash scripts/checksum-verify.sh --update <your-file.md>`
> 6. Run: `bash scripts/manifest-index.sh` to add it to the index.
> 7. Promote to Canon when GM-approved: `bash scripts/canon-promote.sh <UUID>`
