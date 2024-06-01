#!/bin/sh

format="251/140"

all_ids=""

get_ids(){

	for i in "$@" ; do
		if  echo "$i" | grep -q "playlist?list" ; then


			json="$(yt-dlp -j --flat-playlist "$i")"
			ids="$(echo "$json"  | grep -o '"id": "..........."' | cut -d '"' -f 4)"
			all_ids="$(printf "%s\n%s" "$ids" "$all_ids" )"

		else 
			
			all_ids="$(printf "%s\n%s" "$i" "$all_ids" )"
			
		fi
	done

	all_ids="$(printf "%s" "$all_ids" | sed '/^$/d')"
}


printf "%s" "$all_ids"


download_songs(){

	echo "$all_ids" | xargs  -P 8 -I {} -d '\n' \
	yt-dlp -x -f "$format" \
	--embed-metadata  \
	--parse-metadata "%(artist)s:%(meta_album_artist)s"  \
	--replace-in-metadata "meta_album_artist" ", .*$" "" \
	--download-archive  db \
	--convert-thumbnails jpg --ppa "ffmpeg: -c:v mjpeg -vf crop='ih:ih'" \
	--embed-thumbnail \
	-o "%(artist)s - %(title)s [%(id)s].%(ext)s" \
	-- {}

}


create_playlists(){

	for i in "$@" ; do
		if  echo "$i" | grep -q  "playlist?list" ; then

			if echo "$i" | grep -q "/playlist?list=OLAK" ; then
				continue
			fi


			json="$(yt-dlp -j --flat-playlist "$i")"
			ids="$(echo "$json"  | grep -o '"id": "..........."' | cut -d '"' -f 4)"
			playlist_name="$(echo "$json"  | grep -oP '"playlist_title": ".*"'  | cut -d '"' -f 4 | head -n 1)"

			echo "$ids" | xargs -I {} -n 1 -d '\n'  find .  -name "*{}*" > "${playlist_name}.m3u"
			
		fi
	done


}

[ "$1" = "" ] && echo "No args !!! You must give me url at least one url of song | album | playlist on YTMusic." && exit 1



print_help(){
	echo ""

}


#[ "$1"='-f'] && 



get_ids "$@"
download_songs
create_playlists "$@"




