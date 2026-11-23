#!/usr/bin/env bash
# ============================================================
#  DaniOS — descarga el binario de opencode y lo deja en la ISO.
#  Versión: la última de la rama 1.x (o OPENCODE_VERSION=1.2.3)
# ============================================================
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."

VER="${OPENCODE_VERSION:-latest}"
ARCH="${OPENCODE_ARCH:-x64}"

if [ "$VER" = "latest" ]; then
    URL="https://github.com/sst/opencode/releases/latest/download/opencode-linux-${ARCH}.tar.gz"
else
    URL="https://github.com/sst/opencode/releases/download/v${VER#v}/opencode-linux-${ARCH}.tar.gz"
fi

DEST="config/includes.chroot/usr/local/bin"
mkdir -p "$DEST"

TMP="$(mktemp -d /tmp/danios-opencode.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo "[opencode] descargando $URL"
curl -fL --retry 3 --retry-delay 2 -o "$TMP/opencode.tar.gz" "$URL"
tar -xzf "$TMP/opencode.tar.gz" -C "$TMP"

install -m 0755 "$TMP/opencode" "$DEST/opencode"

echo -n "[opencode] versión instalada: "
"$DEST/opencode" --version 2>/dev/null || echo "(no se pudo comprobar)"
