# Working on hstack

hstack sets up a Mac and configures Claude Code from checked-in files. Two
entry points:

- `./setup-my-laptop` — Homebrew packages, fonts, shell, iTerm2, Claude Code
- `/setup-my-claude` — marketplaces, plugins, settings, preferences
  (wraps `bin/hstack-setup-claude`)

## Two files are called CLAUDE.md

They are unrelated. Check which one you are editing.

| File | Loaded | Contains |
|---|---|---|
| `CLAUDE.md` (this file) | when working in this repo | how to change hstack |
| `prefs/CLAUDE.md` | every session, everywhere | personal preferences, installed to `~/.claude/CLAUDE.md` |

## Idempotency is the constraint

Every script must be safe to run any number of times. This is not a nice-to-have;
it is the reason the repo works at all.

Every filesystem mutation goes through a helper in `install/lib.sh`. No module
calls `ln`, `cp`, `mkdir`, `rm`, `curl`, or `defaults write` directly:

| Helper | For |
|---|---|
| `hs_run` | any command; prints instead of running under `--dry-run` |
| `hs_link` | symlinks, backing up a real file once |
| `hs_write` | writing a file, only when the content differs |
| `hs_marker_block` | a managed region inside a file you do not own |
| `hs_clone_or_pull` | git checkouts |
| `hs_fetch` | downloads, skipped when the file exists |
| `hs_defaults` | `defaults write`, only on change |

Two rules that come from bugs already fixed here:

- **Never call a helper that sets `HSTACK_BACKUP_DIR` through `$(...)`.** Command
  substitution runs in a subshell, so the assignment is lost and you get one
  backup directory per file instead of one per run.
- **`hs_marker_block` replaces in place.** Removing and re-appending reorders
  blocks when a file holds more than one, and the file never stabilizes.

If a change cannot be made idempotent, the design is wrong. Find another one.

## `--dry-run` has to stay honest

New code paths go through `hs_run` or `hs_sh`. A mutation that bypasses them is
invisible to `--dry-run`, which is the only safe way to inspect this repo before
running it.

Never print success for work that did not happen. Use `hs_done`, which is silent
under `--dry-run`. Check the result rather than the exit code where an installer
can exit 0 having done nothing — both the nvm and SDKMAN installers do this.

## Where things go

Ask: would this be wrong on a personal laptop, or wrong after changing jobs?

- Yes to either → `local/`, which is gitignored. See `local.example/`.
- Secrets, tokens, internal hostnames, cluster names → nowhere in this repo.
- Otherwise → the repo.

## Common changes

**Add a third-party plugin.** One line in `claude/plugins.txt` as
`name@marketplace`. If its marketplace is not in `claude/marketplaces.txt`, add
that too. Nothing else.

**Add a skill.** A directory under `plugins/hstack/skills/`. The marketplace is
registered against this clone as a directory source, so a new skill is live next
session with no commit or push. Use the `skill-creator` plugin.

**Change a dotfile.** Edit it in `dotfiles/`. `~/.zshrc` is a symlink here, so
editing either path edits the same file.

**Change the iTerm2 profile.** Dynamic Profiles cannot be edited in the iTerm2
UI. Change the Default profile in Settings, then run `bin/hstack-iterm2-export`
to capture it back.

## Watch out for

- **macOS ships bash 3.2.** `"${arr[@]}"` on an empty array is an unbound
  variable error under `set -u`; use `${arr[@]+"${arr[@]}"}`. Test with
  `/bin/bash`, not Homebrew's.
- **Installers that edit `~/.zshrc`.** It is a symlink into this repo, so an
  installer appending to it writes to a tracked file, usually with absolute
  `/Users/<name>` paths that are private and broken elsewhere. nvm takes
  `PROFILE=/dev/null` and SDKMAN takes `rcupdate=false`, but plugin installers
  give no such option — `claude-mem` appended a bun block and a version-pinned
  alias during the first real run. `bin/hstack-secret-sweep` fails on absolute
  home paths under `dotfiles/` for exactly this reason. Rewrite them with
  `$HOME`, or move them to `local/zshrc.local`.
- **Two `claude` binaries.** `~/.local/bin/claude` self-updates; a Homebrew cask
  copy lags and shadows it once `/opt/homebrew/bin` is on `PATH`. Scripts here
  prefer the former explicitly. The cask is deliberately not in the `Brewfile`.
- **CLI flags vary by version.** `claude plugin install --yes` does not exist
  before 2.1.247. Detect flags, do not assume them.

## Before pushing

    shellcheck --severity=warning -x -P install:bin:. setup-my-laptop install/*.sh bin/hstack-*
    ./setup-my-laptop --dry-run
    ./setup-my-laptop && ./setup-my-laptop     # second run: no changes, no new backup
    ./bin/hstack-doctor
    ./bin/hstack-secret-sweep

`hstack-secret-sweep` holds the pattern; do not copy it elsewhere. `local/` is
gitignored — confirm with `git status` that it never appears.

Prose in this repo goes through `humanizer` before it is committed.

## Versioning

`VERSION` and `plugins/hstack/.claude-plugin/plugin.json` hold the same version.
Bump both. `claude plugin tag` checks they agree.
