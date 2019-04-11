#!/bin/bash
ocpath='/var/www/html'
htuser='www-data'
htgroup='www-data'

echo "adjusting Nextcloud file permissions:"
echo "chmod.."
find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750
echo "ownership:"
echo "/"
chown -R ${htuser}:${htgroup} ${ocpath}/
echo "apps"
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
echo "custom_apps"
chown -R ${htuser}:${htgroup} ${ocpath}/custom_apps/
echo "config"
chown -R ${htuser}:${htgroup} ${ocpath}/config/
echo "data"
chown -R ${htuser}:${htgroup} ${ocpath}/data/
echo "themes"
chown -R ${htuser}:${htgroup} ${ocpath}/themes/

echo ".htaccess"
chown root:${htuser} ${ocpath}/data/.htaccess

chmod 0644 ${ocpath}/.htaccess
chmod 0644 ${ocpath}/data/.htaccess
echo "finished!"
