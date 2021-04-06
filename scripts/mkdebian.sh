#!/bin/sh -e

show_make_var()
{
	local var="$1"

	make --silent \
	     --no-builtin-rules \
	     --no-builtin-variables \
	     --directory $top_dir \
	     showvar-$var
}

# Simply log a message to stderr
log()
{
	printf "$(basename $0): $*" >&2
}

# Show help
usage() {
	local ret=$1

	cat >&2 <<_EOF
Usage: $(basename $0) [OPTIONS] <FLAVOUR> [BUILDDIR]

Build Debian package for the specified toolchain.

With OPTIONS:
  -h|--help -- This message.

Where:
  FLAVOUR  -- toolchain to build package for.
  BUILDDIR -- pathname to root of output directory hierarchy to generate content
              into
_EOF

	exit $ret
}

# Check and sanitize command line content
if ! options=$(getopt \
               --name "$(basename $0)" \
               --options h \
               --longoptions help \
               -- "$@"); then
	# Something went wrong, getopt will put out an error message for us
	echo
	usage 1
fi
# Replace command line with getopt parsed output
eval set -- "$options"
# Process command line option arguments now that it has been sanitized by getopt
while [ $# -gt 0 ]; do
	case $1 in
	-h|--help)  usage 0;;
	--)         shift 1; break;;
	-*)         log "unrecognized option '$1'\n\n"; usage 1;;
	*)          break;;
	esac

	shift 1
done

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
	log "invalid number of arguments.\n\n"
	usage 1
fi

top_dir=$(realpath --canonicalize-existing $(dirname $0)/..)

flavour="$1"
if ! show_make_var "flavours" | grep --quiet --word-regexp "$flavour"; then
	log "unknown toolchain '$flavour' specified.\n"
	exit 1
fi

if [ $# -eq 2 ]; then
	builddir="$2"
else
	builddir=$(show_make_var "BUILDDIR")
fi

version=$(show_make_var "VERSION")
major=$(echo "$version" | sed -n 's/^\([0-9]\+\)\..*/\1/p')
min=$(echo "$version" | sed -n 's/^[0-9]\+\.//p')
arch=$(dpkg --print-architecture)
debian_path=$builddir/$flavour/debian

make --silent \
     --directory $top_dir \
     clean-$flavour \
     BUILDDIR:="$builddir"

make --directory $top_dir \
     install-$flavour \
     PREFIX:="/opt/xtchain-$major" \
     BUILDDIR:="$builddir" \
     DESTDIR:="$debian_path"

mkdir -p $debian_path/DEBIAN
cat > $debian_path/DEBIAN/control <<_EOF
Package: xtchain-$flavour-$major
Version: $version
Section: devel
Priority: optional
Architecture: $arch
Maintainer: ComEth maintainer <cometh@ic.fr>
Description: $flavour cross compiling toolchain
_EOF

exec dpkg-deb --root-owner-group --build "$debian_path" "$builddir"
