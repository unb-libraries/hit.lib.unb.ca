#!/usr/bin/env bash
# Builds the Drupal theme assets (custom/themes/*/dist) before the image build.
#
# Called by deployment-workflow.yaml through github-workflows' pre-build-command, which runs
# once in each platform job, on GitHub-hosted amd64 and arm64 Ubuntu 24.04 runners. Installs
# what dockworker's theme:build-all needs, then runs it.
set -euo pipefail

SASS_VERSION=1.62.1

# The distribution's PHP (dockworker needs 8.3+) plus the extensions it requires; ext-yaml is
# not on the stock runner image. Unversioned packages, because the amd64 and arm64 runners can
# be on different Ubuntu releases (ubuntu-latest is 26.04; ubuntu-24.04-arm is 24.04).
sudo apt-get update -q
sudo apt-get install -y -q --no-install-recommends \
    php-cli php-curl php-gd php-mbstring php-xml php-yaml php-zip unzip
if ! command -v composer >/dev/null; then
    sudo apt-get install -y -q --no-install-recommends composer
fi
php --version
composer --version

case "$(uname -m)" in
    x86_64) sass_arch=x64 ;;
    aarch64) sass_arch=arm64 ;;
    *) echo "::error title=Unsupported runner::No Dart Sass build for $(uname -m)."; exit 1 ;;
esac
curl -fsSL "https://github.com/sass/dart-sass/releases/download/$SASS_VERSION/dart-sass-$SASS_VERSION-linux-$sass_arch.tar.gz" \
    | tar -xz -C "$RUNNER_TEMP"

composer install --prefer-dist --no-progress

# dockworker requires a TTY; script(1) provides one.
SASS_PATH="$RUNNER_TEMP/dart-sass/sass" script -q -e -c "vendor/bin/dockworker theme:build-all"

# Fail if the build produced nothing, rather than shipping an unstyled image.
ls custom/themes/*/dist/css/*.css
