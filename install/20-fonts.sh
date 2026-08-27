#!/usr/bin/env bash
# MesloLGS NF — the four faces powerlevel10k expects. This is a different
# family from the font-meslo-lg-nerd-font cask, so it is fetched directly.

hs_head "fonts"

BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
for face in "Regular" "Bold" "Italic" "Bold%20Italic"; do
  name="MesloLGS NF ${face//%20/ }.ttf"
  hs_fetch "$BASE/${name// /%20}" "$HOME/Library/Fonts/$name"
done

hs_log "set iTerm2 font to 'MesloLGS NF' if a profile still shows boxes"
