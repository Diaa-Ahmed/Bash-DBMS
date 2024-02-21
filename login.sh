#!/bin/bash
while true 
do
user_info=$(zenity --forms --title="Login" \
    --text="\n\n\n\nEnter your credentials\n\n\n\n" \
    --add-entry="                	Username    	             " \
    --add-password="             	        Password     		     " \
    --width=600 --height=450)


username=$(echo "$user_info" | cut -d '|' -f 1)
password=$(echo "$user_info" | cut -d '|' -f 2)

if [ "$username" = 'Diaa' ] && [ "$password" = '123' ]; then
    ./guidelines.sh
elif [ "$username" = 'Mo' ] && [ "$password" = '1' ]; then
    ./guidelines.sh
elif [ "$username" = '' ] || [ "$password" = '' ]; then 
	zenity --notification --window-icon="Information" --text="Program Closed!"
	break;
else
    zenity --error --text="Invalid Username or Password"
    
fi
done

