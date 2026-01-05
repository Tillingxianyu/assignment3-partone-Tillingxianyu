#!/bin/sh

filesdir=$1
searchstr=$2

if [ $# -lt 2 ]; then
    echo "Error : there is no value"
    exit 1
fi

if [ ! -d "$filesdir" ]; then 
    echo "The file $filesdir is not a directory"
    exit 1
fi

X=$(find "$filesdir" -type f | wc -l)
Y=$(grep -r "$searchstr" "$filesdir" | wc -l)

echo "The number of files are $X and the number of matching lines are $Y"
