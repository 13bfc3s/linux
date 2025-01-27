# ==============================================
#               HISTORY CONFIG
# ==============================================
# History colors
HBLU="\033[0;94m"
HNON="\033[0m"
# History Setup
HISTTIMEFORMAT=$(echo -e ${HBLU}[%F %T]${HNON})
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups

# ==============================================
#                TIMEZONE
# ==============================================
export TZ=America/Chicago

# ==============================================
#                  PROMPT
# ==============================================
# Prompt colors
GRN="\[\033[1;32m\]"
CYN="\[\033[1;36m\]"
RED="\[\033[1;31m\]"
YLW="\[\033[1;33m\]"
BLU="\[\033[38;90m\]"
NON="\[\033[0m\]"
# Cursor Setup
if [ $(id -u) -eq 0 ]; then
    PS1="\t $GRN[\h] $NON$BLU\u $NON$YLW{\w} $NON$RED#$NON "
    PS2="$YLW[cont...]$NON "
else
    PS1="\t $GRN[\h] $NON$BLU\u $NON$YLW{\w} $NON% "
    PS2="$YLW[cont...]$NON "
fi

# ==============================================
#             EDITOR & PAGER
# ==============================================
EDITOR=$(which nano)
PAGER=$(which less || which more)

# ==============================================
#                 EXPORTS
# ==============================================
export PS1 PS2 EDITOR PAGER  # Removed PATH (don't reset it accidentally)

# ==============================================
#                 UMASK
# ==============================================
umask 022

# ==============================================
#                 ALIASES
# ==============================================
# Navigation
alias home='cd ~'
alias sys='cd /var/log/'
alias cd..='cd ..'
alias cd../..='cd ../..'
alias cd../../..='cd ../../..'

# System Info
alias now="date +%T"
alias up="uptime"
alias mnt="mount | column -t"
alias mem='free -h'
alias disk='df -h | grep -v tmpfs'
alias cpu='top -o %CPU'

# Listing/Viewing
alias cls="clear; pwd; echo"
alias ls="ls -lhaF --color=auto"
alias ll="ls -al --color=auto"
alias lm="ls -al | $PAGER"
alias jlog="journalctl -f"
alias log='sudo journalctl -xe'

# Utilities
alias search='sudo grep -winr "./" -le'
alias tracert='mtr'
alias reload='source ~/.bash_aliases'
alias genpass='openssl rand -base64 20 | cut -c1-16'

# ==============================================
#                   MOTD
# ==============================================
echo -e ""
echo -e "Welcome, $USER!"
echo -e "It is $(date +'%A') my dudes! $(date +'%Y-%m-%d')"
echo -e "System Uptime: $(uptime -p | cut -d ' ' -f2-)\n"
