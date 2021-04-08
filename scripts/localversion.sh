#!/bin/sh

MAJOR="1"
MINOR="0"
VERSION="${MAJOR}.${MINOR}-rc1"

usage() {
	echo "Usage: $(basename $0) [srctree]" >&2
	exit 1
}

svn_tag()
{
	local relurl="$1"

	echo "$relurl" | sed -n 's;^\^/tags/\([^/]\+\).*;\1;p'
}

svn_dirty()
{
	local path="$1"
	local stat

	if ! stat=$(env LANG= LC_ALL= LC_MESSAGES=C \
	            svn --non-interactive status "$path"); then
		return 1
	fi

	if [ -n "$stat" ]; then
		echo -n "dirty"
	fi

	return 0
}

svn_mixed()
{
	local path="$1"
	local ref="$2"
	local rev;
	local _dummy_;

	env LANG= LC_ALL= LC_MESSAGES=C \
	svn --non-interactive info --recursive "$path" 2>/dev/null | \
	sed --quiet 's;^Revision:[ \t]*;;p' | \
	while read rev; do
		if [ "$rev" != "$ref" ]; then
			echo -n "+"
			return 0
		fi
	done

	return 0
}

svn_is_top()
{
	local relurl="$1"
	local nr

	nr=$(echo "$relurl" | \
	     sed -n 's/^\^\/trunk/trunk/;s/^\^\/branches\///;s/^\^\/tags\///;s/[/]\+/ /;p' | \
	     wc -w)
	if [ "$nr" != "1" ]; then
		return 1
	fi

	return 0
}

svn_version()
{
	local dir="$1"
	local name="$VERSION"
	local relurl
	local tag
	local rev
	local mixed
	local dirty

	if ! relurl=$(env LANG= LC_ALL= LC_MESSAGES=C \
	              svn --non-interactive info "$dir" 2>/dev/null | \
	              sed --quiet 's;^Relative URL:[ \t]*;;p'); then
		return 1
	fi
	if ! svn_is_top "$relurl"; then
		return 1
	fi

	tag=$(svn_tag "$relurl")
	rev=$(env LANG= LC_ALL= LC_MESSAGES=C \
	      svn --non-interactive info "$dir" 2>/dev/null | \
	      sed --quiet 's;^Revision:[ \t]*;;p')

	if [ "$tag" != "$VERSION" ]; then
		name="${name}~s${rev}"
	fi

	mixed=$(svn_mixed "$dir" "$rev")
	name="${name}${mixed}"

	dirty=$(svn_dirty "$dir")
	if [ -n "$dirty" ]; then
		name="${name}~${dirty}"
	fi

	echo -n "${name}"

	return 0
}

git_exact_tag()
{
	git describe --tags --exact-match 2>/dev/null
}

git_sha()
{
	git rev-parse --quiet --verify --short HEAD
}

git_dirty()
{
	# Check for uncommitted changes.
	if git --no-optional-locks status -uno --porcelain 2>/dev/null | \
	   grep -qE '^.. '; then
		echo -n "dirty"
	fi
}

git_version()
{
	local tag
	local name="$VERSION"

	if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
		return 1
	fi

	tag=$(git_exact_tag)
	if [ "$tag" != "$VERSION" ]; then
		name="${name}~g$(git_sha)"
	fi

	dirty=$(git_dirty)
	if [ -n "$dirty" ]; then
		name="${name}~${dirty}"
	fi

	echo -n "${name}"

	return 0
}

scm_version()
{
	if git_version; then
		return
	fi

	if svn_version "."; then
		return
	fi

	echo -n "$VERSION"
}

srctree=.
if test $# -gt 0; then
	srctree=$1
	shift
fi
if test $# -gt 0 -o ! -d "$srctree"; then
	usage
fi

cd "$srctree"
if ! scm_version; then
	echo "$(basename $0): Unsupported version control system" >&2
fi
