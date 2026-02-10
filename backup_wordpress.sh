#!/bin/bash

set -o pipefail
set -eu

BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
DB_PASSWORD=$(docker inspect wordpress | jq -r '.[0]["Config"]["Env"][]' | grep ^WORDPRESS_DB_PASSWORD | cut -d = -f 2-)
docker exec wordpress tar c -C /var/www/html . | gzip > "wordpress_fs_${BACKUP_DATE}.tar.gz"
docker exec mariadb mariadb-dump -u wordpress "-p${DB_PASSWORD}" wordpress | xz > wordpress_db_${BACKUP_DATE}.sql.xz
