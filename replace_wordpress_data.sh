#!/bin/bash

set -o pipefail
set -eux

if [ $# -ne 3 ]; then
	echo "Usage: $0 <db_backup> <fs_backup> <original_domain>"
	exit 1
fi

DB_BACKUP=$1
FS_BACKUP=$2
ORIGINAL_DOMAIN=$(echo $3 | sed 's/\./\\./g')
DB_PASSWORD=$(docker inspect wordpress | jq -r '.[0]["Config"]["Env"][]' | grep ^WORDPRESS_DB_PASSWORD | cut -d = -f 2-)

# Stop wordpress
docker stop wordpress

# Drop tables from database
drop_tables=$(docker exec mariadb mariadb -u wordpress "-p${DB_PASSWORD}" -Nse "SELECT GROUP_CONCAT('DROP TABLE IF EXISTS ', table_name, ';') FROM information_schema.tables WHERE table_schema='wordpress'" wordpress | tr ',' "\n")

echo $drop_tables | docker exec -i mariadb mariadb -u wordpress "-p${DB_PASSWORD}" wordpress

# Restore database from SQL dump
xzcat $DB_BACKUP | sed "s/$ORIGINAL_DOMAIN/www.devday.de/g" | docker exec -i mariadb mariadb -u wordpress "-p${DB_PASSWORD}" wordpress

# Replace wp-content in /var/www/docker
sudo rm -rf /var/www/docker/wordpress
sudo install -o www-data -g www-data -d /var/www/docker/wordpress
sudo tar xf "$FS_BACKUP" --strip-components 2 -C /var/www/docker/wordpress/ ./wp-content
sudo chown -R www-data:www-data /var/www/docker/wordpress

# Start wordpress
docker start wordpress
