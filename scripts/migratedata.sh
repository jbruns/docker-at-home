#!/bin/bash
mkdir /mnt/datamigration
mount -t cifs -o username=adminuser,domain=ad.domain.tld //dockerhost.ad.domain.tld/datamigration /mnt/datamigration
cd /mnt/datamigration
./datamigrator.sh
cd ~
umount /mnt/datamigration
rmdir /mnt/datamigration
