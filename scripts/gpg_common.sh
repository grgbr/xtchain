# Default keys.openpgp.org server strip UIDs unless the owner of the
# corresponding email address has allowed them to be published.
# This prevents us from importing multiple public keys used to sign software
# packages.
# We might use the MIT key server instead but it is frequently down. Use Ubuntu
# key server for now.
#GPG_KEY_SERVER="--keyserver hkps://keys.openpgp.org"
#GPG_KEY_SERVER="--keyserver hkps://pgp.mit.edu"
GPG_KEY_SERVER="--keyserver keyserver.ubuntu.com"

log()
{
	printf "$(basename $0): $1\n" >&2
}
