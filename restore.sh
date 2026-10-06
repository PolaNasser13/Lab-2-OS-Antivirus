#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Please enter: dir, malicious_dir"
    exit 1
fi

dir="$1"
malicious_dir="$2"

mkdir -p "$dir"
mkdir -p "$malicious_dir"

count=$(ls "$malicious_dir" | wc -l)

if [ "$count" -eq 0 ]; then
    echo "No malicious files to review."
    exit 0
fi

while true; do
    count=$(ls "$malicious_dir" | wc -l)

    if [ "$count" -eq 0 ]; then
        echo "All files reviewed."
        break
    fi

    echo "Files in quarantine:"
    ls "$malicious_dir" | cat -n

    echo "Pick a file number (or q to quit):"
    read choice || break

    if [ "$choice" = "q" ]; then
        break
    fi

    if ! echo "$choice" | grep -q -E '^[0-9]+$'; then
        echo "Please type a number."
        continue
    fi

    if [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
        echo "Number out of range."
        continue
    fi

    name=$(ls "$malicious_dir" | sed -n "${choice}p")

    echo "Selected: $name"
    echo "1) Restore it"
    echo "2) Delete it forever"
    echo "3) Leave it"

    read action || break

    if [ "$action" = "1" ]; then
        mv "$malicious_dir/$name" "$dir/$name"
        echo "Restored $name to $dir."
    elif [ "$action" = "2" ]; then
        rm "$malicious_dir/$name"
        echo "$name permanently deleted."
    elif [ "$action" = "3" ]; then
        echo "Left $name as it is."
    else
        echo "Invalid option."
    fi
done
