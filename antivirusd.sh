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

if ! echo "$interval" | grep -q -E '^[0-9]+$'; then
    echo "Error: interval-secs must be a number"
    exit 1
fi

mkdir -p "$malicious_dir"

badFiles='\.(exe|bat|vbs|scr|ps1)$'
badWords='virus|trojan|malware|worm|ransomware'

scan() {
    ls "$dir" | while read name; do

        if [ ! -f "$dir/$name" ]; then
            continue
        fi

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

if [ ! -f directory-info.last ]; then
    scan
    ls -l "$dir" > directory-info.last
fi

while true; do
    sleep "$interval"
    ls -l "$dir" > directory-info.new

    if ! cmp -s directory-info.last directory-info.new; then
        scan
        cp directory-info.new directory-info.last
    fi
done