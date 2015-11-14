# sync-o-tater

3D video taken with potato.

A tool to merge two videos into one side-by-side audio-synced 3D monstrosity.

Requires ffmpeg (with h264 support at the moment, can be edited if you want)
https://www.ffmpeg.org/

Clapperless, originally found here*  http://users.mur.at/ms/projects/clapperless/
(scipy and numby needed for this, python2 based)
- clap2.py, part of this repo, works with a bit less output.  

and the excellent exiftool
http://www.sno.phy.queensu.ca/~phil/exiftool/

Probably can be compressed into a much more workable beast at some point with some help. 


Usage:

$ syncotater.sh -l LEFTFILE -r RIGHTFILE -C /path/to/clap2.py -o OUTPUTFILE

Required:
-l leftvid
-r rightvid
-o outputvid
-C clapperlessfile
Optional:
-p qualitypreset
        (ffmpeg preset for h264)
-c Hres:Vres:offsetH:offestV
        ie, 1080p -> 900p would use 1600:900:160:90
-t
        test mode (output command strings only, no reencoding)


Stuff-n-things (not bugs, just...stuff-n-things):

Clapperless can be fooled with two videos that do not match up, so this is your problem to ensure you pass two valide videos in.
The terms "left" and "right" are just there to try and keep things straight in the script.  There'sn no autocorrection for having them reversed.  

The faster the frame rate you shoot, the easier it is to have small offset.

This could probably be extended to handle 360-cam views by a motivated sort. That's just not me right now...maybe someday.
