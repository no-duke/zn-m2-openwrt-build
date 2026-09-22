#!/bin/bash
#
# Check if upstream Passwall packages have new commits
# Output: should_build (true/false) and latest_pkg_sha
#

set -euo pipefail

# Get latest SHA from upstream passwall packages
LATEST_SHA=$(gh api repos/Openwrt-Passwall/openwrt-passwall-packages/commits/main --jq .sha)
echo "latest_pkg_sha=$LATEST_SHA" >> $GITHUB_OUTPUT

# Check cache
if [ -f "/tmp/passwall-cache/packages-sha" ]; then
    CACHED_SHA=$(cat /tmp/passwall-cache/packages-sha)
    if [ "$LATEST_SHA" = "$CACHED_SHA" ]; then
        echo "No new commits since last build"
        echo "should_build=false" >> $GITHUB_OUTPUT
        exit 0
    fi
fi

echo "New upstream changes detected"
echo "should_build=true" >> $GITHUB_OUTPUT
