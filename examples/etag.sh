#!/bin/bash

#################################################################################
# Get the AWS S3 ETag for a file.
# -------------------------------------------------------------------------------
# For s3://... URLS the ETag is fetched using the AWS API.
# For local files the ETag is calculated locally.
#################################################################################

set -e

export MEGABYTE=$((1024*1024))

# The following are the default settings in AWS CLI.
# If you use different values via `aws configure`, you must also change the values here.
export MULTIPART_THRESHOLD=$((8*$MEGABYTE))
export MULTIPART_CHUNKSIZE=$((8*$MEGABYTE))

if [ $# -ne 1 ]
then
    echo "Usage: $0 <path>" >&2
    echo "  <path> can either be a local file, or an S3 url like s3://bucket/dir/file" >&2
    exit 1;
fi

if [[ "$1" =~ ^s3://([^/]+)/(.+)$ ]]
then
    BUCKET="${BASH_REMATCH[1]}"
    S3_PATH="${BASH_REMATCH[2]}"
    result=$(aws s3api head-object --bucket "$BUCKET" --key "$S3_PATH" --query 'ETag' 2>/dev/null | sed -e 's/["\\]//g')
    if [[ "$result" =~ ^[a-f0-9]{32}(-[0-9]+)?$ ]]
    then
        echo "$result"
        exit 0
    else
        echo "ERROR: $1 not found." >&2
        exit 1
    fi
else
    if [[ -f "$1" ]]
    then
        FILE_SIZE=$(du -b "$1" | awk '{ print $1 }')
        if [[ $FILE_SIZE -le $MULTIPART_THRESHOLD ]]
        then
            echo $(md5sum "$1" | awk '{ print $1 }')
            exit 0
        else
            # To round up a/b with integer division, we can add b-1 to a and calculate (a+b-1)/b
            N_PARTS=$((($FILE_SIZE+$MULTIPART_CHUNKSIZE-1)/$MULTIPART_CHUNKSIZE))
            CONCATENATED_MD5_HASHES=""
            for (( n=0; n<$N_PARTS; n++ ))
            do
                CHUNK_MD5=$(dd bs=$MULTIPART_CHUNKSIZE count=1 skip=$n if="$1" 2>/dev/null | md5sum | awk '{ print $1 }')
                CONCATENATED_MD5_HASHES="${CONCATENATED_MD5_HASHES}${CHUNK_MD5}"
            done
            echo $(echo "${CONCATENATED_MD5_HASHES}" | xxd -r -p - | md5sum | cut -f 1 -d ' ')-$N_PARTS
        fi
    else
        echo "ERROR: $1 not found." >&2
        exit 1
    fi
fi
