#!/usr/bin/env bash
# ==============================================================================
# Script de instalación para ma-proton
# ==============================================================================

set -e

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"

echo "=========================================================="
echo "          Instalador de ma-proton para macOS              "
echo "=========================================================="

mkdir -p "${BIN_DIR}"

TARGET_LINK="${BIN_DIR}/ma-proton"
ln -sf "${SOURCE_DIR}/bin/ma-proton" "${TARGET_LINK}"
chmod +x "${SOURCE_DIR}/bin/ma-proton"

echo "[+] Enlace creado en: ${TARGET_LINK}"

# Verificar si ~/.local/bin está en el PATH
if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo "[!] Nota: Asegúrate de tener ~/.local/bin en tu PATH en ~/.zshrc:"
    echo '    export PATH="${HOME}/.local/bin:${PATH}"'
fi

echo ""
echo "[*] Ejecutando autodiagnóstico inicial..."
"${TARGET_LINK}" status

echo ""
echo "[✓] ma-proton se ha instalado correctamente."
echo "    Uso básico: ma-proton run <juego.exe>"
echo "    Ver ayuda:  ma-proton --help"
