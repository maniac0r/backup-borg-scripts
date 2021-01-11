
export PATH_TO_REPOSITORIES=/share/homes/borg/repos
export SOURCEHOST=a.b.c.d
export SOURCEHOSTNAME=example_server

source borgize-remote.sh

ssh -R /var/borg/borg-remote.sock:/share/homes/borg/var/borg-local.sock root@$SOURCEHOST \
    BORG_RSH="/var/borg/socat-wrap.sh" \
    borg init -e none ssh://foo/$PATH_TO_REPOSITORIES/$SOURCEHOSTNAME
