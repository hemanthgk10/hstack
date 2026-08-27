#!/usr/bin/env bash
# oh-my-zsh, powerlevel10k, zsh plugins, nvm, sdkman, and the dotfile symlinks.

hs_head "shell"

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH_DIR/custom"

hs_clone_or_pull https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR" --depth 1
hs_clone_or_pull https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k" --depth 1
hs_clone_or_pull https://github.com/zsh-users/zsh-autosuggestions.git \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" --depth 1
hs_clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" --depth 1

# ── nvm ─────────────────────────────────────────────────────────────────────
# From upstream rather than brew: Homebrew's nvm formula is explicitly
# unsupported by the nvm maintainers.
#
# PROFILE=/dev/null stops the installer editing a shell rc file. That matters
# here because ~/.zshrc is a symlink into this repo — without it, the installer
# would append its source block to a tracked file. dotfiles/zshrc already
# contains the nvm lines, so nothing is lost.
#
# NVM_DIR is pinned rather than inherited, so an existing install elsewhere in
# the environment cannot redirect this one.
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  hs_skip "present    nvm"
else
  hs_sh "PROFILE=/dev/null NVM_DIR=\"$HOME/.nvm\" bash -c 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'"
  if [ "$HSTACK_DRY_RUN" = 1 ] || [ -s "$HOME/.nvm/nvm.sh" ]; then
    hs_done "installed  nvm"
  else
    hs_warn "nvm install reported success but $HOME/.nvm/nvm.sh is missing"
  fi
fi

if [ "$HSTACK_DRY_RUN" != 1 ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
  if [ -z "$(ls -A "$HOME/.nvm/versions/node" 2>/dev/null)" ]; then
    hs_log "installing node lts"
    # shellcheck disable=SC1091
    ( export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"; nvm install --lts ) \
      && hs_ok "installed  node lts"
  else
    hs_skip "present    node ($(ls "$HOME/.nvm/versions/node" | tr '\n' ' '))"
  fi
fi

# ── sdkman ──────────────────────────────────────────────────────────────────
# Candidates (java, gradle, maven) are per-project choices and are NOT
# installed here. Run `sdk install java` when a project needs one.
# rcupdate=false keeps the installer out of ~/.zshrc, which is a symlink into
# this repo. dotfiles/zshrc already sources sdkman-init.sh, at the end of the
# file where SDKMAN requires it.
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  hs_skip "present    sdkman"
else
  # SDKMAN's installer requires bash 4+. macOS ships 3.2, so use the Homebrew
  # bash from the Brewfile. Without it the installer exits 1 having done
  # nothing, which is why the result is checked rather than the exit code.
  MODERN_BASH=""
  for b in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    [ -x "$b" ] && [ "$("$b" -c 'echo ${BASH_VERSINFO[0]}')" -ge 4 ] && MODERN_BASH="$b" && break
  done

  if [ -z "$MODERN_BASH" ]; then
    hs_warn "skipping sdkman: it needs bash 4+, and only bash $BASH_VERSION is available"
    hs_warn "  run 'brew install bash', then: ./setup-my-laptop --only 30-shell"
  else
    hs_sh "SDKMAN_DIR=\"$HOME/.sdkman\" $MODERN_BASH -c 'curl -s \"https://get.sdkman.io?rcupdate=false\" | $MODERN_BASH'"
    if [ "$HSTACK_DRY_RUN" = 1 ] || [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
      hs_done "installed  sdkman"
    else
      hs_warn "sdkman install reported success but $HOME/.sdkman/bin/sdkman-init.sh is missing"
      hs_warn "  (an inherited SDKMAN_DIR can redirect the installer)"
    fi
  fi
fi

# ── dotfiles ────────────────────────────────────────────────────────────────
hs_link "$HSTACK_ROOT/dotfiles/zshrc"    "$HOME/.zshrc"
hs_link "$HSTACK_ROOT/dotfiles/p10k.zsh" "$HOME/.p10k.zsh"
hs_link "$HSTACK_ROOT/dotfiles/gitconfig" "$HOME/.gitconfig"

# gh rewrites its own config, so seed it rather than symlinking.
hs_copy_if_absent "$HSTACK_ROOT/dotfiles/gh-config.yml" "$HOME/.config/gh/config.yml"

# ── local overlay ───────────────────────────────────────────────────────────
if [ -f "$HSTACK_ROOT/local/zshrc.local" ]; then
  hs_link "$HSTACK_ROOT/local/zshrc.local" "$HOME/.hstack.local"
else
  hs_skip "no local/zshrc.local (fine — .zshrc sources it only if present)"
fi

if [ -f "$HSTACK_ROOT/local/gitconfig.local" ]; then
  hs_link "$HSTACK_ROOT/local/gitconfig.local" "$HOME/.gitconfig.local"
elif [ ! -f "$HOME/.gitconfig.local" ]; then
  hs_warn "no ~/.gitconfig.local — git has no user.name/user.email yet. Set them:"
  hs_warn "  git config -f ~/.gitconfig.local user.name  'Your Name'"
  hs_warn "  git config -f ~/.gitconfig.local user.email 'you@example.com'"
fi

[ "$SHELL" = /bin/zsh ] || hs_log "default shell is $SHELL; 'chsh -s /bin/zsh' to switch"
