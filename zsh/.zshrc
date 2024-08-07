zmodload zsh/datetime
# Record the start time
start_time=$EPOCHREALTIME

# Update path $PATH.
export PATH=/usr/local/bin:$PATH
export PATH=$HOME/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.swiftpm/bin:$PATH

# Syntax highlighting
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/opt/homebrew/share/zsh-syntax-highlighting/highlighters
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# Use the zshift package to select a random theme
random_theme() {
  # Check if zshift is installed and in PATH
  if ! command -v zshift &>/dev/null; then
    echo "zshift not found. Attempting to install..."
    if [ -d "$HOME/Code/configs/zshift" ]; then
      cd "$HOME/Code/configs/zshift" >/dev/null
      swift package experimental-install 2>&1 || echo "Failed to install zshift"
      popd >/dev/null
    else
      echo "Error: zshift directory not found at $HOME/Code/configs/zshift"
      return 1
    fi
  fi

  # Run zshift and capture its output
  zshift_output=$(zshift 2>&1)
  if [ $? -ne 0 ]; then
    echo "Error running zshift: $zshift_output"
    return 1
  fi

  # Evaluate zshift output in the current shell
  eval "$zshift_output"

  # Check if ZSH_THEME was set
  if [ -z "$ZSH_THEME" ]; then
    echo "Error: ZSH_THEME not set by zshift"
    return 1
  fi

  echo "ZSH theme set to: $ZSH_THEME"

  # Source oh-my-zsh to apply the new theme
  source $ZSH/oh-my-zsh.sh
}

random_theme

# update automatically without asking
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 1
# Uncomment the following line to change how often to auto-update (in days).
# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"
# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

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
DISABLE_UNTRACKED_FILES_DIRTY="true"

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
plugins=(git mercurial)

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases

alias zshconfig="code ~/.zshrc"
alias ohmyzsh="code ~/.oh-my-zsh"
alias ztheme='(){ export ZSH_THEME="$@" && source $ZSH/oh-my-zsh.sh }'

# Record the end time
end_time=$EPOCHREALTIME
elapsed_time=$(($end_time - $start_time))
echo "zshrc loaded in $elapsed_time seconds"
