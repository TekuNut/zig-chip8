#!/usr/bin/env sh

set -e

version_lt() {
    if [ "$1" = "$2" ]; then
        return 1
    fi
    printf '%s\n%s' "$1" "$2" | sort -C -V
}

MINISIGN_VERSION="$2"
MINISIGN_URL="https://github.com/jedisct1/minisign/releases/download/${MINISIGN_VERSION}/minisign-${MINISIGN_VERSION}-linux.tar.gz"
MINISIGN_SIGNATURE_URL="https://github.com/jedisct1/minisign/releases/download/${MINISIGN_VERSION}/minisign-${MINISIGN_VERSION}-linux.tar.gz.minisig"
MINISIGN_PUBKEY="RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3"

ZIG_VERSION="$1"
ZLS_VERSION="$(echo "${ZIG_VERSION}" | cut -d. -f1,2).0"

# Tarball naming changed after Zig 0.14.1
if version_lt "${ZIG_VERSION}" "0.14.1"; then
    ZIG_TARBALL_NAME="zig-linux-x86_64-${ZIG_VERSION}"
else
    ZIG_TARBALL_NAME="zig-x86_64-linux-${ZIG_VERSION}"
fi

# ZLS Tarball naming changed after ZLS 0.15.0
if version_lt "${ZLS_VERSION}" "0.15.0"; then
    ZLS_TARBALL_NAME="zls-linux-x86_64-${ZLS_VERSION}"
else
    ZLS_TARBALL_NAME="zls-x86_64-linux-${ZLS_VERSION}"
fi


ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL_NAME}.tar.xz"
ZIG_SIGNATURE_URL="https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL_NAME}.tar.xz.minisig"
ZIG_PUBKEY="RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U"

ZLS_URL="https://builds.zigtools.org/${ZLS_TARBALL_NAME}.tar.xz"
ZLS_SIGNATURE_URL="https://builds.zigtools.org/${ZLS_TARBALL_NAME}.tar.xz.minisig"
ZLS_PUBKEY="RWR+9B91GBZ0zOjh6Lr17+zKf5BoSuFvrx2xSeDE57uIYvnKBGmMjOex"

alias get_file="curl --location --remote-name --no-progress-meter --fail"

mkdir -p "/home/vscode/.local/bin"

get_file "${MINISIGN_URL}"
tar -xzf "minisign-${MINISIGN_VERSION}-linux.tar.gz"
ln -s /home/vscode/minisign-linux/x86_64/minisign /home/vscode/.local/bin/minisign

get_file "${MINISIGN_SIGNATURE_URL}"
minisign -Vm minisign-"${MINISIGN_VERSION}"-linux.tar.gz -P ${MINISIGN_PUBKEY}

get_file "${ZIG_URL}"
get_file "${ZIG_SIGNATURE_URL}"
minisign -Vm "${ZIG_TARBALL_NAME}.tar.xz" -P ${ZIG_PUBKEY}

tar -xf "${ZIG_TARBALL_NAME}.tar.xz"
ln -s "/home/vscode/${ZIG_TARBALL_NAME}/zig" /home/vscode/.local/bin/zig

get_file "${ZLS_URL}"
get_file "${ZLS_SIGNATURE_URL}"
minisign -Vm "${ZLS_TARBALL_NAME}.tar.xz" -P "${ZLS_PUBKEY}"

tar -xf "${ZLS_TARBALL_NAME}.tar.xz"
ln -s "/home/vscode/zls" /home/vscode/.local/bin/zls
