#!/bin/bash

url=$1
minecraft=https://www.youtube.com/watch?v=NX-i0IWl3yg
video1=input.mp4
video2=minecraft.mp4

if [ -z "$url" ]
then
    echo "Usage: ./script.sh <video-url>"
    exit 1
fi

rm -f $video1
youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' $url -o $video1

if [ ! -f "$video2" ]
then
    echo "Downloading minecraft.mp4"
    youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' $minecraft -o $video2
fi

duration_1=$(ffprobe -i $video1 -show_entries format=duration -v quiet -of csv="p=0")
duration_2=$(ffprobe -i $video2 -show_entries format=duration -v quiet -of csv="p=0")
loops=$(echo "scale=0; $duration_1 / $duration_2" | bc -l)


ffmpeg -i $video1 -i $video2 -filter_complex \
    "[0:v]fps=30,scale=-1:ih/2[top]; \
    [1:v]fps=30,scale=-1:ih/2[bottom]; \
    [bottom]loop=$loops:32767:0,setpts=N/FRAME_RATE/TB[bottom]; \
    [bottom]trim=duration=$duration_1[bottom]; \
    [top][bottom] vstack=inputs=2[v]; \
    [0:a]aformat=sample_fmts=fltp:channel_layouts=stereo[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -c:a aac -crf 23 -preset veryfast -shortest output.mp4 -y

