#!/bin/bash

DIR=$(eval echo ~$USER/.local/share/themes)
ALL_THEMES=$(echo $(ls -l $DIR | grep '^d' | awk '{printf $NF"\n"}'))" Next Previous"
complete -W "$ALL_THEMES" sway-theme
