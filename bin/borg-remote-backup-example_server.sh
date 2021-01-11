
export PATH_TO_REPOSITORIES=/share/homes/borg/repos
export SOURCEHOST=a.b.c.d
export SOURCEHOSTNAME=example_server

DEJT=$(date +%Y-%m-%d-%H-%M)

source borgize-remote.sh

ssh -R /var/borg/borg-remote.sock:/share/homes/borg/var/borg-local.sock root@$SOURCEHOST \
    BORG_RSH="/var/borg/socat-wrap.sh" \
    borg create --list --compression lz4 -v --stats --progress --exclude-from /var/borg/$SOURCEHOSTNAME.exclude ssh://foo/$PATH_TO_REPOSITORIES/$SOURCEHOSTNAME::$DEJT /
    
