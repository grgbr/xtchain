#!/bin/sh -e

. /tmp/test/docker_test_build.sh

toolchain="$1"
tarball="$2"

docker_setup_build_test

su --login $USER --command "mkdir -p $HOME/xtchain"
su --login $USER --command "tar --directory $HOME/xtchain -xvf $2"

docker_run_mkdebian_build_test "$HOME/xtchain" "$toolchain"
