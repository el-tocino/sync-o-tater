#!/bin/bash
# $1 = left video
# $2 = right video

#adjust to point at your copy
CLPR=~/clapperless.py

# boring test stuff

if [ $# -lt 2 ]  || [ $# -gt 3 ]
	then
		echo "Usage: $0 leftvideofile rightvideofile [optional: clapperless path]"
		exit 1
fi

if [ ! -r $1 ]
	then	
		echo "Can't read left video?"
		exit 2
fi

if [ ! -r $2 ]
	then
		echo "Can't read right video?"
		exit 2
fi

if [ $# -eq 3 ]
	then
		CLPR=$3
fi

if [ ! -r $CLPR ]
	then
		echo "Can't find clapperless!"
		exit 3
fi

# find framerate of the videos

LFR=$(exiftool -VideoFrameRate $1 | awk ' { print $NF} ' )
RFR=$(exiftool -VideoFrameRate $2 | awk ' { print $NF} ' )

if [ $LFR != $RFR ]
	then
		echo "Differing frame rates. This tool needs matched frame rates for now."
		exit 4 
fi

# clapperless hates fractional framerates.
case ${RFR} in
	"29.97")
		LFR=30
		;;
	"59.94")
		LFR=60
		;;
	"47.8")
		LFR=48
		;;
	"119.88")
		LFR=120
		;;
	"239.76")
		LFR=240
	;;

esac

# count frames....
LFC=$(ffprobe -i $1 -show_frames -hide_banner |grep coded_picture_number | tail -1 | cut -d= -f2 )
RFC=$(ffprobe -i $2 -show_frames -hide_banner |grep coded_picture_number | tail -1 | cut -d= -f2 )

# get frame offsets...
FOFF=$(python2 ${CLPR} -c -r ${LFR} $1 $2 | tail -1 |awk ' { print $1 } ')

# Using the second number's decimals would give a relative quality assessment. Closer to .5, the worse the offset.  

#Offset would be A_n = B_1. A has X items, B has Y.
#If (n = 0 && X = Y) then Booya!
#If n < 0 then (swap [A,B], absval(n)).
#If (X - n = Y ) then trim A to [A_n -> X]
#If (X - n > Y ) then trim A to [A_n -> (A_n + Y)]
#If (X - n < Y ) then trim B to [B_1 -> (Y - (Y - A_n))] and trim A to [A_n -> X]

if [ ${FOFF} -ne 0 ] 
	then

		if [ ${FOFF} -lt 0 ]
			then
				FOFF=$(( 0 - ${FOFF}))
				SORT_ORDER=2
				echo "Reversing video sort order."
			else
				SORT_ORDER=1
				echo "Normal sort order."
			fi
	

	else
		if [ ${LFC} -ne ${RFC} ]
			then

				echo "Unequal frame counts."
			else
				echo "Equal frame counts."
			fi	
	
	fi
	
# make this optional...
# Trim video edges...on super wide angles should help the final rendering look better...
# 1920x1080 -> 1706x960
# 1280x720 -> 1138x640
# 2k -> ?
# other -> ???
#ffmpeg -strict -2 -codec h264 -i $1 -filter:v "crop=1706:960:107:60" Left-$$.mp4 
#ffmpeg -strict -2 -codec h264 -i $2 -filter:v "crop=1706:960:107:60" Rigt-$$.mp4 
# on 1080p and wide angle video, offset cropping could make aligning a bit better as well. 
#ffmpeg -strict -2 -codec h264 -i $1 -filter:v "crop=1706:960:110:60" Left-$$.mp4 
#ffmpeg -strict -2 -codec h264 -i $2 -filter:v "crop=1706:960:104:60" Rigt-$$.mp4 

#
#ffmpeg -i Left-$$.mp4 -i Right-$$.mp4 -filter_complex \
#"[0:v]setpts=PTS-STARTPTS, pad=iw*2:ih[bg]; \
##[1:v]setpts=PTS-STARTPTS[fg]; [bg][fg]overlay=w; \
#amerge,pan=stereo:c0<c0+c2:c1<c1+c3" output

