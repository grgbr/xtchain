#!/bin/sh -e

. /tmp/test/docker_test_build.sh

toolchain="$1"
url="$2"
branch="$3"

docker_setup_build_test "git"

if [ -n "$branch" ]; then
	su --login $USER --command "git clone -b $branch $url $HOME/xtchain"
else
	su --login $USER --command "git clone $url $HOME/xtchain"
fi

docker_run_mkdebian_build_test "$HOME/xtchain" "$toolchain"
