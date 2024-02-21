#!/bin/bash

zenity --text-info \
    --title="Guidelines" \
    --width=400 --height=200 \
    --filename=<(cat guidelines) \
    --width=600 --height=400 \
    --checkbox="I have read and understood the guidelines." \
    --ok-label="Proceed" \
    --cancel-label="Cancel" \
    --modal

if [ $? -eq 0 ]; then
    ./main.sh
else
    echo "Canceled"
fi

