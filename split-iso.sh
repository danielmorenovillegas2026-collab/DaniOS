#!/usr/bin/env bash
# ============================================================
#  Divide una ISO en partes de menos de 2 GiB (límite de GitHub
#  Releases) y genera las sumas de verificación y unir.sh.
#
#  Uso:
#    ./scripts/split-iso.sh out/danios-amd-amd64.hybrid.iso
#    ./scripts/split-iso.sh out/danios-nvidia-amd64.hybrid.iso
#    PART_MB=1800 ./scripts/split-iso.sh
#
#  Se puede ejecutar varias veces: cada ISO añade sus partes a
#  dist/ sin borrar las de la otra edición.
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

ISO="${1:-out/danios-amd-amd64.hybrid.iso}"
DEST="${2:-dist}"
PART_MB="${PART_MB:-1900}"

[ -f "$ISO" ] || { echo "ERROR: no existe $ISO" >&2; exit 1; }

BASE="$(basename "$ISO")"
mkdir -p "$DEST"

# Limpia solo los archivos de esta ISO (no toca la otra edición)
rm -f "$DEST/$BASE".part[0-9]* "$DEST/$BASE.parts.sha256" "$DEST/$BASE.sha256"

echo ">> Dividiendo $ISO en partes de ${PART_MB} MiB..."
split -b "${PART_MB}M" -d -a 1 --numeric-suffixes=1 "$ISO" "$DEST/$BASE.part"

echo ">> Generando sumas SHA-256..."
( cd "$DEST" && sha256sum "$BASE".part[0-9]* > "$BASE.parts.sha256" )
sha256sum "$ISO" > "$DEST/$BASE.sha256"

cat > "$DEST/unir.sh" <<'EOF'
#!/bin/sh
# Une las partes de una ISO de DaniOS y comprueba su SHA-256.
# Uso: ./unir.sh danios-amd-amd64.hybrid.iso
set -e
BASE="${1:-}"
if [ -z "$BASE" ]; then
    echo "Uso: $0 <nombre-de-la-iso>"
    echo "ISOs disponibles en esta carpeta:"
    ls *.part1 2>/dev/null | sed 's/\.part1$//' || true
    exit 1
fi
cat "$BASE".part* > "$BASE"
sha256sum -c "$BASE.sha256"
echo "Listo: $BASE"
EOF
chmod +x "$DEST/unir.sh"

echo
ls -lh "$DEST"
echo
echo ">> Listo. Sube los archivos de $DEST/ como assets del release."
echo "   SHA-256: $(cut -d' ' -f1 "$DEST/$BASE.sha256")"
