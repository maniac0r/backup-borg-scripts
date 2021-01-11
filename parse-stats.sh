#!/opt/bin/bash

LOGF=$1
  if [ -z "$LOGF" ] ; then
    echo "Please specify log file to analyze"
    exit 1
  else
    if [ "$LOGF" == "-a" ] ; then
      for FILE in `ls /share/homes/borg/borgbackup.log-*` ; do
        /share/homes/borg/parse-stats.sh "$FILE"
      done
      exit 0
    fi
  fi

#LOGF="/share/homes/borg/borgbackup.log-2017-12-29-01-00"

LOGTIMESTAMP=$(date -d "$(echo $LOGF | sed s/.*\.log-// | sed s/-/\ /3 | sed s/-/\:/3)" +%s%N )

echo "Processing log:$LOGF"

declare -A ARR_SERVER
declare -A ARR_DURATION
declare -A ARR_THIS_ORIG
declare -A ARR_THIS_COMPRESSED
declare -A ARR_THIS_DEDUPLICATED
declare -A ARR_ALL_ORIG
declare -A ARR_ALL_COMPRESSED
declare -A ARR_ALL_DEDUPLICATED
declare -A ARR_NUMBEROFFILES
#declare -A ARR_TIMESTART
#declare -A ARR_TIMEEND
declare -A ARR_CHUNKSUNIQUE
declare -A ARR_CHUNKSTOTAL
declare -A ARR_ERRORS
declare -A ARR_REPOSERVER
declare -A ARR_KEEPING
declare -A ARR_PRUNING
declare -A ARR_TIMESTAMP_START
declare -A ARR_TIMESTAMP_END

dehumanise() {
    echo $1 $2 | /opt/bin/awk \
      'BEGIN{IGNORECASE = 1}
       function printpower(n,b,p) {printf "%u\n", n*b^p; next}
       /[0-9]$/{print $1;next};
       /K(iB)?$/{printpower($1,  2, 10)};
       /M(iB)?$/{printpower($1,  2, 20)};
       /G(iB)?$/{printpower($1,  2, 30)};
       /T(iB)?$/{printpower($1,  2, 40)};
       /KB$/{    printpower($1, 10,  3)};
       /MB$/{    printpower($1, 10,  6)};
       /GB$/{    printpower($1, 10,  9)};
       /TB$/{    printpower($1, 10, 12)}'
}

dehumanisetime(){
  HOURS=0
  MINUTES=0
  SECS=0
  T=$1

  if [[ "$T" =~ "minutes" ]]  ; then
    T1=$(echo $T | sed s/\ minutes.*// )
    T2=$(echo $T1 | sed s/.*[^0-9.]//)
    MINUTES=$T2
  fi

  if [[ "$T" =~ "seconds" ]]  ; then
    T3=$(echo $T | sed s/\ seconds.*// )
    T4=$(echo $T3 | sed s/.*[^0-9.]//)
    SECS=$T4
  fi

  if [[ "$T" =~ "hours" ]]  ; then
    T5=$(echo $T | sed s/\ hours.*// )
    T6=$(echo $T5 | sed s/.*[^0-9.]//)
    HOURS=$T6
  fi

  bc <<< "$HOURS * 3600 + $MINUTES * 60 + $SECS"
}


OIF=$IFS
IFS='
'

while read LINE ; do

  if [[ "$LINE" =~ ^[0-9]+:\ .* ]] ; then
    ID=$(echo $LINE | awk -F ":" '{print $1}')
    SERVER=$(echo $LINE | awk '{print $2}')
    ERRORS=0

    ARR_SERVER[$SERVER]=$SERVER
    ARR_ERRORS[$SERVER]=$ERRORS
  fi

# duration
  if [[ "$LINE" =~ ^Duration:\  ]] ; then
    DURATION=$(echo $LINE | awk -F ":" '{print $2}')
    DURATIONSECS=$(dehumanisetime "$DURATION")
    ARR_DURATION[$SERVER]=$DURATIONSECS
  fi

# this archive
  if [[ "$LINE" =~ ^This\ archive:.* ]] ; then
    THISARCHIVE=$(echo $LINE | awk -F ":" '{print $2}')
    THIS_ORIG=$(echo $THISARCHIVE | awk '{print $1" "$2}')
    THIS_COMPRESSED=$(echo $THISARCHIVE | awk '{print $3" "$4}')
    THIS_DEDUPLICATED=$(echo $THISARCHIVE | awk '{print $5" "$6}')
    THIS_ORIG2=$(dehumanise "$THIS_ORIG")
    THIS_COMPRESSED2=$(dehumanise "$THIS_COMPRESSED")
    THIS_DEDUPLICATED2=$(dehumanise "$THIS_DEDUPLICATED")
    ARR_THIS_ORIG[$SERVER]=$THIS_ORIG2
    ARR_THIS_COMPRESSED[$SERVER]=$THIS_COMPRESSED2
    ARR_THIS_DEDUPLICATED[$SERVER]=$THIS_DEDUPLICATED2
  fi

# all archives
  if [[ "$LINE" =~ ^All\ archives:.* ]] ; then
    ALLARCHIVES=$(echo $LINE | awk -F ":" '{print $2}')
    ALL_ORIG=$(echo $ALLARCHIVES | awk '{print $1" "$2}')
    ALL_COMPRESSED=$(echo $ALLARCHIVES | awk '{print $3" "$4}')
    ALL_DEDUPLICATED=$(echo $ALLARCHIVES | awk '{print $5" "$6}')
    ALL_ORIG2=$(dehumanise "$ALL_ORIG")
    ALL_COMPRESSED2=$(dehumanise "$ALL_COMPRESSED")
    ALL_DEDUPLICATED2=$(dehumanise "$ALL_DEDUPLICATED")
    ARR_ALL_ORIG[$SERVER]=$ALL_ORIG2
    ARR_ALL_COMPRESSED[$SERVER]=$ALL_COMPRESSED2
    ARR_ALL_DEDUPLICATED[$SERVER]=$ALL_DEDUPLICATED2
  fi

# number of files
  if [[ "$LINE" =~ ^Number\ of\ files:.* ]] ; then
    NUMBEROFFILES=$(echo $LINE | awk -F ":" '{print $2}' | sed "s/\ //")
   ARR_NUMBEROFFILES[$SERVER]=$NUMBEROFFILES
  fi

# Time start
  if [[ "$LINE" =~ ^Time\ \(start\):.* ]] ; then
    TIMESTART=$(echo $LINE | sed s/.*,\ //)
   TIMESTAMP_START=$(date -d "$TIMESTART" +%s%N)
   ARR_TIMESTAMP_START[$SERVER]=$TIMESTAMP_START
  fi

# Time end
  if [[ "$LINE" =~ ^Time\ \(end\):.* ]] ; then
    TIMEEND=$(echo $LINE | sed s/.*,\ //)
   TIMESTAMP_END=$(date -d "$TIMEEND" +%s%N)
   ARR_TIMESTAMP_END[$SERVER]=$TIMESTAMP_END
  fi

# Chunk index
  if [[ "$LINE" =~ ^Chunk\ index:.* ]] ; then
    CHUNKSUNIQUE=$(echo $LINE | awk '{print $3}')
    CHUNKSTOTAL=$(echo $LINE | awk '{print $4}')
   ARR_CHUNKSUNIQUE[$SERVER]=$CHUNKSUNIQUE
   ARR_CHUNKSTOTAL[$SERVER]=$CHUNKSTOTAL
  fi

# Errors
  if [[ "$LINE" =~ [eE]rr ]] ; then
    ((ERRORS++))
   ARR_ERRORS[$SERVER]=$ERRORS
  fi

# REPOSITORY MAINTENANCE STATS
  if [[ "$LINE" =~ ^\/share\/WD-RED-8TB-NEW\/borg-repository\/ ]] ; then
    REPOSERVER=$(echo $LINE | sed 's/.*\///' | tr -d \: )
    KEEPING=0
    PRUNING=0
    ARR_REPOSERVER[$REPOSERVER]=$REPOSERVER
    ARR_KEEPING[$REPOSERVER]=$KEEPING
    ARR_PRUNING[$REPOSERVER]=$PRUNING
  fi

  if [[ "$LINE" =~ ^Keeping ]] ; then
   ((KEEPING++))
   ARR_KEEPING[$REPOSERVER]=$KEEPING
  fi

  if [[ "$LINE" =~ ^Pruning ]] ; then
   ((PRUNING++))
  ARR_PRUNING[$REPOSERVER]=$PRUNING
  fi

done < $LOGF

cat /dev/null > parse-stats.txt

for SERVER in "${!ARR_SERVER[@]}" ; do
  [[ -z "${ARR_TIMESTAMP_END[$SERVER]}" ]] && ARR_TIMESTAMP_END[$SERVER]=$LOGTIMESTAMP
  [[ -z "${ARR_TIMESTAMP_START[$SERVER]}" ]] && ARR_TIMESTAMP_START[$SERVER]=$LOGTIMESTAMP
  [[ -z "${ARR_DURATION[$SERVER]}" ]] && ARR_DURATION[$SERVER]=0
  [[ -z "${ARR_THIS_ORIG[$SERVER]}" ]] && ARR_THIS_ORIG[$SERVER]=0
  [[ -z "${ARR_THIS_COMPRESSED[$SERVER]}" ]] && ARR_THIS_COMPRESSED[$SERVER]=0
  [[ -z "${ARR_THIS_DEDUPLICATED[$SERVER]}" ]] && ARR_THIS_DEDUPLICATED[$SERVER]=0
  [[ -z "${ARR_ALL_ORIG[$SERVER]}" ]] && ARR_ALL_ORIG[$SERVER]=0
  [[ -z "${ARR_ALL_COMPRESSED[$SERVER]}" ]] && ARR_ALL_COMPRESSED[$SERVER]=0
  [[ -z "${ARR_ALL_DEDUPLICATED[$SERVER]}" ]] && ARR_ALL_DEDUPLICATED[$SERVER]=0
  [[ -z "${ARR_NUMBEROFFILES[$SERVER]}" ]] && ARR_NUMBEROFFILES[$SERVER]=0
  [[ -z "${ARR_CHUNKSUNIQUE[$SERVER]}" ]] && ARR_CHUNKSUNIQUE[$SERVER]=0
  [[ -z "${ARR_CHUNKSTOTAL[$SERVER]}" ]] && ARR_CHUNKSTOTAL[$SERVER]=0
  [[ -z "${ARR_ERRORS[$SERVER]}" ]] && ARR_ERRORS[$SERVER]=1
  [[ -z "${ARR_KEEPING[$SERVER]}" ]] && ARR_KEEPING[$SERVER]=0
  [[ -z "${ARR_PRUNING[$SERVER]}" ]] && ARR_PRUNING[$SERVER]=0

  echo "borgbackup.duration,host=${ARR_SERVER[$SERVER]} value=${ARR_DURATION[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.size.current.original,host=${ARR_SERVER[$SERVER]} value=${ARR_THIS_ORIG[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.size.current.compressed,host=${ARR_SERVER[$SERVER]} value=${ARR_THIS_COMPRESSED[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.size.current.deduplicated,host=${ARR_SERVER[$SERVER]} value=${ARR_THIS_DEDUPLICATED[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.size.total.original,host=${ARR_SERVER[$SERVER]} value=${ARR_ALL_ORIG[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.size.total.compressed,host=${ARR_SERVER[$SERVER]} value=${ARR_ALL_COMPRESSED[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.size.total.deduplicated,host=${ARR_SERVER[$SERVER]} value=${ARR_ALL_DEDUPLICATED[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.numberoffiles,host=${ARR_SERVER[$SERVER]} value=${ARR_NUMBEROFFILES[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.chunks.unique,host=${ARR_SERVER[$SERVER]} value=${ARR_CHUNKSUNIQUE[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.chunks.total,host=${ARR_SERVER[$SERVER]} value=${ARR_CHUNKSTOTAL[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.errors,host=${ARR_SERVER[$SERVER]} value=${ARR_ERRORS[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.cleanup.kept,host=${ARR_SERVER[$SERVER]} value=${ARR_KEEPING[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
  echo "borgbackup.cleanup.pruned,host=${ARR_SERVER[$SERVER]} value=${ARR_PRUNING[$SERVER]} ${ARR_TIMESTAMP_END[$SERVER]}" >> parse-stats.txt
done

echo "Submitting up to: ${ARR_TIMESTAMP_END[$SERVER]}"

/sbin/curl -i -X POST 'http://a.b.c.d:8086/write?db=backups' --data-binary '@parse-stats.txt'
