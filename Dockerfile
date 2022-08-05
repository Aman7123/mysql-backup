# Image info
FROM databack/mysql-backup:master
LABEL maintainer="Aaron Renner <https://github.com/Aman7123>"
# Updates the user
USER root
# Adds new libraries
RUN apk add --update curl jq httpie file && \
    rm -rf /var/cache/apk/*