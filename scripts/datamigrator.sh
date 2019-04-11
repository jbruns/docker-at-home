#!/bin/bash
case $HOSTNAME in
  someserver1.ad.domain.tld) echo "collecting Nextcloud and Caddy data.."
  systemctl stop apache2
  tar -cvf /mnt/datamigration/nextcloud_data.tar --owner=33 --group=33 -C /var/www/html/nextcloud/data .
  tar -cvf /mnt/datamigration/nextcloud_config.tar --owner=33 --group=33 -C /var/www/html/nextcloud/config .
  tar -cvf /mnt/datamigration/nextcloud_customapps.tar --owner=33 --group=33 -C /var/www/html/nextcloud/apps previewgenerator/
  tar -rvf /mnt/datamigration/nextcloud_customapps.tar --owner=33 --group=33 -C /var/www/html/nextcloud/apps bruteforcesettings/
  tar -rvf /mnt/datamigration/nextcloud_customapps.tar --owner=33 --group=33 -C /var/www/html/nextcloud/apps groupfolders/
  tar -cvf /mnt/datamigration/caddy_data.tar --owner=0 --group=0 -C /etc/ssl/caddy .
  systemctl start apache2
  ;;
  someserver2.ad.domain.tld) echo "collecting Plex data.."
  systemctl stop plexmediaserver
  tar -cvf /mnt/datamigration/plex_data.tar --owner=1203 --group=1203 -C /var/lib/plexmediaserver Library/
  systemctl start plexmediaserver
  ;;
  someserver3.ad.domain.tld) echo "collecting MariaDB data.."
  mysqldump nextclouddb > /mnt/datamigration/mariadb_nextclouddb.sql
  ;;
  someserver4.ad.domain.tld) echo "collecting Tautulli and Grafana data.."
  systemctl stop tautulli grafana-server
  tar -cvf /mnt/datamigration/tautulli_data.tar --owner=1203 --group=1203 -C /opt/Tautulli/data backups/
  tar -rvf /mnt/datamigration/tautulli_data.tar --owner=1203 --group=1203 -C /opt/Tautulli/data cache/
  tar -rvf /mnt/datamigration/tautulli_data.tar --owner=1203 --group=1203 -C /opt/Tautulli/data logs/
  tar -rvf /mnt/datamigration/tautulli_data.tar --owner=1203 --group=1203 -C /opt/Tautulli/data newsletters/
  tar -rvf /mnt/datamigration/tautulli_data.tar --owner=1203 --group=1203 -C /opt/Tautulli config.ini
  tar -rvf /mnt/datamigration/tautulli_data.tar --owner=1203 --group=1203 -C /opt/Tautulli tautulli.db
  tar -cvf /mnt/datamigration/grafana_config.tar --owner=472 --group=472 -C /etc/grafana .
  tar -cvf /mnt/datamigration/grafana_data.tar --owner=472 --group=472 -C /var/lib/grafana .
  systemctl start tautulli grafana-server
  ;;
esac
