#!/bin/sh
# A simple wrapper script to test the touchscreen using tslib.

export TSLIB_TSDEVICE=/dev/input/event0
export TSLIB_CALIBFILE=/etc/pointercal
export TSLIB_FBDEVICE=/dev/fb0
export TSLIB_CONFFILE=/etc/ts.conf
export TSLIB_PLUGINDIR=/usr/lib/ts

echo "...........Running touchscreen test tool..........."
echo "Please touch and draw on the LCD screen"

ts_test

echo "...........Exiting..........."
