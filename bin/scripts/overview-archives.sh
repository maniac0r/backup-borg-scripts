#!/bin/bash

source ~borg/bin/scripts/borg-setenv.sh

DEJT=$(date +%Y-%m-%d-%H-%M)
REPORT="borg-overview-archives-$DEJT"

for SOURCEHOSTNAME in `ls $REPOS` ; do
  echo $REPOS/$SOURCEHOSTNAME":" | tee -a $REPORTS/$REPORT
  borg list $REPOS/$SOURCEHOSTNAME | tee -a $REPORTS/$REPORT
  echo "" | tee -a $REPORTS/$REPORT
done

# fix perms if we ran this as root..
chown -R borg $BORG_CACHE_DIR
chown -R borg $BORG_CONFIG_DIR
chown -R borg $TMPDIR
chown -R borg $REPORTS
