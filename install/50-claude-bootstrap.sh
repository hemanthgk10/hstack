#!/usr/bin/env bash
# Get Claude Code far enough along that /setup-my-claude exists.
#
# Chicken-and-egg: /setup-my-claude is a command inside the hstack plugin, so
# the plugin has to be installed before the command can run. This module does
# that much and nothing more. Everything else happens in /setup-my-claude.

hs_head "claude code"

# Prefer the official installer's binary over a Homebrew cask copy. Both can
# exist; the ~/.local/bin one updates itself and is usually far newer.
if [ -x "$HOME/.local/bin/claude" ]; then
  CLAUDE="$HOME/.local/bin/claude"
elif hs_have claude; then
  CLAUDE="$(command -v claude)"
else
  CLAUDE=""
fi

if [ -n "$CLAUDE" ]; then
  hs_skip "present    claude ($("$CLAUDE" --version 2>/dev/null | head -1)) at $CLAUDE"
else
  hs_log "installing claude code"
  hs_sh 'curl -fsSL https://claude.ai/install.sh | bash'
  if [ -x "$HOME/.local/bin/claude" ]; then
    CLAUDE="$HOME/.local/bin/claude"
    hs_done "installed  claude"
  else
    hs_warn "claude install did not produce ~/.local/bin/claude"
    hs_warn "install it manually, then: ./setup-my-laptop --only 50-claude-bootstrap"
    return 0 2>/dev/null || exit 0
  fi
fi

# Warn about a shadowing second copy rather than silently picking one.
if [ -x /opt/homebrew/bin/claude ] && [ "$CLAUDE" != /opt/homebrew/bin/claude ]; then
  hs_warn "a second claude exists at /opt/homebrew/bin/claude ($(/opt/homebrew/bin/claude --version 2>/dev/null | head -1))"
  hs_warn "  remove it so versions cannot diverge: brew uninstall --cask claude-code"
fi

# --yes was added after 2.1.139. Detect rather than assume.
YES_FLAG=""
"$CLAUDE" plugin install --help 2>&1 | grep -q -- '--yes' && YES_FLAG="--yes"

# Register this clone as a marketplace. Directory source, not GitHub: edits to
# plugins/hstack take effect next session with no commit-push-update cycle.
if "$CLAUDE" plugin marketplace list 2>/dev/null | grep -q "$HSTACK_ROOT"; then
  hs_skip "registered hstack marketplace ($HSTACK_ROOT)"
else
  if hs_run "$CLAUDE" plugin marketplace add "$HSTACK_ROOT"; then
    hs_done "registered hstack marketplace"
  else
    hs_warn "could not add the marketplace (not signed in yet?)"
    hs_warn "run 'claude' to sign in, then: $HSTACK_ROOT/bin/hstack-setup-claude"
    return 0 2>/dev/null || exit 0
  fi
fi

if "$CLAUDE" plugin list 2>/dev/null | grep -q 'hstack@hstack'; then
  hs_skip "installed  hstack plugin"
else
  hs_run "$CLAUDE" plugin install hstack@hstack $YES_FLAG || \
    hs_warn "could not install the hstack plugin — sign in and re-run"
fi

cat <<'NEXT'

  Machine setup is done. Two steps left:

    1. open a new terminal, or: exec zsh
    2. run: claude
       then: /setup-my-claude

  /setup-my-claude installs the plugin set, settings and preferences.

NEXT
