
ssh root@$SOURCEHOST "mkdir /var/borg ; chmod 700 /var/borg/"
scp socat-wrap.sh ../conf/$SOURCEHOSTNAME.exclude root@$SOURCEHOST:/var/borg/
ssh root@$SOURCEHOST "chmod 755 /var/borg/socat-wrap.sh ; rm /var/borg/borg-remote.sock"
