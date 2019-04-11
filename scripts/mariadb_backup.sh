#!/bin/bash
databaselist="nextclouddb"
for database in $databaselist; do
  /usr/bin/mysqldump --lock-tables -u root -p$1 --databases $database > /tmp/mariadb/$database.sql
done