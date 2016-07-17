#!/bin/bash

CAMERA=/dev/video0
BACKLIGHT_PATH=/sys/class/backlight/intel_backlight
KEYBOARD_PATH=/sys/class/leds/asus::kbd_backlight
CAPTURE=/tmp/autobrightness.jpg
INTERVAL=120
BFACTOR=10

function getBright(){
	while true 
	do
		if [[ $standby -eq 0 && $keybright -gt 0 ]]; then
			setKeyboardBright
		fi
		if [ $standby -gt 0 ]; then # se monitor in standby non esegue script
			getBrightValues
			rm -f $CAPTURE
			if [ ! -e $CAMERA ]; then
				continue
			fi
			ffmpeg -nostats -loglevel 0 -f v4l2 -i $CAMERA -vframes 1 -y $CAPTURE > /dev/null
			b=$(convert $CAPTURE -colorspace Gray -format "%[mean]" info: | awk -F'.' '{print $1}')
			rm -f $CAPTURE
			b=$((b/(BFACTOR *80)))
			bres=$(((MAX*b)/100))
			setBright
			setKeyboardBright
		fi
		sleep $INTERVAL
	done
}

function getStaticValues() {
	MAX=$(cat "$BACKLIGHT_PATH/max_brightness")
	KMAX=$(cat "$KEYBOARD_PATH/max_brightness")
}

function getBrightValues (){
	AC=$(cat /sys/class/power_supply/AC0/online)
	
	CBR=$(cat "$BACKLIGHT_PATH/brightness")
	if [ $AC == 0 ];then # batteria
		m=$( echo $BFACTOR/10 | bc )
		BFACTOR=$( echo $BFACTOR*$m | bc )
		BFACTOR=${BFACTOR%.*}
		INTERVAL=300 # 5 minuti se batteria
	else
		INTERVAL=120 # 2 minuti se collegato AC
	fi
	
	standby=$(cat $BACKLIGHT_PATH/actual_brightness)
	keybright=$(cat "$KEYBOARD_PATH/brightness");
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
				if [[ $count -lt 320 ]];then
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


function setKeyboardBright(){
	if [ $standby -eq 0 ]; then
		kres=0;
	else
		if [ $AC -eq 0 ]; then
			KMAX=1;
		fi
	
		kres=$(($KMAX-(($bres*$KMAX)/($MAX/$KMAX))))
	
		if [[ $standby -gt 0 && $kres -eq 0 && $AC -eq 1 ]]; then
			kres=1;
		fi
	fi

	echo $kres > "$KEYBOARD_PATH/brightness"
}


case "$1" in
	start)
		echo -en "Starting $0 \t"
		getStaticValues
		getBrightValues
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
