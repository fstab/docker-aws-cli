#!/bin/bash

# Compare contents of S3 and local directory.
# Usage: s3diff.sh <s3://bucket/s3-dir> <local-dir>

if [[ $# -ne 2 ]]
then
    echo "Usage: $0 <s3://bucket/s3-dir> <local-dir>" >&2
    exit 1
fi

if [[ "$1" =~ ^s3://([^/]+)/(.+)$ ]]
then
    BUCKET="${BASH_REMATCH[1]}"
    S3_DIR="${BASH_REMATCH[2]}"
else
    echo "ERROR: $1 is not a valid s3 url. Expected format is s3://bucket/s3-dir" >&2
    exit 1
fi

if [[ "$S3_DIR" != */ ]]
then
    S3_DIR="${S3_DIR}/"
fi

LOCAL_DIR="$2"

if [[ ! -d "$LOCAL_DIR" ]]
then
    echo "ERROR: $2: directory not found." >&2
    exit 1
fi

if [[ "$LOCAL_DIR" != */ ]]
then
    LOCAL_DIR="${LOCAL_DIR}/"
fi

FILE_LIST=$(mktemp -t s3diff.XXXXXXXX)
trap "rm $FILE_LIST" EXIT

aws s3 ls --recursive "s3://${BUCKET}/${S3_DIR}" | awk '{ print $4 }' | while read path
do
    echo "${path#$S3_DIR}" >> $FILE_LIST
done

find "${LOCAL_DIR}" -type f | while read path
do
    echo "${path#$LOCAL_DIR}" >> "${FILE_LIST}"
done

ETAG_CMD="$(dirname $0)/etag.sh"
if [[ ! -x "${ETAG_CMD}" ]]
then
    echo "${ETAG_CMD}: Command not found."
    exit 1
fi

cat "${FILE_LIST}" | sort | uniq | while read FILE
do
    ETAG_LOCAL=$($ETAG_CMD "$LOCAL_DIR$FILE" 2> /dev/null)
    if [[ ! "$ETAG_LOCAL" =~ ^[a-f0-9]{32}(-[0-9]+)?$ ]]
    then
        echo -e "\033[0;31m[diff]\033[0m $FILE is missing on local filesystem."
        continue
    fi
    ETAG_S3=$($ETAG_CMD "s3://$BUCKET/$S3_DIR/$FILE" 2> /dev/null)
    if [[ ! "$ETAG_S3" =~ ^[a-f0-9]{32}(-[0-9]+)?$ ]]
    then
        echo -e "\033[0;31m[diff]\033[0m $FILE is missing on S3."
        continue
    fi
    if [[ "$ETAG_LOCAL" != "$ETAG_S3" ]]
    then
        echo -e "\033[0;31m[diff]\033[0m $FILE differs."
    else
        echo -e "\033[0;32m[ok]\033[0m $FILE."
    fi
done
