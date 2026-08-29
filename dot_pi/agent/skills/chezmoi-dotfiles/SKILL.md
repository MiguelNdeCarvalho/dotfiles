---
name: chezmoi-dotfiles
description: Safely modify dotfiles managed by chezmoi on this machine. Use whenever changing files under ~/.config, home-directory dotfiles, Hyprland or Noctalia configuration, or any target backed by ~/.local/share/chezmoi. Edit the live target/origin file only, validate it, then run `chezmoi re-add <target>` so chezmoi updates its source and the configured workflow commits and pushes to git. Never edit the chezmoi source copy directly.
compatibility: Requires chezmoi and this machine's configured re-add workflow, which commits and pushes changes.
---

# Chezmoi dotfiles workflow

Treat files in the home directory as authoritative targets. Let `chezmoi re-add` update chezmoi's source state and git history.

## Workflow

1. Resolve the live target path under `$HOME`.
2. Confirm chezmoi manages it:
   ```bash
   chezmoi source-path "$target"
   ```
   A nonzero result means it is unmanaged. Do not assume a corresponding source file exists.
3. Read and edit the live target only, such as:
   ```text
   ~/.config/hypr/hyprland.lua
   ```
4. Do not edit files below:
   ```text
   ~/.local/share/chezmoi/
   ```
   Direct source edits bypass the target-first workflow and may later overwrite the live configuration.
5. Validate the target using relevant syntax, tests, and runtime checks. Run `chezmoi diff -- "$target"` when useful to inspect the pending target/source difference.
6. After validation succeeds, synchronize, commit, and push through the configured workflow:
   ```bash
   chezmoi re-add "$target"
   ```
   Pass all changed managed targets when one task intentionally changes several files. Avoid bare `chezmoi re-add` because it can capture unrelated modifications.
7. Verify completion:
   ```bash
   source_dir="$(chezmoi source-path)"
   git -C "$source_dir" status --short --branch
   git -C "$source_dir" log -1 --oneline
   ```
   Confirm command output shows successful commit/push and source repository has no unexpected changes.

## Failure handling

- If validation fails, fix target first. Do not re-add broken configuration.
- If `chezmoi re-add` fails, report exact short error and leave target intact for recovery.
- If push fails after commit, report local commit hash and push failure. Do not claim remote synchronization.
- If unrelated source-repository changes exist, do not discard or include them silently.
- Do not run `chezmoi apply` after editing target; it can replace target with old source state before re-add.

## Completion report

Report:

- Target path changed
- Validation performed
- `chezmoi re-add` result
- Commit hash
- Push/branch status
