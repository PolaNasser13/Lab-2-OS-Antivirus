#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Please enter: dir, malicious_dir, interval-secs"
    exit 1
fi

dir="$1"
malicious_dir="$2"
interval="$3"

if [ ! -d "$dir" ]; then
    echo "Error: $dir is not a folder"
    exit 1
fi

mkdir -p "$malicious_dir"

badFiles='\.(exe|bat|vbs|scr|ps1)$'
badWords='virus|trojan|malware|worm|ransomware'

scan() {
    ls "$dir" | while read name; do

        isBad="no"

        if echo "$name" | grep -i -q -E "$badFiles"; then
            isBad="yes"
        fi

        if cat "$dir/$name" | grep -a -i -q -E "$badWords"; then
            isBad="yes"
        fi

        if [ "$isBad" = "yes" ]; then
            echo "$name is malicious and it is DELETED"
            cp "$dir/$name" "$malicious_dir/$name"
            rm "$dir/$name"
        fi

    done
}


