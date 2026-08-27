# hstack

Sets up a Mac and configures Claude Code from files in this repo. Clone it, run
two commands, get the same machine you had before.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Read this before running it

`setup-my-laptop` installs software and replaces dotfiles in your home
directory. Read `setup-my-laptop` and `install/*.sh` before you run them, the
same as any other script off the internet.

Two things that make it recoverable:

    ./setup-my-laptop --dry-run     # prints every change, makes none

Existing dotfiles are moved to `~/.hstack-backup/<timestamp>/` before anything
replaces them. One directory per run. Nothing is deleted.

This is one person's setup. Fork it and change what you disagree with — see
[Making it yours](#making-it-yours).

## Requirements

macOS on Apple silicon. Admin rights, for Homebrew. Everything else is
installed by the scripts.

## Quick start

    git clone https://github.com/hemanthgk10/hstack ~/Documents/hstack
    cd ~/Documents/hstack
    ./setup-my-laptop

Takes 15–30 minutes, mostly Homebrew. Then open a new terminal and:

    claude
    /setup-my-claude

That installs the plugin set and preferences. Restart Claude Code afterwards —
plugins do not load in the session that installed them.

Check the result any time with `bin/hstack-doctor`.

## What it installs

### Applications

| | |
|---|---|
| iTerm2 | terminal, configured below |
| Sublime Text | editor |
| IntelliJ IDEA | JVM work |
| Docker Desktop | containers |
| Google Chrome | also drives `chrome-devtools-mcp` |
| Slack | |
| Claude | desktop app |

### Command line

| | |
|---|---|
| `gh`, `git-lfs`, `act` | GitHub, large files, Actions run locally |
| `go`, `python@3.12`, `openjdk@11`, `bazelisk` | languages and builds |
| `nvm` | Node, from upstream — Homebrew's nvm is unsupported |
| `sdkman` | JVM toolchains. No candidates installed; run `sdk install java` |
| `awscli`, `gcloud-cli`, `flyctl` | AWS, Google Cloud, fly.io |
| `kubernetes-cli`, `helm`, `k9s` | Kubernetes |
| `mysql@8.0`, `libpq`, `redpanda` | databases and streaming |
| `ollama` | local models. No models pulled — that is a multi-GB choice |
| `jq`, `coreutils`, `autojump`, `bash` | plumbing. `bash` because macOS ships 3.2 and SDKMAN needs 4+ |

### Shell and terminal

oh-my-zsh with powerlevel10k, plus `zsh-autosuggestions`,
`zsh-syntax-highlighting` and `autojump`. The MesloLGS NF font family that
powerlevel10k needs, which is not the same as the Nerd Font cask.

iTerm2 gets an `hstack` profile: MesloLGS NF 13, powerline glyphs, separate
light and dark palettes, 100k lines of scrollback. It installs as a Dynamic
Profile, so it applies without restarting iTerm2.

`~/.zshrc`, `~/.p10k.zsh` and `~/.gitconfig` are symlinked into this repo.
Editing them is editing the repo — commit and push to carry a change to your
other machines.

### Claude Code

| Plugin | Why |
|---|---|
| [superpowers](https://github.com/obra/superpowers) | brainstorming, TDD, systematic debugging, worktrees |
| code-review | multi-agent review with confidence scoring |
| security-guidance | security review on edits and commits |
| skill-creator | writing and evaluating new skills |
| [humanizer](https://github.com/blader/humanizer) | strips AI tells from prose |
| frontend-design | frontend that does not look generated |
| ui-ux-pro-max | palettes, type pairings, UX rules |
| [ponytail](https://github.com/DietrichGebert/ponytail) | pushes for the smallest solution that works |
| claude-mem | carries context between sessions |
| context7 | current library docs on demand |
| chrome-devtools-mcp | drives and inspects a real browser |
| claude-plan-statusline | plan state in the status line |

Plus two skills of my own, in `plugins/hstack/skills/`:

- **review-until-convergence** — re-reviews after each round of fixes until a
  pass finds nothing new. One pass finds the problems in the original code, not
  the ones the fixes introduced. Caps at 5 passes.
- **parallel-worktree-agents** — runs several agents at once, each in its own
  git worktree, so they cannot overwrite each other.

And preferences in `prefs/CLAUDE.md`, installed to `~/.claude/CLAUDE.md`.

## Usage

    ./setup-my-laptop [options]

    -n, --dry-run       print every change, make none
        --only <name>   run one module (repeatable)
        --skip <name>   skip a module (repeatable)
    -q, --quiet         errors and warnings only
    -l, --list          list modules
    -h, --help

Modules run in order: `00-preflight`, `10-brew`, `20-fonts`, `30-shell`,
`40-iterm2`, `50-claude-bootstrap`.

    bin/hstack-doctor          check that everything is in place
    bin/hstack-upgrade         git pull, then re-apply
    bin/hstack-setup-claude    what /setup-my-claude runs
    bin/hstack-iterm2-export   capture iTerm2 changes back into the repo
    bin/hstack-secret-sweep    check nothing private is about to be committed

## Making it yours

Three files carry most of what makes this mine rather than yours:

- `Brewfile` — what gets installed
- `claude/plugins.txt` — which Claude Code plugins
- `prefs/CLAUDE.md` — how Claude should work

Edit those and the rest follows. Adding a plugin is one line; adding a skill is
a directory under `plugins/hstack/skills/`.

## The local/ overlay

Anything employer-specific goes in `local/`, which is gitignored: work email,
corporate CA bundles, internal plugins, internal skills. Changing jobs means
replacing one directory, and this repo stays publishable.

    cp -r local.example local
    # edit what you need, delete the rest

Every script checks for the files it wants and skips them when absent, so
`local/` is entirely optional. See [local.example/README.md](local.example/README.md).

`local/` is not in this repo, so pushing does not back it up. Keep a copy
somewhere private.

## Uninstall

Dotfiles come back from the backup directory:

    ls ~/.hstack-backup/
    cp ~/.hstack-backup/<timestamp>/.zshrc ~/.zshrc     # replaces the symlink

The iTerm2 profile:

    rm ~/Library/Application\ Support/iTerm2/DynamicProfiles/hstack.json

Plugins, individually:

    claude plugin uninstall <name>
    claude plugin marketplace remove hstack

Homebrew packages are left alone. `brew bundle cleanup --file=Brewfile` lists
what is installed but not in the Brewfile, if you want to go the other way.

## Tested

Verified on the machine it was built from: `--dry-run` output reviewed, run
twice with no changes on the second pass, `hstack-doctor` green, shell modules
exercised against an isolated `HOME` to check the fresh-machine path.

Not yet verified end to end on a genuinely clean Mac. If you run it on one, I
would like to hear how it went.

## Licence

MIT. See [LICENSE](LICENSE).

The repo shape — one script, checked-in config, upgrade by pulling — follows
[gstack](https://github.com/garrytan/gstack). The contents are entirely
different: gstack is a skill library, hstack is a machine setup.
