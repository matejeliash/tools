#!/bin/sh



if [ "$1" = "-d" ];then

	stream_url="$(curl "$2" | grep download.php | cut -d '"' -f 2  | sed 's/download.php/download_free_stream.php/g')"
else
	stream_url="$(curl "$1" | grep download.php | cut -d '"' -f 2  | sed 's/download.php/download_free_stream.php/g')"
fi

#stream_url="${stream_url}&stream=1"

part1="$(echo "$stream_url" | cut -d '&' -f 1)"

part2="$(echo "$stream_url" | cut -d '&' -f 2-)"

final_url="${part1}&stream=1&session=&${part2}"

echo "$final_url"
echo "$part2"


echo "$final_url" >> .fastshare_logs

if [ "$1" = "-d" ];then

	 aria2c "$final_url" -o "$part2" 
else
	mpv "$final_url"

fi




