#!/bin/bash

## Change me!
groupadd -g 1000 nemo
##

apt-get update
apt-get upgrade -y
apt-get install -y man-db lsb-release ripgrep bat vim curl wget time tree aria2 jq dos2unix dstat ncdu unzip python3-pip
ln /usr/bin/batcat /usr/local/bin/bat

cat << EOF > /etc/apt/sources.list.d/git-core-ubuntu-ppa-jammy.list
deb https://ppa.launchpadcontent.net/git-core/ppa/ubuntu/ $(lsb_release -cs) main
# deb-src https://ppa.launchpadcontent.net/git-core/ppa/ubuntu/ jammy main
EOF
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E363C90F8F1B6217
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get update
apt-get install -y git git-lfs

# Patch dstat when running container as non-root.
#
# Create a new file under /usr/local/bin to workaround weird docker build behavior where in-place
# changes or renaming of /usr/bin/dstat vanishes during docker run.
sed 's/^    user = getpass.getuser()$/    try: user = getpass.getuser();\n    except KeyError: user = "I have no name!"\n/' /usr/bin/dstat >> /usr/local/bin/dstat \
    && chmod ugo+x /usr/local/bin/dstat

cat << 'EOF' > /etc/bash.bashrc.initubuntu
#### initubuntu additions from here onwards ####
export TERM=xterm-256color

git_branch() {
   local branch=$(/usr/bin/git branch 2>/dev/null | grep '^*' | colrm 1 2)
   [[ "$branch" == "" ]] && echo "" || echo "($branch) "
}

# All colors are bold
COLOR_GREEN="\[\033[1;32m\]"
COLOR_PURPLE="\[\033[1;35m\]"
COLOR_YELLOW="\[\033[1;33m\]"
COLOR_BLUE="\[\033[01;34m\]"
COLOR_OFF="\[\033[0m\]"

prompt_prefix() {
    # VScode calls pyenv shell instead of pyenv activate.
    if [[ (${TERM_PROGRAM} == "vscode") && (! -v VIRTUAL_ENV) && (-v PYENV_VERSION) ]]; then
        echo -n "($PYENV_VERSION) "
    fi
}

# Define PS1 before conda bash.hook, to correctly display CONDA_PROMPT_MODIFIER
#export PS1="\$(prompt_prefix)[$COLOR_GREEN\w$COLOR_OFF] $COLOR_PURPLE\$(git_branch)$COLOR_OFF\$ "
export PS1="\$(prompt_prefix)[$COLOR_BLUE\u@\h$COLOR_OFF:$COLOR_GREEN\w$COLOR_OFF] $COLOR_PURPLE\$(git_branch)$COLOR_OFF\$ "

man() {
        env \
                LESS_TERMCAP_mb=$(printf "\e[1;31m") \
                LESS_TERMCAP_md=$(printf "\e[1;31m") \
                LESS_TERMCAP_me=$(printf "\e[0m") \
                LESS_TERMCAP_se=$(printf "\e[0m") \
                LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
                LESS_TERMCAP_ue=$(printf "\e[0m") \
                LESS_TERMCAP_us=$(printf "\e[1;32m") \
                man "$@"
}

# Custom aliases
alias ll='ls -alF --color=auto'

export DSTAT_OPTS="-cdngym"
EOF

# TODO: skip if already exists.
echo 'source /etc/bash.bashrc.initubuntu' >> /etc/bash.bashrc

cat << 'EOF' > /etc/vim/vimrc.local
" Hybrid line numbers (https://github.com/josiahdavis/dotfiles/blob/master/.vimrc)
"
" Prefer built-in over RltvNmbr as the later makes vim even slower on
" high-latency aka. cross-region instance.
:set number relativenumber
:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
:  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
:augroup END

" Relative number only on focused-windoes (see: jeffkreeftmeijer/vim-numbertoggle)
autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &number | set relativenumber   | endif
autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &number | set norelativenumber | endif

" Remap keys to navigate window aka split screens to ctrl-{h,j,k,l}
" See: https://vi.stackexchange.com/a/3815
"
" Vim defaults to ctrl-w-{h,j,k,l}. However, ctrl-w on Linux (and Windows)
" closes browser tab.
"
" NOTE: ctrl-l was "clear and redraw screen". The later can still be invoked
"       with :redr[aw][!]
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

" Stanza extracted from https://github.com/verdimrc/linuxcfg/blob/main/.vimrc
set laststatus=2
set hlsearch
set colorcolumn=80
set splitbelow
set splitright

set lazyredraw
set nottyfast

autocmd FileType help setlocal number
autocmd BufNewFile,BufRead *.jl set filetype=julia
autocmd BufNewFile,BufRead *.cu set filetype=cuda
autocmd BufNewFile,BufRead *.cuh set filetype=cuda
autocmd BufEnter *.yaml,*.yml :set indentkeys-=0#
if v:version >= 800
    " Smart paste mode. See Vim's xterm-bracketed-paste help topic.
    let &t_BE = "\<Esc>[?2004h"
    let &t_BD = "\<Esc>[?2004l"
    let &t_PS = "\<Esc>[200~"
    let &t_PE = "\<Esc>[201~"
endif

""" Coding style
" Prefer spaces to tabs
filetype indent on
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab
set nowrap
set foldmethod=indent
set foldlevel=99
set smartindent

""" Shortcuts
map <F3> :set paste!<CR>
" Use <leader>l to toggle display of whitespace
nmap <leader>l :set list!<CR>

" Highlight trailing space without plugins -- https://stackoverflow.com/a/48951029
highlight RedundantSpaces ctermbg=red guibg=red
match RedundantSpaces /\s\+$/

" Terminado supports 256 colors
set t_Co=256
set cursorline
highlight CursorLine cterm=None ctermbg=236
highlight CursorLineNr cterm=None ctermbg=236
"colorscheme delek
"colorscheme elflord
"colorscheme murphy
"colorscheme ron
highlight colorColumn ctermbg=237

if exists('$KITTY_WINDOW_ID') || $TERM == "xterm-kitty"
    let &t_ut=''
endif
EOF

yes | unminimize

cat << 'EOF' > /tmp/delta.sh
#!/bin/bash

# Constants
APP=delta
GH=dandavison/delta

mkdir -p ~/.local/bin
cd /usr/local/bin

latest_download_url() {
  curl --silent "https://api.github.com/repos/${GH}/releases/latest" |   # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/delta-.*-$(uname -i)-unknown-linux-musl.tar.gz" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                         # Pluck JSON value
}


LATEST_DOWNLOAD_URL=$(latest_download_url)
TARBALL=${LATEST_DOWNLOAD_URL##*/}
curl -LO ${LATEST_DOWNLOAD_URL}

# Go tarball has no root, so we need to create one
DIR=${TARBALL%.tar.gz}
tar -xzf $TARBALL && rm $TARBALL

[[ -L ${APP}-latest ]] && rm ${APP}-latest
mv $DIR/delta /usr/local/bin/
EOF
bash /tmp/delta.sh
rm /tmp/delta.sh

cat << 'EOF' > /tmp/duf.sh
#!/bin/bash

# Constants
APP=duf
GH=muesli/duf

latest_download_url() {
  [[ $(uname -i) == "x86_64" ]] && local arch=amd64 || local arch=arm64
  curl --silent "https://api.github.com/repos/${GH}/releases/latest" |   # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/duf_.*_linux_$arch.deb" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                         # Pluck JSON value
}

LATEST_DOWNLOAD_URL=$(latest_download_url)
DEB=${LATEST_DOWNLOAD_URL##*/}
(cd /tmp/ && curl -LO ${LATEST_DOWNLOAD_URL})

apt-get install -y /tmp/$DEB && rm /tmp/$DEB
EOF
bash /tmp/duf.sh
rm /tmp/duf.sh

cat << 'EOF' > /tmp/yq.sh
#!/bin/bash

# Constants
APP=yq
GH=mikefarah/yq

mkdir -p ~/.local/bin
cd ~/.local/bin

latest_download_url() {
  curl --silent "https://api.github.com/repos/${GH}/releases/latest" |   # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/yq_linux_amd64.tar.gz" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                         # Pluck JSON value
}


LATEST_DOWNLOAD_URL=$(latest_download_url)
TARBALL=${LATEST_DOWNLOAD_URL##*/}
curl -LO ${LATEST_DOWNLOAD_URL}

# Go tarball has no root, so we need to create one
DIR=${TARBALL%.tar.gz}
tar -xzf $TARBALL && rm $TARBALL

mv yq_linux_amd64 /usr/local/bin/yq
./install-man-page.sh
rm yq.1 install-man-page.sh
EOF
bash /tmp/yq.sh
rm /tmp/yq.sh

apt-get autoclean
rm -fr /root/.cache/pip

git config --system init.defaultBranch main
git config --system alias.lol "log --graph --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(bold white)— %an%C(reset)%C(bold yellow)%d%C(reset)' --abbrev-commit --date=relative"
git config --system alias.lolc "! clear; git lol -\$(expr \`tput lines\` '*' 2 / 3)"
git config --system alias.lola "lol --all"
git config --system alias.lolac "lolc --all"
git config --system credential.helper 'cache --timeout=14400'
git config --system core.editor "vim"
git config --system pull.ff "only"
git config --system merge.renormalize "true"
if command -v delta &> /dev/null ; then
    echo "adjust-git.sh: delta is available..."
    git config --system core.pager "delta -s"
    git config --system interactive.diffFilter "delta -s --color-only"
    git config --system delta.navigate "true"

    # https://github.com/dandavison/delta/discussions/1461#discussion-5342765
    git config --system delta.wrap-max-lines unlimited
    git config --system delta.wrap-right-percent 1
    git config --system delta.wrap-left-symbol " "
fi
