#!/bin/bash

RUNDEJT=$(date +%Y-%m-%d-%H-%M)
INPUT_PARAM=$1
MY_BORG_PARAMS="--compression lz4 --stats"
MY_BORG_SCRIPTS="/share/homes/borg/bin/scripts/"
source $MY_BORG_SCRIPTS/borg-setenv.sh

echo "BORG_CONFIG_DIR:  $BORG_CONFIG_DIR"
echo "BORG_KEYS_DIR:            $BORG_KEYS_DIR"
echo "BORG_SECURITY_DIR:        $BORG_SECURITY_DIR"
echo "BORG_CACHE_DIR:           $BORG_CACHE_DIR"
echo "TMPDIR:                   $TMPDIR"
echo "REPOS:                    $REPOS"
echo "BORG_BASE:                $BORG_BASE"
echo "UNIX USER:                $BORG_USER"
echo "MY BORG PARAMS:           $BORG_PARAMS"
echo ""
NREPOS=$(ls $REPOS | wc -l)
if [ $NREPOS -eq 0 ] ; then
  echo "ERROR: NO BORG REPOSITORIES FOUND, EXITING !!!"
  exit 1
fi
echo "BORG Repositories found:" $(ls $REPOS | wc -l)

echo ""

echo "fixing permissions..."
find $REPOS -user 0 -exec chown borg {} \;

echo ""


if [ -z "$INPUT_PARAM" ] ; then

        i=1
        for SOURCEHOSTNAME in `ls $REPOS` ; do
          DEJT=$(date +%Y-%m-%d-%H-%M)
          source $CONFIGS/$SOURCEHOSTNAME.conf
          echo "$i: $SOURCEHOSTNAME - $SOURCEHOST"

          # BORGIZE
          ssh -p $SOURCEPORT root@$SOURCEHOST "mkdir /var/borg ; chmod 700 /var/borg/"
          scp -P $SOURCEPORT $MY_BORG_SCRIPTS/socat-wrap.sh $CONFIGS/$SOURCEHOSTNAME.exclude root@$SOURCEHOST:/var/borg/
          ssh -p $SOURCEPORT root@$SOURCEHOST "chmod 755 /var/borg/socat-wrap.sh ; rm /var/borg/borg-remote.sock"

          # BACKUP
          ssh -p $SOURCEPORT -R /var/borg/borg-remote.sock:/share/homes/borg/var/borg-local.sock root@$SOURCEHOST \
            BORG_RSH="/var/borg/socat-wrap.sh" \
            borg create $MY_BORG_PARAMS --exclude-from /var/borg/$SOURCEHOSTNAME.exclude ssh://foo/$REPOS/$SOURCEHOSTNAME::$DEJT /
#          echo ""
           ((i++))
        done

else
        SOURCEHOSTNAME=$INPUT_PARAM
        SOURCEHOST=$SOURCEHOSTNAME
          DEJT=$(date +%Y-%m-%d-%H-%M)
          source $CONFIGS/$SOURCEHOSTNAME.conf
          echo "$SOURCEHOSTNAME - $SOURCEHOST"

          # BORGIZE
          ssh -p $SOURCEPORT root@$SOURCEHOST "mkdir /var/borg ; chmod 700 /var/borg/"
          scp -P $SOURCEPORT $MY_BORG_SCRIPTS/socat-wrap.sh $CONFIGS/$SOURCEHOSTNAME.exclude root@$SOURCEHOST:/var/borg/
          ssh -p $SOURCEPORT root@$SOURCEHOST "chmod 755 /var/borg/socat-wrap.sh ; rm /var/borg/borg-remote.sock"

          # BACKUP
          ssh -p $SOURCEPORT -R /var/borg/borg-remote.sock:/share/homes/borg/var/borg-local.sock root@$SOURCEHOST \
            BORG_RSH="/var/borg/socat-wrap.sh" \
            borg create $MY_BORG_PARAMS --exclude-from /var/borg/$SOURCEHOSTNAME.exclude ssh://foo/$REPOS/$SOURCEHOSTNAME::$DEJT /
#          echo ""
fi

echo "################################################################################" >> /share/homes/borg/borgbackup.log

(cat /share/homes/borg/bin/scripts/mailheader.txt ; egrep ' - |^This archive|^All archives|^Duration|^$' /share/homes/borg/borgbackup.log) | sendmail -t

mv /share/homes/borg/borgbackup.log /share/homes/borg/borgbackup.log-$RUNDEJT

echo "fixing permissions..."
find $REPOS -user 0 -exec chown borg {} \;

echo "pruning old archives..."
/share/homes/borg/bin/scripts/prune-archives.sh 2>&1 >> /share/homes/borg/borgbackup.log-$RUNDEJT 2>&1

echo "fixing permissions..."
find $REPOS -user 0 -exec chown borg {} \;

if [ -n "$TMPDIR" ] ; then
  echo "removing tmp files..."
  rm -rf $TMPDIR/*
fi

cd /share/homes/borg ; ./parse-stats.sh /share/homes/borg/borgbackup.log-$RUNDEJT

