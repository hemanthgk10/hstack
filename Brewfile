# hstack — packages for a working laptop.
#
# Employer-specific tools do NOT belong here. They go in local/Brewfile.local,
# which is gitignored. Test: would this be wrong on a personal laptop, or wrong
# after changing jobs? If yes to either, it belongs in local/.

# redpanda and agentty are not in homebrew-core, so their taps are required.
# Homebrew 6 asks you to trust a third-party tap before loading its formulae:
#   brew trust redpanda-data/tap
#   brew trust empty-user77/agentty
tap "redpanda-data/tap"
tap "empty-user77/agentty"

# ── shell and core ──────────────────────────────────────────────────────────
brew "bash"               # macOS ships bash 3.2 from 2007; sdkman needs 4+
brew "coreutils"          # GNU tools; several scripts assume them
brew "autojump"           # `j <dir>` — the zsh plugin needs this binary
brew "jq"                 # hstack-setup-claude merges settings.json with it

# ── git and github ──────────────────────────────────────────────────────────
brew "gh"
brew "git-lfs"
brew "act"                # run GitHub Actions locally

# ── languages and runtimes ──────────────────────────────────────────────────
# node is managed by nvm (install/30-shell.sh), not here.
brew "go"
brew "python@3.12"
brew "openjdk@11"
brew "google-java-format"
brew "bazelisk"

# ── databases and clients ───────────────────────────────────────────────────
brew "mysql@8.0"
brew "libpq"              # psql without the full postgres server
brew "redpanda-data/tap/redpanda"

# ── cloud, containers, kubernetes ───────────────────────────────────────────
brew "awscli"
brew "kubernetes-cli"
brew "helm"
brew "k9s"                # in homebrew-core; the derailed/k9s tap is legacy
brew "flyctl"             # fly.io

# ── local models ────────────────────────────────────────────────────────────
# The formula, not the ollama-app cask: this gives the CLI plus the local
# server. No models are pulled automatically.
brew "ollama"

# ── applications ────────────────────────────────────────────────────────────
cask "iterm2"
cask "sublime-text"
cask "google-chrome"
cask "docker-desktop"
cask "slack"
# Homebrew 6.0.8 fails to parse this cask ("undefined method 'command_wrapper'").
# The token is correct; the bug is upstream and clears with `brew update`.
cask "intellij-idea"

# ── claude ──────────────────────────────────────────────────────────────────
cask "claude"             # desktop app
cask "empty-user77/agentty/agentty"
cask "gcloud-cli"

# The claude CLI is deliberately NOT installed from brew. The official
# installer puts it in ~/.local/bin and keeps it updated itself; the cask
# lags behind and shadows it once /opt/homebrew/bin is on PATH. Two copies
# of different versions is worse than one.
# install/50-claude-bootstrap.sh handles it.
