#!/bin/sh
# 2017-08-20 by maniac based on: https://github.com/borgbackup/borg/issues/900#issuecomment-264184600

export PATH=/opt/bin:/opt/sbin:$PATH

export PATH_TO_REPOSITORIES=/share/homes/borg/repos
export BORGSERVER_HOME=/share/homes/borg

source $BORGSERVER_HOME/bin/scripts/borg-setenv.sh

rm -f /share/homes/borg/var/borg-local.sock
rm -rf /share/WD-RED-8TB-NEW/borg-tmp/*

echo "" >> ~borg/borg-server.log
echo -n "STARTING BORG: " >> ~borg/borg-server.log
date >> ~borg/borg-server.log

chown -R borg:borg /share/WD-RED-8TB-NEW/borg-cache/

su borg -c "/opt/bin/socat UNIX-LISTEN:/share/homes/borg/var/borg-local.sock,fork \
    \"EXEC:/opt/bin/borg serve --restrict-to-path $PATH_TO_REPOSITORIES --umask 077\"
           " 2>&1 >> ~borg/borg-server.log 2>&1 &
           
