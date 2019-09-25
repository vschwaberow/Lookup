#!/bin/bash
#  MacOS version by Volker Schwaberow
# This one loads amass, assetfinder, finddomains and struggles to get one unique
# domain list.

CLEAR='\033[0m'
RED='\033[0;31m'

usage() {
if [ -n "$1" ]; then
echo -e "${RED}👉 $1${CLEAR}\n";
fi
echo "Usage: $0 [-d domainname] [-h] "
echo "  -d, --domain             Domainname to recon"
echo ""
echo "Example: $0 --domain example.com"
exit 1
}


exit_script() {
    echo "[!] Script exited. Trying to delete temp files"
    trap - SIGINT SIGTERM
    if [ -f "$tempfile1".txt ]; then
        rm "$tempfile1"*
    fi
    if [ -f "$tempfile2".txt ]; then
        rm "$tempfile2"*
    fi
    if [ -f "$tempfile3" ]; then
        rm "$tempfile3"*
    fi
    if [ -f "$DOMAIN".txt ]; then
        rm "$DOMAIN".txt
    fi
    kill -- -$$
}

domain=$1

# parse params
if [ "$#" = 0 ]; then
    usage
fi

while [[ "$#" > 0 ]]; do case $1 in
  -d|--domain) DOMAIN="$2"; shift;shift;;
  -h|--http-probe) HTTP_PROBE=1;shift;;
  -p|--passive) PASSIVE=1;shift;;
  -v|--verbose) VERBOSE=1;shift;;
*) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

tempfile1=$(mktemp)
tempfile2=$(mktemp)
tempfile3=$(mktemp)


AMASS=$(which amass) || { echo >&2 "I require amass but it's not installed.  Aborting."; exit 1; }
ASSETFINDER=$(which assetfinder) || { echo >&2 "I require assetfinder but it's not installed.  Aborting."; exit 1; }
FINDOMAIN=$(which findomain-osx.dms) || { echo >&2 "I require findomain but it's not installed.  Aborting."; exit 1; }
CURL=$(which curl) || { echo >&2 "I require curl but it's not installed.  Aborting."; exit 1; }


trap exit_script SIGINT SIGTERM

echo "[I] Starting passive scan with amass"
MERGED="$DOMAIN"_dom
$AMASS enum -passive -d $DOMAIN -oA $tempfile1
cat "$tempfile1".txt >> "$DOMAIN"_dom
rm "$tempfile1"*


if [ "$PASSIVE" = 0]; then
    echo "[I] Starting active scan with amass"
    $AMASS enum -active -d $DOMAIN -oA $tempfile2
    cat "$tempfile2".txt >> "$DOMAIN"_dom
    rm "$tempfile2"*
else
    echo "[I] Skipping active scan with amass"
fi

echo "[I] Starting passive scan with assetfinder"
$ASSETFINDER $DOMAIN | tee $tempfile3
cat $tempfile3 >> "$DOMAIN"_dom
rm $tempfile3

echo "[I] Starting passive scan with findomain"
$FINDOMAIN -t $DOMAIN -o
cat "$DOMAIN".txt >> "$DOMAIN"_dom
rm "$DOMAIN".txt
cat "$DOMAIN"_dom | sort -u --version-sort | tee "$DOMAIN"_dom


