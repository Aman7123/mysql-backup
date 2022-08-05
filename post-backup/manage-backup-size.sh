#!/bin/bash
# Copyright (c) 2022 Aaron Renner. All rights reserved.
# --
# --
# General vars
NAME="manage-backup-size"
DB_DUMP_DEBUG=${DB_DUMP_DEBUG:-true}
DOWNLOAD_FOLDER_COUNT=$(ls $DB_DUMP_TARGET | wc -l)
FILE_TO_DELETE=$(ls -t ${DB_DUMP_TARGET} | sort | head -1)
if [[ -n "$DB_DUMP_DEBUG" ]]; then
    echo "DEBUG [$NAME]: Starting..."
    set -x
fi
# --
# --
# Some general debug info
if [ $DB_DUMP_DEBUG == "true" ]; then
    echo "DEBUG [${NAME}]:"
    echo "DOWNLOAD_FOLDER_COUNT: $DOWNLOAD_FOLDER_COUNT"
    echo "FILE_TO_DELETE: $FILE_TO_DELETE"
fi
# --
# --
# Action only if lots of files in the download folder
if [ $DOWNLOAD_FOLDER_COUNT -gt 20 ]; then
    echo "Download folder is at capacity. Deleting oldest data."
    # Remove the oldest file
    rm -rf ${DB_DUMP_TARGET}/${FILE_TO_DELETE}
fi