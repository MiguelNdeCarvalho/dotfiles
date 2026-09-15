---
name: atomic-commit-workflow
description: Apply strict atomic Git commit workflow and path-scoped message style. You must use this skill whenever the user asks to commit changes, create or prepare commits, split work into commits, stage changes for a commit, or write commit messages—even if they only say "commit this," "stage it," or ask for message suggestions.
---

# Atomic commit workflow

Create small, independently reviewable commits in established path-scoped style. Never turn a worktree full of changes into one huge commit.

## Non-negotiable principles

- Make each commit one logical change. One logical change may include tightly coupled files that must move together, such as behavior and its tests, a manifest and its resulting lockfile, or source and required tracked generated output.
- Split changes that can be reviewed, reverted, or explained independently—even when they are in the same file. Stage hunks when necessary.
- Default to one concern and usually one file. Treat roughly 50 changed lines as a review prompt, not a quota. At more than 100 lines or more than 5 files, stop and prove the change is indivisible; otherwise split it.
- Never use a broad project objective as justification for a broad commit. Split initiatives by subsystem or dependency-safe, reversible step.
- Preserve all unrelated work. Never discard, rewrite, stash, or absorb changes merely to make the worktree look clean.
- Keep implementation and the tests that directly validate it in the same commit.
- Keep a lockfile or required generated output with the source change that produced it, but exclude unrelated churn and investigate surprising regeneration.
- Run relevant focused checks where practical. Expand checks when shared interfaces or infrastructure are affected.
- Let hooks run normally. Never bypass hooks or use `--no-verify`.

## Inspect before deciding

Before staging or proposing a split, inspect all three views:

```bash
git status --short --branch
git diff --stat
git diff
git diff --cached --stat
git diff --cached
```

Also inspect repository instructions and recent local message style when available. Established repository-local conventions and enforced rules override the generic message style below; otherwise use the path-scoped style defined here.

Inspect the contents, type, and size of every untracked path considered for staging. Never stage an untracked file based only on `git status`; check it for secrets and generated or binary content first.

Classify every changed file and hunk as:

1. part of the current logical change,
2. part of a separate commit, or
3. unrelated work to leave untouched.

Do not assume an already staged change belongs to the requested commit. If the index contains content outside the authorized unit, do not stage or commit anything else. Ask the user to commit or clear it, or obtain explicit permission to unstage only named paths or hunks while preserving the worktree. Then reinspect the index. If ownership or intent remains ambiguous, stop and ask rather than moving or committing it.

## Build atomic commits

Use these tests when grouping changes:

- Can the commit be described by one concise imperative sentence?
- Can it be reviewed and reverted independently?
- Would splitting it leave either side broken, misleading, or unable to pass its direct tests?
- Are repeated edits one mechanical operation over one coherent file family?

Group files when splitting would leave a side broken or misleading, or when the edits form one coherent mechanical operation. Examples of valid coupling include implementation plus direct tests, provider declaration plus regenerated lockfile, and a coherent rename plus necessary reference updates. Split unrelated formatting, cleanup, refactors, fixes, or configuration changes.

For a mixed file, use patch staging. A preparatory refactor may be separate only when it is independently valid and checks remain green.

Large generated, encrypted, rename, or deletion diffs can exaggerate line counts. Inspect their source intent and exact file list separately, but keep them together only if splitting would break the logical operation.

## Stage narrowly

Stage explicit paths or hunks:

```bash
git add -- path/to/file
git add -p -- path/to/file
git add -u -- exact/deleted/path
```

Avoid blanket staging and implicit inclusion: do not use `git add -A`, `git add .`, or `git commit -a`. Do not use broad reset, checkout, clean, or stash operations to manipulate someone else's work.

For deletions, verify the exact deleted path list and check remaining references. Group repeated deletions only when they remove one coherent artifact family. Preserve pure renames as renames where practical.

## Verify every staged unit

Before each commit—not just once for the whole task—run:

```bash
git status --short
git diff --cached --name-status
git diff --cached --stat
git diff --cached
git diff --cached --check
```

Confirm that:

- the index contains exactly one logical change,
- no unrelated hunk or pre-existing staged work slipped in,
- deletions, renames, generated files, and lockfiles are intentional,
- the staged diff matches the proposed subject,
- whitespace checks and relevant tests pass.

If a check or hook modifies files, inspect those changes. Stage only outputs belonging to the same logical change, rerun the relevant checks, and verify the staged diff again.

## Format subjects deterministically

Use a concise, capitalized imperative action with no final period. Default to a subject only; add a body only when essential context cannot fit in the subject.

Do not use Conventional Commit prefixes such as `feat:` or `fix:` unless repository rules require them.

Use path spelling established by recent repository history, including logical or managed target paths. Otherwise preserve repository-relative spelling and case. Separate directory components with `: ` rather than `/`.

Apply these rules in order:

1. **Modified file:** Include every directory component and the basename, then the action.
   - Nested: `folder1: folder2: file.ext: Change behavior`
   - Root: `file.ext: Change behavior`
2. **Added file:** Use its containing directories as scope; put the basename in the `Add` action.
   - Nested: `folder1: folder2: Add file.ext`
   - Root: `Add file.ext`
3. **Deleted file:** Use its containing directories as scope; use `Remove basename` for an exact ordinary deletion. Use `Nuke basename-or-pattern` only for an intentional wholesale cleanup.
   - Nested ordinary: `folder1: Remove file.ext`
   - Nested cleanup: `folder1: Nuke old-*.tfvars`
   - Root: `Remove file.ext` or, for wholesale cleanup, `Nuke file.ext`
4. **Renamed file:** Use the shared containing directory as scope and write `Rename old-name to new-name`. At root, omit the scope.
   - Nested: `folder1: Rename old.tf to main.tf`
   - Root: `Rename old.tf to main.tf`
5. **Tightly coupled multi-file change:** Use the longest useful shared directory scope. Name the primary behavior or configuration file when companion tests, lockfiles, or generated outputs merely follow it. For peer files receiving the same operation, compress their basenames with a truthful brace group, prefix glob, or family name. For a coherent cross-tree mechanical operation, use the shortest accurate directory-family wildcard.
   - Primary plus companion: `site_server: terraform.tf: Bump AWS provider to v6.52.0`
   - Peer family: `services: deployment_{api,orders}.tf: Set resource limits`
   - Cross-tree family: `site_*: Use data to get the region instead of var`

Do not enumerate unrelated paths in one subject; split the commits instead. Do not invent a directory scope for root files.

### Good subjects

- `folder1: file.ext: Change retry behavior`
- `folder1: Nuke file`
- `folder1: Add file`
- `site_monitoring: prometheus_alerting.tf: Update thresholds from the last 30d`
- `.github: workflows: build-deploy.yml: Remove environment from build push step`
- `site_kubernetes: utils: clickhouse-backup-cron: main.py: Use CH_BACKUP_TEMP_PVC_SIZE for temp storage`
- `.mise.toml: Bump AWS to v2.34.0`
- `site_inception: Rename old-cognito.tf to cognito.tf`

### Bad subjects

- `misc changes` — vague, non-imperative, and probably non-atomic
- `feat(terraform): bump provider.` — unwanted Conventional Commit syntax and a final period
- `folder1/file: updated stuff` — slash path, lowercase non-imperative action, and vague summary
- `Update files` — omits the path and intent
- `folder1: file1: Change API and folder2: file2: Fix alert` — combines independently reviewable changes
- `WIP` — does not describe a finished logical change

## Step-by-step workflow

1. Read repository instructions and determine whether the request authorizes committing, staging only, splitting/planning, or message writing only. Do not perform a stronger action than requested.
2. Inspect status plus complete unstaged and staged diffs.
3. Inventory files and hunks; preserve unrelated and ambiguous changes.
4. Plan the smallest dependency-safe commit sequence. Put prerequisites before dependents and tests with their behavior.
5. Select the next logical unit and stage only its explicit files or hunks.
6. Review staged names, stat, full diff, and `git diff --cached --check`.
7. Run relevant checks where practical. Inspect and narrowly stage any check-generated output, then re-verify the index.
8. Derive the subject from the staged paths and intent using the deterministic rules above.
9. If the user requested a commit, commit normally and allow hooks to run. If asked only to prepare or stage, stop before committing and report the staged unit.
10. Reinspect status after each commit, then repeat from the next logical unit. Report what remains staged, unstaged, or untracked; do not silently absorb it.

## History and remote safety

- Do not amend unless the user explicitly requests it. Even then, amend only an agent-owned, unpublished current commit of the same logical scope after inspecting the index. Prefer a new fix commit once history is shared.
- Do not push unless the user explicitly requests it. Before pushing, require successful checks and review the outgoing commits and destination branch.
- Do not force-push unless the user explicitly approves a force-push. Never use plain `--force`; confirm the branch is appropriate, fetch first, and prefer `--force-with-lease`. Stop if the lease fails.
- Never widen authorization: a request to commit does not authorize amend, push, force-push, or hook bypass.
