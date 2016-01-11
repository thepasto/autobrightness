#!/bin/bash

CAMERA=/dev/video0
BACKLIGHT_PATH=/sys/class/backlight/intel_backlight
CAPTURE=/tmp/autobrightness.jpg
INTERVAL=300
BFACTOR=13

function getBright(){
	while true 
	do
		getBrightValues
		rm -f $CAPTURE
		if [ ! -e $CAMERA ]; then
			continue
		fi
		ffmpeg -nostats -loglevel 0 -f v4l2 -i $CAMERA -vframes 1 -y $CAPTURE > /dev/null
		b=$(convert $CAPTURE -colorspace Gray -format "%[mean]" info: | awk -F'.' '{print $1}')
		b=$((b/(BFACTOR *100)))
		bres=$(((MAX*b)/100))
		setBright
		sleep $INTERVAL
	done
}

function getBrightValues (){
	AC=$(cat /sys/class/power_supply/AC0/online)
	MAX=$(cat "$BACKLIGHT_PATH/max_brightness")
	CBR=$(cat "$BACKLIGHT_PATH/brightness");
	if [ $AC == 0 ];then
		m=$( echo $BFACTOR/10 | bc )
		BFACTOR=$( echo $BFACTOR*$m | bc )
		BFACTOR=${BFACTOR%.*}
	fi
}

function setBright (){
	maxcn=$(( bres > CBR ? bres : CBR ))
	mincn=$(( bres < CBR ? bres : CBR ))
	
	if [[ $maxcn -eq $bres ]]; then
		count=$mincn
		count2=0
		until [ $count -gt $maxcn ]; do
			if [[ $count -lt 50 ]];then
				break
			fi
			if [ $count2 -eq 5 ];then
				echo $count > "$BACKLIGHT_PATH/brightness"
				count2=0
				sleep 0.005
			fi
			let count+=1
			let count2+=1
		done
	fi
	
	if [[ $mincn -eq $bres ]]; then
		count=$maxcn
		count2=0
		until [ $count -lt $mincn ]; do
			if [[ $count -lt 50 ]];then
				break
			fi
			if [ $count2 -eq 5 ]; then
				echo $count > "$BACKLIGHT_PATH/brightness"
				count2=0
				sleep 0.005
			fi
			let count-=1
			let count2+=1
		done
	fi
}

case "$1" in
	start)
		echo -en "Starting $0 \t"
		getBright &
		if [ $? == 0 ];then
			echo "[OK]"
		else
			echo "[FAIL]"
		fi
		echo ""
		exit 0
	;;

	stop) 
		echo -en "Stopping $0 \t"
		kill -15 $$ & > /dev/null
		if [ $? == 0 ];then
			echo "[OK]"
		else
			echo "[FAIL]"
		fi
		exit 0
	;;
	
	restart)
		sh $0 stop
		sh $0 start
	;;
	
	*)
		echo "Usage: $0 {start|stop|restart}" >&2
		exit 1
	;;

esac

exit 0

getBright

