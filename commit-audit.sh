#!/bin/bash
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

#set -e


for argument in "$@" 
do 
	if [ "$1" == "-h" -o "$1" == "--help" ]; then
	echo "usage: commit-audit.sh [ -h | -d | -c | -r ] [Git URL]" >&2
	echo "See statistics on git commits for a code repository." >&2
	echo "  -h,  Display this usage guide." >&2
	#echo "  -o,  Outputs to markdown." >&2
	echo "  -d,  Provide git commit statistics about individual developers." >&2
	echo "  -c,  Display report in CSV format.  This is good for mass scanning of repos." >&2
	echo "  -r,  Use a remote git repository." >&2
	echo "  Git URL  If you provide an optional url path (via https) to a remote git repository" >&2
	echo "  Example: commit-audit.sh -d -r https://github.com/CycloneDX/cyclonedx-python" >&2
	echo
	exit 0
	elif [[ $argument == "-d" ]]; then 
		export DEVSTATS="1"; 
	elif [[ $argument == "-r" ]]; then 
		export REMOTEGIT="1"; 
	elif [[ $argument == "-c" ]]; then 
		export CSV="1"; 
	fi
	echo $argument | grep -qi '.git' && export GITEXT="1"
	echo $argument | grep -qi 'https://' && export HTTPPRE="1"
	echo $argument | grep -qi 'http://' && export HTTPPRE="1" && export NOENCRYPTION="1"
	if [[ $GITEXT == "1" ]] && [[ $HTTPPRE = "1" ]]; then 
		export GITTARGET="$argument";
	fi
done

# exit 1 if DEVSTATS and CSV are both 1
if [[ $DEVSTATS == "1" ]] && [[ $CSV == "1" ]]; then
	echo "ERROR: Can't use -d and -c together.  Choose ONE and start again!"
	exit 1
fi


#if [[ $REMOTEGIT == "1" ]] && [[ $CSV != "1" ]]; then
if [[ $REMOTEGIT == "1" ]]; then
        if [[ ! -d ./git-commit-audit-temp-dir ]]; then mkdir ./git-commit-audit-temp-dir;fi
        git clone $GITTARGET ./git-commit-audit-temp-dir > /dev/null 2>&1 && export clonesuccess="1"
        if [[ $clonesuccess = "1" ]]; then
                cd ./git-commit-audit-temp-dir
		if [[ $CSV != "1" ]]; then echo;fi
		if [[ $CSV != "1" ]]; then echo "${mag}ATTENTION: Remote Git repos will never show as ${grn}VERIFIED${mag} unless you import their keys.${end}";fi
        elif [[ $clonesuccess != "1" ]]; then
                echo "Git Clone did not work.  Exiting.... "
                exit 1
        fi
fi

GITARY=$(git log --pretty='format:%H|%aN|%s|%G?')

# check if there are any commits in git
if [[ -z $GITARY ]]; then echo "No commits found.  Exiting... "; exit 1; fi

NUMBERCOMMITS=$(echo "$GITARY" | wc -l | xargs)
GOODSIGS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "G"){print $1;} }' | wc -l | xargs)
NOSIGS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "N" || $4 == "B"){print $1;} }' | wc -l | xargs)
UNKNOWNSIGS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "E" || $4 == "U"){print $1;} }' | wc -l | xargs)
EXPIREDSIGS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "X" || $4 == "Y" || $4 == "R"){print $1;} }' | wc -l | xargs)
DEVNAMES=$(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u)

PERCENT=$(bc <<< "scale=4; ($GOODSIGS/$NUMBERCOMMITS) * 100" | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
PERCENTOTHER=$(bc <<< "scale=4; ($UNKNOWNSIGS/$NUMBERCOMMITS) * 100" | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
PERCENTEXPIRED=$(bc <<< "scale=4; ($EXPIREDSIGS/$NUMBERCOMMITS) * 100" | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
PERCENTBAD=$(bc <<< "scale=4; ($NOSIGS/$NUMBERCOMMITS) * 100" | sed '/\./ s/\.\{0,1\}0\{1,\}$//')


if [[ $CSV == "1" ]] && [[ $REMOTEGIT == "1" ]]; then
	echo "TARGET=\"$GITTARGET\",VERIFIED=$PERCENT,UN-VERIFIED=$PERCENTOTHER,EXPIRED/REVOKED=$PERCENTEXPIRED,BAD=$PERCENTBAD"	
	# Clean up local repos
	if [[ $clonesuccess = "1" ]]; then cd ../; rm -rf ./git-commit-audit-temp-dir/;fi
	exit 0
elif [[ $CSV == "1" ]] && [[ $REMOTEGIT != "1" ]]; then
	echo "Must provide remote GIT url.  Exiting...  "
	exit 1
fi

echo 
echo "Total number of Developers who have commited is $(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u|wc -l|xargs)"
echo "STATUS , ${grn}VERIFIED, ${cyn}UN-VERIFIED:, ${yel}EXPIRED/REVOKED:, ${red}BAD/UN-SIGNED:${end}" | awk -F',' '{ printf "%-25s %-20s %-20s %-20s %-20s\n", $1, $2, $3, $4, $5}'
echo "Total Commits: , ${grn}$GOODSIGS, ${cyn}$UNKNOWNSIGS, ${yel}$EXPIREDSIGS, ${red}$NOSIGS${end}" | awk -F',' '{ printf "%-25s %-20s %-20s %-24s %-20s\n", $1, $2, $3, $4, $5}'
echo "Percentages: , ${grn}$PERCENT, ${cyn}$PERCENTOTHER, ${yel}$PERCENTEXPIRED, ${red}$PERCENTBAD${end}" | awk -F',' '{ printf "%-25s %-20s %-20s %-24s %-20s\n", $1, $2, $3, $4, $5}'
echo 

if [[ $DEVSTATS == "1" ]] && [[ $CSV != "1" ]]; then 
	echo "Individual Developer Commit Statistics:"
	DEVARRAY=$(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u|sed "s/\ /_/g")
	echo "$DEVARRAY" > ./tempfile
	echo "${blu}NAME: ${end}$DEVCOMMITNUMBER, ${grn}VERIFIED, ${cyn}UN-VERIFIED:, ${yel}EXPIRED/REVOKED:, ${red}BAD/UN-SIGNED:${end}" | awk -F',' '{ printf "%-36s %-20s %-20s %-20s %-20s\n", $1, $2, $3, $4, $5}'
	for devname in $(<tempfile); do
		if [[ -n $devname ]]; then
                	devname2=$(echo $devname | sed "s/\_/ /g")
                	DEVCOMMITNUMBER=$(echo "$GITARY" | grep -ic "$devname2" | xargs)
                	DEVGOODCOMMITS=$(echo "$GITARY" | grep -i "$devname2" | awk -F '|' '{ if($4 == "G"){print $1,$2,$3,$4;} }' | wc -l | xargs)
                	DEVEXPIREDCOMMITS=$(echo "$GITARY" | grep -i "$devname2" | awk -F '|' '{ if($4 == "X" || $4 == "Y"){print $1,$2,$3,$4;} }' | wc -l | xargs)
                	DEVBADCOMMITS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "N" || $4 == "B"){print $1,$2,$3,$4;} }' | grep -ic "$devname2" | xargs)
                	DEVUNKNOWNSIGS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "E" || $4 == "U" || $4 == "R"){print $1,$2,$3,$4;} } ' | grep -ic "$devname2" | xargs)
                	echo "${blu}$devname2, ${grn}$DEVGOODCOMMITS, ${cyn}$DEVUNKNOWNSIGS, ${yel}$DEVEXPIREDCOMMITS, ${red}$DEVBADCOMMITS${end}"| awk -F',' '{ printf "%-32s %-20s %-20s %-24s %-20s\n", $1, $2, $3, $4, $5}'
        	fi
	done
fi

# Clean up local repos
if [[ $clonesuccess = "1" ]]; then cd ../; rm -rf ./git-commit-audit-temp-dir/;fi

# this is the correct sed to remove any number of trailing zeros:
# sed 's/\.*00*$//'
# other possibility: '/\./ s/\.\{0,1\}0\{1,\}$//'

BOOM!
