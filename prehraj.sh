#!/bin/sh


video_options=""
selected_url=""
video_url=""
input=""

download_arg=0
original_arg=0
select_first_arg=0


print_help(){

echo "
Usage:
    $> prehraj.sh [-d] [-o][query]
       prehraj.sh \"MOVIE_NAME\"
       prehraj.sh \"SERIES_NAME s01e10\"
    Both -d and query are optional, if query not provided keyboard input is required. 
    Options:
       -h, --help  
           Show  help message and exit
       -d, --download
           Selected file will be downloaded
       -o, --original
           Original video quality is selected

    "


}

# prehraj.sh [-h] [-d] [-original] [....]

# simple input parsing
parse_input(){
	
	# loop over program args from terminal
	last_arg=""
	c=0
	for i in "$@" ; do

		# just print help and exit
		if [ "$i" = "-h" ] || [ "$i" = "--help" ];then
			print_help && exit
		fi

		c=$((c+1))
		last_arg="$i"

		if [ "$c" = "$#" ]; then
			 break
		fi
	
		if [ "$i" = "-d" ] || [ "$i" = "--download" ];then
			download_arg=1

		elif [ "$i" = "-o" ] || [ "$i" = "--original" ];then
			original_arg=1
		elif [ "$i" = "-f" ] ;then
			select_first_arg=1
		else
			echo "Wrong argument -> ${i} on position ${c}" && exit
		fi	
	
	done
	
	# check if last arg is input else ask for input
	if [ -z "$1" ] || [ "$last_arg" = "-d" ] || [ "$last_arg" = "-o" ] ;then

		echo "Search: "
		read input
	else
		input="$last_arg"
	fi

	input="$(echo "$input" | sed 's/ /%20/g')"

}


# get all urls using curl and format textfor fzf selection
search(){
	results="$(curl -s "https://prehraj.to/hledej/${input}" "https://prehraj.to/hledej/${input}?vp-page=2" )"

	urls_and_names="$( echo "$results" | grep -o  'video--link" href="[^>]*' )" # | cut -d '"' -f 3 )"

	[ -z "$urls_and_names" ] && echo "Nothing found, exiting ..." &&  exit

	urls="$(echo "$urls_and_names" | cut -d '"' -f 3)"
	names="$(echo "$urls_and_names" | cut -d '"' -f 5)"

	sizes="$( echo "$results" | grep -o  'tag--size">[^<]*'  | cut -d '>' -f 2)"




	num_result="$(echo "$urls" | wc -l)"
	
	BLUE="\033[1;34m"
	RED="\033[1;31m"
	ENDC="\033[0m"

	lines="$(for i in $(seq "$num_result")
	do
		printf "%-3s " "$i" 
		size="$(printf "%s" "$sizes" | sed "${i}q;d" | tr '\n' ' ')"
		printf "%s%-12s" "$BLUE" "$size" 
		name="$(printf "%s" "$names" | sed "${i}q;d" | tr '\n' ' ')"
		printf "%s%s%s\n" "$RED" "$name" "$ENDC"

	done )"

	video_options="$lines"
	
}

# select available videos from prehraj
select_video(){
	
	line=""
	if [ "$select_first_arg" = "1" ] ; then
		line="$(echo "$video_options" | fzf --filter="$input" | head -n 1 )"
	else
		line="$(echo "$video_options" | fzf --ansi --prompt "Select from options: " )"
	fi

	[ $? != 0 ] && exit

	num="$(echo "$line" | cut -d ' ' -f 1 | tr -d ' ' )"
	title="$(echo "$line" | cut -d ' ' -f 2  )"


	video_id="$(echo  "$urls"  | sed "${num}q;d")"

	full_url="https://prehraj.to${video_id}"

	selected_url="$full_url"

}


# select from avilable qualities, ORIGINAL video can be in various formats and resolutions, 
# ORIGINAL is the highest quality, other options are trancoded versions of ORIGINAL video in h264 coded 
select_quality(){
	

	if [ "$original_arg" = "1" ]
	then
		video_url="${selected_url}?do=download"
		return
	fi

	video_page="$(curl "$selected_url" | grep "type: 'video/mp4'")"
	#echo "$video_page"
	options="$(echo "$video_page" | cut -d "'" -f 6)"

	echo "$options"
	selected="$(printf "ORIGINAL\n%s" "$options" | fzf --prompt "Select quality: ")"
	[ $? != 0 ] && exit


	if [ "$selected" = "ORIGINAL" ]
	then
		video_url="${selected_url}?do=download"
	else
		video_url="$(echo "$video_page" | grep "$selected" | cut -d '"' -f 2 )"
	#	mpv "$video_url"
	fi


}


play_video(){
	
	if [ -n "$(uname -a | grep "Android")" ]
	then	
		# android mpv
		am start --user 0 -a android.intent.action.VIEW -d "$video_url" -n is.xyz.mpv/.MPVActivity
	else	
		# linux mpv
		mpv --title="$title"  "$video_url"

	fi


}



download_video(){
		
	if [ "$(echo "$video_url" | grep "do=download")" ]
	then
		 nohup aria2c --file-allocation=none -x 16 -s 16  "$video_url" & 
	else
		name="$(echo "$selected_url" | sed 's|https://prehraj.to/||g' | sed 's/..............$//g'| sed 's/%20/ /g')"

	 nohup aria2c --file-allocation=none  -x 16 -s 16 "$video_url" -o "${name}.mp4" & 


	fi


	

}



check_dependencies(){

	[ -n "$( command -v "grep ")" ] && echo "Grep not installed !!!" && exit 


}

# main

check_dependencies

parse_input "$@"
search 
select_video  
select_quality

if [ "$download_arg" = 1 ];then
	download_video
else
	play_video
fi

exit

# prehraj
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


