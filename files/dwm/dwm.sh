#!/bin/bash
# 2021-10-30 Hyperling
# Basically .xinitrc, but not placed there to avoid GDM/GNOME problems.

## Load System Libs ##

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

if [ -d /usr/local/etc/X11/xinit/xinitrc.d ]; then
  for f in /usr/local/etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi


## Variables ##

purple="#400080"


## Background ##

xsetroot -solid "$purple"


## Status Bars ##

# slstatus, from Suckless #
#exec slstatus &

# Custom #
while true; do
  xsetroot -name "`whoami`@`hostname` `date +"%Y-%m-%d %H:%M:%S"`"
done &


## Start ##

exec dwm
