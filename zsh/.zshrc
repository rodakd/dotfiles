export ZSH="$HOME/.oh-my-zsh"
plugins=(git)
source $ZSH/oh-my-zsh.sh
PROMPT='%{$fg_bold[cyan]%}% arch %{$fg_bold[blue]%}%~%{$reset_color%}$(git_prompt_info): '
ZSH_THEME_GIT_PROMPT_PREFIX=" %B$FG[165]("
ZSH_THEME_GIT_PROMPT_SUFFIX=")%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

export EDITOR="nvim"
export COMPOSE_PROFILES=nginx
export NODE_CONFIG_ENV="local"
export NODE_OPTIONS=--max_old_space_size=4096

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
	exec startx
fi

alias chrome="nohup google-chrome-stable --restore-last-session > /dev/null &; disown"
alias spotify="nohup spotify > /dev/null &; disown"
alias i3conf="nvim ~/.config/i3/config"
alias res="nvim ~/.Xresources"
alias zshrc="nvim ~/.zshrc"
alias dock="autorandr --load docked"
alias logo="sudo pkill -u rodakd"
alias nvconf="nvim ~/.config/nvim"
alias xcolor="xcolor --selection clipboard"
alias pc="sudo pacman -S"
alias keyb="~/dotfiles/scripts/keyboard.sh"
alias ivy="cd ~/projects/ivy"
alias respect="cd ~/projects/respect"
alias nv="nvim ."

ALSA_CARD=Audio
LIBGL_DRI3_DISABLE=1

source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

alias luamake=/home/rodakd/lua-language-server/3rd/luamake/luamake
export PATH="/home/rodakd/lua-language-server/bin:/home/rodakd/.local/bin:$PATH"

# fnm
export PATH="/home/rodakd/.local/share/fnm:$PATH"
eval "`fnm env`"
