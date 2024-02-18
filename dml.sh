#!/bin/bash

Check_insert(){
    table_name=$(echo -e "$@" | tr '\n' ' '| cut -d ' ' -f3 )
    echo $table_name ;
    file="databases/$connected/${table_name}"
    column_names_file="databases/$connected/.${table_name}.meta"
    column_names=$(echo $@ | sed -n 's/.*(\(.*\)) values.*/\1/p' | tr -d ' ' | tr ',' '\n')
    values=$(echo $@ | sed -n 's/.*values (\(.*\)) *;/\1/p' | tr -d ' '| tr ',' '\n')
    columns_count=$(echo "$column_names" | wc -l)
    values_count=$(echo "$values" | wc -l)
    count1=1
    count2=1
    while IFS=':' read -r column_name column_type _; do
    	if [[ "$column_name" != "$(echo "$column_names" | sed -n ${count1}p)" ]]; then
    	    echo "Error: Column $column_name should come before $(echo "$column_names" | sed -n ${count1}p)"
    	    count2=0
    	    break
    	fi
    	((count1++))
    done < "$column_names_file"

    if [ $columns_count -ne $values_count && $columns_count -gt 0 ]; then
    	echo "Error: Number of columns donot match number of values."
    	zenity --notification --window-icon="ERROR" --text="Number of columns does not match number of values!"
    	return 1
    elif [ $count2 -eq 0 && $columns_count -gt 0 ]; then
    	echo "Error: Columns do not match the meta data!"
    	zenity --notification --window-icon="ERROR" --text="Columns do not match the meta data!"
    	return 1
    else 
    	formatted_values=$(echo "$values" | tr '\n' ':')
	formatted_values=${formatted_values::-1}
	echo $formatted_values
	echo "$formatted_values" >> $file
	return 0
    fi   
}



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
		pattern="^insert[[:space:]]+into[[:space:]]+[[:alpha:]_]+[[:space:]]*(\([[:space:]]*[[:alpha:]_]+[[:space:]]*(,[[:space:]]*[[:alpha:]_]+[[:space:]]*)*\))?[[:space:]]*values[[:space:]]*\([[:space:]]*('[^']*'|[^[:space:]]+)[[:space:]]*(,[[:space:]]*[^[:space:]]+[[:space:]]*)*\);?"

		table_name=$(echo -e "$@" | tr '\n' ' '| cut -d ' ' -f3 )
		if [[ ! $@ =~ $pattern ]]; then	
	         	echo "Doesn't Match"
	         	zenity --notification --window-icon="ERROR" --text="Wrong Statement! Syntax ERROR"
	         	echo "Failed To Insert Into Table!" | zenity --text-info --title="ERROR" \
	      	    		--height 400 --width 600 --font="Arial 20"
	      	elif [ ! -f $"databases/$connected/$table_name" ]; then
		 	echo "Table Does not Exists"
	         	zenity --notification --window-icon="ERROR" --text="Table Does Not Exists" 
	        else 
	        	Check_insert $@ ;
	         	if [ $? -eq 0 ]; then
		     		echo "Inserted Successfully"
		     		echo "Inserted Successfully!" | zenity --text-info --title="Successful" \
	      			--height 400 --width 600 --font="Arial 20"
		 	else 
		     		echo "Failed To Insert"
		     		echo "Failed To Insert" | zenity --text-info --title="ERROR" \
	      			--height 400 --width 600 --font="Arial 20"		
		 	fi  
	        fi
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
    	
    	
    	
    	
    	
    	
    	
    	
    	
    	
    	
