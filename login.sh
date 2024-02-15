#!/bin/bash

user_info=$(zenity --password --username --title="Login" )

username=$(echo "$user_info" | cut -d '|' -f 1)
password=$(echo "$user_info" | cut -d '|' -f 2)

if [ "$username" = 'Diaa' ] && [ "$password" = '123' ]
then
    ./main.sh
else
    zenity --error --text="Invalid Username or Password" ;
fi

