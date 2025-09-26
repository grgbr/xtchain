#!/bin/bash -e

wordsize()
{
	local cc="$1"
	
	echo '#include <limits.h>' | \
		$cc -dM -E - | \
		sed -n 's/^#define[[:space:]]\+__WORDSIZE[[:space:]]\+//p'
}

if [ $# -eq 0 ]; then
	CC=cc
else
	CC="$*"
fi

set -o pipefail
if ! bits=$(wordsize "$CC"); then
	echo "Failed to detect machine word size !" >&2
	exit 1
fi

echo $bits
