#!/bin/bash

#################################################################################
# Calculate the S3 ETag for a multipart file.
#################################################################################

set -e

export MEGABYTE=$((1024*1024))

if [ $# -ne 2 -a $# -ne 1 ]
then
    echo "Usage: $0 <file> [part-size-mb]" >&2
    echo "  <file>         is the path to the file." >&2
    echo "  [part-size-mb] is the size of a part for multipart uploads. Default is 8." >&2
    exit 1;
fi

if [ ! -f "$1" ]; then
    echo "Error: $1 not found." >&2
    exit 1
else
    FILE=$1
fi

if [ -z "$2" ]; then
    PART_SIZE_MB=8
elif [[ "$2" =~ ^[0-9]+$ ]]; then
    PART_SIZE_MB=$2
else
   echo "Error: $2 is not a number" >&2
   exit 1
fi

FILE_SIZE_BYTE=$(du -b "$FILE" | cut -f 1)
# To round up a/b with integer division, we can add b-1 to a and calculate (a+b-1)/b
N_PARTS=$((($FILE_SIZE_BYTE+$PART_SIZE_MB*$MEGABYTE-1)/(PART_SIZE_MB*$MEGABYTE)))

TMP_FILE=$(mktemp -t s3md5.XXXXXXXX)

for (( n=0; n<$N_PARTS; n++ ))
do
    dd bs=$(($PART_SIZE_MB*$MEGABYTE)) count=1 skip=$n if="$FILE" 2>/dev/null | md5sum | cut -f 1 -d ' ' >> $TMP_FILE
done

echo $(xxd -r -p $TMP_FILE | md5sum | cut -f 1 -d ' ')-$N_PARTS
rm $TMP_FILE
