#!/bin/bash

SOURCEHOSTNAME=$1

source ~borg/bin/scripts/borg-setenv.sh

DEJT=$(date +%Y-%m-%d-%H-%M)
REPORT="borg-info-$DEJT"

if [ -z "$SOURCEHOSTNAME" ] ; then
  for SOURCEHOSTNAME in `ls $REPOS` ; do
    echo $REPOS/$SOURCEHOSTNAME":" | tee -a $REPORTS/$REPORT
    LASTARCHIVE=$(borg list --last 1 $REPOS/$SOURCEHOSTNAME | awk '{print $1}')
    borg info $REPOS/$SOURCEHOSTNAME::$LASTARCHIVE 2>&1 | tee -a $REPORTS/$REPORT
    echo "" | tee -a $REPORTS/$REPORT
  done
else
  echo $REPOS/$SOURCEHOSTNAME":" | tee -a $REPORTS/$REPORT
  LASTARCHIVE=$(borg list --last 1 $REPOS/$SOURCEHOSTNAME | awk '{print $1}')
  borg info $REPOS/$SOURCEHOSTNAME::$LASTARCHIVE 2>&1 | tee -a $REPORTS/$REPORT
  echo "" | tee -a $REPORTS/$REPORT
fi


# fix perms if we ran this as root..
chown -R borg $BORG_CACHE_DIR
chown -R borg $BORG_CONFIG_DIR
chown -R borg $TMPDIR
chown -R borg $REPORTS
