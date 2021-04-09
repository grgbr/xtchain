#!/bin/bash -e

show_make_var()
{
	local var="$1"

	make --silent \
	     --no-builtin-rules \
	     --no-builtin-variables \
	     --directory $top_dir \
	     showvar-$var
}

git_is_url_ok()
{
	local url="$1"
	local repo=$(echo "$url" | sed -n 's/#.*$//p')
	local branch=$(echo "$url" | sed -n 's/^[^#]\+[#]*//p')

	git ls-remote --quiet \
	              --exit-code \
	              "$repo" \
	              "$branch" >/dev/null 2>&1
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
Usage: $(basename $0) [OPTIONS] <FLAVOUR> <DOCKER_IMAGE>

Run the specified FLAVOUR toolchain build test from within DOCKER_IMAGE docker
image.

With OPTIONS:
  -g|--git GIT_URL -- Fetch xtchain source tree using the remote git tree
                      located at GIT_URL.
  -s|--svn SVN_URL -- Fetch xtchain source tree using the remote svn tree
                      located at SVN_URL.
  -h|--help        -- This message.

Where:
  FLAVOUR      -- toolchain to run a build test for.
  DOCKER_IMAGE -- Base docker OS image from which to run the build test
                  (See https://hub.docker.com/_/ubuntu for example images).
  GIT_URL      -- Git URL to versioned xtchain source tree according to the
                  following format: <GIT_REPO_URL>[#<BRANCH|TAG|SHA>]
  SVN_URL      -- Subversion URL to versioned xtchain source tree.
_EOF

	exit $ret
}

# Check and sanitize command line content
if ! options=$(getopt \
               --name "$(basename $0)" \
               --options s:g:h \
               --longoptions svn:,git:,help \
               -- "$@"); then
	# Something went wrong, getopt will put out an error message for us
	echo
	usage 1
fi
# Replace command line with getopt parsed output
eval set -- "$options"
# Process command line option arguments now that it has been sanitized by getopt
scm=
url=
while [ $# -gt 0 ]; do
	case $1 in
	-h|--help)  usage 0;;
	-s|--svn)   scm="svn"; url="$2"; shift 1;;
	-g|--git)   scm="git"; url="$2"; shift 1;;
	--)         shift 1; break;;
	-*)         log "unrecognized option '$1'\n\n"; usage 1;;
	*)          break;;
	esac

	shift 1
done

if [ $# -ne 2 ]; then
	log "invalid number of arguments.\n\n"
	usage 1
fi

toolchain="$1"
image="$2"

top_dir=$(realpath --canonicalize-existing $(dirname $0)/..)

docker_cmd="docker run --rm"
if tty --silent; then
	docker_cmd="$docker_cmd --tty --interactive"
fi

if [ "$scm" = "git" ]; then
	repo=$(echo "$url" | sed -n 's/#.*$//;p')
	branch=$(echo "$url" | sed -n 's/^[^#]\+[#]*//p')

	if [ -n "$branch" ]; then
		if git ls-remote --quiet \
		                 --exit-code \
		                 "$repo" \
		                 "$branch" >/dev/null 2>&1; then
			exec $docker_cmd --volume $top_dir/test:/tmp/test \
			                 "$image" \
			                 /tmp/test/docker_test_git_build.sh \
			                 "$toolchain" \
			                 "$repo" \
			                 "$branch"
		fi
	else
		if git ls-remote --quiet \
		                 --exit-code \
		                 "$repo" >/dev/null 2>&1; then
			exec $docker_cmd --volume $top_dir/test:/tmp/test \
			                 "$image" \
			                 /tmp/test/docker_test_git_build.sh \
			                 "$toolchain" \
			                 "$repo"
		fi
	fi

	log "'$url': invalid git URL.\n"
	exit 1
elif [ "$scm" = "svn" ]; then
	if ! svn info $url >/dev/null 2>&1; then
		log "'$url': invalid Subversion URL.\n"
		exit 1
	fi

	exec $docker_cmd --volume $top_dir/test:/tmp/test \
	                 "$image" \
	                 /tmp/test/docker_test_svn_build.sh "$toolchain" "$url"
else
	outdir=$(show_make_var "BUILDDIR")/$toolchain

	mkdir -p $outdir
	tar --exclude-vcs \
	    --exclude='./out*' \
	    --exclude='./.*.swp' \
	    --exclude='./*~' \
	    --directory="$top_dir" \
	    -cvzf $outdir/xtchain.tar.gz \
	    .

	exec $docker_cmd --volume $top_dir/test:/tmp/test \
	                 --volume $outdir:/tmp/src \
	                 "$image" \
	                 /tmp/test/docker_test_tar_build.sh \
	                 "$toolchain" \
	                 "/tmp/src/xtchain.tar.gz"
fi
