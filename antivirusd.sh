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