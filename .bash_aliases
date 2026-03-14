# ==============================================
#                  SECRETS
# ==============================================
if [ -f "$HOME/.bash_secrets" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.bash_secrets"
fi

# ==============================================
#               HISTORY CONFIG
# ==============================================
HBLU="\033[0;94m"
HNON="\033[0m"
HISTTIMEFORMAT=$(printf "${HBLU}[%(%F %T)T]${HNON} ")
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend cmdhist

# ==============================================
#                TIMEZONE
# ==============================================
export TZ=America/Chicago

# ==============================================
#                  PROMPT
# ==============================================
GRN="\[\033[1;32m\]"
CYN="\[\033[1;36m\]"
RED="\[\033[1;31m\]"
YLW="\[\033[1;33m\]"
BLU="\[\033[38;5;245m\]"
NON="\[\033[0m\]"

if [ "$(id -u)" -eq 0 ]; then
    PS1="\t $GRN[\h] $NON$BLU\u $NON$YLW{\w} $NON$RED#$NON "
else
    PS1="\t $GRN[\h] $NON$BLU\u $NON$YLW{\w} $NON% "
fi
PS2="$YLW[cont...]$NON "
export PS1 PS2

# ==============================================
#             EDITOR & PAGER
# ==============================================
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="vim"
else
    export EDITOR="nano"
fi

if command -v less >/dev/null 2>&1; then
    export PAGER="less"
else
    export PAGER="more"
fi

# ==============================================
#                 UMASK
# ==============================================
umask 022

# ==============================================
#             OPTIONAL TOOLING
# ==============================================
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    # shellcheck disable=SC1091
    . /usr/share/doc/fzf/examples/key-bindings.bash
fi

if [ -f /usr/share/bash-completion/completions/fzf ]; then
    # shellcheck disable=SC1091
    . /usr/share/bash-completion/completions/fzf
fi

# ==============================================
#                 ALIASES
# ==============================================
alias home='cd "$HOME"'
alias ..='cd ..'
alias ...='cd ../..'
alias cd..='cd ..'
alias sys='cd /var/log'

alias now='date "+%T"'
alias up='uptime'
alias mnt='mount | column -t'
alias mem='free -h'
alias disk='df -h | grep -v tmpfs'
alias cpu='top -o %CPU'
alias cls='clear; pwd; echo'
alias jlog='journalctl -f'
alias log='sudo journalctl -xe'
alias tracert='mtr'
alias reload='source "$HOME/.bash_aliases"'
alias genpass='openssl rand -base64 24 | tr -d "\n" | cut -c1-20; echo'
alias subtitle='$HOME/.scripts/subtitle/subtitle.py'
alias fixmonitor='sudo modprobe amdgpu'
alias grep='grep --color=auto'

if command -v eza >/dev/null 2>&1; then
    alias ls='eza -lah --group-directories-first'
    alias ll='eza -la --group-directories-first'
    alias la='eza -a'
elif command -v exa >/dev/null 2>&1; then
    alias ls='exa -lah --group-directories-first'
    alias ll='exa -la --group-directories-first'
    alias la='exa -a'
else
    alias ls='ls -lhaF --color=auto'
    alias ll='ls -al --color=auto'
    alias la='ls -A --color=auto'
fi

if command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
elif command -v bat >/dev/null 2>&1; then
    alias bat='bat'
fi

if command -v rg >/dev/null 2>&1; then
    alias search='rg -n --hidden --smart-case'
    alias files='rg --files'
fi

if command -v zoxide >/dev/null 2>&1; then
    alias cd='z'
fi

# ==============================================
#                   MOTD
# ==============================================
echo
echo "Welcome, $USER!"
echo "It is $(date +'%A') my dudes! $(date +'%Y-%m-%d')"
echo "System Uptime: $(uptime -p | cut -d ' ' -f2-)"
echo
