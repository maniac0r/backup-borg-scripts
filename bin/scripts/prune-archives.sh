#!/bin/bash

source ~borg/bin/scripts/borg-setenv.sh

DEJT=$(date +%Y-%m-%d-%H-%M)
REPORT="borg-prune-$DEJT"

for SOURCEHOSTNAME in `ls $REPOS` ; do
  echo $REPOS/$SOURCEHOSTNAME":" | tee -a $REPORTS/$REPORT
  borg prune -v --list --keep-daily=7 --keep-weekly=4 --keep-monthly=3 $REPOS/$SOURCEHOSTNAME 2>&1 | tee -a $REPORTS/$REPORT
#  borg prune -v --list --dry-run --keep-daily=7 --keep-weekly=4 --keep-monthly=3 $REPOS/$SOURCEHOSTNAME 2>&1 | tee -a $REPORTS/$REPORT
  echo "" | tee -a $REPORTS/$REPORT
done

find $BORG_CACHE_DIR -user 0 -exec chown borg:borg {} \;
find $BORG_CONFIG_DIR -user 0 -exec chown borg:borg {} \;
find $TMPDIR -user 0 -exec chown borg:borg {} \;
find $REPORTS -user 0 -exec chown borg:borg {} \;
