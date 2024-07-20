#!/bin/sh

# 251 = 120ish bit opus audio with ,opus extension
# 140 = 128 bit aac audio with m4a extension
# 251/140 deafults to opus but if opus is not present then aac will be download 

archive=".db"
touch "$archive"
format="251/140"

all_ids=""
id_count=""

archive_size="$(wc -l "$archive" | cut -d ' ' -f 1)"





# loop over arguments and extract ids from playlists or albums 
get_ids(){
	for i in "$@" ; do
		if  echo "$i" | grep -q "playlist?list" ; then

			# extract ids from playlist json
			json="$(yt-dlp -j --flat-playlist "$i" 2> /dev/null)"
			ids="$(echo "$json"  | grep -o '"id": "..........."' | cut -d '"' -f 4)"
			all_ids="$(printf "%s\n%s" "$ids" "$all_ids" )"

		else 
			# append to all_ids string
			all_ids="$(printf "%s\n%s" "$i" "$all_ids" )"
			
		fi
	done

	all_ids="$(printf "%s" "$all_ids" | sed '/^$/d')"
}




download_songs(){
	
	echo "Downloading songs: "
	echo "$all_ids" | xargs  -P 8 -I {} -d '\n' \
	yt-dlp -q -x -f "$format" \
	--embed-metadata  \
	--parse-metadata "%(artist)s:%(meta_album_artist)s"  \
	--replace-in-metadata "meta_album_artist" ", .*$" "" \
	--download-archive  "$archive" \
	--convert-thumbnails jpg --ppa "ffmpeg: -c:v mjpeg -vf crop='ih:ih'" \
	--embed-thumbnail \
	-o "%(artist)s - %(title)s [%(id)s].%(ext)s" \
	--  {} 

	echo "Finished downloading"



}


create_playlists(){

	for i in "$@" ; do
		if  echo "$i" | grep -q  "playlist?list" ; then

			if echo "$i" | grep -q "/playlist?list=OLAK" ; then
				continue
			fi


			json="$(yt-dlp -j --flat-playlist "$i" 2> /dev/null)"
			ids="$(echo "$json"  | grep -o '"id": "..........."' | cut -d '"' -f 4)"
			playlist_name="$(echo "$json"  | grep -oP '"playlist_title": ".*"'  | cut -d '"' -f 4 | head -n 1)"

			if [ -e "${playlist_name}.m3u" ];then
				current_time="$(date +"%Y-%m-%d-%H:%M:%S")"
				echo "Playlist already exists, adding timestamp to playlist ${playlist_name}!!!"
				playlist_name="${playlist_name}_${current_time}"
			fi


			echo "$ids" | xargs -I {} -n 1 -d '\n'  find .  -name "*{}*" > "${playlist_name}.m3u"
			echo "Created playlist file ${playlist_name}.m3u"
			
		fi
	done


}




print_help(){
	echo "usage: ./ytmd.sh [-h] <YTMUSIC url>..."
	exit 1
}

check_args(){

	[ "$1" = "" ] && echo "No arguments !!! You must give me url at least one url of song | album | playlist on YTMusic." && exit 1

	for i in "$@" ; do
		if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
			print_help 
		fi
	done
	
	for i in "$@" ; do
		if ! echo "$i" | grep -q "/playlist?list=" && !  echo "$i" | grep -q "/watch?v=" ; then
			echo "Error, <$i> is invalid argument !!!"
			exit 1 
		fi
	done

}

progress(){
	while true; do
		cur_archive_size="$(wc -l "$archive" | cut -d ' ' -f 1)"
		downloaded=$((cur_archive_size - archive_size))
		#echo  "$downloaded / $id_count"
		printf "Downloaded: %s / %s\r" "$downloaded" "$id_count"
		sleep 5
	done
}

check_args "$@"
get_ids "$@"
echo "$all_ids"
id_count="$(echo "$all_ids" | wc -l | cut -d ' ' -f 1)"
progress & # start background process showing downloading progress
pid=$! # pid of progress bar process
download_songs
kill "$pid"
create_playlists "$@"




