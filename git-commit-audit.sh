#!/bin/bash

set -e

  if [ "$1" == "-h" -o "$1" == "--help" ]; then
    echo "usage: commit-check [-h|--help] [options]" >&2
    echo "Show long refs for all unsigned/unverified git commits in the current tree." >&2
    echo "  -h, --help  Display this usage guide." >&2
    echo "  options     Options to be passed to the invocation of git log." >&2
    return 1
  fi
  
  if [[ -z $2 ]]; then
	git clone $2 ./git-commit-audit-temp-dir && export clonesuccess="1"
	if [[ $clonesuccess = "1" ]]; then 
		cd ./git-commit-audit-temp-dir
	elif [[ $clonesuccess != "1" ]]; then 
		echo "Git Clone did not work" && exit 1
	fi
  fi

  GITARY=$(git log --pretty='format:%H|%aN|%s|%G?' $@)
  
  # check if there are any commits in git
  if [[ -z $GITARY ]]; then echo "No commits found.  Exiting... "; exit 1; fi

  NUMBERCOMMITS=$(echo "$GITARY" | wc -l | xargs)
  BADCOMMITS=$(echo "$GITARY" | awk -F '|' '{ if($4 != "G"){print $1;} }' | wc -l | xargs)
  GOODCOMMITS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "G"){print $1;} }' | wc -l | xargs)
  DEVNAMES=$(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u)

  if [[ $BADCOMMITS -gt $GOODCOMMITS ]]; then 
	PERCENT=$(bc <<< "scale=4; ($GOODCOMMITS/$BADCOMMITS ) * 100")
  elif [[ $BADCOMMITS -lt $GOODCOMMITS ]]; then 
	PERCENT=$(bc <<< "scale=4; ($BADCOMMITS/$GOODCOMMITS ) * 100")
  fi
  echo "Total commits: $NUMBERCOMMITS | Signed commits: $GOODCOMMITS | Un-signed commits: $BADCOMMITS"
  echo "Percentage of commits that have been signed = $PERCENT %"
  echo "Total number of Developers who have commited is $(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u|wc -l|xargs)"
  echo "====================================================="
  echo
  echo "Individual Developer Commit Statistics:"
  DEVARRAY=$(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u|sed "s/\ /_/g")
  echo "$DEVARRAY" > ./tempfile
  for devname in $(<tempfile); do
        if [[ -n $devname ]]; then
		devname2=$(echo $devname | sed "s/\_/ /g")
		DEVCOMMITNUMBER=$(echo "$GITARY" | grep -i "$devname2" | wc -l | xargs)
		DEVGOODCOMMITS=$(echo "$GITARY" | grep -i "$devname2" | awk -F '|' '{ if($4 == "G"){print $1,$2,$3,$4;} }' | wc -l | xargs)
		DEVBADCOMMITS=$(echo "$GITARY" | awk -F '|' '{ if($4 != "G"){print $1,$2,$3,$4;} }' | grep -i "$devname2" | wc -l | xargs)
		echo "$devname2 = Total commits: $DEVCOMMITNUMBER | Signed commits: $DEVGOODCOMMITS | Un-signed commits: $DEVBADCOMMITS"
	fi
  done

  if [[ $clonesuccess = "1" ]]; then cd ../; rm -rf ./git-commit-audit-temp-dir/;fi

