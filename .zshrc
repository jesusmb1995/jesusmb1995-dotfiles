# Profiling setup. Also uncomment at the bottom.
# zmodload zsh/zprof

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"
# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git tmux zshmarks)

if [ -z "$ZSH_TMUX_AUTOSTART" ]; then
	export ZSH_TMUX_AUTOSTART=true
fi

# Autoconnect to avoid startup time
export ZSH_TMUX_AUTOCONNECT=true

# Change directory to current after attaching
# This is a custom mod of plugin at `/home/jberlanga/.oh-my-zsh/plugins/tmux/tmux.plugin.zsh`
export ZSH_TMUX_CD=true

# Prepare new warm tmux session on the background 
# Check for TMUX to avoid infinite loop
if [ -z "$TMUX" ]; then
  export TMUX_WARM_DAEMON=$(cat /tmp/tmux_warm_daemon.pid)
  ps -p ${TMUX_WARM_DAEMON} > /dev/null 2>&1
  if [ $? -ne 0  ]; then
    /usr/bin/tmux_warm_daemon
  fi
  
  export TMUX_PREATTACH_PATH="$(pwd)"
  kill -USR1 ${TMUX_WARM_DAEMON}

  # $NVIM is set by Neovim in direct child shells. Propagate it into the
  # global tmux env before the tmux plugin attaches to the pre-warmed session.
  if [[ -n "$NVIM" ]]; then
    tmux set-environment -g NVIM_TERM_DIR "$(pwd)" 2>/dev/null
  fi
fi

source $ZSH/oh-my-zsh.sh

# When a terminal is opened from Neovim, hide cwd and git info from the prompt
# while still in the initial directory. Neovim sets NVIM_TERM_DIR in the tmux
# environment via TermOpen autocmd; we pick it up here in the pre-warmed shell.
_short_git_info() {
  local branch
  branch=$(command git symbolic-ref --short HEAD 2>/dev/null) || return 0
  local short
  if (( ${#branch} > 6 )); then
    short="${branch:0:2}${branch: -4}"
  else
    short="$branch"
  fi
  local indicator=""
  if [[ "$(parse_git_dirty)" == "$ZSH_THEME_GIT_PROMPT_DIRTY" ]]; then
    indicator=" %{$fg[yellow]%}%1{✗%}"
  fi
  echo "%{$fg[red]%}${short}%{$reset_color%}${indicator}%{$reset_color%} "
}

_nvim_prompt_check() {
  if [[ -n "$TMUX" && -z "$_NVIM_INITIAL_DIR" ]]; then
    local val=$(tmux show-environment -g NVIM_TERM_DIR 2>/dev/null)
    if [[ "$val" == NVIM_TERM_DIR=* ]]; then
      _NVIM_INITIAL_DIR="${val#NVIM_TERM_DIR=}"
      tmux set-environment -gu NVIM_TERM_DIR 2>/dev/null
    fi
  fi
  if [[ -z "$_SHELL_PROJECT_ROOT" ]]; then
    _SHELL_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
    _SHELL_INITIAL_DIR="$PWD"
  fi
  local current_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -n "$_NVIM_INITIAL_DIR" && "$PWD" == "$_NVIM_INITIAL_DIR" ]]; then
    PROMPT="%(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} )%{$reset_color%}"
  elif [[ -n "$_SHELL_PROJECT_ROOT" && "$current_root" == "$_SHELL_PROJECT_ROOT" ]]; then
    if [[ "$PWD" == "$_SHELL_INITIAL_DIR" ]]; then
      PROMPT="%(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} )%{$reset_color%}"
    else
      PROMPT="%(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} ) %{$fg[cyan]%}%c%{$reset_color%}"
    fi
    PROMPT+=' $(_short_git_info)'
  else
    PROMPT="%(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} ) %{$fg[cyan]%}%c%{$reset_color%}"
    PROMPT+=' $(git_prompt_info)'
  fi
}
precmd_functions+=(_nvim_prompt_check)

# User configuration
bindkey -v
export KEYTIMEOUT=1
bindkey ^R history-incremental-search-backward

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
source /home/jberlanga/.aliases

# Load whatever is on .profile, e.g. exports.
if [ -f ~/.profile ]; then 
    . ~/.profile;
fi

# Lazy load function
nvm() {
if [[ -z "${NVM_DIR}" ]]; then
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi
nvm "$@"
}

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
source /home/jberlanga/m_nvim.zsh

# Command bookmark per directory: savecmd runcmd
# Use savecmd to save last command into .local_cmd_bookmarks
source /luksmap/Code/savecmd/savecmd.zsh

#zprof

# Added by Pear Runtime, configures system with Pear CLI
export PATH="/home/jberlanga/.config/pear/bin":$PATH

# Cursor cli
export PATH="/home/jberlanga/.local/bin":$PATH
