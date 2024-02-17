#!/bin/bash

check_select(){
	command=$(echo $@ | awk '{print $1}')
	columns=$(echo $@ | awk -F ' from ' '{print $1}'| cut -d ' ' -f 2-)

	table=$(echo $@ | awk -F ' from ' '{print $2}' | awk '{print $1}')
	conditions=$(echo $@ | awk -F ' where ' '{print $2}')

	# Printing the extracted parts
	# columns=$(echo "$columns" | awk '{$1=$1};1')	
	
	if [ $columns = 'all' ]
	then
	    echo "Columns: All"
	else
	    echo "Columns: $columns"
	fi
	
	echo "Table: $table"
	echo "Conditions: $conditions"
}

if [ -z $connected ]
    then
       echo -e "PLease Connect to database first \n ex : 'use' my_database , $1" |
       zenity --text-info --title="ERROR" --height 400 --width 600 --font="Arial 20"
       return 0
    else
    	case $@ in
    	"insert into "*)
    		;;
    	"select "*)
    		;;
    	"update "*)
    		;;
    	"delete from "*)
    		;;
    	*)
    		;;
    	esac
fi 
    	
    	
    	
    	
    	
    	
    	
    	
    	
    	
    	
