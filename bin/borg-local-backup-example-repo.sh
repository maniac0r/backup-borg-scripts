export PATH_TO_REPOSITORIES=/path/to/your/borg-repos-folder
export REPONAME="example-repo"

DEJT=$(date +%Y-%m-%d-%H-%M)

borg create --list --compression lz4 -v --stats --progress $PATH_TO_REPOSITORIES/$REPONAME::$DEJT /path/to/folder/you/want/to/backup
