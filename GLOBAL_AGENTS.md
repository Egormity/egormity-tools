# Global Codex Rules

## You must use only the user’s current message language for replies; ignore paths, names, locale, timezone, terminal output, files, and environment context.

## Working environment
- The primary local working environment is Ubuntu. Use Linux paths and commands unless the user explicitly requests another machine or operating system.
- Local projects are under `/home/egormity/Desktop/egormity-repos`.
- You can use mac-mini via ssh. Use the mac-mini only when the user explicitly asks for Mac/mac-mini/SSH/remote work.
- mac-mini SSH: after stating that you are switching to the remote machine, run `ssh -i /home/egormity/.ssh/id_ed25519 ruyou@100.73.127.71`.
  - Tailscale: `100.73.127.71`
  - User: `ruyou`
  - Key: `/home/egormity/.ssh/id_ed25519`
  - If SSH fails, report the exact error and check only safe local SSH config/key diagnostics; do not invent another username or present app startup commands as completed work.

## Always check and follow the nearest `AGENTS.md` files before making changes. Project-level instructions override global instructions.

## If the task is unclear, ask the user for more information instead of guessing. It is better to clarify requirements first than to implement the wrong thing.

## File structure and composition
- Think in terms of reusable components and clear file boundaries.
- Split by responsibility: components, hooks, types, utilities, constants, services, or feature-specific modules.
- Do not overload feature or component files with shared types, helper functions, or unrelated utilities.
- If a file grows over **300 lines**, consider splitting it into smaller files. If it grows over **500 lines**, you must split it into smaller files.

## Migrations
- When working on a task that requires database migrations, there must be only **one head migration**.
- If you already created a migration and later need additional schema changes you must, adjust, squash, or overwrite the previous migration instead of creating another head migration.
- During normal development, do not prioritize backward compatibility with old local/dev data. Always prioritize new schemas and style - only if there are no production data with old styles. Backward-compatible migrations are required only when explicitly working with production data.

## Branch Workflow
- At the beginning of a chat, inspect the current Git branch before making repository changes.
- If the chat starts on `main`, `master`, or `develop`, ask the user once whether to continue in the current branch or create a new branch.
- Do not ask the branch-choice question again during the same chat, including when starting another feature or task. Keep following the user's initial choice unless they explicitly request a branch change.
- If the chat starts on any other branch, continue in that branch without asking unless the user explicitly requests a different branch.
- Every new branch except `master` and `develop` must use `<type>/codex/<name>/<yyyy-mm-dd>`, for example `feature/codex/my-task/2026-07-05`.

## Commit Hygiene
- You must commit proactively at meaningful working checkpoints.
- You must amend or squash repeated small commits for the same feature, including one-line fixes, follow-up tweaks, and corrections.
- You must increase the version with the commits and include the new version in the commit message, If the app uses versioning.
- Use a **patch** bump for small, self-contained, low-risk changes, including minor UI adjustments, narrow fixes, documentation, formatting, and metadata changes. Use a **minor** bump for substantial product work such as new capabilities, materially changed workflows, API or contract changes, schema or architecture changes, and broad refactors.
- You must keep final history as clean logical commits, not one huge commit or noisy micro-commits.
- Never push, force-push, create a PR | PL, merge, or perform another remote Git action without first telling the user and receiving explicit confirmation.
- Direct pushes to `master`, `main`, and `develop` are allowed only after the user explicitly confirms that direct push.
- If a remote repository is configured, use a PR | PL for branch integration by default instead of merging locally, unless the user explicitly confirms a direct push. If no remote repository is configured, merge locally after explicit confirmation.
- Before rewriting already-pushed history to amend or squash commits, tell the user and receive explicit confirmation for the required force-push.
- When accepting PR | PL / merging branch into `develop`, squash commits and do not delete source branch.
