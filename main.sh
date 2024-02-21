#!/bin/bash

connected='';
while true
do
    result=$(zenity --text-info \
                --title="Database Management System" \
                --height 400 --width 600 \
                --text="Write your query:" \
                --editable)

    # Check if result is empty (user clicked "x" or canceled)
    if [ -z "$result" ]; then
        break
    fi
    
# Replace '*' with 'all'
result=${result//\*/all} 

case "${result,,}" in
    
"create database "*)
                    # Extract database name from the user input
                    db_name=$(echo $result | awk '{print $3}')
                    # Create directory with the database name
                    if [ -z "$db_name" ]; then
                    	echo "Database Name Can Not Be Empty!" | 
                    	zenity --text-info --title="ERROR" \
                    	--height 400 --width 600 --font="Arial 20"
                    else 
                    	mkdir -p "databases/$db_name"
                    	# Display dialog with result
                    	echo "Database '$db_name' is created!" | 
                    	zenity --text-info --title="Successful" \
                    	--height 400 --width 600 --font="Arial 20"
                    fi
                    ;;
"show databases"*)
                    # list all directories in databases dir
                    db=$(ls databases)
                    # Display dialog with databases
                    echo "$db" | zenity --text-info --title="Databases" \
                    --height 400 --width 600 --font="Arial 20"
                    ;;
"drop database "*)
                    # Extract database name from the user input
                    db_name=$(echo $result | awk '{print $3}')
                    # Drop directory with the database name
                    if [ -z "$db_name" ]; then
                    	echo "Database Name Can Not Be Empty!" | 
                    	zenity --text-info --title="ERROR" \
                    	--height 400 --width 600 --font="Arial 20"
                    elif [ -d databases/$db_name ];then
                    	rm -df "databases/$db_name"
                    	# Display dialog with result
                    	echo "Database '$db_name' is dropped!" | 
                    	zenity --text-info --title="Successful" \
                    	--height 400 --width 600 --font="Arial 20"
                    else 
                    	echo "Database '$db_name' Not Found!" | 
                    	zenity --text-info --title="ERROR" \
                    	--height 400 --width 600 --font="Arial 20"
                    fi
                    ;;
"use "*)
                    # Extract database name from the user input
                    db_name=$(echo $result | awk '{print $2}')
                    if [ -z "$db_name" ]; then
                    	echo "Database Name Can Not Be Empty!" | 
                    	zenity --text-info --title="ERROR" \
                    	--height 400 --width 600 --font="Arial 20"
                    elif [ -d databases/$db_name ]
                    then
                        echo -e "Connected to $db_name Successfully" |
       		        zenity --text-info --title="Successful" \
       		        --height 400 --width 600 --font="Arial 20"
                        connected=$db_name;
                    else
                        echo "Wrong Database Name" |
       		        zenity --text-info --title="ERROR" \
       		        --height 400 --width 600 --font="Arial 20"
                       echo $connected;
                    fi
                    ;;
*)
		    if [[ "${result,,}" == "create table "* || "${result,,}" == "drop table "* || "${result,,}" == "show tables"* ]]; then
		    	source ./ddl.sh $result ;
		    	if [ ! $? -eq 0 ];then
		       		# Display dialog with result
		       		echo "Wrong Statement, $result" |zenity --text-info --title="ERROR" \
		       		--height 400 --width 600 --font="Arial 20"
                    	fi
		    elif [[ "${result,,}" == "insert into "* || "${result,,}" == "select "* || "${result,,}" == "update "* || "${result,,}" == "delete from "* ]]; then
		    	source ./dml.sh $result ;
		    	if [ ! $? -eq 0 ];then
		       		# Display dialog with result
		       		echo "Wrong Statement, $result" |zenity --text-info --title="ERROR" \
		       		--height 400 --width 600 --font="Arial 20"
                    	fi
		    else
		       # Display dialog with result
		       echo "Wrong Statement, $result" |zenity --text-info --title="ERROR" \
		       --height 400 --width 600 --font="Arial 20"
                    fi
                    ;;
    esac
done
