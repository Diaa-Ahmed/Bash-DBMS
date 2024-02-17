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

Check_create(){
    meta_file="databases/$connected/.${table_name}.meta"
    touch "$meta_file"
    count=0
    data_type_pattern="int|varchar[[:space:]]*\([0-9]{1,3}\)[[:space:]]*"
    IFS=',' read -ra columns_array <<< "$@"
    for column in "${columns_array[@]}"; do

        name=$(echo "$column" | awk '{print $1}')
        data_type=$(echo "$column" | awk '{print $2}')
        constraint=$(echo "$column" | awk '{print $3 " " $4}')

        echo $data_type;
        if [[ ! -z $constraint ]] && [[ $constraint = "primary key" ]]; then
           (( count++ ))
        else
            constraint="";
        fi
        if [[ $data_type =~ $data_type_pattern ]]; then
            data_type=$(echo "$data_type" | grep -oE "$data_type_pattern")
            echo "$name:$data_type:$constraint" >> "$meta_file"
        else
            echo dddddddd;
            rm -f "$meta_file"
            return 1
        fi

    done

        if [ ! $count -eq 1 ]; then
            echo "promary key error"
            rm -f "$meta_file"
            return 1
        else
            return 0
        fi
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
        "delete from "*)
            ;;
        "create table "*)
              pattern="^create table [[:alpha:]]+[[:space:]]*\([[:space:]]*([[:alpha:]]*[[:space:]]+int[[:space:]]*( primary key)?,[[:space:]]*|[[:alpha:]]*[[:space:]]+varchar\([0-9]{1,3}\)[[:space:]]*( primary key[[:space:]]*)?,[[:space:]]*)*([[:alpha:]]*[[:space:]]+int[[:space:]]*( primary key[[:space:]]*)?[[:space:]]*|[[:alpha:]]*[[:space:]]+varchar\([0-9]{1,3}\)[[:space:]]*( primary key[[:space:]]*)?[[:space:]]*)\);?$"
        
		if [[ ! $@ =~ $pattern ]]; then
		    echo "Doesn't Match"
		    return 1
		fi

		table_name=$(echo -e "$@" | tr '\n' ' '| cut -d ' ' -f3 )
		table_name=$(echo "$table_name" | awk '{gsub("\\(", ""); print}')
		

		if [ -e $table_name.txt ]; then
		    echo "Table Already Exists"
		    return 1 ;
		else
		   columns=$(echo -e "$@" | tr '\n' ' '| cut -d '(' -f2-)

		    Check_create $columns ;
		    if [ $? -eq 0 ]; then
		       touch databases/$connected/$table_name.txt ;
		       echo "Table Created Successfully"
		    else
		        rm -f databases/$connected/$table_name.txt;
		        echo "Failed To Create Table"
		    fi   
		fi
		
            ;;
        "select "*)
            check_select $@
            return 0
            ;;
         "drop table "*)
             # Extract table name from the user input
	     table_name=$(echo $@ | awk '{print $3}')
	     echo $@ ;
	     echo $table_name;
	     # Check if the table file exists
	     if [ -f "databases/$connected/$table_name" ]; then
	      # Remove the table file and its meta data
	      rm -f "databases/$connected/$table_name"
	      rm -f "databases/$connected/.${table_name}.meta"
	      # Display dialog with result
	      echo "Table $table_name is dropped!" | zenity --text-info --title="Successful" \
	      --height 400 --width 600 --font="Arial 20"
	     else
	      # Table file not found
	      echo "Table $table_name not found!" | zenity --text-info --title="ERROR" \
	      --height 400 --width 600 --font="Arial 20"
	     fi
	     return 0        
            ;;
            
        "show tables"*)  
            # shopt -s extglob # Enable extended pattern matching
            # list all files in database dir
            tables=$(ls databases/$connected/ ) #!(*_meta) | xargs -n1 basename)
            echo $tables
            # Display dialog with databases
            echo "$tables" | zenity --text-info --title="Tables" \
            --height 400 --width 600 --font="Arial 20"
            # shopt -u extglob # Disable extended pattern matching
            return 0
            ;;
        *) 
            return 1 ;
            ;;
        esac
    fi
    


