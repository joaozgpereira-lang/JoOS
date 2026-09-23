# JoOS — zsh environment
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="firefox"
export TERM="xterm-256color"
export QT_QPA_PLATFORM="wayland"
export GDK_BACKEND="wayland,x11"
export XDG_CURRENT_DESKTOP="Hyprland"

alias ls="eza --icons"
alias ll="eza --icons -la"
alias la="eza --icons -a"
alias cat="bat"
alias gs="git status"
alias gc="git commit"
alias update="sudo pacman -Syu"
alias joos="joos-menu"

setopt AUTO_CD
setopt HIST_IGNORE_DUPS

autoload -Uz vcs_info
zstyle ':vcs_info:*' formats ' %F{208}(%b)%f'
zstyle ':vcs_info:*' actionformats ' %F{208}(%b|%a)%f'

precmd() { vcs_info }

PROMPT='%(?.%F{green}➜.%F{red}✗)%f %B%F{208}%~%b %f'
RPROMPT='${vcs_info_msg_0_}'