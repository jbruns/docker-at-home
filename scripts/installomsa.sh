#!/bin/bash
echo 'deb http://linux.dell.com/repo/community/openmanage/920/$(lsb_release -cs) $(lsb_release -cs) main' | tee -a /etc/apt/sources.list.d/linux.dell.com.sources.list
gpg --keyserver pool.sks-keyservers.net --recv-key 1285491434D8786F
gpg -a --export 1285491434D8786F | apt-key add -
apt-get update
apt-get install srvadmin-all