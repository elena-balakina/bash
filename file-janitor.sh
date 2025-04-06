#!/usr/bin/env bash
echo -e 'File Janitor, 2025 \nPowered by Bash'
echo ""

validate_directory() {
    local dir="$1"

    if [ ! -e "$dir" ]; then
        echo "$dir is not found"
        return 1
    fi

    if [ ! -d "$dir" ]; then
        echo "$dir is not a directory"
        return 1
    fi

    return 0
}


check_and_list() {
dir="$1"
if ! validate_directory "$dir"; then
    return
fi

echo "Listing files in $dir"
ls -A -X -1 "$dir"	
}

count_and_print() {
    local dir="$1"

    tmp_count=$(find "$dir" -maxdepth 1 -type f -name "*.tmp" | wc -l)
    tmp_size=$(find "$dir" -maxdepth 1 -type f -name "*.tmp" -printf "%s\n" 2>/dev/null | awk '{total += $1} END {print total + 0}')
    
    log_count=$(find "$dir" -maxdepth 1 -type f -name "*.log" | wc -l)
    log_size=$(find "$dir" -maxdepth 1 -type f -name "*.log" -printf "%s\n" 2>/dev/null | awk '{total += $1} END {print total + 0}')
    
    py_count=$(find "$dir" -maxdepth 1 -type f -name "*.py" | wc -l)
    py_size=$(find "$dir" -maxdepth 1 -type f -name "*.py" -printf "%s\n" 2>/dev/null | awk '{total += $1} END {print total + 0}')

    echo "$tmp_count tmp file(s), with total size of $tmp_size bytes"
    echo "$log_count log file(s), with total size of $log_size bytes"
    echo "$py_count py file(s), with total size of $py_size bytes"
}


check_and_report() {
    local dir="$1"

    if [ -n "$dir" ]; then
		if ! validate_directory "$dir"; then
			return
		fi
        count_and_print "$dir"
    else
        count_and_print "."
    fi
}

delete_and_move() {
	local dir="$1"
	
	# Найти старые .log файлы и удалить их, предварительно посчитав
	old_logs=$(find "$dir" -maxdepth 1 -type f -name "*.log" -mtime +3)
    count=$(echo "$old_logs" | grep -c .)

    echo -n "Deleting old log files..."
    if [ "$count" -gt 0 ]; then
        echo "$old_logs" | xargs rm -f
    fi
    echo "  done! $count files have been deleted"
	
	# Найти все .tmp файлы и удалить их
	tmp_files=$(find "$dir" -maxdepth 1 -type f -name "*.tmp")
    count=$(echo "$tmp_files" | grep -c .)
    
	echo -n "Deleting temporary files..."
    if [ "$count" -gt 0 ]; then
        echo "$tmp_files" | xargs rm -f
    fi
    echo "  done! $count files have been deleted"
	
	# Найдём все .py файлы в dir, но без поддиректорий
	py_files=$(find "$dir" -maxdepth 1 -type f -name "*.py")
    count=$(echo "$py_files" | grep -c .)

    echo -n "Moving python files..."

    if [ "$count" -gt 0 ]; then
        local target="$dir/python_scripts"
		mkdir -p "$target"
        echo "$py_files" | while read -r file; do
            mv "$file" "$target/"
        done
    fi
    echo "  done! $count files have been moved"
	
	echo ""
	if [ "$dir" = "." ]; then
        echo "Clean up of the current directory is complete!"
	else
		echo "Clean up of $dir is complete!"
    fi
}



clean() {
	local dir="$1"

	if [ -n "$dir" ]; then
		if ! validate_directory "$dir"; then
			return
		fi
		echo "Cleaning $dir..."
        delete_and_move "$dir"
    else
        delete_and_move "."
    fi

}


if [ "$1" = "help" ]; then
    cat file-janitor-help.txt
elif [ "$1" = "list" ]; then
    if [ "$2" = "" ]; then
	echo "Listing files in the current directory"
	ls -A -X -1
	else
	check_and_list "$2"
	fi
elif [ "$1" = "report" ]; then
	if [ "$2" = "" ]; then
	echo "The current directory contains:"
	check_and_report
	else
	echo "$2 contains:"
	check_and_report "$2"
	fi
elif [ "$1" = "clean" ]; then
	if [ "$2" = "" ]; then
	echo "Cleaning the current directory..."
	clean
	else
	clean "$2"
	fi
else
    echo "Type file-janitor.sh help to see available options"
fi



