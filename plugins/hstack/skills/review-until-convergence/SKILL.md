---
name: review-until-convergence
description: Review code repeatedly until a pass finds nothing new. Use when reviewing a PR, branch, or diff, and whenever the user says review, check my changes, or is this ready to merge. One review pass is not enough — fixes introduce new problems.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Grep
  - Glob
  - Agent
---

# Review until convergence

A single review pass finds the problems in the original code. It does not find
the problems introduced by fixing them. Converged means the last pass over the
current code found nothing new.

## Loop

1. **Review.** Use the `code-review` plugin if it is installed; otherwise
   review the diff directly. Scope is the working diff unless the user named a
   PR, branch, or path.

2. **Triage.** Split findings into: fix now, out of scope, disagree. Say which
   is which. A finding you disagree with is not fixed silently — state why.

3. **Fix.** Apply the fix-now set. Keep each fix minimal.

4. **Re-review the new state.** Not the original diff. The fixes are now part
   of what is under review.

5. **Stop when a pass produces zero new findings.** Findings you already
   declined do not count as new. Report convergence and the pass count.

## Cap

Stop after 5 passes. If it has not converged by then, that is the finding: say
so, list what is still open, and hand it back. Do not keep going.

Rising or oscillating finding counts across passes mean the fixes are causing
the problems. Stop and say that instead of continuing.

## Reporting

Report per pass: how many findings, how many fixed, how many declined. Then the
verdict — converged after N passes, or hit the cap with M open.

Do not claim convergence without a final pass over the final code. A pass that
found nothing because it reviewed the old diff is not convergence.
