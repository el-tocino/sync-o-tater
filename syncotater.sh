#!/bin/bash
# $1 = left video
# $2 = right video

#adjust to point at your copy
CLPR=~/clapperless.py

# boring test stuff

if [ $# -ne 2 ]
	then
		echo "Usage: $0 leftvideofile rightvideofile"
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

if [ -x $CLPR ]
	then
		echo "Can't exec clapperless!"
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


LOF=$(python2 ${CLPR} -c -r ${LFR} $1 $2 | tail -1 | awk ' { print $1 } ' |cut -d: -f4)
ROF=$(python2 ${CLPR} -c -r ${LFR} $2 $1 | tail -1 | awk ' { print $1 } ' |cut -d: -f4)

# Trim video edges...on super wide angles should help the final rendering look better...
#ffmpeg -strict -2 -codec h264 -i $1 -filter:v "crop=1706:960:107:60" Left-$$.mp4 
#ffmpeg -strict -2 -codec h264 -i $2 -filter:v "crop=1706:960:107:60" Rigt-$$.mp4 

#
#ffmpeg -i Left-$$.mp4 -i Right-$$.mp4 -filter_complex \
#"[0:v]setpts=PTS-STARTPTS, pad=iw*2:ih[bg]; \
##[1:v]setpts=PTS-STARTPTS[fg]; [bg][fg]overlay=w; \
#amerge,pan=stereo:c0<c0+c2:c1<c1+c3" output

