# Global Codex Rules

## You must use only the user’s current message language for replies; ignore paths, names, locale, timezone, terminal output, files, and environment context.

## Working environment
- You can use mac-mini via ssh. Use the mac-mini only when the user explicitly asks for Mac/mac-mini/SSH/remote work.
- Projects are under `Desktop/egormity-repos` on both Windows and mac-mini.
- mac-mini SSH: run `ssh mac-mini` after stating that you are switching to the remote machine.
  - Tailscale: `100.73.127.71`
  - User: `ruyou`
  - Key: `%USERPROFILE%\.ssh\id_ed25519_codex_mac`
  - If SSH fails, report the exact error and check only safe local SSH config/key diagnostics; do not invent another username or present app startup commands as completed work.

## Always check and follow the nearest `AGENTS.md` files before making changes. Project-level instructions override global instructions.

## If the task is unclear, ask the user for more information instead of guessing. It is better to clarify requirements first than to implement the wrong thing.

## File structure and composition
- Think in terms of reusable components and clear file boundaries.
- Split by responsibility: components, hooks, types, utilities, constants, services, or feature-specific modules.
- Do not overload feature or component files with shared types, helper functions, or unrelated utilities.
- If a file grows over **300 lines**, consider splitting it into smaller files.

## Migrations
- When working on a task that requires database migrations, there must be only **one head migration**.
- If you already created a migration and later need additional schema changes you must, adjust, squash, or overwrite the previous migration instead of creating another head migration.
- During normal development, do not prioritize backward compatibility with old local/dev data. Always prioritize new schemas and style - only if there are no production data with old styles. Backward-compatible migrations are required only when explicitly working with production data.

## Branch Workflow
- Before starting work on a new feature, you must ask the user whether to continue in the current branch or switch to a new one.

## Commit Hygiene
- You must commit proactively at meaningful working checkpoints.
- You must squash repeated small commits for the same feature, including one-line fixes, follow-up tweaks, and corrections.
- You must increase the version with the commits and include the new version in the commit message, If the app uses versioning.
- You must keep final history as clean logical commits, not one huge commit or noisy micro-commits.
- Every branch except `master` and `develop` must use `<type>/codex/<name>/<yyyy-mm-dd>`, for example `feature/codex/my-task/2026-07-05`.
- Direct pushes to `master / main` and `develop` are not allowed.
- If a remote repository is configured, create a PR | PL for branch integration instead of merging locally. If no remote repository is configured, merge locally.
- When accepting PR | PL / merging branch into `develop`, squash commits and do not delete source branch.
