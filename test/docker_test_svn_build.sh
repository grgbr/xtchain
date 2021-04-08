#!/bin/sh -e

. /tmp/test/docker_test_build.sh

toolchain="$1"
url="$2"

docker_setup_build_test "subversion-tools"

su --login $USER --command "svn checkout $url $HOME/xtchain"

docker_run_mkdebian_build_test "$HOME/xtchain" "$toolchain"
