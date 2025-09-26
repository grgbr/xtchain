#!/bin/bash -e

scriptdir=$(dirname $(type -p $0))
. $scriptdir/gpg_common.sh

# Show help
usage() {
	local ret=$1

	cat >&2 <<_EOF
Usage: $(basename $0) [OPTIONS] [SIGFILE] <DATAFILE>

Verify GPG signed data.

With OPTIONS:
  -h|--help              -- this help message
  -d|--homedir <HOMEDIR> -- pathname to GPG home directory

Where:
  SIGFILE  -- pathname to GPG detached signature file.
  DATAFILE -- pathname to GPG signed data file.
_EOF

	exit $ret
}

# Setup shell behavior.
#
# Pipeline return code is the value of the last (rightmost) command to exit with
# a non-zero status.
set -o pipefail
# All sub-shells will inherit the above settings
export SHELLOPTS

gpg_homedir=""

# Check and sanitize command line content
if ! opts=$(getopt \
            --name "$(basename $0)" \
            --options d:h \
            --longoptions homedir:,help \
            -- "$@"); then
	# Something went wrong, getopt will put out an error message for us
	echo
	usage 1
fi
# Replace command line with getopt parsed output
eval set -- "$opts"
# Process command line option arguments now that it has been sanitized by getopt
while [ $# -gt 0 ]; do
	case $1 in
	-d|--homedir) gpg_homedir="$2"; shift 1;;
	-h|--help)    usage 0;;
	--)           shift 1; break;;
	-*)           log "Unrecognized option \'$1\'\n"; usage 1;;
	*)            break;;
	esac

	shift 1
done

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
	log "Invalid number of arguments.\n"
	usage 1
fi

if [ -n "$gpg_homedir" ]; then
	if [ ! -d "$gpg_homedir" ]; then
		log "Invalid GPG home directory: '$gpg_homedir': No such directory."
		exit 1
	fi

	gpg_homedir="--homedir $gpg_homedir"
fi

sig_file=""
data_file=""
if [ $# -eq 2 ]; then
	sig_file="$1"
	if [ ! -f "$sig_file" ]; then
		log "Invalid GPG signature file: '$sig_file': No such file."
		exit 1
	fi

	data_file="$2"
else
	data_file="$1"
fi
if [ ! -r "$data_file" ]; then
	log "Invalid data file: '$data_file': No such file."
	exit 1
fi

gpg_cmd="gpg $gpg_homedir --batch $GPG_KEY_SERVER --quiet --log-file /dev/null"

if ! stat=$($gpg_cmd --status-fd 1 --verify "$sig_file" "$data_file" 2>/dev/null); then
	fpr=$(echo "$stat" | \
	      sed --silent 's/^\[GNUPG:\] NO_PUBKEY[[:blank:]]*//p')
	if [ -z "$fpr" ]; then
		log "Failed to verify GPG signature."
		exit 1
	fi

	log "Importing GNU public GPG key..."
	if ! $gpg_cmd --recv-keys "$fpr" 2>/dev/null; then
		log "Failed to fetch '$fpr' GPG public signing key."
		exit 1
	fi

	log "Marking GPG public key as ultimately trusted..."
	if ! $gpg_cmd --export-ownertrust | \
	     awk -F':' '{ print $1 ":6:" }' | \
	     $gpg_cmd --import-ownertrust; then
		log "Failed to mark GPG public key as ultimately trusted."
		exit 1
	fi

	if ! $gpg_cmd --verify "$sig_file" "$data_file" 2>/dev/null; then
		log "Failed to verify GPG signature."
		exit 1
	fi
fi

log "'$data_file': GPG signature verification successful."
