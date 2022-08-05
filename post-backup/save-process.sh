#!/bin/bash
# Copyright (c) 2022 Aaron Renner. All rights reserved.
# --
# --
# General vars
NAME="save-process"
# Important with default
SP_ENABLE_ENCRYPTION=${SP_ENABLE_ENCRYPTION:-true}
SP_ENABLE_TRANSFER=${SP_ENABLE_TRANSFER:-true}
SP_ENCRYPTION_KEY=${SP_ENCRYPTION_KEY:-password}
SP_OUTPUT_DIR=/tmp/backup-processor
DB_DUMP_DEBUG=${DB_DUMP_DEBUG:-true}
# Generic used in code
FILE_NAME=$(basename ${DUMPFILE})
ENCRYPTED_FILE_NAME="${FILE_NAME}.enc"
ENCRYPTED_FILE_PATH=${SP_OUTPUT_DIR}/${ENCRYPTED_FILE_NAME}
DATE_CMD=$(date -u)
DISCORD_LINKS=""
RUNTIME_START=$(date +%s)
if [[ -n "$DB_DUMP_DEBUG" ]]; then
    echo "DEBUG [$NAME]: Starting..."
    set -x
fi
# --
# --
# Some general debug info
if [ $DB_DUMP_DEBUG == "true" ]; then
    echo "DEBUG [${NAME}]:"
    echo "FILE_NAME: ${FILE_NAME}"
    echo "SP_OUTPUT_DIR: ${SP_OUTPUT_DIR}"
    echo "SP_ENCRYPTION_KEY: ${SP_ENCRYPTION_KEY}"
    echo "ENCRYPTED_FILE_NAME: ${ENCRYPTED_FILE_NAME}"
    echo "ENCRYPTED_FILE_PATH: ${ENCRYPTED_FILE_PATH}"
fi
# --
# --
# Create the working directory
mkdir -p ${SP_OUTPUT_DIR}
# --
# --
# File encryption
if [ $SP_ENABLE_ENCRYPTION == "true" ]; then
    openssl enc -aes256 -nosalt -base64 -A -md sha256 -k ${SP_ENCRYPTION_KEY} -in ${DUMPFILE} -out ${ENCRYPTED_FILE_PATH}
fi
# --
# --
if [ $SP_ENABLE_TRANSFER == "true" ]; then
    # "Session" variable for output file
    SESSION_LOG="\nStarting new log..."
    # Setup output file
    T_SH_DIR=$(dirname ${SP_T_SH_OUTPUT})
    mkdir -p ${T_SH_DIR}
    touch ${SP_T_SH_OUTPUT}
    # Run the curl POST to the remote server
    T_SH_URL="https://transfer.sh/${ENCRYPTED_FILE_NAME}"
    # Holds response for logging
    T_SH_RESPONSE=$(curl -Ifs --upload-file ${ENCRYPTED_FILE_PATH} "${T_SH_URL}")
    # Save to temp buffer for parsing values
    ## This needed to be done because echo-ing the cURL was resulting in weird text
    touch ${T_SH_DIR}/t_sh_tmp.log
    echo -e "${T_SH_RESPONSE}" >> ${T_SH_DIR}/t_sh_tmp.log
    T_SH_DELETE_LINK=$(cat -v ${T_SH_DIR}/t_sh_tmp.log | grep delete | sed "s/x-url-delete: //g" | sed "s/\^M//g")
    T_SH_WEB_LINK=$(cat ${T_SH_DIR}/t_sh_tmp.log | grep http | tail -1)
    ## Add the parsed links into our session log
    SESSION_LOG="${SESSION_LOG}\nLink: ${T_SH_WEB_LINK}\nDelete link: ${T_SH_DELETE_LINK}"
    ## finally delete temp file
    rm ${T_SH_DIR}/t_sh_tmp.log
    # Enables Discord Webhook
    DISCORD_LINKS="${DISCORD_LINKS}[[transfer.sh]](${T_SH_WEB_LINK})\n[[transfer.sh delete]](${T_SH_DELETE_LINK})"
    # Error handling for bad files or server
    if [ -z "$T_SH_RESPONSE" ]; then 
        ERROR_MSG="ERROR [${NAME}]: Failed to upload file ${FILE_NAME} to transfer.sh"
        echo ${ERROR_MSG}
        echo ${ERROR_MSG} >> ${SP_T_SH_OUTPUT}
    fi
    # Log files
    echo -e "${SESSION_LOG}\nFinished..." >> ${SP_T_SH_OUTPUT}
    # Debug for the uploaded files
    if [ $DB_DUMP_DEBUG == "true" ]; then
        echo "DEBUG [${NAME}]: Upload the file:"
        echo "T_SH_RESPONSE: ${T_SH_RESPONSE}"
    fi
fi
# --
# --
# Ability for github release
if [ -n "$SP_GH_PK" ] && [ -n "$SP_GH_USER" ] && [ -n "$SP_GH_REPO" ]; then
    # Scoped vars
    TAG_FORMAT=$(date -u +"%m-%d-%YT%H-%MZ")
    FILE_MIME_TYPE=$(file -b --mime-type ${ENCRYPTED_FILE_PATH})
    # Create new release
    GH_UPLOAD_RESPONSE=$(curl -f \
                    -H "Authorization: token ${SP_GH_PK}" \
                    -d "{\"tag_name\":\"${TAG_FORMAT}\",\"target_commitish\":\"main\",\"name\":\"${TAG_FORMAT}\",\"body\":\"${DATE_CMD}\",\"draft\":false}" \
                    "https://api.github.com/repos/${SP_GH_USER}/${SP_GH_REPO}/releases")
    # Get release ID and URL
    GH_HTTP_URL=$(echo ${GH_UPLOAD_RESPONSE} | jq -r .html_url)
    GH_UPLOAD_ID=$(echo ${GH_UPLOAD_RESPONSE} | jq -r .id)
    # Enabled Discord webhook
    DISCORD_LINKS="${DISCORD_LINKS}\n[[GitHub]](${GH_HTTP_URL})"
    # Build the upload URL for this file to go
    GH_UPLOAD_URL="https://uploads.github.com/repos/${SP_GH_USER}/${SP_GH_REPO}/releases/${GH_UPLOAD_ID}/assets?name=${ENCRYPTED_FILE_NAME}"
    # Publish this new backup file
    GH_ASSET_UPLOAD=$(curl -f \
                      -H "Authorization: token ${SP_GH_PK}" \
                      -H "Content-Type: ${FILE_MIME_TYPE}" \
                      --data-binary @${ENCRYPTED_FILE_PATH} \
                      ${GH_UPLOAD_URL})
    # Debug for the uploaded files
    if [ $DB_DUMP_DEBUG == "true" ]; then
        echo "DEBUG [${NAME}]: Upload to GitHub:"
        echo "GH_UPLOAD_URL: ${GH_UPLOAD_URL}"
        echo "GH_ASSET_UPLOAD: ${GH_ASSET_UPLOAD}"
    fi
fi
# --
# --
# End the processing count
RUNTIME_END=$(date +%s)
RUNTIME_DURATION=$((${RUNTIME_END}-${RUNTIME_START}))
# --
# --
# Discord push
if [ -n "$SP_DISCORD_WEBHOOK" ]; then

    DISCORD_RESPONSE=$(curl -f \
        -H "Content-Type: application/json" \
        -d "{\"embeds\":[{\"type\":\"rich\",\"title\":\"Backup Executed 📂\",\"description\":\"Runtime: ${RUNTIME_DURATION} s\n${DISCORD_LINKS}\",\"color\":16776960,\"footer\":{\"text\":\"${DATE_CMD}\"}}]}" \
        "${SP_DISCORD_WEBHOOK}")
    # Debug for the uploaded files
    if [ $DB_DUMP_DEBUG == "true" ]; then
        echo "DEBUG [${NAME}]: Upload to Discord:"
        echo "DISCORD_RESPONSE: ${DISCORD_RESPONSE}"
    fi
fi