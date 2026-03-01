# CampaignLoreLM

A canon management framework for tabletop RPG campaigns, designed for collaborative
work with LLMs (Claude, Codex, Gemini, etc.). Keep your lore consistent, tracked,
and retrievable across sessions without burning context on re-reading every document.

---

## What This Is

CampaignLoreLM gives you:

- **Structured document format** — every lore file has a UUID, SemVer version,
  SHA-256 checksum, and a required `## At a Glance` section. LLMs can scan summaries
  before deciding whether to read the full document.
- **Machine-readable canon registry** — `canon-manifest.json` tracks all documents
  with two tiers: `canonical_documents` (integrity-verified pillar docs) and
  `extended_index` (all metadata-bearing files).
- **UUID-driven retrieval** — look up any document by UUID to get its path, body,
  metadata summary, or release history without manually browsing files.
- **Pre-commit validation** — a git hook automatically verifies checksums and trailing
  space compliance on staged `.md` files before every commit.
- **LLM instruction file** — `AGENTS.md` gives any LLM the workflow rules and campaign
  context it needs to maintain canon consistency. Part I is immutable infrastructure;
  Part II is your campaign configuration.

---

## Quick Start

### 1. Create your campaign repo

Click **"Use this template"** on GitHub to create a fresh copy in your own account,
then clone your new repo:

```bash
git clone git@github.com:<your-username>/<your-campaign-repo>.git my-campaign
cd my-campaign
bash scripts/install-hooks.sh   # one-time: activates pre-commit validation
```

> **Do not clone this repo directly.** The template button creates a clean copy in
> your account with no upstream pointing back here. A direct clone will have `origin`
> set to this repo and `git push` will fail (or worse, succeed if you have access).

> **After step 1, your LLM drives the rest.** Steps 2–4 describe what needs to happen —
> but in practice you just describe your campaign and ask. The LLM reads `AGENTS.md`
> on startup and knows the full workflow: it will fill in the templates, generate UUIDs,
> compute checksums, run the indexing scripts, and promote documents to canon on request.
> The manual commands below document what it does under the hood.

### 2. Configure your campaign

**LLM-first:** Open a chat session (e.g. `claude` in the repo root) and describe your
campaign — system, tone, setting, cast, themes, any special constraints. Ask the LLM to
fill in `AGENTS.md` Part II and draft `CANON.md` from your description. It knows the
required structure and placeholder locations.

**Manual fallback:** Edit `AGENTS.md` Part II directly (system, tone, setting, PCs, NPCs,
current state) and edit `CANON.md` to fill in setting anchors, timeline, factions, and
the authority map.

### 3. Create lore documents

**LLM-first:** Ask the LLM to create a document — e.g. *"Create a lore file for the city
of Kharys-Vel"* or *"Write an NPC profile for the merchant Dovan."* It will choose the
right template, generate a UUID, write the content, fix trailing spaces, compute the
checksum, and index the file in the manifest.

**Manual fallback:** Copy a template and complete each step yourself:

```bash
cp templates/lore-template.md World/MyLocation.md
cp templates/npc-template.md NPCs/VillainName.md
cp templates/pc-template.md Story/PCs/PlayerCharacter.md
```

For each new file:
1. Replace the UUID: `uuidgen | tr '[:upper:]' '[:lower:]'`
2. Fill in metadata fields (Title, Scope, Last Updated, Status)
3. Write your content
4. Fix trailing spaces: `bash scripts/metadata-lint.sh --fix <file>`
5. Compute checksum: `bash scripts/checksum-verify.sh --update <file>`
6. Index it: `bash scripts/manifest-index.sh`

### 4. Promote pillar documents to canon

**LLM-first:** Ask the LLM to promote a document — e.g. *"Promote the Kharys-Vel city
document to canonical status; it's the primary setting reference."* It will run the
scripts and confirm the result.

**Manual fallback:** When a document is load-bearing and GM-approved:

```bash
bash scripts/canon-promote.sh <UUID> --pillar "Description of this document's role"
bash scripts/canon-validate.sh       # confirm clean
```

---

## Session Workflow

### Session start
```bash
bash scripts/canon-validate.sh   # confirm clean state before editing
```
Read `CANON.md` for current campaign state.

### After editing documents
```bash
bash scripts/metadata-lint.sh --fix <file>
bash scripts/checksum-verify.sh --update <file>
```

### Before committing
```bash
bash scripts/canon-validate.sh --update   # sync manifest + CANON.md + extended_index
bash scripts/canon-validate.sh            # confirm all OK
git add <files> canon-manifest.json
git commit -m "..."
```

---

## Repository Structure

```
my-campaign/
├── AGENTS.md                  # LLM workflow instructions (Part I: infra / Part II: campaign)
├── CANON.md                   # Starting context index — read this first every session
├── canon-manifest.json        # Machine-readable canon registry
├── README.md                  # This file
├── LICENSE                    # MIT
│
├── templates/                 # Starting points for new documents
│   ├── lore-template.md       # Location, setting, or general lore
│   ├── npc-template.md        # Non-player character profile
│   └── pc-template.md         # Player character lore file
│
├── [World/ or Setting/]       # Your location and setting documents (create as needed)
├── [NPCs/]                    # NPC profiles (create as needed)
├── [Story/]                   # Campaign planning, PC files, session notes (create as needed)
│
└── scripts/                   # Canon management tooling
    ├── canon-validate.sh      # Validate / sync manifest + CANON.md pointers
    ├── checksum-verify.sh     # Verify / update SHA-256 body checksums
    ├── metadata-lint.sh       # Check / fix trailing-space compliance
    ├── lore-get.sh            # UUID-driven lore retrieval
    ├── manifest-index.sh      # Rebuild extended_index in canon-manifest.json
    ├── history-mirror.sh      # Mirror Release Notes into release_history JSON
    ├── body-verify.sh         # Validate body extraction for all indexed files
    ├── canon-promote.sh       # Promote a Canon document to canonical_documents
    ├── install-hooks.sh       # One-time pre-commit hook setup
    └── hooks/
        └── pre-commit         # Auto-runs lint + checksum on git commit
```

---

## Script Reference

| Script | Purpose |
|--------|---------|
| `canon-validate.sh` | Validate all manifest entries against live files; check CANON.md pointer versions; check extended_index freshness. Use `--update` to sync. |
| `checksum-verify.sh <file>` | Verify body SHA-256. Use `--update` to recompute. |
| `metadata-lint.sh <file>` | Check/fix trailing-space compliance on metadata fields. Use `--fix`. |
| `manifest-index.sh` | Scan all `.md` files and rebuild `extended_index` in `canon-manifest.json`. |
| `history-mirror.sh` | Parse Release Notes blocks and populate `release_history` in `extended_index`. |
| `lore-get.sh` | UUID-driven retrieval: `--path`, `--body`, `--meta`, `--history [--last N]`. |
| `body-verify.sh` | Validate that `lore-get.sh --body` output is clean for all indexed files. |
| `canon-promote.sh <UUID>` | Promote a `Status: Canon` document to `canonical_documents`. Use `--pillar`. |
| `install-hooks.sh` | One-time setup: installs the pre-commit validation hook. |

**Dependencies:** `bash 3.2+`, `jq`, standard POSIX tools. Works on Linux and macOS.

---

## Document Format

Every lore `.md` file begins with a metadata block:

```
___
# Document Metadata

**Document Title:** <title>
**Document ID (UUID):** `<uuid>`
**Version (SemVer):** `<X.Y.Z>`
**Status:** Canon|Draft|Deprecated
**Canonical Scope:** <SLASH/SEPARATED/SCOPES>
**Last Updated (YYYY-MM-DD):** `<YYYY-MM-DD>`
**Checksum:** `<SHA-256-HEX>`

## Versioning Notes
...

## Release Notes (from <prev> → <new>)
- <bullet>
___

## At a Glance
- <3–5 bullet summary>

[document body]
```

- **UUID** never changes for the lifetime of a document.
- **Checksum** is the SHA-256 of everything after the closing `___`.
- Every field line ends with exactly **two trailing spaces**.
- Every document body opens with `## At a Glance` (3–5 bullets).

---

## LLM Compatibility

`AGENTS.md` is read natively by **Claude Code** (the `claude` CLI). For other tools:

| Tool | Instruction file |
|------|-----------------|
| Claude Code (`claude` CLI) | `AGENTS.md` ✓ (native) |
| Cursor | `.cursor/rules/` — copy or symlink relevant sections |
| GitHub Copilot | `.github/copilot-instructions.md` — copy relevant sections |
| Codex / ChatGPT | Paste `AGENTS.md` Part I into system prompt; paste Part II as user context |
| Other LLMs | Include `AGENTS.md` content in system or context prompt |

For tools without native `AGENTS.md` support, the structure of the file (two-part with
clear delimiter) makes it easy to paste selectively.

---

## Canon Manifest

Two parallel keys in `canon-manifest.json`:

| Key | Purpose | Managed by |
|-----|---------|-----------|
| `canonical_documents` | Integrity-tracked pillar docs; verified on every validate run | `canon-promote.sh`, `canon-validate.sh` |
| `extended_index` | All metadata-bearing docs; full metadata + release history | `manifest-index.sh`, `history-mirror.sh` |

Do not manually edit `canonical_documents`. Use `canon-promote.sh <UUID>` to add entries
and `canon-validate.sh --update` to sync metadata.

---

## License

MIT — see [LICENSE](LICENSE). Use freely, fork for your campaign, contribute back if
you improve the tooling.
