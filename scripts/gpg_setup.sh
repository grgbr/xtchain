#!/bin/bash -e

# Official GNU public keyring.
GNU_KEYRING_URL="https://ftp.gnu.org/gnu/gnu-keyring.gpg"

# Pablo Galindo Salgado GPG public key for 3.10.x and 3.11.x source files and
# tags (fingerprint: 64E628F8D684696D)
# See https://www.python.org/downloads/, section 'OpenPGP Public Keys'.
PYTHON_SRC_KEY_URL="https://keybase.io/pablogsal/pgp_keys.asc"

# Karel Zak GPG public key for util-linux source releases
# (fingerprint E4B71D5EEC39C284)
# For more infos about kernel developpers GPG key ring, see
# https://korg.docs.kernel.org/pgpkeys.html
UTIL_LINUX_SRC_KEY_URL="https://git.kernel.org/pub/scm/docs/kernel/pgpkeys.git/plain/keys/E4B71D5EEC39C284.asc"

# Daniel Stenberg GPG public key for curl source releases
# For more infos about Curl GPG key ring, see
# https://daniel.haxx.se/address.html
CURL_SRC_KEY_URL="https://daniel.haxx.se/mykey.asc"

scriptdir=$(dirname $(type -p $0))
. $scriptdir/gpg_common.sh

gpg_fetch_import_key()
{
	local name="$1"
	local url="$2"

	log "Downloading ${name}..."
	if ! curl --silent --output $keyring "$url"; then
		log "Failed to download ${name}."
		return 1
	fi

	log "Importing ${name}..."
	if ! $gpg_cmd $GPG_KEY_SERVER --import $keyring; then
		log "Failed to import ${name}."
		return 1
	fi

	return 0
}

# Show help
usage() {
	local ret=$1

	cat >&2 <<_EOF
Usage: $(basename $0) [OPTIONS] <FETCHDIR>

Setup local GPG keyring for verifying downloaded source distributions
authenticity.

With OPTIONS:
  -h|--help -- this help message

Where:
  FETCHDIR  -- pathname to fetch directory.
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

# Check and sanitize command line content
if ! opts=$(getopt \
            --name "$(basename $0)" \
            --options h \
            --longoptions help \
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
	-h|--help)    usage 0;;
	--)           shift 1; break;;
	-*)           log "Unrecognized option \'$1\'\n"; usage 1;;
	*)            break;;
	esac

	shift 1
done

if [ $# -ne 1 ]; then
	log "Invalid number of arguments.\n"
	usage 1
fi

fetchdir="$1"
if [ ! -d "$fetchdir" ]; then
	log "Invalid fetching directory: '$fetchdir': No such directory."
	exit 1
fi

lock="$(realpath --canonicalize-missing $fetchdir/$(basename $0).lock)"
keyring="$(realpath --canonicalize-missing $fetchdir/keyring.gpg)"
gpg_homedir="$(realpath --canonicalize-missing $fetchdir/.gnupg)"
gpg_cmd="gpg --homedir $gpg_homedir --batch --quiet"

exec 200<>$lock
if ! flock --nonblock --exclusive 200; then
	log "'$lock': Failed to acquire lock: is another instance running ?"
	exit 1
fi

trap "trap '' INT QUIT TERM HUP EXIT; rm -f $keyring $lock" EXIT

log "Downloading GNU public GPG keyring..."
if ! curl --silent --output $keyring "$GNU_KEYRING_URL"; then
	log "Failed to download GNU public GPG keyring."
	exit 1
fi

log "Importing GNU public GPG keyring..."
if ! $gpg_cmd $GPG_KEY_SERVER --import $keyring; then
	log "Failed to import GNU public GPG keyring."
	exit 1
fi

if ! gpg_fetch_import_key "Python source releases GPG public key" \
                          "$PYTHON_SRC_KEY_URL"; then
	exit 1
fi

if ! gpg_fetch_import_key "Util-linux source releases GPG public key" \
                          "$UTIL_LINUX_SRC_KEY_URL"; then
	exit 1
fi

if ! gpg_fetch_import_key "Curl source releases GPG public key" \
                          "$CURL_SRC_KEY_URL"; then
	exit 1
fi

log "Refreshing GNU public GPG keyring..."
if ! $gpg_cmd $GPG_KEY_SERVER --refresh-keys; then
	log "Failed to refresh GNU public GPG keyring."
	exit 1
fi

log "Marking GNU public GPG keys as ultimately trusted..."
if ! $gpg_cmd --export-ownertrust | \
     awk -F':' '{ print $1 ":6:" }' | \
     $gpg_cmd --import-ownertrust; then
	log "Failed to mark GNU public GPG keys as ultimately trusted."
	exit 1
fi

log "Local GPG keyring setup successfully."
