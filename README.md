# docker@home
A starting point for hosting some useful home[automation] services on Docker.

*So uh, what am I looking at?*
The files here amount to how I ended up configuring my Ubuntu 18.04 Docker host, which provides several services:

- Nextcloud: cloud storage and file sync across devices
- Grafana: a pretty face for your monitoring data
- InfluxDB: time-series database for performance metrics
- Plex: media streaming server
- UniFi Software-Defined Networking controller
- MariaDB: SQL database services
- Caddy: edge proxy with automated TLS configuration
- Backups for all of the above

My hope is that these files will be useful in your case - more of a guide, rather than plug and play. *Don't blind fire anything - inspect carefully and tailor to your needs.*

I have been running many of these services for several years; most recently on a pile of virtual machines.
Therefore, I needed to migrate all of the persistent data out of each one of the VMs, and into Docker volumes.
I scripted as much as possible in hopes that the downtime would be minimal. I loved that I was able to start with an Ubuntu VM on my desktop, run the scripts, and end up with a fully Dockerized copy of my environment! Plus, when I did it "for real", there were very few issues.

*What do the scripts do?*
- build.sh: this is my attempt at automating bare metal -> fully functional Docker host. There is no error handling and very little re-run-ability. I concede that there are approximately eighteen thousand better ways to do this, but then again I'm building this on a single host, and just need it done as quickly as possible.
- migratedata.sh: I copied this file to each one of the "source" machines. It mounts the CIFS share that the Docker host exposes and then runs datamigrator.sh in that share to collect the required data.
- datamigrator.sh: this is intended to run on the "source" machine that contains persistent data you want to ferry over to the new Docker host. I used CIFS on both ends of the transfer; anything works. This should serve as a good guide on what files you want to preserve for each of the services.
- datarestorer.sh: this takes the collected data and reassembles it into a Docker volume, making permissions changes, replacing files, etc where necessary.

Before running datarestorer.sh, I did a `docker-compose up --no-start` to get images downloaded, containers/volumes created and so forth. This gets everything in place to start dumping your existing data into without starting services.
 
I reconciled necessary configuration changes (IP addresses, hostnames, etc..) in a 'config-replacements' directory, which I planted in the datamigration repository and replaced in each Docker volume as necessary after the data was restored verbatim from the source.