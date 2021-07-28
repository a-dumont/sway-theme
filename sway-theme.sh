#!/bin/bash

while getopts i: flag
do
    case "${flag}" in
        i) IMG=${OPTARG};;
    esac
done

THEME=${@:$OPTIND:1}
DIR=$(eval echo ~$USER/.local/share/themes/$THEME)
DIR2=$(eval echo ~$USER/.local/share/themes)
CACHE=$(eval echo ~$USER/.cache)

if [ $THEME = "Next" ]; then
		CURRENT=$(cat $DIR2/current)
		ALL_THEMES=($(ls -l $DIR2 | grep '^d' | awk '{printf $NF"\n"}'))
		N=${#ALL_THEMES[@]}
		i=0
		for ITER in "${ALL_THEMES[@]}"
		do
				if [ "$ITER"  = "$CURRENT" ]; then
					((j=i+1))
					((j=j%$N))
					${BASH_SOURCE[0]} ${ALL_THEMES[j]}
					exit 0
				fi
		((i=$i+1))
		done
fi

if [ $THEME = "Previous" ]; then
		CURRENT=$(cat $DIR2/current)
		ALL_THEMES=($(ls -l $DIR2 | grep '^d' | awk '{printf $NF"\n"}'))
		N=${#ALL_THEMES[@]}
		i=0
		for ITER in "${ALL_THEMES[@]}"
		do
				if [ "$ITER"  = "$CURRENT" ]; then
					${BASH_SOURCE[0]} ${ALL_THEMES[i-1]}
					exit 0
				fi
		((i=$i+1))
		done
fi

#If new theme create directory and fill it
if [ ! -d "$DIR" ]; then
		rm -r $(eval echo ~$USER/.cache/wal/*)
		#If background image file is specified (jpg)
		if [[ -n $IMG ]]; then
				FMT=$(echo $IMG | sed 's/\./\ /g' | awk '{printf tolower($NF)}')
				if [[ $FMT = "png" ]] ; then
						convert $IMG /tmp/$THEME.jpg
						IMG="/tmp/$THEME.jpg"
				elif [[ $FMT = "jpg" ]] || [[ $FMT = "jpeg" ]]; then
						:
				else
						echo "Image must be png or jpg"
						exit 0
				fi

				read -p "Do you want to create dir $DIR? (y/N): " ANS
				if [[ $ANS = "y" ]] || [[ $ANS = "Y" ]] || [[ $ANS = "yes" ]]; then
					mkdir $DIR
					cp $IMG $DIR/background.jpg
					convert -blur 0x6 -resize 1920x1080! $DIR/background.jpg $DIR/lockscreen.jpg
					wal -q -e -t -s -n -i $DIR/background.jpg
					
					cp $CACHE/wal/colors.json  $DIR/colors-wal.json
					sed -i -e '1,6d' $DIR/colors-wal.json
					
					cp $CACHE/wal/colors $DIR/
					cp $CACHE/wal/colors-kitty.conf $DIR/
					sed -i -e '1,6d' $DIR/colors-kitty.conf

					cp $CACHE/wal/colors-waybar.css $DIR/
					sed -i -e '1,4d' $DIR/colors-waybar.css
					cp $CACHE/wal/colors-sway $DIR/
				else
					echo "Aborted"
					exit 0
				fi
		else
				echo "Missing image, use the -i flag."
				exit 0
		fi
fi

#Change the lockscreen
cp $DIR/lockscreen.jpg $(eval echo ~$USER/.local/share/themes/)

#Move files
cp $DIR/colors-kitty.conf $(eval echo ~$USER/.config/kitty/colors.conf)
cp $DIR/colors-waybar.css $(eval echo ~$USER/.config/waybar/colors.css)
cp $DIR/colors $(eval echo ~$USER/.config/wofi/colors)

#Change background
PID=$(pidof swaybg)
swaymsg exec "swaybg -m fill -i $DIR/background.jpg"
kill $PID

wal -q -t -e  --theme $DIR/colors-wal.json

#Update kitty colors
KITTENS=($(ls /tmp | grep kitty-socket))

for KITTY in "${KITTENS[@]}"
do
	kitty @ --to "unix:/tmp/$KITTY" set-colors $DIR/colors-kitty.conf
done

#Update cava
pkill -USR2 cava

echo $THEME > $DIR/../current

ALL_THEMES=$(ls -l $DIR/.. | grep '^d' | awk '{printf $NF"\n"}')
complete -W $ALL_THEMES Theme

exit 0
