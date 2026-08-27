---
name: parallel-worktree-agents
description: Run several agents at once, each isolated in its own git worktree. Use when work splits into independent pieces that all touch files — parallel features, a migration across many files, fixing several failures at once.
allowed-tools:
  - Bash
  - Read
  - Agent
---

# Parallel agents in worktrees

Agents editing the same working tree overwrite each other. A git worktree gives
each one its own checkout of the same repository, so they can run at once.

Use `superpowers:using-git-worktrees` for worktree mechanics and
`superpowers:dispatching-parallel-agents` for how to split work. This skill is
the rule for combining them.

## The rule

Every dispatched agent that writes files gets `isolation: "worktree"`. No
exceptions for "it's just one agent" or "it's a small change" — the isolation
costs almost nothing and the failure it prevents is silent, corrupt state.

Read-only agents that search or summarize do not need one.

## Splitting the work

Split so the pieces do not need each other's results. If piece B needs piece
A's output, that is a sequence, not a fan-out, and running them in parallel
just produces a conflict later.

Good splits: one file or module per agent, one test failure per agent, one
independent feature per agent.

Bad splits: an agent that defines an interface and another that consumes it,
two agents editing the same file, anything where "merge the results" means
resolving semantic conflicts by hand.

If the work does not split cleanly, say so and do it sequentially. A bad
parallel split is slower than a good sequential one.

## Collecting

1. Wait for every agent. Do not report partial results as complete.
2. Read what each one actually did — the diff, not its summary of the diff.
3. Merge worktree branches one at a time. Conflicts here mean the split was
   wrong; record that rather than just resolving it.
4. Run the full test suite on the merged result. Each agent's tests passing in
   isolation says nothing about the combination.
5. Remove worktrees once merged.

## Reporting

Say how many agents ran, what each produced, what conflicted, and what the
merged state does. If an agent failed or returned nothing, say which and do not
quietly drop its share of the work.
