#!/bin/bash
filename=${1-recording.ogv}

width=1280
height=720
y=100
x=100

(terminator --geometry=${width}x${height}+${x}+${y} --borderless ; killall recordmydesktop )&
sleep 1
[[ -e /usr/bin/guake ]] && /usr/bin/guake --hide
mplayer /usr/share/sounds/freedesktop/stereo/bell.oga
recordmydesktop --width=${width} --height=${height} -x ${x} -y ${y} --on-the-fly-encoding -o "$filename"

