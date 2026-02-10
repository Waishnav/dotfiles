# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Zinit Plugin Manager ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Initialize completion system (must be after zsh-completions)
autoload -Uz compinit && compinit
zinit cdreplay -q

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

# --- History ---
HISTSIZE=32768
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# --- Completion styling ---
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# --- Keybindings ---
bindkey '^k' history-search-backward
bindkey '^j' history-search-forward
bindkey '^[w' kill-region

# --- Environment ---
export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi
export DOCKER_HOST=unix:///var/run/docker.sock

# --- PATH ---
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.amp/bin:$PATH"

# Cargo/Rust (if installed)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Bun (if installed)
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

# --- Tool Initialization ---
command -v mise &>/dev/null && eval "$(mise activate zsh)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v fzf &>/dev/null && eval "$(fzf --zsh)"

# --- Omarchy-style Aliases (eza, zoxide, git) ---
if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

if command -v zoxide &>/dev/null; then
  alias cd="zd"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
fi

open() { xdg-open "$@" >/dev/null 2>&1 & }

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias d='docker'
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# --- Custom Aliases ---
alias oc='opencode'
alias cc='claude'
alias ldf='lume diff --file-panel-pos bottom'

# Claude Code with Antigravity Proxy
alias ccap='ANTHROPIC_AUTH_TOKEN="test" \
  ANTHROPIC_BASE_URL="http://localhost:8080" \
  ANTHROPIC_MODEL="claude-opus-4-5-thinking" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-5-thinking" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-5-thinking" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="gemini-3-flash[1m]" \
  CLAUDE_CODE_SUBAGENT_MODEL="claude-sonnet-4-5-thinking" \
  ENABLE_EXPERIMENTAL_MCP_CLI="false" \
  claude'

alias ccgp='ANTHROPIC_AUTH_TOKEN="test" \
  ANTHROPIC_BASE_URL="http://localhost:8080" \
  ANTHROPIC_MODEL="gemini-3-pro-high[1m]" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="gemini-3-pro-high[1m]" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="gemini-3-flash[1m]" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="gemini-2.5-flash-lite[1m]" \
  CLAUDE_CODE_SUBAGENT_MODEL="gemini-3-flash[1m]" \
  ENABLE_EXPERIMENTAL_MCP_CLI="true" \
  claude'

# --- Custom Functions ---
ask() {
  if [ -t 0 ]; then
    prompt="$*"
  else
    prompt="$(cat)"
  fi
  opencode run -m github-copilot/grok-code-fast-1 --agent general \
    "$prompt" 2>/dev/null | glow -
}

ask_hard() {
  if [ -t 0 ]; then
    prompt="$*"
  else
    prompt="$(cat)"
  fi
  opencode run -m github-copilot/gpt-5-mini --agent general \
    "$prompt" 2>/dev/null | glow -
}
