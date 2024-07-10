#!/usr/bin/env bash

VSCODE_VERSION="${VERSION:-"latest"}"

set -e

if [ "$(id -u)" -ne 0 ]; then
	echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi

ARCH="$(uname -m)"
if [ "${ARCH}" == "x86_64" ] ; then
	if [ -f "/lib/ld-musl-x86_64.so.1" ] ; then
		ARCH="linux-alpine"
	else
		ARCH="linux-x64"
	fi
elif [ "${ARCH}" == "aarch64" ] || [ "${ARCH}" == "arm64" ]; then
	if [ -f "/lib/ld-musl-aarch64.so.1" ] ; then
		ARCH="alpine-arm64"
	else
		ARCH="linux-arm64"
	fi
elif [ "${ARCH}" == "arm" ]; then
	ARCH="linux-armhf"
else
	echo -e "unsupported arch: ${ARCH}"
	exit 1
fi

DOWNLOAD_URL_ROOT="https://update.code.visualstudio.com/${VSCODE_VERSION}"

# remove existing installations
rm -f /home/vscode/.vscode-server


curl -sL ${DOWNLOAD_URL_ROOT}/server-${ARCH}/stable/ -o /tmp/vscode-server.tgz
curl -sL ${DOWNLOAD_URL_ROOT}/cli-${ARCH}/stable/ -o /tmp/vscode-cli.tgz
pushd /tmp && tar xf vscode-server.tgz && tar xf vscode-cli.tgz && popd

# get hash
if [ "${VERSION}" == "latest" ] ; then
  HASH=$(/tmp/vscode-server-${ARCH}/bin/code-server -v | head -2 | tail -1)
else
  HASH=$(echo $VERSION | cut -d ':' -f 2)
fi

echo ${HASH} > /home/vscode/.vscode-server-hash
mkdir -p /home/vscode/.vscode-server/cli/servers/Stable-${HASH}/server
cp -r /tmp/vscode-server-${ARCH}/* /home/vscode/.vscode-server/cli/servers/Stable-${HASH}/server/
cp /tmp/code /home/vscode/.vscode-server/code-${HASH}
chown -R vscode:vscode /home/vscode

rm -rf /tmp/vscode-server-${ARCH}
rm /tmp/code
rm /tmp/vscode-server.tgz
rm /tmp/vscode-cli.tgz

echo "Done!"
