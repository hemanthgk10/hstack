#!/usr/bin/env bash
# Formulae, casks and taps from Brewfile. brew bundle is already declarative,
# so this module is mostly a wrapper that reports what is missing first.

hs_head "packages"

BREWFILE="$HSTACK_ROOT/Brewfile"
[ -f "$BREWFILE" ] || hs_die "missing $BREWFILE"

# Auto-update during a check turns a 2-second dry run into a 2-minute one.
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

# --adopt lets brew take over an app that is already in /Applications but was
# installed by hand. Without it, `brew install --cask iterm2` aborts with
# "It seems there is already an App at ...", which is the normal state of any
# machine that had these apps before it had hstack.
export HOMEBREW_CASK_OPTS="${HOMEBREW_CASK_OPTS:---adopt}"

if [ "$HSTACK_DRY_RUN" = 1 ]; then
  if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
    hs_skip "satisfied  Brewfile"
  else
    hs_log "would install, from Brewfile:"
    # brew bundle writes its report to stderr, not stdout.
    brew bundle check --verbose --file="$BREWFILE" 2>&1 \
      | grep "needs to be installed" | sed 's/^/       /' || true
  fi
else
  if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
    hs_skip "satisfied  Brewfile"
  else
    hs_run brew bundle --file="$BREWFILE"
    hs_done "installed  Brewfile"
  fi
fi

# Employer-specific packages, applied only when the overlay is present.
LOCAL_BREWFILE="$HSTACK_ROOT/local/Brewfile.local"
if [ -f "$LOCAL_BREWFILE" ]; then
  if brew bundle check --file="$LOCAL_BREWFILE" >/dev/null 2>&1; then
    hs_skip "satisfied  Brewfile.local"
  else
    hs_run brew bundle --file="$LOCAL_BREWFILE"
    hs_done "installed  Brewfile.local"
  fi
fi

# ollama is installed but no models are pulled — that is a multi-GB decision.
if hs_have ollama && [ -z "$(ollama list 2>/dev/null | tail -n +2)" ]; then
  hs_log "ollama has no models yet. Pull one when you want it, e.g."
  hs_log "  ollama pull qwen2.5-coder:7b"
fi
