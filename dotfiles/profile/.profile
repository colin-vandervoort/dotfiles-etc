# cSpell: ignore sshhome jenv GOSUMDB PKG_CONFIG_PATH pnpm CPPFLAGS
#
# POSIX-sh config shared by bash and zsh (see dotfiles/.bash_profile and
# dotfiles/zsh/.zshrc, which both source this). Keep this file portable:
# no [[ ]], no shell-specific completion syntax.

# Homebrew (sets PATH, MANPATH, HOMEBREW_PREFIX, etc.)
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# .NET Core SDK tools
[ -d "$HOME/.dotnet/tools" ] && export PATH="$PATH:$HOME/.dotnet/tools"

# Obsidian CLI (Obsidian > Settings > General > Command line interface)
[ -d "/Applications/Obsidian.app/Contents/MacOS" ] && export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# Preferred editor for local and remote sessions
if [ -n "$SSH_CONNECTION" ]; then
  export EDITOR='nvim'
else
  export EDITOR='mvim'
fi

# navigate to global ssh directory
alias sshhome="cd ~/.ssh"

alias tmux="tmux -f ~/.config/tmux/tmux.conf"

# bat config
export BAT_THEME="base16"

# Go config
export GOPATH=$HOME/golang
# export GOPROXY=https://proxy.golang.org,direct
# export GOSUMDB="sum.golang.org"
export PATH=$PATH:$GOPATH/bin
# cSpell: ignore batgodoc
bgd() {
  go doc "$@" | bat -l go
}

# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
alias pn=pnpm
# pnpm end

# Deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Python
export PATH=/Users/colin/Library/Python/3.13/bin:$PATH

# Ruby

# put Homebrew Ruby first in PATH
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# help compilers find ruby
export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"

# help pkg-config find ruby
export PKG_CONFIG_PATH="/opt/homebrew/opt/ruby/lib/pkgconfig"

# gems
export PATH=$HOME/.gem/bin:$PATH
export GEM_HOME=$HOME/.gem

# Dart / Flutter
export PATH=$HOME/development/flutter/bin:$PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Java / JVM
# https://github.com/jenv/jenv
test -d "$HOME/.jenv/bin" && {
    export PATH="$HOME/.jenv/bin:$PATH"
}
command -v jenv > /dev/null && {
    eval "$(jenv init -)"
}

# uv
[ -f "$HOME/.local/bin/env" ] && \. "$HOME/.local/bin/env"

# rustup / cargo
[ -f "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"
