#!/usr/bin/env bash
set -euo pipefail

OUT_MD="${1:-system_info.md}"
OUT_JSON="${2:-${OUT_MD%.md}.json}"
GENERATED_AT="$(date -Iseconds)"

mkdir -p "$(dirname "$OUT_MD")" "$(dirname "$OUT_JSON")"

strip_cr() { tr -d '\r'; }
have() { command -v "$1" >/dev/null 2>&1; }
can_use_powershell() {
  [[ $IS_WSL -eq 1 ]] &&
    have powershell.exe &&
    powershell.exe -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' >/dev/null 2>&1
}

IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null || [[ "${WSL_DISTRO_NAME-}" != "" ]]; then
  IS_WSL=1
fi

KERNEL="$(uname -r 2>/dev/null || echo "N/D")"
DISTRO="$(lsb_release -d -s 2>/dev/null || awk -F= '/^PRETTY_NAME=/ {gsub(/"/, "", $2); print $2}' /etc/os-release 2>/dev/null || echo "N/D")"
LCPU="$(lscpu 2>/dev/null || echo "N/D")"
CPU_MODEL="$(echo "$LCPU" | awk -F: '/Model name/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CPU_LOGICAL="$(echo "$LCPU" | awk -F: '/^CPU\(s\)/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CPU_THREADS_PER_CORE="$(echo "$LCPU" | awk -F: '/Thread\(s\) per core/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CPU_CORES_PER_SOCKET="$(echo "$LCPU" | awk -F: '/Core\(s\) per socket/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CPU_MAX_MHZ="$(echo "$LCPU" | awk -F: '/CPU max MHz/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CPU_MIN_MHZ="$(echo "$LCPU" | awk -F: '/CPU min MHz/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CACHE_L1="$(echo "$LCPU" | awk -F: '/L1d cache/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CACHE_L2="$(echo "$LCPU" | awk -F: '/L2 cache/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CACHE_L3="$(echo "$LCPU" | awk -F: '/L3 cache/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"

MEM_TOTAL_KB="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
MEM_TOTAL_GB="$(awk -v kb="${MEM_TOTAL_KB:-0}" 'BEGIN { printf("%.2f", kb/1024/1024) }')"

GPU_INFO="N/D"
if have nvidia-smi; then
  GPU_INFO="$(nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null | paste -sd ';' - || echo "N/D")"
elif have lspci; then
  GPU_INFO="$(lspci 2>/dev/null | awk '/VGA|3D|Display/ {$1=""; sub(/^ /, ""); print}' | paste -sd ';' - || echo "N/D")"
fi

WIN_CPU_NAME="N/D"
WIN_CPU_CORES="N/D"
WIN_CPU_LOGICAL="N/D"
WIN_CPU_MAX_MHZ="N/D"
WIN_CPU_CURR_MHZ="N/D"
WIN_RAM_GB="N/D"
WIN_OS_VER="N/D"
WSL_STATUS="N/D"
HAS_POWERSHELL=0

if can_use_powershell; then
  HAS_POWERSHELL=1
  PS_CPU="$(powershell.exe -NoProfile -Command '
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed
"{0}`t{1}`t{2}`t{3}`t{4}" -f $cpu.Name,$cpu.NumberOfCores,$cpu.NumberOfLogicalProcessors,$cpu.MaxClockSpeed,$cpu.CurrentClockSpeed
' 2>/dev/null | strip_cr || true)"
  IFS=$'\t' read -r WIN_CPU_NAME WIN_CPU_CORES WIN_CPU_LOGICAL WIN_CPU_MAX_MHZ WIN_CPU_CURR_MHZ <<< "$PS_CPU"

  WIN_RAM_GB="$(powershell.exe -NoProfile -Command '$cs = Get-CimInstance Win32_ComputerSystem; [math]::Round($cs.TotalPhysicalMemory/1GB,2)' 2>/dev/null | strip_cr || echo "N/D")"
  WIN_OS_VER="$(powershell.exe -NoProfile -Command '(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName + " " + (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion' 2>/dev/null | strip_cr || echo "N/D")"
  WSL_STATUS="$(powershell.exe -NoProfile -Command 'wsl.exe --status' 2>/dev/null | strip_cr || echo "N/D")"
fi

{
  echo "# Informações do Sistema"
  echo
  echo "_Gerado em: ${GENERATED_AT}_"
  echo
  echo "## Ambiente Linux/WSL"
  echo "- **Kernel**: \`${KERNEL}\`"
  echo "- **Distro**: ${DISTRO}"
  echo "- **É WSL?**: $([[ $IS_WSL -eq 1 ]] && echo "Sim" || echo "Não")"
  echo
  echo "### CPU"
  echo "- **Modelo**: ${CPU_MODEL:-N/D}"
  echo "- **CPUs lógicas**: ${CPU_LOGICAL:-N/D}"
  echo "- **Threads por núcleo**: ${CPU_THREADS_PER_CORE:-N/D}"
  echo "- **Núcleos por socket**: ${CPU_CORES_PER_SOCKET:-N/D}"
  echo "- **CPU max MHz**: ${CPU_MAX_MHZ:-N/D}"
  echo "- **CPU min MHz**: ${CPU_MIN_MHZ:-N/D}"
  echo "- **Cache L1d**: ${CACHE_L1:-N/D}"
  echo "- **Cache L2**: ${CACHE_L2:-N/D}"
  echo "- **Cache L3**: ${CACHE_L3:-N/D}"
  echo
  echo "### Memória"
  echo "- **Memória total visível**: ${MEM_TOTAL_GB} GB"
  echo
  echo "### GPU"
  echo "- **GPU detectada**: ${GPU_INFO:-N/D}"
  echo
  if [[ $HAS_POWERSHELL -eq 1 ]]; then
    echo "## Host Windows"
    echo "- **Windows**: ${WIN_OS_VER:-N/D}"
    echo "- **CPU**: ${WIN_CPU_NAME:-N/D}"
    echo "- **Núcleos físicos**: ${WIN_CPU_CORES:-N/D}"
    echo "- **Threads lógicas**: ${WIN_CPU_LOGICAL:-N/D}"
    echo "- **Clock máximo MHz**: ${WIN_CPU_MAX_MHZ:-N/D}"
    echo "- **Clock atual MHz**: ${WIN_CPU_CURR_MHZ:-N/D}"
    echo "- **RAM física total**: ${WIN_RAM_GB:-N/D} GB"
    echo
    echo "### WSL --status"
    echo '```'
    echo "${WSL_STATUS:-N/D}"
    echo '```'
  fi
  echo
  echo "## Observações"
  echo "- Em WSL, os números vistos pelo Linux podem refletir limites da VM."
  echo "- Quando possível, este relatório usa PowerShell para incluir dados do host Windows."
} > "$OUT_MD"

export GENERATED_AT KERNEL DISTRO IS_WSL CPU_MODEL CPU_LOGICAL CPU_THREADS_PER_CORE
export CPU_CORES_PER_SOCKET CPU_MAX_MHZ CPU_MIN_MHZ CACHE_L1 CACHE_L2 CACHE_L3
export MEM_TOTAL_KB MEM_TOTAL_GB GPU_INFO WIN_CPU_NAME WIN_CPU_CORES WIN_CPU_LOGICAL
export WIN_CPU_MAX_MHZ WIN_CPU_CURR_MHZ WIN_RAM_GB WIN_OS_VER WSL_STATUS

python3 - "$OUT_JSON" <<'PY'
import json
import os
import sys

def env(name: str) -> str:
    return os.environ.get(name, "N/D")

data = {
    "generated_at": env("GENERATED_AT"),
    "linux": {
        "kernel": env("KERNEL"),
        "distro": env("DISTRO"),
        "is_wsl": env("IS_WSL") == "1",
        "cpu": {
            "model": env("CPU_MODEL"),
            "logical_cpus": env("CPU_LOGICAL"),
            "threads_per_core": env("CPU_THREADS_PER_CORE"),
            "cores_per_socket": env("CPU_CORES_PER_SOCKET"),
            "max_mhz": env("CPU_MAX_MHZ"),
            "min_mhz": env("CPU_MIN_MHZ"),
            "cache_l1d": env("CACHE_L1"),
            "cache_l2": env("CACHE_L2"),
            "cache_l3": env("CACHE_L3"),
        },
        "memory": {
            "total_kb": env("MEM_TOTAL_KB"),
            "total_gb": env("MEM_TOTAL_GB"),
        },
        "gpu": env("GPU_INFO"),
    },
    "windows_host": {
        "os": env("WIN_OS_VER"),
        "cpu": env("WIN_CPU_NAME"),
        "physical_cores": env("WIN_CPU_CORES"),
        "logical_processors": env("WIN_CPU_LOGICAL"),
        "max_mhz": env("WIN_CPU_MAX_MHZ"),
        "current_mhz": env("WIN_CPU_CURR_MHZ"),
        "ram_gb": env("WIN_RAM_GB"),
        "wsl_status": env("WSL_STATUS"),
    },
}

with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

echo "Arquivos gerados: $OUT_MD e $OUT_JSON"
