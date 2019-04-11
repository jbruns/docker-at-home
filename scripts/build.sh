#!/bin/bash

# install all of the required packages
apt-get update
apt-get upgrade -y
apt-get install -y \
   realmd \
   sssd \
   sssd-tools \
   libnss-sss \
   libpam-sss \
   krb5-user \
   adcli \
   samba-common-bin \
   oddjob \
   oddjob-mkhomedir \
   packagekit \
   apt-transport-https \
   ca-certificates \
   curl \
   gnupg-agent \
   software-properties-common \
   autofs \
   cifs-utils \
   samba

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
curl -fsSL https://repos.influxdata.com/influxdb.key | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

add-apt-repository \
   "deb https://repos.influxdata.com/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update

apt-get install -y \
   docker-ce \
   docker-ce-cli \
   containerd.io \
   docker-compose \
   telegraf

# scoot telegraf out of the way of some docker default uid's.
# create system accounts.
systemctl stop telegraf
groupmod -g 1200 telegraf
usermod -u 1200 -g 1200 telegraf
usermod -aG docker telegraf
adduser --system --no-create-home --group --uid 1201 unifi
adduser --system --no-create-home --group --uid 1202 organizr
adduser --system --group --uid 1203 plex
adduser --system --no-create-home --group --uid 1204 sonarr
adduser --system --no-create-home --group --uid 1205 radarr
addgroup --gid 1301 mediastream
usermod -aG mediastream plex

# create autofs/rclone mountpoints and datamigration directory
mkdir /mnt/afs
mkdir -p /mnt/cloud/cloudDrive
chown -R plex:plex /mnt/cloud/cloudDrive
mkdir /var/datamigration

# install rclone
curl https://rclone.org/install.sh | bash

# join the domain. configure samba.
mv ../realmd.conf /etc/realmd.conf
realm discover ad.domain.tld
realm join \
   --user=AdminUser \
   --computer-ou="ou=Servers,dc=ad,dc=domain,dc=tld" \
   --verbose \
   ad.domain.tld
mv /etc/sssd/sssd.conf /etc/sssd/sssd.conf.orig
mv ../sssd.conf /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd
mv /etc/samba/smb.conf /etc/samba/smb.conf.orig
mv ../smb.conf /etc/samba/smb.conf
chmod 600 /etc/samba/smb.conf
mv ../60-smbtuning.conf /etc/sysctl.d/60-smbtuning.conf
systemctl restart smbd nmbd
net ads join createcomputer="Servers" -U AdminUser
pam-auth-update --enable mkhomedir
systemctl restart sssd smbd nmbd

# configure autofs
mkdir /etc/auto.master.d
mv ../auto.cifs /etc/auto.master.d/
mv ../amnt.autofs /etc/auto.master.d/

# stage autofs credentials
# here, I grabbed files out of a 'cred' directory and put them in /root, followed by a chmod 600.


# stage docker-compose files and supporting scripts/configuration
# '.env' provides secret or sensitive data that we don't necessarily want in docker-compose.yml.
mkdir -p /etc/docker_shared/prod/
mv ../cred/env /etc/docker_shared/prod/.env
chmod 600 /etc/docker_shared/prod/.env
chown root:root /etc/docker_shared/prod/.env

mv ../docker-compose.yml /etc/docker_shared/prod/
mv nextcloudfixperms.sh /etc/docker_shared
mv mariadb_backup.sh /etc/docker_shared
chmod 700 /etc/docker_shared/mariadb_backup.sh
mv ../config-replacements/Caddyfile /etc/docker_shared/
sed -i -e "s/placeholder/$HOSTNAME/g" /etc/docker_shared/Caddyfile
chown -R AdminUser@ad.domain.tld:domain\ admins@ad.domain.tld /etc/docker_shared/

# configure rclone and create a service to mount gdrive on boot
mv ../mountclouddrive.service /lib/systemd/system/mountclouddrive.service
sed -i -e 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf
mkdir -p /home/plex/.config/rclone
mv ../rclone.conf /home/plex/.config/rclone
chmod 600 /home/plex/.config/rclone/rclone.conf
chown -R plex:plex /home/plex/.config/

systemctl daemon-reload
systemctl enable mountclouddrive.service
systemctl restart autofs

# configure telegraf
mv ../telegraf.conf /etc/telegraf
chown telegraf:telegraf /etc/telegraf/telegraf.conf
systemctl start telegraf

# stage configuration file replacements and other data needed for restoration process
chmod 764 /var/datamigration
mv ../mariadb_grants.sql /var/datamigration
mv datamigrator.sh /var/datamigration
mv datarestorer.sh /var/datamigration
mv ../config-replacements/config.php /var/datamigration/nextcloud_config.php
sed -i -e "s/placeholder/$HOSTNAME/g" /var/datamigration/nextcloud_config.php
mv ../config-replacements/config.ini /var/datamigration/tautulli_config.ini
mv ../config-replacements/influxdb.conf /var/datamigration/influxdb.conf
mv ../config-replacements/Preferences.xml /var/datamigration/plex_Preferences.xml
mv ../config-replacements/50-server.cnf /var/datamigration/mariadb_50-server.cnf
chown -R homeadmin@ad.domain.tld:domain\ admins@ad.domain.tld /var/datamigration