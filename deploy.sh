#!/bin/bash
# Deploy hugo site to master branch
#
# Assumes you are on a branch called 'source' for storing the
# source and buildling. Builds and pushes to 'master' branch.
#
# Joshua Powers <mrpowersj@gmail.com>
#
# Source: https://powersj.io/post/github-hugo/

set -ux

BRANCH_CURRENT=$(git rev-parse --abbrev-ref HEAD)
BRANCH_MASTER="master"
BRANCH_SOURCE="source"
BUILD_DIR="build"
GIT_REMOTE="origin"
GIT_REMOTE_URL=$(git remote get-url --push "$GIT_REMOTE")

cleanup() {
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
}

error() {
    echo "$@" 1>&2
}

fail() {
    [ $# -eq 0 ] || error "$@"
    exit 1
}

if [ "$BRANCH_CURRENT" != "$BRANCH_SOURCE" ]; then
    fail "Not on source branch"
fi

echo "Updating git submodules"
git submodule init || fail "submodule init failed"
git submodule update || fail "submodule update failed"

echo "Building site"
cleanup
hugo --destination "$BUILD_DIR" || fail "Build failed"
pushd "$BUILD_DIR" || fail "could not change to build dir"

echo "Creating git commit"
git init
git remote add "$GIT_REMOTE" "$GIT_REMOTE_URL"
git checkout --orphan "$BRANCH_MASTER"
git add .
git commit -m "Site updated at $(date -u "+%Y-%m-%d %H:%M:%S") UTC"

echo "Publishing site"
git push --force "$GIT_REMOTE" "$BRANCH_MASTER"

popd
cleanup
