#!/bin/bash
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

set -e

if [ "$1" == "-h" -o "$1" == "--help" ]; then
echo "usage: git-commit-audit.sh [-h|--help] [Git URL]" >&2
echo "See statistics on git commits for a code repository." >&2
echo "  -h, --help  Display this usage guide." >&2
echo "  -o, --output Outputs to markdown." >&2
echo "  Git URL  If you provide an optional url path (via https) to a remote git repository" >&2
echo "  Example: git-commit-audit.sh https://github.com/CycloneDX/cyclonedx-python" >&2
echo
exit 0
fi

if [ "$1" == "-o" -o "$1" == "--output" ]; then
echo "Sending data to file."

exit 0
fi


if [[ -n $1 ]]; then
        if [[ ! -d ./git-commit-audit-temp-dir ]]; then mkdir ./git-commit-audit-temp-dir;fi
        git clone "$1" ./git-commit-audit-temp-dir && echo "Git Clone was a success" && export clonesuccess="1"
        if [[ $clonesuccess = "1" ]]; then
                cd ./git-commit-audit-temp-dir
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
UNKNOWNSIGS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "E" || $4 == "X" || $4 == "Y" || $4 == "U" || $4 == "R"){print $1;} }' | wc -l | xargs)
DEVNAMES=$(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u)

PERCENT=$(bc <<< "scale=4; ($GOODSIGS/$NUMBERCOMMITS) * 100")
PERCENTOTHER=$(bc <<< "scale=4; ($UNKNOWNSIGS/$NUMBERCOMMITS) * 100")
PERCENTBAD=$(bc <<< "scale=4; ($NOSIGS/$NUMBERCOMMITS) * 100")
echo
echo "====================================================="
echo -e "Total commits: $NUMBERCOMMITS | ${grn}Verified signed commits:$GOODSIGS${end} | ${yel}Un-verified signed commits: $UNKNOWNSIGS${end} | ${red}Bad or Un-signed commits: $NOSIGS${end}" # | tr ',' '\t'
echo "====================================================="
echo "${grn}Percentage of commits that have been VERIFIED signed = $PERCENT %${end}"
echo "${yel}Percentage of commits that have been signed but not verifed = $PERCENTOTHER %${end}"
echo "${red}Percentage of commits that have not been signed or are bad = $PERCENTBAD %${end}"
echo "Total number of Developers who have commited is $(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u|wc -l|xargs)"
echo "====================================================="
echo
echo "Individual Developer Commit Statistics:"
DEVARRAY=$(echo "$GITARY" | awk -F '|' '{print $2;}'|sort -u|sed "s/\ /_/g")
echo "$DEVARRAY" > ./tempfile
echo "${blu}Name: ${end}$DEVCOMMITNUMBER, ${grn}Verified${end}, ${yel}Un-verified:${end}, ${red}Bad/Un-signed:${end}" | awk -F',' '{ printf "%-35s %-20s %-30s %-20s\n", $1, $2, $3, $4}'
for devname in $(<tempfile); do
if [[ -n $devname ]]; then
                devname2=$(echo $devname | sed "s/\_/ /g")
                DEVCOMMITNUMBER=$(echo "$GITARY" | grep -ic "$devname2" | xargs)
                DEVGOODCOMMITS=$(echo "$GITARY" | grep -i "$devname2" | awk -F '|' '{ if($4 == "G"){print $1,$2,$3,$4;} }' | wc -l | xargs)
                DEVBADCOMMITS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "N" || $4 == "B"){print $1,$2,$3,$4;} }' | grep -ic "$devname2" | xargs)
                DEVUNKNOWNSIGS=$(echo "$GITARY" | awk -F '|' '{ if($4 == "E" || $4 == "X" || $4 == "Y" || $4 == "U" || $4 == "R"){print $1,$2,$3,$4;} } ' | grep -ic "$devname2" | xargs)
                echo "${blu}$devname2, ${grn}$DEVGOODCOMMITS, ${yel}$DEVUNKNOWNSIGS, ${red}$DEVBADCOMMITS${end}"| awk -F',' '{ printf "%-35s %-20s %-20s %-20s\n", $1, $2, $3, $4}'
        fi
done

if [[ $clonesuccess = "1" ]]; then cd ../; rm -rf ./git-commit-audit-temp-dir/;fi
