#!/bin/bash
# ███████╗███╗   ██╗ ██████╗ ██╗    ██╗██████╗ ██╗      █████╗ ██████╗ ███████╗
# ██╔════╝████╗  ██║██╔═══██╗██║    ██║██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝
# ███████╗██╔██╗ ██║██║   ██║██║ █╗ ██║██████╔╝██║     ███████║██║  ██║█████╗
# ╚════██║██║╚██╗██║██║   ██║██║███╗██║██╔══██╗██║     ██╔══██║██║  ██║██╔══╝
# ███████║██║ ╚████║╚██████╔╝╚███╔███╔╝██████╔╝███████╗██║  ██║██████╔╝███████╗
# ╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═════╝╚══════╝
#
#         SnowBlade — macOS Terminal Setup
#         Dev: Abishekraghav Murugeashan
# ─────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

banner() {
    echo ""
    echo -e "${CYAN}+------------------------------------------+${RESET}"
    printf "${CYAN}|${RESET}${BOLD} %-40s ${RESET}${CYAN}|${RESET}\n" "$@"
    echo -e "${CYAN}+------------------------------------------+${RESET}"
}
ok()   { echo -e "${GREEN}[✔]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
err()  { echo -e "${RED}[✘]${RESET} $1"; }
info() { echo -e "${CYAN}[i]${RESET} $1"; }

# ── macOS check ───────────────────────────────────────────────
clear
echo -e "${CYAN}"
echo "███████╗███╗   ██╗ ██████╗ ██╗    ██╗██████╗ ██╗      █████╗ ██████╗ ███████╗"
echo "██╔════╝████╗  ██║██╔═══██╗██║    ██║██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝"
echo "███████╗██╔██╗ ██║██║   ██║██║ █╗ ██║██████╔╝██║     ███████║██║  ██║█████╗  "
echo "╚════██║██║╚██╗██║██║   ██║██║███╗██║██╔══██╗██║     ██╔══██║██║  ██║██╔══╝  "
echo "███████║██║ ╚████║╚██████╔╝╚███╔███╔╝██████╔╝███████╗██║  ██║██████╔╝███████╗"
echo "╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═════╝╚══════╝"
echo -e "${RESET}"
echo -e "        ${BOLD}SnowBlade — macOS Terminal Setup${RESET}"
echo -e "        ${BOLD}Dev: Abishekraghav Murugeashan${RESET}"
echo ""

if [[ "$(uname)" != "Darwin" ]]; then
    err "This script is for macOS only!"; exit 1
fi

# ── Step 1: Xcode CLI Tools ───────────────────────────────────
banner "Step 1: Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
    ok "Xcode CLI tools already installed"
else
    warn "Installing Xcode CLI tools..."
    xcode-select --install
    info "Click Install in the popup, then re-run this script"
    exit 0
fi

# ── Step 2: Rosetta 2 (M1/M2/M3) ─────────────────────────────
banner "Step 2: Rosetta 2 (Apple Silicon only)"
if [[ "$(uname -m)" == "arm64" ]]; then
    if /usr/bin/pgrep oahd &>/dev/null; then
        ok "Rosetta 2 already installed"
    else
        softwareupdate --install-rosetta --agree-to-license
        ok "Rosetta 2 installed"
    fi
else
    info "Intel Mac — Rosetta not needed"
fi

# ── Step 3: DNS ───────────────────────────────────────────────
banner "Step 3: DNS Setup (OpenDNS + Google)"
IFACE=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
if [ -n "$IFACE" ]; then
    read -p "  Apply fast DNS on $IFACE? (y/n): " dns_apply
    if [[ "$dns_apply" == "y" ]]; then
        sudo networksetup -setdnsservers "$IFACE" 208.67.222.222 208.67.220.220 8.8.8.8 8.8.4.4
        ok "DNS set on $IFACE"
    fi
else
    warn "Could not detect interface — set DNS manually"
fi

# ── Step 4: Homebrew ──────────────────────────────────────────
banner "Step 4: Homebrew"
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
    ok "Homebrew installed"
else
    ok "Homebrew found — updating"
    brew update
fi

BREW_PREFIX=$(brew --prefix)
sudo mkdir -p /usr/local/bin

install_brew() {
    if brew list "$1" &>/dev/null; then
        ok "$1 already installed"
    else
        brew install "$1" 2>/dev/null && ok "$1 ✔" || warn "$1 failed"
    fi
}
install_cask() {
    if brew list --cask "$1" &>/dev/null; then
        ok "$1 already installed"
    else
        brew install --cask "$1" 2>/dev/null && ok "$1 ✔" || warn "$1 failed"
    fi
}

# ── Step 5: Core Dev Tools ────────────────────────────────────
banner "Step 5: Core Dev & Language Tools"
for tool in git python3 go ruby node jq wget curl openssl rename; do
    install_brew "$tool"
done

# ── Step 6: Terminal Quality of Life ─────────────────────────
banner "Step 6: Terminal QOL Tools"
for tool in tmux neovim bat tree fzf htop httpie thefuck tldr; do
    install_brew "$tool"
done
# fzf shell integration
"${BREW_PREFIX}/opt/fzf/install" --all --no-bash --no-fish 2>/dev/null
ok "fzf shell integration done"

# ── Step 7: Network Tools ─────────────────────────────────────
banner "Step 7: Network Tools"
for tool in nmap netcat wget curl ipcalc dnsmap tcpdump speedtest-cli openssh awscli; do
    install_brew "$tool"
done

# ── Step 8: File & Text Tools ─────────────────────────────────
banner "Step 8: File & Text Tools"
for tool in ripgrep fd unzip p7zip imagemagick ffmpeg pandoc; do
    install_brew "$tool"
done

# ── Step 9: Web & API Tools ───────────────────────────────────
banner "Step 9: Web & API Tools"
for tool in httpie gh hugo; do
    install_brew "$tool"
done

# ── Step 10: Python packages ──────────────────────────────────
banner "Step 10: Python Packages"
pip3 install --break-system-packages requests beautifulsoup4 2>/dev/null || \
pip3 install requests beautifulsoup4
ok "Python packages installed"

# ── Step 11: Zsh Plugins ──────────────────────────────────────
banner "Step 11: Zsh Plugins"
install_brew "zsh-syntax-highlighting"
install_brew "zsh-autosuggestions"

# ── Step 12: GUI Apps ─────────────────────────────────────────
banner "Step 12: GUI Apps"
install_cask "sublime-text"
install_cask "iterm2"
install_cask "firefox"

# ── Step 13: Sublime subl command ────────────────────────────
banner "Step 13: subl command"
if [ ! -L /usr/local/bin/subl ]; then
    sudo ln -sf "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
    ok "subl linked"
else
    ok "subl already linked"
fi

# ── Step 14: Apache ───────────────────────────────────────────
banner "Step 14: Apache (httpd)"
install_brew "httpd"

# ── Step 15: Write zshrc ──────────────────────────────────────
banner "Step 15: Writing ~/.zshrc — SnowBlade Edition"

ZSHRC="$HOME/.zshrc"
[ -f "$ZSHRC" ] && cp "$ZSHRC" "$ZSHRC.snowblade.bak" && warn "Old .zshrc backed up → .zshrc.snowblade.bak"

cat > "$ZSHRC" << ZSHRC_EOF
# ─────────────────────────────────────────────────────────────
#   SnowBlade zshrc — Abishekraghav Murugeashan
#   macOS Terminal Setup
# ─────────────────────────────────────────────────────────────

# ── Homebrew PATH ───────────────────────────────────────────
eval "\$(${BREW_PREFIX}/bin/brew shellenv)" 2>/dev/null || true
export PATH="/usr/local/bin:\$PATH"
export PATH=\$PATH:\$(go env GOPATH 2>/dev/null)/bin

# ── Completion ──────────────────────────────────────────────
autoload -Uz compinit
compinit -d ~/.cache/zcompdump 2>/dev/null || compinit
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive tab ✅

# ── History ─────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
alias history="history 0"

# ── Options ─────────────────────────────────────────────────
setopt autocd
setopt interactivecomments
setopt magicequalsubst
setopt nonomatch
setopt notify
setopt numericglobsort
setopt promptsubst
WORDCHARS=\${WORDCHARS//\/}
export PROMPT_EOL_MARK=""
bindkey -e
bindkey ' ' magic-space
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ── Kali-style Prompt ───────────────────────────────────────
PROMPT=\$'%F{green}┌──(%B%F{blue}%n%b%F{green}@%F{blue}%m%F{green})-[%B%F{reset}%~%b%F{green}]\n└─%B%F{blue}\$%b%F{reset} '
RPROMPT=\$'%(?.. %? %F{red}%B⨯%b%F{reset})'

# ── System ──────────────────────────────────────────────────
alias cls='clear'
alias py='python3'
alias ll='ls -la'
alias la='ls -la'
alias ..='cd ..'
alias ...='cd ../..'
alias cls-his='echo " " > ~/.zsh_history'
alias ls='ls -G'

# ── Config ──────────────────────────────────────────────────
alias profile='subl ~/.zshrc'
alias sc='source ~/.zshrc'
alias zprofile='subl ~/.zprofile'
alias zsc='source ~/.zprofile'

# ── Network ─────────────────────────────────────────────────
alias myip='ifconfig | grep "inet "'
alias locip='curl ipinfo.io/ip'
alias open-ports='lsof -i -P -n | grep LISTEN'
alias netreset='sudo ifconfig en0 down && sudo ifconfig en0 up'
alias st='speedtest'

# ── Services (macOS style) ───────────────────────────────────
alias apstart='sudo brew services start httpd'
alias apstop='sudo brew services stop httpd'
alias sshstart='sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist'
alias sshstop='sudo launchctl unload -w /System/Library/LaunchDaemons/ssh.plist'
alias svstatus='brew services list'
alias vpnstart='sudo brew services start openvpn'
alias vpnstop='sudo brew services stop openvpn'

# ── Apps ────────────────────────────────────────────────────
alias ff='open -a Firefox'
alias lp='subl'
alias update='brew update && brew upgrade'
alias pyserver='python3 -m http.server'

# ── Better CLI Tools ────────────────────────────────────────
alias cat='bat'           # better cat with syntax highlight
alias vim='nvim'          # better vim
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias find='fd'           # faster find
alias top='htop'          # better top

# ── Productivity ────────────────────────────────────────────
alias please='sudo'
alias ip='ipconfig getifaddr en0'
alias pubip='curl ipinfo.io/ip'
alias week='date +%V'
alias path='echo $PATH | tr ":" "\n"'   # readable PATH

# ── Git Shortcuts ───────────────────────────────────────────
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gco='git checkout'

# ── fzf (fuzzy finder) ──────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ── Zsh Syntax Highlighting ─────────────────────────────────
ZSH_HL="${BREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -f "\$ZSH_HL" ] && source "\$ZSH_HL"

# ── Zsh Autosuggestions ─────────────────────────────────────
ZSH_AS="${BREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "\$ZSH_AS" ] && source "\$ZSH_AS"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'

# ── thefuck (fix typos) ─────────────────────────────────────
command -v thefuck &>/dev/null && eval \$(thefuck --alias)

ZSHRC_EOF

ok "~/.zshrc written"

# ── Done ─────────────────────────────────────────────────────
banner "SnowBlade Setup Complete! ⚔️"
echo ""
echo -e "${GREEN}Activate now:${RESET}"
echo -e "  ${BOLD}source ~/.zshrc${RESET}"
echo ""
echo -e "${CYAN}What's in your terminal now:${RESET}"
echo "  tmux       → split terminal sessions"
echo "  neovim     → better vim"
echo "  bat        → cat with syntax colors"
echo "  fzf        → fuzzy search everything (Ctrl+R for history)"
echo "  tree       → folder visualizer"
echo "  thefuck    → type 'fuck' to fix last command typo"
echo "  tldr       → simple man pages"
echo "  ripgrep    → super fast grep"
echo "  fd         → faster find"
echo "  httpie     → better curl for APIs"
echo "  subl       → open any file in Sublime"
echo ""
echo -e "${BOLD}  SnowBlade ⚔️  — Ready${RESET}"
echo ""
