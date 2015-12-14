# sync-o-tater

3D video from potato.

A tool to merge two side-by-side videos into one audio-synced 3D monstrosity.  
(a handy quick reference to taking 3d video is http://www.dashwood3d.com/blog/beginners-guide-to-shooting-stereoscopic-3d/ )

Requires ffmpeg (2.8+, with h264 and hstack)
https://www.ffmpeg.org/

python (2.7, currently)
Clapperless, originally found here*  http://users.mur.at/ms/projects/clapperless/
(scipy and numby needed for this, python2 based)
- clap2.py, part of this repo, works with a bit less output.  

OpenCV (for python 2, for the frame counter)
http://opencv.org/

Probably can be compressed into a much more workable beast at some point with some help. 


Usage:

$ syncotater.sh -l LEFTFILE -r RIGHTFILE -C /path/to/clap2.py -o OUTPUTFILE [-tcph]

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

Brotip: recompile a version of ffmpeg for your host with "-O3 -march=native" (as well as on libx264,yasm, etc...).  Makes a 0-10% difference in quick testing.  Also if you compile a version to just have the input and output formats you want, helps a tiny bit.
