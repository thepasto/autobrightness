#!/bin/bash

CAMERA=/dev/video0
SCREEN=/sys/class/backlight/intel_backlight/brightness
CAPTURE=/tmp/autobrightness.jpg
INTERVAL=300
DEFAULT=900
BFACTOR=12

function getBright(){
	while true 
	do
		getMaxBright
		getCurrentBright
		rm -f $CAPTURE
		if [ ! -e $CAMERA ]; then
			sleep 1
			break
		fi
		ffmpeg -nostats -loglevel 0 -f v4l2 -i $CAMERA -vframes 1 $CAPTURE > /dev/null
		sleep 1
		b=$(convert $CAPTURE -colorspace Gray -format "%[mean]" info: | awk -F'.' '{print $1}')
		echo "TORNO0 $b"
		b=$((b/(BFACTOR *100)))
		echo "TORNO $b"
		bres=$(((MAX*b)/100))
		echo "TORNO2 $bres"
		setBright
		sleep $INTERVAL
	done
	getBright
}

function getMaxBright (){
	AC=$(cat /sys/class/power_supply/AC0/online)
	MAX=$(cat /sys/class/backlight/intel_backlight/max_brightness)
	if [ $AC == 0 ];then
		BFACTOR=$((BFACTOR*2))
	fi
}

function runningInst (){
	ABPID=$(ps ax | grep "autobrightness.sh start" | grep -v "grep" | awk '{print $1}')
}

function getCurrentBright (){
	CBR=$(cat $SCREEN);
}

function setBright (){
	maxcn=$(( bres > CBR ? bres : CBR ))
	mincn=$(( bres < CBR ? bres : CBR ))
	
	if [[ $maxcn -eq $bres ]]; then
		count=$mincn
		count2=0
		until [ $count -gt $maxcn ]; do
			if [ $count2 -eq 5 ];then
				echo $count > $SCREEN
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
			if [ $count2 -eq 5 ]; then
				echo $count > $SCREEN
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
		runningInst
		kill -s 9 $ABPID & > /dev/null
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

