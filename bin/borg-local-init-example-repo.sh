export PATH_TO_REPOSITORIES=/path/to/borg-repos-folder
export REPONAME="example-repo"

borg init -e none $PATH_TO_REPOSITORIES/$REPONAME
