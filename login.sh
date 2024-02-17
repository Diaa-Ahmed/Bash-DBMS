#!/bin/bash

user_info=$(zenity --forms --title="Login" \
    --text="\n\n\n\nEnter your credentials\n\n\n\n" \
    --add-entry="                	Username    	             " \
    --add-password="             	        Password     		     " \
    --width=800 --height=600)

username=$(echo "$user_info" | cut -d '|' -f 1)
password=$(echo "$user_info" | cut -d '|' -f 2)

if [ "$username" = 'Diaa' ] && [ "$password" = '123' ]; then
    ./main.sh
else
    zenity --error --text="Invalid Username or Password"
fi

