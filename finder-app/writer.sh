#!/bin/sh
writefile=$1
writestr=$2

if [ $# -lt 2 ];
then 
    echo "Error : not value"
    exit 1
fi

path=$(dirname "$writefile")
if [ ! -d "$path" ];
then 
    mkdir -p "$path" || { echo "Error : could not create file $path"; exit 1; } 
fi

echo "$writestr" > "$writefile" || { echo "Error permission denide"; exit 1; } 
