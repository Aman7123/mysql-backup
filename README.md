# Custom MySQL Backup

## Description
This project serves as a personal extension of the remarkable [Databacker's MySQL Backup](https://github.com/databacker/mysql-backup) software. It primarily incorporates additional libraries into the container, enabling the use of popular CLI resources like [curl](https://curl.se/) and [jq](https://stedolan.github.io/jq/). The inclusion of these libraries aims to enhance the [Pre- and Post- Processing](https://github.com/databacker/mysql-backup#backup-pre-and-post-processing) features provided in the original project.

## Running with Docker-Compose
**IMPORTANT NOTE**: Before running, execute `sudo chmod -R 777` on the `pos-backup` folder to set the necessary permissions.

### Ensure to populate these variables:

| Variable | Description |
|---|---|
| DB_SERVER | The host of the MySQL database. |
| DB_USER | The username for database access. |
| DB_PASS | The password for the database user account. |
| DB_DUMP_FREQ | Backup frequency in minutes. |
| SP_ENABLE_ENCRYPTION | Toggle to enable encryption during the upload process. |
| SP_ENCRYPTION_KEY | The encryption key to be used. |
| SP_ENABLE_TRANSFER | Toggle to save to transfer.sh. |
| SP_GH_PK | Utilize a GitHub Personal Access Token to enable upload to GitHub. |
| SP_GH_USER | The username associated with the Access Token for GitHub uploads. |
| SP_GH_REPO | The repository to use when creating backup releases. |
| SP_DISCORD_USER | Toggle to enable direct pings when using Discord alerts. |
| SP_DISCORD_WEBHOOK | Provides the capability to alert via Discord with backup URLs, if configured. |

### Discord Alert Example
![Example of Discord alert showing hyperlinks](.github/resources/discord-example.png)

## Decrypting Backups
```bash
openssl \
    enc \
    -d \
    -aes256 \
    -nosalt \
    -base64 \
    -A \
    -md sha256 \
    -d \
    -k <SP_ENCRYPTION_KEY> \
    -in <encrypted-file> \
    -out db_backup.tgz
```