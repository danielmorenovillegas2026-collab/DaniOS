#!/usr/bin/env bash
# ============================================================
#  Descarga el motor de voz (Vosk) y el modelo español para el
#  asistente de DaniOS. Se ejecuta dentro del contenedor de build.
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

DEST="config/includes.chroot/opt/danios/asistente"
CACHE="cache/asistente"
VENDOR="$DEST/vendor"
MODELO="$DEST/modelo"

WHEEL_URL="https://files.pythonhosted.org/packages/fc/ca/83398cfcd557360a3d7b2d732aee1c5f6999f68618d1645f38d53e14c9ff/vosk-0.3.45-py3-none-manylinux_2_12_x86_64.manylinux2010_x86_64.whl"
WHEEL_SHA="25e025093c4399d7278f543568ed8cc5460ac3a4bf48c23673ace1e25d26619f"
MODELO_URL="https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip"
MODELO_SHA="09b239888f633ef2f0b4e09736e3d9936acfd810bc65d53fad45261762c6511f"

if [ -f "$VENDOR/vosk/__init__.py" ] && [ -f "$MODELO/am/final.mdl" ]; then
    echo "[asistente] motor y modelo ya presentes"
    exit 0
fi

mkdir -p "$CACHE" "$DEST"

descargar() { # url sha destino
    local url="$1" sha="$2" destino="$3"
    if [ -f "$destino" ] && echo "$sha  $destino" | sha256sum -c --status 2>/dev/null; then
        echo "[asistente] reutilizando $(basename "$destino")"
        return 0
    fi
    echo "[asistente] descargando $(basename "$destino")..."
    curl -fL --retry 3 --connect-timeout 20 -o "$destino.part" "$url"
    if ! echo "$sha  $destino.part" | sha256sum -c --status; then
        echo "[asistente] ERROR: la suma de $(basename "$destino") no coincide" >&2
        rm -f "$destino.part"
        exit 1
    fi
    mv -f "$destino.part" "$destino"
}

descargar "$WHEEL_URL" "$WHEEL_SHA" "$CACHE/vosk.whl"
descargar "$MODELO_URL" "$MODELO_SHA" "$CACHE/modelo-es.zip"

echo "[asistente] instalando la librería vosk..."
rm -rf "$VENDOR"
mkdir -p "$VENDOR"
unzip -q -o "$CACHE/vosk.whl" -d "$VENDOR"

echo "[asistente] instalando el modelo de español..."
rm -rf "$MODELO" "$DEST/vosk-model-small-es-0.42"
unzip -q -o "$CACHE/modelo-es.zip" -d "$DEST"
mv "$DEST/vosk-model-small-es-0.42" "$MODELO"

chmod -R a+rX "$DEST"
echo "[asistente] listo: $(du -sh "$DEST" | cut -f1)"
