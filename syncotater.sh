#!/bin/bash

# func dat
PrintUsage () {
cat << EOF
Usage:
syncotater.sh -htlrcopCV

Required:
-l leftvid
-r rightvid
-o outputvid
-C clapperlessfile
-f frame rate counter
Optional:
-p qualitypreset
        (ffmpeg preset for h264)
-c Hres:Vres:offsetH:offestV
        ie, 1080p -> 900p would use 1600:900:160:90
-t
        test mode (output command strings only, no reencoding)
EOF
}

if [ $# -lt 4 ]
        then
                PrintUsage
                exit 0
fi

# do the stuff and things!

while getopts "htl:r:o:c:p:C:f:" OPTION; do
    case ${OPTION} in
        t) PREFIX="echo ";;
        l) LEFTVID="$OPTARG" ;;
	r) RIGHTVID="$OPTARG" ;;
	o) OUTFILE="$OPTARG" ;;
	c) CROPOPTS='  -filter:v "crop='$OPTARG'"' ;;
	p) PRESETOPT="$OPTARG" ;;
	C) CLPR="$OPTARG" ;;
	f) FRAMER="$OPTARG";;
    esac
done
shift $(($OPTIND - 1))

if [ ! -r ${LEFTVID} ]
	then	
		echo "Can't read left video?"
		exit 2 fi

if [ ! -r ${RIGHTVID} ]
	then
		echo "Can't read right video?"
		exit 2
fi

if [ -e ${OUTFILE}-3d.mp4 ]
	then
		echo "${OUTFILE}-3d.mp4 exists, cowardly refusing to try overwriting."
		exit 3
	else 
		touch ${OUTFILE}
		CRTD=$?	
		if [ ! ${CRTD} ]
			then
				echo "Unable to write to file ${OUTFILE}."
				exit 3
			else
				rm -f ${OUTFILE}
		fi	
fi

if [ ! -r ${CLPR} ]
	then
		echo "Can't find clapperless!"
		exit 4
fi

if [ ! -x ${FRAMER} ]
	then
		echo "Can't run frame rate tool!"
		exit 5
fi

PRESETOPT="${PRESETOPT:-ultrafast}"
# veryslow slow fast ultrafast, etc
ENCODEROPT=" -strict -2 -acodec aac -vcodec  libx264 -preset ${PRESETOPT} "

# old ways to get frames/rates 
# 
#LFC=$(ffprobe -i ${LEFTVID} -show_frames -hide_banner |grep coded_picture_number | tail -1 | cut -d= -f2 )
#RFC=$(ffprobe -i ${RIGHTVID} -show_frames -hide_banner |grep coded_picture_number | tail -1 | cut -d= -f2 )
#LFR=$(exiftool -VideoFrameRate ${LEFTVID} | awk ' { print $NF} ' )
#RFR=$(exiftool -VideoFrameRate ${RIGHTVID} | awk ' { print $NF} ' )

while read count rate
do
	LFC=$count
	LFR=$rate
done < <(${FRAMER} ${LEFTVID})

while read count rate
do
	RFC=$count
	RFR=$rate
done < <(${FRAMER} ${RIGHTVID})

if [ $LFR != $RFR ]
	then
		echo "Differing frame rates. This tool needs matched frame rates for now."
		exit 5 
fi

# clapperless hates fractional framerates. Set one framerate as whole number, 
# but keep frame interval time at actual frame rate interval.

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


# get frame offsets...
FOFF=$(python2 ${CLPR} -c -r ${LFR} ${LEFTVID} ${RIGHTVID} | tail -1 |awk ' { print $1 } ')

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
		# matching syncs and lengths
	else

		#Unmatched things, fixing those up...
	
		if [ ${FOFF} -lt 0 ]
			then
				FOFF=$(( 0 - ${FOFF}))
				# trim right to start at left.
				FRONT_TRIM=$(echo "${FOFF} * ${FR_IVAL}" | bc)
                		FRONT_TRIM_TIME=$(date -d "1970-1-1 0:00 + 0${FRONT_TRIM} seconds" "+%H:%M:%S.%N")

                                RFCT=$((${RFC} - ${FOFF}))

				LFCT=${RFCT}
                                if [ ${RFCT} -eq ${LFC} ]
                                        then
                                                #trimmed right equals left
                                                RTRIMARGS="-ss ${FRONT_TRIM_TIME}"
                                                LTRIMARGS=''
                                        else
                                                RFCE=$((${RFCT} - ${LFC}))
                                                        if [ ${RFCE} -gt 0 ]
                                                                then
                                                                        #Right ending exceeds, trimming
                                                                        END_TRIM=$(echo "${FR_IVAL} * ${LFC}" | bc)
                                                                        RTRIMARGS="-ss ${FRONT_TRIM_TIME} -t ${END_TIME}"
                                                                        LTRIMARGS=''
                                                                else
                                                                        #Left ending exceeds, trimming.
                                                                        END_TIME=$( echo "${FR_IVAL} * ${RFCT}" | bc)
                                                                        RTRIMARGS="-ss ${FRONT_TRIM_TIME}"
                                                                        LTRIMARGS="-ss 0 -t ${END_TIME}"
                                                        fi
                                fi

			else
				LFCT=$((${LFC} - ${FOFF}))
				FRONT_TRIM=$(echo "${FOFF} * ${FR_IVAL}" | bc)
				FRONT_TRIM_TIME=$(date -d "1970-1-1 0:00 + 0${FRONT_TRIM} seconds" "+%H:%M:%S.%N")

				if [ ${LFCT} -eq ${RFC} ]
					then
						#trimmed left equals right. 
						LTRIMARGS="-ss ${FRONT_TRIM_TIME}"	
						RTRIMARGS=''
					else
						LFCE=$((${LFCT} - ${RFC}))
							if [ ${LFCE} -gt 0 ]
								then
									#Left ending exceeds, trimming.
									END_TRIM=$(echo "${FR_IVAL} * ${RFC}" | bc)
									LTRIMARGS="-ss ${FRONT_TRIM_TIME} -t ${END_TIME}"		
									RTRIMARGS=''
								else
									#Right ending exceeds, trimming.
									END_TIME=$( echo "${FR_IVAL} * ${LFCT}" | bc)
									LTRIMARGS="-ss ${FRONT_TRIM_TIME}"
									RTRIMARGS="-ss 0 -t ${END_TIME}"
							fi	
				fi

		fi

fi

echo "LFR RFR LFC RFC FOFF" >> $$.out
echo "$LFR $RFR $LFC $RFC $FOFF " >> $$.out


# Crop args:
LCROPARGS="${CROPOPTS}"
RCROPARGS="${CROPOPTS}"
# Shifted crop args:
# LCROPARGS=' -filter:v "crop=1600:900:164:90"'
# RCROPARGS=' -filter:v "crop=1600:900:156:90"'

echo "Trimmed left, front trim, front trime time, end trim, end trim time" >> $$.out
echo "${LFCT}, ${FRONT_TRIM}, ${FRONT_TRIM_TIME}, ${END_TIME}, ${END_TRIM_TIME}" >> $$.out
echo " left args, right args, left crop args, right crop args, encoding options" >> $$.out
echo "${LTRIMARGS}, ${RTRIMARGS}, ${LCROPARGS}, ${RCROPARGS}, ${ENCODEROPT}" >> $$.out


echo "ffmpeg -i ${LEFTVID}  ${LTRIMARGS} ${ENCODEROPT} ${LAUDOPTS} ${LCROPARGS} ${OUTFILE}-left.mp4" >> $$.out
${PREFIX} ffmpeg -i ${LEFTVID} ${LTRIMARGS} ${ENCODEROPT} ${LAUDOPTS} ${LCROPARGS} ${OUTFILE}-left.mp4
echo "ffmpeg -i ${RIGHTVID}  ${RTRIMARGS} ${ENCODEROPT} ${RAUDOPTS} ${RCROPARGS} ${OUTFILE}-right.mp4" >> $$.out
${PREFIX} ffmpeg -i ${RIGHTVID}  ${RTRIMARGS} ${ENCODEROPT} ${RAUDOPTS} ${RCROPARGS} ${OUTFILE}-right.mp4	

echo ${PREFIX} ffmpeg -i ${OUTFILE}-left.mp4 -i ${OUTFILE}-right.mp4 -filter_complex "[0:v][1:v]hstack=inputs=2[v]; [0:a][1:a]amerge[a]" -map "[v]" -map "[a]" -ac 2 ${ENCODEROPT} ${OUTFILE}-3d.mp4 >> $$.out
${PREFIX} ffmpeg -i ${OUTFILE}-left.mp4 -i ${OUTFILE}-right.mp4 -filter_complex "[0:v][1:v]hstack=inputs=2[v]; [0:a][1:a]amerge[a]" -map "[v]" -map "[a]" -ac 2 ${ENCODEROPT} ${OUTFILE}-3d.mp4
echo "## ${OUTFILE}-3d.mp4 made with Potato! ##"

exit 0

