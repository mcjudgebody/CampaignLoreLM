# AGENTS.md — CampaignLoreLM: Canon Management Framework

> **How this file works — read before editing:**
>
> This file has **two parts**, separated by a clearly marked delimiter line.
>
> - **Part I (above the delimiter):** Infrastructure specification — document format,
>   script reference, workflow rules, and canon discipline. **Do not edit this section
>   during campaign setup or play.** It defines the tools and rules that keep your
>   lore consistent across sessions and across LLM context windows.
>
> - **Part II (below the delimiter):** Campaign configuration — your campaign's world,
>   tone, cast, and current state. Fill this section in when bootstrapping a new
>   campaign. Update it as the campaign evolves. Keep it **brief** — this file is
>   the LLM's quick-reference context, not a lore document.
>
> **If you are an LLM reading this file:**
> Apply the rules in Part I to all document work. Use Part II as your campaign
> context. Do not propose changes to Part I unless explicitly asked to modify
> infrastructure. If you find yourself editing above the delimiter, stop and ask
> the human to confirm.

---

# Part I — Infrastructure

## 0) Start Here — Session Protocol

Before creating, editing, or reconciling **any** document:

1. **Run `bash scripts/canon-validate.sh`** from the repo root. If it reports FAILs,
   surface them before proceeding. Do not silently ignore failures.
2. **Read `CANON.md`** — the canonical index and starting context for this campaign.
   It contains setting anchors, timeline locks, faction summaries, and authority
   pointers to all primary source documents.

**Default rule:** If you are unsure what is canon, consult `CANON.md` first. If a
document conflicts with `CANON.md`, flag it as `POTENTIAL VERSION CONFLICT` rather
than silently resolving it.

**CANON.md structure:** `CANON.md` follows the convention spec in `docs/canon-format.md`.
When building or extending `CANON.md`, consult that spec — particularly §3 (the anchor
subsection + inline pointer pattern) and §4 (the two reference formats and what the
validation script checks).

---

## 1) Required Metadata Block Format

Every Markdown document in this repository **must begin** with the following metadata
block format exactly. This block is what the canon management scripts parse for
integrity verification, indexing, and version history.

```text
___
# Document Metadata

**Document Title:** <TITLE>
**Document ID (UUID):** `<UUID>`
**Version (SemVer):** `<X.Y.Z>`
**Status:** <Canon|Draft|Deprecated>
**Canonical Scope:** <SLASH/SEPARATED/SCOPES>
**Last Updated (YYYY-MM-DD):** `<YYYY-MM-DD>`
**Checksum:** `<SHA-256-HEX>`

## Versioning Notes
- **MAJOR** (`X.0.0`): Breaking canon changes (alters meaning, sequence, or core artifacts)
- **MINOR** (`0.X.0`): Additive content consistent with existing canon
- **PATCH** (`0.0.X`): Typos, formatting, minor clarifications with no semantic change

## Release Notes (from <PREV> → <NEW>)
- <bullet describing what changed>
___
```

### Metadata rules

- Every field line in the primary metadata section (above `## Versioning Notes`)
  **must end with exactly two trailing space characters**. This is required for
  correct Markdown line-break rendering. `metadata-lint.sh --fix` corrects violations.
- `Document ID (UUID)` is generated once at creation and **never changes** across
  versions. Generate with `uuidgen` or any UUID v4 generator.
- `Checksum` is the SHA-256 of everything after the closing `___` line.
  Compute with `bash scripts/checksum-verify.sh --update <file>`.
- `Last Updated (YYYY-MM-DD)` should reflect the local calendar date of the edit.
- `Version (SemVer)` increments: PATCH for typos/formatting, MINOR for additive
  content, MAJOR for breaking changes.
- `Status` values: `Canon` (GM-endorsed), `Draft` (working, non-authoritative),
  `Deprecated` (superseded, kept for history).
- When creating a new version: bump Version, update Last Updated, update Checksum,
  add Release Notes bullets.

### Infrastructure files (no metadata block)

The following files are infrastructure documentation and **intentionally omit the metadata
block**. Do not add a metadata block to them:

- `AGENTS.md` (this file)
- `README.md`
- `docs/canon-format.md`

The pre-commit hook and all canon management scripts only apply to files with metadata
blocks. Infrastructure files are excluded by design. If an LLM adds a metadata block to
one of these files, remove it.

### At a Glance section (required in all document bodies)

Every document body (content after the closing `___`) **must open** with:

```markdown
## At a Glance
- <most important fact 1>
- <most important fact 2>
- <most important fact 3>
```

3–5 bullets maximum. Each bullet is a concrete, standalone fact. This section allows
an LLM or GM to quick-scan without reading the full document. Adding `## At a Glance`
to an existing document is a MINOR version bump.

---

## 2) Two-Tier Canon Model

`canon-manifest.json` maintains two parallel signals of "canon":

| Tier | Signal | Meaning | Managed by |
|------|--------|---------|------------|
| **Status: Canon** | `Status:` field in document metadata | Accurate, usable, GM-endorsed content | Author / `manifest-index.sh` |
| **`canonical_documents` entry** | Entry in `canon-manifest.json` | Integrity-tracked pillar doc; checksum-verified on every validate run | `canon-promote.sh` + `canon-validate.sh` |

A document can be `Status: Canon` without being in `canonical_documents` (e.g.,
player handouts accurate but not mechanically load-bearing). A `canonical_documents`
entry always implies `Status: Canon`.

**To promote a document to `canonical_documents`:**
```bash
bash scripts/canon-promote.sh <UUID> [--pillar "description"]
bash scripts/canon-validate.sh       # confirm entry passes integrity check
```

---

## 3) UUID-Driven Lore Retrieval

`canon-manifest.json` maintains a **UUID-indexed retrieval layer** (`extended_index`)
that covers all metadata-bearing `.md` files. Use it without reading full metadata blocks:

```bash
bash scripts/lore-get.sh --path    <UUID>              # file path
bash scripts/lore-get.sh --body    <UUID>              # document body only
bash scripts/lore-get.sh --meta    <UUID>              # compact metadata summary
bash scripts/lore-get.sh --history <UUID> [--last N]   # release history
```

UUID lookup order: `extended_index` first, then `canonical_documents` as fallback.
Both keys live in `canon-manifest.json`. Do not manually edit `canonical_documents`.

**Always use full UUIDs.** All UUID references in any project artifact — script calls, authority pointers, inline cross-references, document metadata — must use the complete five-segment form (e.g. `8d5c9d40-8273-4e95-b125-e432ef80c826`). Abbreviated UUIDs (e.g. `8d5c9d40`) are **not valid** for script lookups and will cause retrieval errors. Never write, copy, or reuse a UUID in abbreviated form.

---

## 4) Script Reference

| Script | Purpose |
|--------|---------|
| `canon-validate.sh` | Validate all manifest entries against live files; check CANON.md pointer versions; check extended_index freshness. Use `--update` to sync all. |
| `checksum-verify.sh <file>` | Verify body SHA-256. Use `--update` to recompute. |
| `metadata-lint.sh <file>` | Check trailing-space compliance. Use `--fix` to repair. |
| `manifest-index.sh` | Scan all `.md` files and rebuild `extended_index` in manifest. |
| `history-mirror.sh` | Parse Release Notes and populate `release_history` in `extended_index`. |
| `lore-get.sh` | UUID-driven retrieval (`--meta`, `--body`, `--path`, `--history`). |
| `body-verify.sh` | Validate that `--body` output is clean for all indexed files. |
| `canon-promote.sh <UUID>` | Promote a `Status: Canon` document to `canonical_documents`. |
| `install-hooks.sh` | One-time setup: installs pre-commit validation hook. |

**Dependencies:** `jq` (required for all manifest operations), `bash 3.2+`, standard POSIX tools.
Scripts are cross-platform (Linux + macOS).

---

## 5) Editing Workflow

### Session start
```bash
bash scripts/canon-validate.sh   # confirm clean state before any edits
```
If FAILs are reported, surface them before proceeding.

### After editing a document
```bash
bash scripts/metadata-lint.sh --fix <file>      # fix trailing spaces
bash scripts/checksum-verify.sh --update <file> # recompute checksum
bash scripts/checksum-verify.sh <file>          # confirm OK
```

### Before committing
```bash
bash scripts/canon-validate.sh --update   # sync manifest + CANON.md pointers; refresh extended_index
bash scripts/canon-validate.sh            # confirm all OK
```
Stage `canon-manifest.json` alongside any canonical document changes — it is a committed
project artifact. Confirm `CANON.md` is current for any affected canonical artifacts
before staging.

### Pre-commit hook (one-time setup)
```bash
bash scripts/install-hooks.sh
```
After setup, `git commit` automatically runs lint + checksum on all staged `.md` files
with metadata blocks, and validates the manifest. Use `git commit --no-verify` only
when explicitly bypassing validation.

---

## 6) CANON.md Authority Pointer Format

When adding or updating authority references in `CANON.md`:

**Inline pointer format** (used in `**Authority:**` blocks in §4 anchor subsections):
```
* <Document Title> (`<UUID>` v<Version>)
```

**Authority Map table** (`CANON.md` §6 / Authority Map):
```
| Pillar | File Path | UUID | Version |
| <description> | `<path/from/repo/root>` | `<UUID>` | `<Version>` |
```

**Rules:**
- UUID is the stable identifier. If a file moves, update the path but not the UUID.
- Version must match the document's current metadata block exactly.
- Checksums live only in `canon-manifest.json` — never in CANON.md or inline pointers.
- `canon-validate.sh --update` syncs CANON.md versions and inline pointers automatically.

---

## 7) Canon Discipline Rules

- Treat repository Markdown files as the source of truth.
- If sources conflict, prefer: most recent `Last Updated` → `Status: Canon` → higher SemVer.
- Never assume older file content is correct if a newer version exists.
- Do not invent NPCs, factions, locations, or mechanics unless asked to create new material.
  Mark new material as **PROPOSED** or **Draft** — do not label Canon without explicit GM request.
- `Draft` documents are non-authoritative by default. Ignore them for lore synthesis unless
  the GM explicitly references them for the current task.
- If something doesn't add up: label `POTENTIAL VERSION CONFLICT`, list competing versions,
  propose which should be canonical and why. Do not silently resolve.
- Do not rename or move files unless explicitly requested.
- Do not delete content; deprecate via metadata and keep history.

---

## 8) Output Conventions

- Markdown only unless asked otherwise.
- Use fenced code blocks for stat blocks, mechanics snippets, and tables needing
  monospaced alignment.
- Avoid walls of text. Use headings, lists, and GM Notes callouts.
- Only add comments where logic isn't self-evident. Do not add docstrings or type
  annotations to code you didn't change.
- Do not add features, refactor, or make "improvements" beyond what was asked.

---

## ⛔ END OF INFRASTRUCTURE — DO NOT EDIT ABOVE THIS LINE ⛔

> **For LLMs:** Everything above this line is infrastructure. It governs how
> documents are formatted, how scripts work, and how canon is maintained. It must
> not be modified during campaign configuration or normal play. If you are asked
> to edit content above this line, push back and ask the human to confirm they
> intend to modify infrastructure — not campaign content.
>
> **For GMs:** Replace every `[PLACEHOLDER]` below with your campaign's details.
> Keep each section **brief**. This file is the LLM's quick-reference context,
> not a lore document. Heavy content belongs in separate `.md` files — not here.
>
> ⚠️ **Anti-drift warning:** Do NOT paste full NPC profiles, stat blocks, location
> descriptions, or multi-paragraph lore into Part II. Use one-line entries and
> reference the separate document file and UUID. If a section is getting long,
> it means the content belongs in a lore file, not here.

---

# Part II — Campaign Configuration

## A. Campaign Core Premise

- **System:** [e.g. GURPS 3rd Edition / D&D 5e / Call of Cthulhu 7e / Pathfinder 2e]
- **Tone:** [e.g. investigative horror / high fantasy / gritty realism / political intrigue]
- **Setting:** [Primary location — city, region, world name]
- **Period / Era:** [e.g. 1923 New England / Medieval / Far Future / Contemporary]
- **Campaign Pacing:** [e.g. starts mundane and grounded; escalates gradually into cosmic horror]
- **Special Constraints:** [e.g. avoid resurrection magic / period accuracy mandatory / specific cosmology rules]

---

## B. Setting Quick Reference

| Item | Value |
|------|-------|
| System | [System + edition] |
| Tone | [One-line descriptor] |
| Setting | [Primary location] |
| Period | [Era or specific year] |
| Campaign start | [Where/when session 0 begins] |
| Key rule or mechanic | [Any custom mechanic the LLM must know] |

---

## C. LLM Instructions for This Campaign

> Replace this block with campaign-specific rules for how the LLM should behave.
> Examples:
> - "Prefer [X] framing — avoid [Y] framing"
> - "Period accuracy for [era] is mandatory; label guesses as NEEDS-VERIFY ([era])"
> - "Do not invent [faction/location/mechanic] without prompting"
> - "Treat [document title] as the authoritative source for [topic]"
> - "Player-facing content must be non-spoilery"

[Add your campaign-specific LLM instructions here.]

---

## D. Controlled Vocabulary / Naming Conventions

> List terms, names, or concepts that have fixed meanings in this campaign.
> One row per term. Keep definitions to one line.

| Term | Meaning |
|------|---------|
| [Term] | [Definition — one line] |

---

## E. Active Player Characters

> One row per PC. UUID links to the Story/PCs/ lore file. Keep notes to one line.
> Full mechanical and narrative detail goes in the lore file, not here.

| PC | Player | Archetype | Location | Story File UUID |
|----|--------|-----------|----------|-----------------|
| [Name or TBD] | [Player] | [Role/class] | [Home district or location] | [UUID or —] |

---

## F. Key NPCs (Brief)

> 3–5 words maximum per NPC entry. Full profiles go in `NPCs/` directory.
> If you need more than one line for an NPC here, the content belongs in a separate file.

| NPC | Role | Location | Notes |
|-----|------|----------|-------|
| [Name] | [Role] | [Location] | [One-line note] |

---

## G. Active Factions (Brief)

> One row per faction. Full faction docs go in their own files.

| Faction | Stance | Notes |
|---------|--------|-------|
| [Faction] | [Allied/Neutral/Hostile/Unknown] | [One-line note] |

---

## H. Current Campaign State

- **Session count:** [0 — not yet started / N sessions completed]
- **Current date (in-fiction):** [e.g. October 14, 1923 / Day 3 of the siege]
- **Active threads:** [List open plot threads, one line each]
- **Last session summary:** [One paragraph max — what happened]
- **Next session setup:** [What the PCs know going into next session]

---

## I. Authority Map

> Once CANON.md is populated, this section summarizes the key documents.
> Full authority map lives in CANON.md §6.

| Document | UUID | Version |
|----------|------|---------|
| CANON.md (starting context index) | [UUID from CANON.md metadata] | [version] |

---

*For the full authority map and all source document pointers, see `CANON.md`.*
*For script usage, see `README.md`.*
