#!/bin/bash
cd "$(dirname "$0")" || exit 1

if [ $# -ne 2 ]; then
    echo "Please enter: dir, malicious_dir"
    exit 1
fi

dir="$1"
malicious_dir="$2"

if [ ! -d "$dir" ]; then
    echo "Error: $dir is not a folder"
    exit 1
fi

mkdir -p "$malicious_dir"

touch whitelist.txt

badFiles='\.(exe|bat|vbs|scr|ps1)$'
badWords='virus|trojan|malware|worm|ransomware'

scan() {
    ls "$dir" | while read name; do

        if [ ! -f "$dir/$name" ]; then
            continue
        fi

        if cat whitelist.txt | grep -x -F -q -- "$name"; then
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

ls -l "$dir" > directory-info.new

if [ ! -f directory-info.last ]; then
    scan
    cp directory-info.new directory-info.last
elif ! cmp -s directory-info.last directory-info.new; then
    scan
    cp directory-info.new directory-info.last
fi