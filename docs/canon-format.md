<!-- Infrastructure documentation — no metadata block by design.
     This file is a convention spec, not a tracked lore artifact.
     canon-validate.sh and the pre-commit hook do not apply to it.
     See AGENTS.md §1 (Infrastructure Files) for the rationale. -->

# CANON.md Convention Specification

`CANON.md` is the **session-start context index** for a CampaignLoreLM campaign repo.
It is not a deep-dive lore document — it is a navigation and orientation layer: setting
anchors, named pillars with prose digests, and machine-verified authority pointers. LLMs
and GMs read it first every session.

This spec defines the required structure, section order, and formatting conventions. It is
grounded in the behavior of `scripts/canon-validate.sh`.

---

## 1. Infrastructure vs. Lore Files

All Markdown files in a CampaignLoreLM repo fall into one of two categories:

| Category | Examples | Metadata block? | Tracked by manifest? |
|---|---|---|---|
| Lore artifacts | `CANON.md`, all docs in lore directories | Yes | Yes |
| Infrastructure | `AGENTS.md`, `README.md`, `docs/canon-format.md` | **No** | No |

Infrastructure files intentionally omit the metadata block. Do not add one. The pre-commit
hook only fires on files with metadata blocks — infrastructure files are excluded by design.

---

## 2. Required Sections (in order)

| Section | Purpose |
|---|---|
| Metadata block (`___` … `___`) | Machine-readable header; checksum-enforced |
| `## At a Glance` | 3–5 bullet quick-scan; required first element of all lore doc bodies |
| Intro block (untitled paragraph + retrieval shortcut) | What this file is; lore-get.sh shortcut |
| `## §1 — Campaign Contract` | Locked system/tone/setting/period facts |
| `## §2 — Canon Keys` | §2.1 naming/terminology; §2.2 conflict tiebreaker |
| `## §3 — Timeline Anchors` | Fixed dates and events |
| `## §4 — Pillars` | Anchor subsections (see §3 below) |
| `## §5 — Controlled Vocabulary` | Short glossary — terms that must not drift |
| `## §6 — Authority Map` | §6.1 format spec; §6.2 machine-verified table |
| `## §7 — Open Questions` | Unresolved decisions; prevents "canon by accident" |
| `## §8 — Changelog Pointer` | Editing discipline guidance |

---

## 3. Pillar Anchor Subsection Pattern (§4)

This is the core structural unit of `CANON.md`. Each pillar is a numbered subsection
under `## §4 — Pillars`:

```markdown
### §4.N [Pillar Name] (anchor)

[Prose digest — 2–5 tight bullets or a short paragraph. What an LLM or GM needs to
know first without reading the full document. Dense, unambiguous, drift-preventing:
who/what this is, how it functions, key canon constraints, what it is not.]

**Authority:**
* [Document Title] (`<UUID>` v<version>)
* [Document Title 2] (`<UUID2>` v<version>) ([optional scope note])
```

### Rules

- The `**Authority:**` block uses inline pointer format exactly as shown. Each pointer
  line **must start with `* `** (asterisk-space). This is what `canon-validate.sh`
  matches when checking inline pointer versions.
- UUID and version must match the document's current metadata block verbatim.
- `canon-validate.sh` (Step 4) scans CANON.md for lines matching `^\* .+(`\`<uuid>\``)` and
  verifies the version against `canonical_documents`. It emits WARN (not FAIL) if no
  inline pointer is found for a promoted document.
- `canon-validate.sh --update` auto-syncs inline pointer versions in CANON.md when
  a promoted document is updated. This only works with the `* Title (\`UUID\` vX.Y.Z)`
  format — table cells and other formats are ignored.
- Multiple authority docs per pillar are normal. Order by specificity (most specific
  first); add a parenthetical scope note when helpful.
- Use `—` (or omit the `**Authority:**` block entirely) for pillars without a promoted
  doc yet.

### PC Roster is the exception — use a table

The PC Roster is the one pillar that belongs in a table. Character sheets and narrative
lore files are distinct references and warrant separate columns:

```markdown
| PC | Player | Archetype | District / Home | Character Sheet | Story File UUID |
|---|---|---|---|---|---|
| [Name or TBD] | [Player] | [Role] | [Location] | [path or —] | `<UUID>` |
```

Add an `**Authority:**` note below the table pointing to the `Story/PCs/` directory.

---

## 4. The Two Reference Formats and What the Script Checks

`CANON.md` uses two distinct reference formats with different machine-visibility:

| Format | Where used | Script behavior |
|---|---|---|
| `* Title (\`UUID\` vX.Y.Z)` | `**Authority:**` blocks in §4 | Checked in Step 4 of validate; version auto-synced by `--update` |
| `\| … \| \`UUID\` \| \`version\` \|` | §6.2 Authority Map table | Version column auto-synced by `--update` |

**Table cells with `[\`UUID\`]`** (e.g., a PC roster UUID cell) are navigational
shortcuts — human-readable only. No script checks or updates them.

---

## 5. Authority Map (§6)

### §6.1 Format block

Include a brief description of the inline pointer format and the table columns.
Emphasize that checksums live only in `canon-manifest.json`, never in `CANON.md`.

### §6.2 Map table

```markdown
| Pillar | File Path | UUID | Version |
|---|---|---|---|
| [Description] | `path/relative/to/root` | `<UUID>` | `<version>` |
```

- One row per document in `canonical_documents` in the manifest.
- Add a row here after running `canon-promote.sh <UUID>`.
- `canon-validate.sh --update` auto-syncs the Version column.
- Do not add checksums to this table.

---

## 6. §7 — Open Questions

A staging area for decisions that are **not yet locked**. If something unresolved is
written in a pillar section without a flag, LLMs will treat it as locked canon. Use §7
instead.

```markdown
## §7 — Open Questions / GM Decisions

- [OPEN ITEM: what is the fate of X? — not yet decided]
- [OPEN ITEM: which faction controls Y? — pending Session 3]
```

---

## 7. §8 — Changelog Pointer

Brief guidance on editing discipline: when CANON.md changes, keep edits small and list
them in Release Notes. Heavy lore additions go in pillar docs; CANON.md gets only an
anchor update and authority pointer.

---

## 8. Versioning Rules for CANON.md

| Change type | Bump |
|---|---|
| Restructure, remove anchors, alter core constraints | MAJOR |
| Add new pillar subsection, add §6.2 row, add glossary term | MINOR |
| Corrections, typo fixes, clarifications with no semantic change | PATCH |

Note: `canon-validate.sh --update` modifies CANON.md body content (syncing inline
pointer versions and the §6.2 Version column). After running `--update`, the body has
changed and requires a version bump and new checksum — at minimum PATCH. The `--update`
command re-finalizes CANON.md automatically (lint + checksum), but you must bump the
version and add a Release Notes entry manually.

---

*Read `AGENTS.md` for the full workflow. Read `CANON.md` at session start.*
