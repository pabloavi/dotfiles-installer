# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
	PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

###########
# ALIASES #
###########
function nvide_function() {
	neovide --multigrid "$@"
	exit
}

alias nvide='nvide_function'

function mkcd() {
	mkdir -p "$1" && cd "$1" || exit
}

function ncm() {
	ncmpcpp-ueberzug "$@"
}

function pdfcompress() {
	gs -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite -dCompatibilityLevel=1.3 -dPDFSETTINGS=/screen -dEmbedAllFonts=true -dSubsetFonts=true -dColorImageDownsampleType=/Bicubic -dColorImageResolution=144 -dGrayImageDownsampleType=/Bicubic -dGrayImageResolution=144 -dMonoImageDownsampleType=/Bicubic -dMonoImageResolution=144 -sOutputFile=$1-compressed.pdf $1
}

function pywal() {
	wal "$@"
	pywalfox update
}

# combines two pictures with ffmpeg
function 2pic() {
	ffmpeg -i "$1" -i "$2" -filter_complex "sws_flags=bicubic;
        color=c=white:4x4,format=yuvj444p,trim=end_frame=1,split=2[c0][c1];
        [0][1]scale2ref='if(gte(max(main_w,main_h),max(iw,ih)),main_w,if(gte(main_w,main_h),iw,oh*mdar))':
                        'if(gte(max(main_w,main_h),max(iw,ih)),main_h,if(gte(main_w,main_h),ow/mdar,ih))'[0max][1ref];
        [1ref][0max]scale2ref='if(gte(max(main_w,main_h),max(iw,ih)),main_w,if(gte(main_w,main_h),iw,oh*mdar))':
                        'if(gte(max(main_w,main_h),max(iw,ih)),main_h,if(gte(main_w,main_h),ow/mdar,ih))'[1max][0max];
        [c0][0max]scale2ref[c0max][0max];[c1][1max]scale2ref[c1max][1max];[c0max][c1max]scale2ref='if(gte(main_w,iw),main_w,iw)':main_h[c0max][c1max];
        [c1max][c0max]scale2ref='if(gte(main_w,iw),main_w,iw)':main_h[c1max][c0max];
        [c0max][0max]overlay=format=auto:x=(W-w)/2:y=(H-h)/2[0f];[c1max][1max]overlay=format=auto:x=(W-w)/2:y=(H-h)/2[1f];
        [0f][1f]vstack,setsar=1" "$3"
}

alias r='ranger'
alias ls='logo-ls'

#################
# ENV VARIABLES #
#################
# source utility functions if they exist
if [ -f "$HOME/scripts/utils" ]; then
	source "$HOME/scripts/utils"
fi

# get 10 line of command output (print_xcolors) (color09) and convert it to base256
PS1_color=$(hex_to_base256 "$(print_xcolors | tail -n +1 | head -n 10 | tail -n 1)")
# PS1_color=$(lua "$HOME/scripts/lua/print_xcolor.lua" 10)
# 
export PS1='\[\e[0m\]\W \[\e[0;1;38;5;${PS1_color}m\] \[\e[0m\]'
export EDITOR='nvim'
export GCM_CREDENTIAL_STORE=cache
export AIRLATEX_USERNAME="cookies:overleaf_session2=s%3AH3rvx-AdIlpr-4f3oF65AxCS-Dvvm8ve.R7PDw%2Fllr8gPzdssL2fDbK70jkLt4NVwzdTDCDJ9rEk"

export PATH="$HOME/.cargo/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
. "$HOME/.cargo/env"
