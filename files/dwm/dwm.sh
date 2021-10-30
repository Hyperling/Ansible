#!/bin/bash
# 2021-10-30 Hyperling
# Basically .xinitrc, but not placed there to avoid GDM problems.

## System Libs ##

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi


## Variables ##

# This doesn't work for some reason. LBRY needs it but added to its executable instead.
eval `dbus-launch` 


## Status Bars ##

# slstatus, from Suckless #

#exec slstatus &

# Custom #

while true; do
  xsetroot -name "`date +"%Y-%m-%d %H:%m:%S"`"
done &


## Start DWM ##

exec dwm
