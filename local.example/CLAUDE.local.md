# Employer-specific Claude rules. Copy to local/CLAUDE.local.md.
#
# These get written to ~/.claude/CLAUDE.md as a separate marker block, so they
# sit alongside the portable preferences without ever entering the public repo.
#
# Git and PR conventions live here on purpose: sign-off requirements, PR
# templates, and branch naming change with every company.

## Commits

- Sign off every commit: `git commit -s`.
- Subject line: `<area>: <what changed>`, imperative, under 72 characters.

## Pull requests

- Link the ticket in the description.
- Describe what changed and how it was verified.

## Branches

- `<initials>/<ticket>-<short-description>`
