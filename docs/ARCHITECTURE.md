# Architecture

Why hstack is shaped the way it is. For how to change it, see
[CLAUDE.md](../CLAUDE.md).

## Two layers, two entry points

Machine setup and Claude Code configuration have different lifecycles. You set
up a machine once; you change your Claude plugin set every few weeks. Splitting
them means the frequent change does not require the expensive one.

    ./setup-my-laptop     bash, runs before Claude Code exists
    /setup-my-claude      a slash command, runs after you have signed in

The ordering is forced. `setup-my-laptop` installs Claude Code, so it cannot
depend on it. `/setup-my-claude` lives inside the hstack plugin, so the plugin
must be installed before the command exists. `install/50-claude-bootstrap.sh`
bridges the gap: it registers the marketplace and installs only the hstack
plugin, then stops and tells you what to run next.

`/setup-my-claude` is a thin wrapper around `bin/hstack-setup-claude`. The
logic lives in bash so it can be tested and run directly.

## hstack is a marketplace

Claude Code has a plugin system with versioning, enable/disable, and updates.
hstack uses it rather than working around it.

`.claude-plugin/marketplace.json` at the repo root makes this repo a
marketplace. `plugins/hstack/` is the plugin inside it. Third-party plugins are
declared in `claude/plugins.txt` and installed by the same CLI.

The alternative — [gstack](https://github.com/garrytan/gstack)'s approach — is
to clone into `~/.claude/skills/` and symlink each skill directory out. That
works, and gstack has good reasons for it: it predates the marketplace system
and supports ten different AI agents, so it needs its own package manager.
Neither applies here. The marketplace route also answers a question the symlink
route does not: how the twelve third-party plugins get installed.

### Directory source, not GitHub

`install/50-claude-bootstrap.sh` registers the marketplace by path:

    claude plugin marketplace add "$HSTACK_ROOT"

so it tracks your working clone. Editing a skill under `plugins/hstack/skills/`
takes effect next session, with no commit-push-update cycle.

The manifest is also at the repo root, so `claude plugin marketplace add
hemanthgk10/hstack` works from GitHub for anyone who does not keep a clone.
Same repo, both paths.

The trade-off: a directory marketplace breaks if you move or delete the clone.
That is acceptable for a repo you deliberately keep checked out.

## Idempotency

Every script is safe to run repeatedly. This is what makes `hstack-upgrade` a
one-liner and makes a partial failure recoverable by re-running.

`install/lib.sh` is the whole mechanism. Every filesystem mutation goes through
a helper there, which gives two properties for free:

- **`--dry-run` works**, because `hs_run` is the single choke point. A mutation
  that bypasses it would be invisible.
- **Re-runs are no-ops**, because each helper checks state before writing.
  `hs_write` compares content, `hs_link` checks the existing symlink target,
  `hs_fetch` skips existing files, `hs_defaults` reads before writing.

Backups follow the same rule. `hs_backup` moves a real file aside once and
ignores symlinks, so the second run has nothing to back up. One timestamped
directory per run, created lazily — a fully idempotent run leaves none.

### Marker blocks

Some files belong to other tools: `~/.claude/CLAUDE.md`, `~/.zshrc`.
`hs_marker_block` manages a region inside them:

    # >>> hstack:prefs >>>
    ...
    # <<< hstack:prefs <<<

It replaces the block in place. An earlier version removed and re-appended it,
which reordered blocks whenever a file held more than one — so the file
alternated between two states forever and never reported "unchanged". In-place
replacement is what makes multiple blocks stable.

## The local/ overlay

The repo is public, and the machine it was built from is a work machine. Those
two facts need a seam.

The test is: *would this be wrong on a personal laptop, or wrong after changing
jobs?* Work email, corporate CA bundles, internal cluster names, employer
plugins and internal runbooks all fail it. They live in `local/`, which is
gitignored.

Applied through mechanisms the tools already have, so nothing is special-cased:

| Overlay file | Mechanism |
|---|---|
| `zshrc.local` | `.zshrc` sources `~/.hstack.local` if it exists |
| `gitconfig.local` | `.gitconfig` has `[include] path = ~/.gitconfig.local` |
| `CLAUDE.local.md` | a second marker block in `~/.claude/CLAUDE.md` |
| `Brewfile.local` | a second `brew bundle` invocation |
| `plugins.local.txt` | the same install loop, second file |
| `skills/` | symlinked into `~/.claude/skills/` |

Every one is optional. Scripts check and skip.

Git and PR conventions live here rather than in `prefs/CLAUDE.md` for the same
reason: sign-off requirements, PR templates and branch naming change with every
employer, and baking them into a public repo makes it wrong the day you move.

## Dotfiles are symlinks

`~/.zshrc` points into `dotfiles/`. Editing either path edits the same file, so
a change made while working is already staged for commit. Copying would let the
two drift, and drift is the problem this repo exists to solve.

The cost: an installer that appends to `~/.zshrc` writes to a tracked file.
nvm and SDKMAN both do this, so both are invoked with the flags that suppress it
(`PROFILE=/dev/null`, `rcupdate=false`), and `dotfiles/zshrc` carries the lines
they would have added.

## iTerm2 as a Dynamic Profile

iTerm2 reads profiles from `DynamicProfiles/` and reloads on change. Writing a
file there is idempotent by construction and needs no restart, which beats
editing the preferences plist while iTerm2 has it open.

Dynamic Profiles cannot be edited in the UI, so `bin/hstack-iterm2-export`
closes the loop the other way: change the Default profile in Settings, run the
export, and the repo catches up. Both directions drop identifiers, window
geometry and the OpenAI keys iTerm2 stores for its own AI features.

## Deliberately not included

- **Support for other AI agents.** gstack carries adapters for ten. This is
  Claude Code only.
- **bun and compiled binaries.** Nothing here needs them, and
  `chrome-devtools-mcp` covers browser control.
- **Skill templating and codegen.** Two skills do not need a build step.
- **The `claude-code` Homebrew cask.** The official installer puts `claude` in
  `~/.local/bin` and updates it itself. Installing both leaves two binaries at
  different versions, with the older one winning once `/opt/homebrew/bin` is on
  `PATH`.
