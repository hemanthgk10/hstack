## Review

Review converges. One pass is not a review — run `review-until-convergence`,
which re-reviews after each round of fixes until a pass finds nothing new.
A single clean pass over unchanged code is the signal to stop, not the first
pass over the original.

## Writing

Prose meant for a human — README files, PR descriptions, docs, commit bodies,
design notes — goes through `humanizer` before I see it. Not a review of the
text, an edit of it.

This does not apply to code, logs, or machine-read output.

## Subagents

Every subagent that touches files runs in its own git worktree. Pass
`isolation: "worktree"` when dispatching. This is what makes several agents
runnable at once without them overwriting each other, so it holds even for a
single agent — the cost is near zero and the habit is what matters.

Read-only agents that only search or summarize do not need one.

## Process

Superpowers' process skills are the default path, not an upgrade:

- Brainstorm before building anything that does not already exist in the repo.
- TDD for features and bugfixes: failing test first.
- Verify before claiming done. Run the command, read the output, then say it
  works. "Should work" is not a result.
- Never commit or push unless I ask. Staging is fine; publishing is mine.

## Scope

Prefer the smallest change that solves the actual problem. `ponytail` covers
this and I want it applied, with one exception: it does not override the
process rules above. Brainstorming, tests, and review are not over-engineering.
