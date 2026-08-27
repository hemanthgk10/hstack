# local.example

Template for `local/`, which is gitignored.

Everything in `local/` is employer-specific or machine-specific: it would be
wrong on a personal laptop, or wrong after changing jobs. Keeping it out of the
public repo means changing employers is a matter of swapping one directory.

## Setting it up

    cp -r local.example local
    # then edit the files you need and delete the ones you do not

Nothing in `local/` is required. Every script checks whether a file exists and
skips it when it does not.

## What goes where

| File | Applied by | Becomes |
|---|---|---|
| `Brewfile.local` | `install/10-brew.sh` | extra brew packages |
| `zshrc.local` | `install/30-shell.sh` | `~/.hstack.local`, sourced by `.zshrc` |
| `gitconfig.local` | `install/30-shell.sh` | `~/.gitconfig.local`, included by `.gitconfig` |
| `CLAUDE.local.md` | `bin/hstack-setup-claude` | an `hstack:local` block in `~/.claude/CLAUDE.md` |
| `marketplaces.local.txt` | `bin/hstack-setup-claude` | extra Claude Code marketplaces |
| `plugins.local.txt` | `bin/hstack-setup-claude` | extra Claude Code plugins |
| `skills/<name>/` | `bin/hstack-setup-claude` | symlinked into `~/.claude/skills/` |

## Back it up somewhere private

`local/` is not in this repo, so nothing here is backed up by pushing. Keep it
in a private repo or a password manager, especially `skills/`, which is where
internal runbooks end up.
