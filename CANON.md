___
# Document Metadata

**Document Title:** [Campaign Name] Canon Index  
**Document ID (UUID):** `76123faa-d6b9-41f4-b56b-ede07519db37`  
**Version (SemVer):** `1.0.0`  
**Status:** Canon  
**Canonical Scope:** CAMPAIGN/CANON-INDEX  
**Last Updated (YYYY-MM-DD):** `2026-03-01`  
**Checksum:** `a22e53586ffa6c18cc34c6df7cf45b4729ebf95e9a958121b07d358131a0c54f`  

## Versioning Notes
- **MAJOR** (`X.0.0`): Breaking canon changes (restructuring, removing anchors, altering core constraints)
- **MINOR** (`0.X.0`): Adding new pillars, new authority pointers, new glossary terms
- **PATCH** (`0.0.X`): Corrections, typo fixes, minor clarifications with no semantic change

## Release Notes (from N/A → 1.0.0)
- Initial CANON.md template
___

## At a Glance
- Starting context index — read this file first every session.
- Contains setting contract, timeline locks, controlled vocabulary, and authority map.
- All authority pointers are UUID-backed, version-tracked, and inline-pointer checked.
- Run `bash scripts/canon-validate.sh` before any editing work to confirm clean state.
- [Add 1–2 campaign-specific quick-facts here once populated.]

---

# [Campaign Name] Canon — Start Here

This file is the **starting context index** for this repository. It provides:
- **canon anchors** that must not drift,
- a **controlled vocabulary** (what we call things),
- a **timeline lock** (campaign start and fixed events), and
- an **authority map** pointing to canonical deep-dive documents.

If you suspect missing context, contradictions, or version bleed, consult this file first.

**Lore retrieval shortcut:** Rather than reading full documents with inline metadata, use
the UUID-driven retrieval layer:
```
bash scripts/lore-get.sh --meta    <UUID>   # title, version, status, scope
bash scripts/lore-get.sh --body    <UUID>   # document body only
bash scripts/lore-get.sh --history <UUID>   # release history
```
UUIDs for all documents are in `canon-manifest.json` (`extended_index` key).
See `AGENTS.md §3` for full retrieval workflow.

---

## §1 — Campaign Contract

- **System:** [e.g. GURPS 3rd Edition / D&D 5e / Call of Cthulhu 7e / Pathfinder 2e]
- **Setting:** [Primary location, era, and brief flavor — e.g. New England, 1923, Prohibition-era port town]
- **Tone:** [e.g. starts mundane and grounded; escalates into Lovecraftian dread; PCs are not conquering heroes]
- **Mythos / cosmology stance:** [e.g. cosmic indifference; gods real and political; no alignment axis assumed]
- **Baseline mandate:** [One non-negotiable campaign truth that must never drift]

---

## §2 — Canon Keys

### §2.1 Naming and Terminology (High-Signal)

> Lock terms here that have caused confusion or must not drift. Add entries as needed during play.

- **[Term]:** [Definition — one line; what it means in this campaign and what it is not]
- **[Term]:** [Definition]

### §2.2 Canon Priority When Artifacts Conflict

Prefer the artifact that is:
1. most recent `Last Updated`, then
2. explicitly marked **Status: Canon**, then
3. has the matching **Checksum** referenced by the GM, then
4. higher SemVer.

When a conflict is detected: mark it `POTENTIAL VERSION CONFLICT` and do not silently "fix" canon.

---

## §3 — Timeline Anchors (Locked)

- **Campaign start:** [Date or description — lock this first; everything else is relative to it]
- **[Event]:** [~time relative to start or absolute date; brief description]
- **[Recurring event]:** [Cadence and why it matters for play]

---

## §4 — Pillars

> Each subsection is an anchor: a prose digest plus machine-verified authority pointers.
> See `docs/canon-format.md §3` for the full anchor subsection pattern and inline pointer rules.

### §4.1 [Pillar Name] (anchor)

[2–5 bullet prose digest. What an LLM or GM needs to know first without reading the full
doc. Dense, drift-preventing, unambiguous: who/what this is, how it functions, key canon
constraints, what it is not.]

**Authority:**
* [Document Title] (`<UUID>` v<version>)

### §4.2 [Pillar Name] (anchor)

[Prose digest.]

**Authority:**
* [Document Title] (`<UUID>` v<version>)
* [Document Title 2] (`<UUID2>` v<version>) ([scope note — optional])

### §4.N PC Roster

[Brief note — e.g. character sheets are system-specific exports; use `Story/PCs/` lore
files for narrative reference. UUIDs are stable across file renames.]

| PC | Player | Archetype | District / Home | Character Sheet | Story File UUID |
|---|---|---|---|---|---|
| [Name or TBD] | [Player] | [Role] | [Location] | [path or —] | `<UUID>` |

**Authority:** `Story/PCs/` — one lore file per PC (background, NPC connections, GM
hooks, session notes). Individual UUIDs tracked in `canon-manifest.json` extended_index.

---

## §5 — Controlled Vocabulary

- **[Term]:** [In-world meaning — what to use and what not to use]
- **[Term]:** [Definition]

*(Add terms here only if they prevent drift or clarify repeated confusion.)*

---

## §6 — Authority Map

### §6.1 Authority Reference Format

Authority references in `**Authority:**` blocks use the following format. Checksums are
stored exclusively in `canon-manifest.json` and managed by `scripts/canon-validate.sh`
— not in this file.

**Inline pointer format** (used in §4 `**Authority:**` blocks):
```
* <Document Title> (`<UUID>` v<Version>)
```

**Authority Map table columns:**
- **Pillar**: description of this document's role in the campaign
- **File Path**: path relative to repo root — navigation hint; UUID is the stable identity
- **UUID**: never changes on rename or move
- **Version**: current SemVer from document metadata; auto-synced by `canon-validate.sh --update`

### §6.2 Map

| Pillar | File Path | UUID | Version |
|---|---|---|---|
| Canon Index (this file) | `CANON.md` | `76123faa-d6b9-41f4-b56b-ede07519db37` | `1.0.0` |
| [Pillar description] | `[path/to/file.md]` | `[UUID]` | `[version]` |

---

## §7 — Open Questions / GM Decisions

> Use this section to park items that are *not yet locked*, so they don't quietly
> become "canon by accident."

- `[OPEN ITEM: ...]`

---

## §8 — Changelog Pointer

When this file changes, keep changes small and list them in the metadata Release Notes.
For major lore additions, prefer updating the pillar document and only adding a
**brief anchor + authority pointer** here.

---

*This file is the session-start context index. Read it first. When in doubt, it is canon.*
