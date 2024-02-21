#!/bin/bash

Check_insert(){
    table_name=$(echo -e "$@" | tr '\n' ' '| cut -d ' ' -f3 )
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

    if [[ $columns_count -ne $values_count && $columns_count -gt 0 ]]; then
    	echo "Error: Number of columns do not match number of values."
    	zenity --notification --window-icon="ERROR" --text="Number of columns does not match number of values!"
    	return 1
    elif [[ $count2 -eq 0 && $columns_count -gt 0 ]]; then
    	echo "Error: Columns do not match the meta data!"
    	zenity --notification --window-icon="ERROR" --text="Columns order does not match the meta data!"
    	return 1
    else 
    	formatted_values=$(echo "$values" | tr '\n' ':'| sed "s/'//g")
	formatted_values=${formatted_values::-1}
	echo "$formatted_values" >> $file
	return 0
    fi   
}

Check_update(){
    
    if [[ ! $@ =~ $pattern ]]; 
    then
        echo "Wrong Syntax"
        zenity --notification --window-icon="ERROR" --text="Wrong Statement! Syntax ERROR"
        return 1;
    fi
    # check if the pattern in fully matched not partially
	matched_part=$(echo "$@" | grep -oE "$pattern")
    if [[ ! $matched_part = $@ ]];
    then
       echo "Partially Wrong Syntax"
       zenity --notification --window-icon="ERROR" --text="Wrong Statement! Syntax ERROR"
       return 1;
    fi 
    ####
    table=$(echo $@ | awk -F ' ' '{print $2}' )
    updating=$(echo $@ | awk -F ' set ' '{print $2}' | awk -F ' where ' '{print $1}' )
    conditions=$(echo $@ | awk -F ' where ' '{print $2}')

    if [ -f databases/$connected/$table ];then

    #initialize variables
    
    cond_cols=""
    cond_cols_values=""
    update_cols=""
    update_cols_values=""
    
    # create a Look up table for col and their order in table

    declare -A lookup_table
    i=1;
     while IFS= read -r meta; do
        col_meta=$(echo $meta | awk -F ':' '{print $1}')
        data_type_meta=$(echo $meta | awk -F ':' '{print $2}')
        lookup_table["$col_meta"]="$i":"$data_type_meta"
        ((i++))
    done < <(cat databases/$connected/.$table.meta)
    
    # check and collect data from 'where' condition

    split=$(echo "$conditions" | awk -v RS=' and ' '{print $1}')
    for cond in $split;
    do
        key=$(echo $cond | awk -F '=' '{print $1}')
        value=$(echo $cond | awk -F '=' '{gsub(";", "");print $2}')
        if [[ $value =~ ^\' ]]; then
            type=varchar;
        else
            type=int
        fi
        value=$(echo $value | awk '{gsub("'\''", "");print $0}')

        ## check if column exist
        flag=${lookup_table[$key]};
        if [ -z $flag ]; then
            echo "column doesn't exist"
            zenity --notification --window-icon="ERROR" --text="Column '$key' Doesn't Exist"
            return 1;
        else
            ## check datatype 
            type_meta=$(echo "${lookup_table[$key]}" | awk -F ':' '{print $2}'| awk -F '(' '{print $1}')
            if [ ! $type_meta = $type ];then
                echo "Datatype doesn't match for column '$key'"
                zenity --notification --window-icon="ERROR" --text="Datatype Doesn't Match For Column '$key'"
                return 1;
            fi
            ####
        fi
        ####   
        # save columns
        val=$(echo "$flag" | awk -F ':' '{print $1}')
        cond_cols=$cond_cols"$val "
        cond_cols_values=$cond_cols_values"$value "
    done
    cond_cols="${cond_cols%?}"

    # check and collect data from 'Set' 

    split=$(echo "$updating" | awk -v RS=',' '{print $1}')
    for cond in $split;
    do
        key=$(echo $cond | awk -F '=' '{print $1}')
        value=$(echo $cond | awk -F '=' '{gsub(";", "");print $2}')
        if [[ $value =~ ^\' ]]; then
            type=varchar;
        else
            type=int
        fi
        value=$(echo $value | awk '{gsub("'\''", "");print $0}')

        ## check if column exist
        flag=${lookup_table[$key]};
        if [ -z $flag ]; then
            echo "column doesn't exist"
            zenity --notification --window-icon="ERROR" --text="Column '$key' Doesn't Exist"
            return 1;
        else
            ## check datatype 
            type_meta=$(echo "${lookup_table[$key]}" | awk -F ':' '{print $2}'| awk -F '(' '{print $1}')
            if [ ! $type_meta = $type ];then
                echo "Datatype doesn't match for column '$key'"
                zenity --notification --window-icon="ERROR" --text="Datatype Doesn't Match For Column '$key'"
                return 1;
            fi
            ####
        fi
        ####   
        # save columns
        val=$(echo "$flag" | awk -F ':' '{print $1}')
        update_cols=$update_cols"$val "
        update_cols_values=$update_cols_values"$value "
    done
    update_cols="${update_cols%?}"

    # Update records 
    awk -v cond_cols="$cond_cols" -v cond_cols_values="$cond_cols_values" -v update_cols="$update_cols" -v update_cols_values="$update_cols_values" 'BEGIN{FS=":"; OFS=":"}
    {
        split(cond_cols, cols, " ");
        split(cond_cols_values, vals, " ");

        split(update_cols, upcol, " ");
        split(update_cols_values, upvals, " ");

        match_count = 0;
        for (i = 1; i <= length(cols); i++) {
            if ($cols[i] == vals[i]) {
                match_count++;
            }
        }
        if (match_count == length(cols))
        {
            for (i = 1; i <= length(upcol); i++) {
               $upcol[i] = upvals[i];
            }
        }
        print
    }' "databases/$connected/$table" > "databases/$connected/$table.tmp" && mv "databases/$connected/$table.tmp" "databases/$connected/$table"
    return 0;
    else
        echo "table doesn't exist"
        zenity --notification --window-icon="ERROR" --text="Table '$table' Doesn't Exist"
        return 1;
    fi
}

check_delete(){
    
    pattern="delete[[:space:]]+from[[:space:]]+[[:alpha:]]+([[:space:]]+where[[:space:]]+[[:alpha:]_]+=([0-9]+|'[[:alnum:]_ ]+')([[:space:]]+(and|or)[[:space:]]+[[:alpha:]]+=('[[:alnum:]_ ]+'|[0-9]+))*[[:space:]]*)?;?"
    if [[ ! $@ =~ $pattern ]]; 
    then
        echo "Wrong Syntax"
        zenity --notification --window-icon="ERROR" --text="Wrong Statement! Syntax ERROR"
        return 1;
    fi
    # check if the pattern in fully matched not partially
    matched_part=$(echo "$@" | grep -oE "$pattern")
    if [[ ! $matched_part = $@ ]];
    then
       echo "Partially Wrong Syntax"
       zenity --notification --window-icon="ERROR" --text="Wrong Statement! Syntax ERROR"
       return 1;
    fi 
    ####
	table=$(echo $@ | awk -F ' ' '{print $3}' )
	conditions=$(echo $@ | awk -F ' where ' '{print $2}')

    if [ -f databases/$connected/$table ];then
        if [[ -z $conditions ]];then
             > databases/$connected/$table ;
            return 0;
        fi
        
    #initialize target_cols and cols_values
    target_cols=""
    cols_values=""
    # create a Look up table for col and their order in table

    declare -A lookup_table
    i=1;
     while IFS= read -r meta; do
        col_meta=$(echo $meta | awk -F ':' '{print $1}')
        data_type_meta=$(echo $meta | awk -F ':' '{print $2}')
        lookup_table["$col_meta"]="$i":"$data_type_meta"
        ((i++))
    done < <(cat databases/$connected/.$table.meta)
    
    # check and collect data from 'where' condition

    split=$(echo "$conditions" | awk -v RS=' and ' '{print $1}')
    for cond in $split;
    do
        key=$(echo $cond | awk -F '=' '{print $1}')
        value=$(echo $cond | awk -F '=' '{gsub(";", "");print $2}')
        if [[ $value =~ ^\' ]]; then
            type=varchar;
        else
            type=int
        fi
        value=$(echo $value | awk '{gsub("'\''", "");print $0}')

        ## check if column exist
        flag=${lookup_table[$key]};
        if [ -z $flag ]; then
            echo "column doesn't exist"
            zenity --notification --window-icon="ERROR" --text="Column '$key' doesn't exist"
            return 1;
        else
            ## check datatype 
            type_meta=$(echo "${lookup_table[$key]}" | awk -F ':' '{print $2}'| awk -F '(' '{print $1}')
            if [ ! $type_meta = $type ];then
                echo "Datatype doesn't match for column '$key'"
                zenity --notification --window-icon="ERROR" --text="Datatype doesn't match for column '$key'"
                return 1;
            fi
            ####
        fi
        ####   
        # save columns
        val=$(echo "$flag" | awk -F ':' '{print $1}')
        target_cols=$target_cols"$val "
        cols_values=$cols_values"$value "
    done
    target_cols="${target_cols%?}"

    # delete records 
    awk -v target_cols="$target_cols" -v cols_values="$cols_values" 'BEGIN{FS=":"; OFS=":"}
    {
        split(target_cols, cols, " ");
        split(cols_values, vals, " ");
        match_count = 0;
        for (i = 1; i <= length(cols); i++) {
            if ($cols[i] == vals[i]) {
                match_count++;
            }
        }
        if (match_count != length(cols))
            print
    }' "databases/$connected/$table" > "databases/$connected/$table.tmp" && mv "databases/$connected/$table.tmp" "databases/$connected/$table"
	return 0;
    else
        echo "table doesn't exist"
        zenity --notification --window-icon="ERROR" --text="Table '$table' Doesn't Exist"
        return 1;
    fi
}

print_data(){
    # Extract arguments
	zenity_cmd="zenity --list --height 400 --width 600 --title='Output Data'"

	# Add columns to the Zenity command
	IFS=',' read -r -a cols <<< "$columns"
	for col in "${cols[@]}"; do
		zenity_cmd+=" --column='$col'"
	done

	# Add values to the Zenity command
	   while IFS=$'\n' read -r record; do
                OLD_IFS=$IFS
		IFS=':'
		val=""
		for col in $record; do
		   col=$(echo "$col" | awk '{$1=$1};1')
		   val+="\"$col\" "
		done
		zenity_cmd+=" $val"
		IFS=$OLD_IFS
         done < <(echo "$output")
	# Execute the Zenity command
	eval "$zenity_cmd"
}

check_select(){
    pattern="select[[:space:]]+(\*|([[:space:]]*[[:alpha:]]+[[:space:]]*,)*[[:space:]]*[[:alpha:]]+[[:space:]]*)[[:space:]]+from[[:space:]]+[[:alpha:]]*[[:space:]]*([[:space:]]+where[[:space:]]+[[:alpha:]]*=('[[:alnum:]_ ]*'|[0-9]*)([[:space:]]+(and|or)[[:space:]]+[[:alpha:]]+=('[[:alnum:]_ ]*'|[0-9]*))*)?[[:space:]]*;?$"

    command=$(echo $@ | awk '{print $1}')
    columns=$(echo $@ | awk -F ' from ' '{print $1}'| cut -d ' ' -f 2-)
    table=$(echo $@ | awk -F ' from ' '{print $2}' | awk '{print $1}')
    table=$(echo "$table" | awk '{gsub(";", ""); print}')
    conditions=$(echo $@ | awk -F ' where ' '{print $2}')
    matched_part=$(echo "$@" | grep -oE "$pattern")
    if [[ ! $@ =~ $pattern ]]; 
    then
        echo "Wrong Syntax"
        zenity --notification --window-icon="ERROR" --text="Wrong Statement! Syntax ERROR"

    # check if the pattern in fully matched not partially

    elif [[ ! $matched_part = $@ ]];
    then
       echo "Partially Wrong Syntax"
       zenity --notification --window-icon="ERROR" --text="Wrong Statement! Syntax ERROR"
	
	# columns=$(echo "$columns" | awk '{$1=$1};1')	

    elif [ -f "databases/$connected/$table" ];then

    # create a Look up table for col and their order in table
    	all_cols="";
        declare -A lookup_table
        i=1;
        while IFS= read -r meta; do
            col_meta=$(echo $meta | awk -F ':' '{print $1}')
            data_type_meta=$(echo $meta | awk -F ':' '{print $2}')
            lookup_table["$col_meta"]="$i":"$data_type_meta"
            all_cols="$all_cols$col_meta ,"
            ((i++))
        done < <(cat "databases/$connected/.$table.meta")
        all_cols="${all_cols%?}"

    # check and collect data from 'where' condition 

    split=$(echo "$conditions" | awk -v RS=' and ' '{print $1}')
    for cond in $split;do
        key=$(echo $cond | awk -F '=' '{print $1}')
        value=$(echo $cond | awk -F '=' '{gsub(";", "");print $2}')
        if [[ $value =~ ^\' ]]; then
            type=varchar;
        else
            type=int
        fi
        value=$(echo $value | awk '{gsub("'\''", "");print $0}')

        ## check if column exist
        flag=${lookup_table[$key]};
        if [ -z $flag ]; then
            echo "column doesn't exist"
            zenity --notification --window-icon="ERROR" --text="Column '$key' Doesn't Exist"
            
        else
            ## check datatype 
            type_meta=$(echo "${lookup_table[$key]}" | awk -F ':' '{print $2}'| awk -F '(' '{print $1}')
            if [ ! $type_meta = $type ];then
                echo "Datatype doesn't match for column '$key'"
                zenity --notification --window-icon="ERROR" --text="Datatype doesn't match for column '$key'"
            fi
            ####
        fi
        ####
    done

    #######################################
    # check if requested column available or not ( in case if not select * ) and keep record of them in $target_cols
    if [[ ! "$columns" = 'all' ]]; then
        target_cols=""
        OLD_IFS=$IFS
        IFS=','
        for col in $columns; do
            col=$(echo "$col" | awk '{$1=$1};1')
            flag=${lookup_table[$col]}
            if [ -z "$flag" ]; then
                echo "column doesn't exist"
                zenity --notification --window-icon="ERROR" --text="Column '$col' Doesn't Exist"
            fi
            val=$(echo "$flag" | awk -F ':' '{print $1}')
            target_cols=$target_cols"$val "
        done
        target_cols="${target_cols%?}"
        IFS=$OLD_IFS
    fi
    ######################################
    # Getting Data
    flag=0;
    data_source="databases/$connected/$table";
      ## check if there no conditions then select all data
    if [ -z "$conditions" ]; then
        output=$(cat "$data_source");
    else
        for cond in $split ; do

            col_name=$(echo $cond | awk -F '=' '{print $1}')
            col_index=$(echo "${lookup_table[$col_name]}" | awk -F ':' '{print $1}')
            col_value=$(echo $cond | awk -F '=' '{gsub(";", "");gsub("'\''", "");print $2}')
            if [ $flag -eq 0 ]; then
                output=$(cat "$data_source" | awk -v col="$col_index" -v val="$col_value" -F ':' '
                BEGIN {}
                {
                    if($col == val) {
                        print
                    }
                }
            ')
                data_source=$output
                ((flag++))
                continue;
            fi
            output=$(echo "$data_source" | awk -v col="$col_index" -v val="$col_value" -F ':' '
                BEGIN {}
                {
                    if($col == val) {
                        print
                    }
                }
            ')
        done
    fi
    ######################################
    # Display Data

    if [[ ! "$columns" = 'all' ]]; then
       output=$(echo "$output" | awk -v target_cols="$target_cols" 'BEGIN{FS=":";OFS=":"}{
        split(target_cols, cols, " "); 
        concat=""
        for (i = 1; i <= length(cols); i++) {
            if ( i == length(cols) )
            {
                concat = concat $cols[i]
            }
            else
                concat = concat $cols[i] ":"
        }   
        print concat
    }')
    else
    	columns=$all_cols;
    fi
    
    echo $columns 
    echo $output
    print_data $columns $output
    ######################################
    else
        echo "table doesn't select exist"
        zenity --notification --window-icon="ERROR" --text="Table '$table' Doesn't Exist"
    fi
}

###################################################
###################################################
if [ -z $connected ]
    then
       echo -e "PLease Connect to database first \n ex : 'use' my_database , $1" |
       zenity --text-info --title="ERROR" --height 400 --width 600 --font="Arial 20"
       return 0
    else
    	case $@ in
    	"insert into "*)
		pattern="insert[[:space:]]+into[[:space:]]+[[:alpha:]_]+[[:space:]]*(\([[:space:]]*[[:alpha:]_]+[[:space:]]*(,[[:space:]]*[[:alpha:]_]+[[:space:]]*)*\))?[[:space:]]*values[[:space:]]*\(([[:space:]]*('[[:alnum:]_ ]+'|[0-9]+)[[:space:]]*)|(,[[:space:]]*('[[:alnum:]_ ]+'|[0-9]+)[[:space:]]*)*\);?"

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
		check_select $@
    		;;
    	"update "*)
		pattern="update[[:space:]]+[[:alpha:]_]+[[:space:]]+set[[:space:]]+[^[:space:]]*[[:space:]]*=([[:space:]]*('[[:alnum:]_ ]+'|[0-9]+)[[:space:]]*)(,[[:space:]]*[^[:space:]]+[[:space:]]*=[[:space:]]*('[[:alnum:]_ ]+'|[0-9]+)[[:space:]]*)*(where[[:space:]]+[[:alpha:]_]+[[:space:]]*=[[:space:]]*[^[:space:]]+[[:space:]]*)?;?"
    		table_name=$(echo -e "$@" | tr '\n' ' '| cut -d ' ' -f2 )
    		echo $table_name
		if [[ ! $@ =~ $pattern ]]; then	
	         	echo "Doesn't Match"
	         	zenity --notification --window-icon="ERROR" --text="Wrong Statement! Syntax ERROR"
	         	echo "Failed To Update Table!" | zenity --text-info --title="ERROR" \
	      	    		--height 400 --width 600 --font="Arial 20"
	      	elif [ ! -f $"databases/$connected/$table_name" ]; then
		 	echo "Table Does not Exists"
	         	zenity --notification --window-icon="ERROR" --text="Table Does Not Exists"
	        else 
	        	Check_update $@ ;
	         	if [ $? -eq 0 ]; then
		     		echo "Updated Successfully"
		     		echo "Updated Successfully!" | zenity --text-info --title="Successful" \
	      			--height 400 --width 600 --font="Arial 20"
		 	else 
		     		echo "Failed To Update"
		     		echo "Failed To Update" | zenity --text-info --title="ERROR" \
	      			--height 400 --width 600 --font="Arial 20"		
		 	fi 
	      	fi
    		;;
    	"delete from "*)
    		check_delete $@
    		if [ $? -eq 0 ]; then
		     		echo "Deleted Successfully"
		     		echo "Deleted Successfully!" | zenity --text-info --title="Successful" \
	      			--height 400 --width 600 --font="Arial 20"
		 	else 
		     		echo "Failed To Deleted"
		     		echo "Failed To Deleted" | zenity --text-info --title="ERROR" \
	      			--height 400 --width 600 --font="Arial 20"		
		 	fi 
    		;;
    	*)
    		return 1;
    		;;
    	esac
fi 
    	
    	
    	
    	
    	
    	
    	
    	
    	
    	
    	
