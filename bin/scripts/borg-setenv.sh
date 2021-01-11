#!/bin/bash
# 2017-11-11 by maniac
# set environment for borg running on server
#

export PATH=/opt/bin:/opt/sbin:$PATH

export BORG_BASE="/share/WD-RED-8TB-NEW"
export BORG_USER=borg
export REPOS=$BORG_BASE/borg-repository
export CONFIGS=/share/homes/borg/conf
export REPORTS=$BORG_BASE/borg-reports

export TMPDIR=$BORG_BASE/borg-tmp
export TEMP=$TMPDIR
export BORG_CONFIG_DIR=$BORG_BASE/borg-config
  export BORG_KEYS_DIR=$BORG_CONFIG_DIR/keys
  export BORG_SECURITY_DIR=$BORG_CONFIG_DIR/security
export BORG_CACHE_DIR=$BORG_BASE/borg-cache

export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
