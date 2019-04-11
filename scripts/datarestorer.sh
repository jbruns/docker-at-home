#!/bin/bash
case $1 in
  caddy) echo "restoring Caddy.."
  docker cp - caddy:/etc/caddycerts < caddy_data.tar
  ;;
  nextcloud) echo "restoring Nextcloud.."
  docker cp - nextcloud:/var/www/html/config < nextcloud_config.tar
  docker cp - nextcloud:/var/www/html/data < nextcloud_data.tar
  docker cp - nextcloud:/var/www/html/custom_apps < nextcloud_customapps.tar
  echo "replacing config.."
  chown www-data:www-data nextcloud_config.php
  docker cp nextcloud_config.php nextcloud:/var/www/html/config/config.php
  echo "files copied, starting Nextcloud to adjust permissions.."
  docker-compose --file /etc/docker_shared/prod/docker-compose.yml start nextcloud
  sleep 5
  docker exec -i nextcloud /bin/bash < /etc/docker_shared/nextcloudfixperms.sh
  echo "adding cron jobs.."
  (crontab -l 2>/dev/null; echo "*/15 * * * * docker exec nextcloud su - www-data -s /bin/bash -c 'php -f /var/www/html/cron.php'") | crontab -
  (crontab -l 2>/dev/null; echo "0 * * * * docker exec nextcloud su - www-data -s /bin/bash -c 'php /var/www/html/occ preview:pre-generate'") | crontab -
  ;;
  plex) echo "restoring Plex.."
  docker cp - plex:/config < plex_data.tar
  chown plex:plex plex_Preferences.xml
  docker cp plex_Preferences.xml plex:/config/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
  ;;
  mariadb) echo "restoring MariaDB.."
  docker-compose --file /etc/docker_shared/prod/docker-compose.yml stop mariadb
  echo "adding performance tuning configuration.."
  chown root:root mariadb_50-server.cnf
  docker cp mariadb_50-server.cnf mariadb:/etc/mysql/mariadb.conf.d/50-server.cnf
  docker-compose --file /etc/docker_shared/prod/docker-compose.yml start mariadb
  echo "sleeping while MariaDB starts up.."
  sleep 10
  echo "adding users and grants.."
  cat mariadb_grants.sql | docker exec -i mariadb /usr/bin/mysql -u root -pDefault123
  echo "restoring data.."
  MARIADBPASSWD=`cat /etc/docker_shared/prod/.env | grep 'MARIADB_ROOT=' | cut -d = -f 2`
  cat mariadb_nextclouddb.sql | docker exec -i mariadb /usr/bin/mysql -u root -p${MARIADBPASSWD} nextclouddb
  ;;
  influxdb) echo "recreating InfluxDB databases.."
  chown root:root influxdb.conf
  docker cp influxdb.conf influxdb:/etc/influxdb/influxdb.conf
  TELEGRAFUSERPASSWD=`cat /etc/docker_shared/prod/.env | grep 'INFLUXDB_TELEGRAFUSER=' | cut -d = -f 2`
  AMADMINPASSWD=`cat /etc/docker_shared/prod/.env | grep 'INFLUXDB_AMADMIN=' | cut -d = -f 2`
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE USER telegrafuser WITH PASSWORD '${TELEGRAFUSERPASSWD}'"
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE USER aMadmin WITH PASSWORD '${AMADMINPASSWD}' WITH ALL PRIVILEGES"
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE telegraf"
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE telegraf_downsampled"
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE telegraf_availability"
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE RETENTION POLICY \"rp_short\" ON \"telegraf\" DURATION 30d REPLICATION 1 DEFAULT"
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE CONTINUOUS QUERY cq_all_measurement ON telegraf BEGIN SELECT mean(*) INTO telegraf_downsampled.autogen.:MEASUREMENT FROM telegraf.rp_short./.*/ GROUP BY time(15m), * END"
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=GRANT ALL ON telegraf TO telegrafuser"
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=GRANT ALL ON telegraf_availability TO telegrafuser"
  curl -i -XPOST "http://localhost:8086/query" --data-urlencode "q=GRANT ALL ON telegraf_downsampled TO telegrafuser"
  echo "restarting InfluxDB to enable auth.."
  docker-compose --file /etc/docker_shared/prod/docker-compose.yml restart influxdb
  cd 
  ;;
  tautulli) echo "restoring Tautulli.."
  docker cp - tautulli:/config < tautulli_data.tar
  chown plex:plex tautulli_config.ini
  docker cp tautulli_config.ini tautulli:/config/config.ini
  ;;
  grafana) echo "restoring Grafana.."
  docker cp - grafana:/etc/grafana < grafana_config.tar
  docker cp - grafana:/var/lib/grafana < grafana_data.tar
  ;;
esac