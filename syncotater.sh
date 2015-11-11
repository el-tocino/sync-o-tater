#!/bin/bash
# $1 = left video
# $2 = right video
# $3 = outputfile
# $4 = sync utility (clapperless/clap2)

echo "Made with Potato!"
CLPR=~/clapperless.py

# boring test stuff

if [ $# -lt 3 ]  || [ $# -gt 4 ]
	then
		echo "Usage: $0 leftvideofile rightvideofile outputfile [optional: clapperless path]"
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

if [ -r $3 ]
	then
		echo "$3 exists, cowardly refusing to try overwriting."
		exit 3
fi

if [ $# -eq 4 ]
	then
		CLPR=$4
fi

if [ ! -r $CLPR ]
	then
		echo "Can't find clapperless!"
		exit 4
fi

# find framerate of the videos

LFR=$(exiftool -VideoFrameRate $1 | awk ' { print $NF} ' )
RFR=$(exiftool -VideoFrameRate $2 | awk ' { print $NF} ' )

if [ $LFR != $RFR ]
	then
		echo "Differing frame rates. This tool needs matched frame rates for now."
		exit 5 
fi

# clapperless hates fractional framerates. Set framerate as whole number, but keep frame interval time at actual frame rate interval.

case ${RFR} in
	"24")
		FR_IVAL="0.04166666666"
		;;
	"25")
		FR_IVAL="0.04"
		;;
	"29.97")
		LFR=30
		FR_IVAL="0.03336670003"
		;;
	"30")
		FR_IVAL="0.03333333333"
		;;
	"59.94")
		LFR=60
		FR_IVAL="0.01668335001"
		;;
	"60")
		FR_IVAL="0.01666666666"
		;;
	"47.8")
		LFR=48
		FR_IVAL="0.02092050209"
		;;
	"48")
		FR_IVAL="0.02083333333"
		;;
	"119.88")
		LFR=120
		FR_IVAL="0.008341675"
		;;
	"120")
		FR_IVAL="0.00833333333"
		;;
	"239.76")
		LFR=240
		FR_IVAL="0.0041708375"
		;;
	"240")
		FR_IVAL=".00416666666"
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

if [ ${FOFF} -eq 0 ]  && [ ${LFC} -eq ${RFC} ]
	then
		LTRIMARGS=''
		RTRIMARGS=''
		echo "matching syncs and lengths!"
	else
		FRONT_TRIM_TIME=$(echo "${FOFF} * ${FR_IVAL}" | bc)
		echo "Unmatched things, fixing those up..."
	
		if [ ${FOFF} -lt 0 ]
			then
				FOFF=$(( 0 - ${FOFF}))
				SORT_ORDER=2
				echo "Reversing video sort order"
			else
				echo "Normal sort order."
				LFCT=$((${LFC} - ${FOFF}))
				if [ ${LFCT} -eq ${RFC} ]
					then
						LTRIMARGS="-ss ${FRONT_TRIM_TIME}"	
						RTRIMARGS=''
					else
						LFCE=$((${LFCT} - ${RFC}))
							if [ ${LFCE} -gt 0 ]
								then
									END_TIME=$(echo "${FR_IVAL} * ${RFC}" | bc)
									LTRIMARGS="-ss ${FRONT_TRIM_TIME} -t ${END_TIME}"		
									RTRIMARGS=''
								else
									END_TIME=$( echo "${FR_IVAL} * ${LFCT}" | bc)
									LTRIMARGS="-ss ${FRONT_TRIM_TIME}"
									RTIRMARGS="-ss 0 -t ${END_TIME}"
							fi	
				fi

		fi

fi

echo "LFR RFR LFC RFC FOFF"
echo "$LFR $RFR $LFC $RFC $FOFF "

echo "Trimmed left, front trim, end time, left args, right args"
echo "${LFCT}, ${FRONT_TRIM_TIME}, ${END_TIME}, ${LTRIMARGS}, ${RTRIMARGS}, ${LCROPARGS}, ${RCROPARGS}"
echo "ffmpeg -strict 2 -codec h264 -i $1  ${LTRIMARGS} ${LCROPARGS} $3-left"	
echo "ffmpeg -strict 2 -codec h264 -i $2  ${RTRIMARGS} ${RCROPARGS} $3-right"	

# make this optional...
# Trim video edges...on super wide angles should help the final rendering look better...
# 1920x1080 -> 1706x960 or 1600x900
# 1280x720 -> 1138x640
# 2k -> ?
# other -> ???
# Crop args:
# LCROPARGS=' -filter:v "crop=1706:960:107:60"'
# RCROPARGS=${LCROPARGS}
# Shifted crop args:
# LCROPARGS=' -filter:v "crop=1706:960:110:60"'
# RCROPARGS=' -filter:v "crop=1706:960:104:60"' 
#ffmpeg -strict -2 -codec h264 -i $1 ${LTRIMARGS} ${LCROPARGS} Left-$$.mp4 
#ffmpeg -strict -2 -codec h264 -i $2 ${RTRIMARGS} ${RCROPARGS} Right-$$.mp4 
# on 1080p and wide angle video, offset cropping could make aligning a bit better as well. 
#ffmpeg -strict -2 -codec h264 -i $1 ${LTRIMARGS} ${LCROPARGS} Left-$$.mp4 
#ffmpeg -strict -2 -codec h264 -i $2 ${RTRIMARGS} ${RCROPARGS} Right-$$.mp4 

#
#ffmpeg -i Left-$$.mp4 -i Right-$$.mp4 -filter_complex \
#"[0:v]setpts=PTS-STARTPTS, pad=iw*2:ih[bg]; \
##[1:v]setpts=PTS-STARTPTS[fg]; [bg][fg]overlay=w; \
#amerge,pan=stereo:c0<c0+c2:c1<c1+c3" output

