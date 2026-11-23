#!/usr/bin/env bash
# ============================================================
#  Arranca la ISO de DaniOS en QEMU para probarla.
#  Uso: ./scripts/test-qemu.sh [--uefi] [opciones extra de qemu]
# ============================================================
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."

ISO="out/danios-amd64.hybrid.iso"
if [ ! -f "$ISO" ]; then
    ISO="$(ls -1 out/*.iso 2>/dev/null | head -1 || true)"
fi
if [ -z "${ISO:-}" ] || [ ! -f "$ISO" ]; then
    echo "ERROR: no encuentro la ISO. Ejecuta primero ./build.sh" >&2
    exit 1
fi

UEFI=0
ARGS=()
for a in "$@"; do
    if [ "$a" = "--uefi" ]; then
        UEFI=1
    else
        ARGS+=("$a")
    fi
done

command -v qemu-system-x86_64 >/dev/null 2>&1 || {
    echo "ERROR: falta qemu-system-x86_64." >&2
    echo "  Bazzite: rpm-ostree install qemu-system-x86 qemu-kvm" >&2
    echo "  Debian:  sudo apt install qemu-system-x86 ovmf" >&2
    exit 1
}

ACCEL=()
if [ -w /dev/kvm ]; then
    ACCEL=(-enable-kvm -cpu host)
else
    echo "AVISO: /dev/kvm no disponible; usaré emulación por software (lento)." >&2
    echo "       Añade tu usuario al grupo kvm o ejecuta con permisos." >&2
    ACCEL=(-cpu max)
fi

BIOS=()
if [ "$UEFI" = 1 ]; then
    OVMF_CODE=""
    for c in \
        /usr/share/edk2/ovmf/OVMF_CODE.fd \
        /usr/share/edk2/ovmf/OVMF_CODE.secboot.fd \
        /usr/share/OVMF/OVMF_CODE.fd \
        /usr/share/ovmf/OVMF_CODE.fd; do
        if [ -f "$c" ]; then OVMF_CODE="$c"; break; fi
    done
    if [ -z "$OVMF_CODE" ]; then
        echo "ERROR: no encuentro OVMF. Instala 'edk2-ovmf' (Fedora) u 'ovmf' (Debian)." >&2
        exit 1
    fi
    OVMF_VARS_SRC="$(dirname "$OVMF_CODE")/OVMF_VARS.fd"
    [ -f "$OVMF_VARS_SRC" ] || OVMF_VARS_SRC="$(dirname "$OVMF_CODE")/OVMF_VARS.secboot.fd"
    OVMF_VARS="$(mktemp /tmp/danios-OVMF_VARS.XXXXXX.fd)"
    cp "$OVMF_VARS_SRC" "$OVMF_VARS"
    BIOS=(
        -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
        -drive "if=pflash,format=raw,file=$OVMF_VARS"
    )
    echo "UEFI: $OVMF_CODE"
fi

echo "ISO: $ISO"
echo "QEMU: ${ACCEL[*]}"

exec qemu-system-x86_64 \
    -m 4096 \
    -smp 2 \
    "${ACCEL[@]}" \
    "${BIOS[@]}" \
    -cdrom "$ISO" \
    -boot d \
    -vga virtio \
    -display gtk,gl=on \
    -device virtio-net-pci,netdev=n0 \
    -netdev user,id=n0 \
    -device qemu-xhci \
    -device usb-tablet \
    "${ARGS[@]}"
