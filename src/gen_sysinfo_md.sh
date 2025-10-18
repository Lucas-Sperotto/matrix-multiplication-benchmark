#!/usr/bin/env bash
set -euo pipefail

OUT_FILE="${1:-system_info.md}"

# Função utilitária para remover CR do PowerShell
strip_cr() { tr -d '\r'; }

# Detecta WSL e ferramentas disponíveis
IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null || [[ "${WSL_DISTRO_NAME-}" != "" ]]; then
  IS_WSL=1
fi

have() { command -v "$1" >/dev/null 2>&1; }

# Linux/WSL (lado Linux)
KERNEL="$(uname -r)"
DISTRO="$( (lsb_release -d -s 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || echo "N/D") )"
LCPU="$(lscpu 2>/dev/null || echo "N/D")"
CPU_MODEL="$(echo "$LCPU" | awk -F: '/Model name/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CPU_CORES="$(echo "$LCPU" | awk -F: '/^CPU\(s\)/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CPU_THREADS_PER_CORE="$(echo "$LCPU" | awk -F: '/Thread\(s\) per core/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CPU_MAX_MHZ="$(echo "$LCPU" | awk -F: '/CPU max MHz/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"
CPU_MIN_MHZ="$(echo "$LCPU" | awk -F: '/CPU min MHz/ {sub(/^[ \t]+/, "", $2); print $2}' | head -n1)"

# Memória (lado Linux – pode refletir limites do WSL, não o host)
MEM_TOTAL_KB="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
MEM_TOTAL_GB="$(awk -v kb="${MEM_TOTAL_KB:-0}" 'BEGIN { printf("%.2f", kb/1024/1024) }')"

# Tenta coletar informações do host Windows via PowerShell
WIN_CPU_NAME="N/D"
WIN_CPU_CORES="N/D"
WIN_CPU_LOGICAL="N/D"
WIN_CPU_MAX_MHZ="N/D"
WIN_CPU_CURR_MHZ="N/D"
WIN_RAM_GB="N/D"
WIN_OS_VER="N/D"
WSL_STATUS="N/D"

if [[ $IS_WSL -eq 1 ]] && have powershell.exe; then
  # CPU (host)
PS_CPU=$(powershell.exe -NoProfile -Command '
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed
"{0}`t{1}`t{2}`t{3}`t{4}" -f $cpu.Name,$cpu.NumberOfCores,$cpu.NumberOfLogicalProcessors,$cpu.MaxClockSpeed,$cpu.CurrentClockSpeed
' | strip_cr)
IFS=$'\t' read -r WIN_CPU_NAME WIN_CPU_CORES WIN_CPU_LOGICAL WIN_CPU_MAX_MHZ WIN_CPU_CURR_MHZ <<< "$PS_CPU"

# RAM (host)
PS_RAM=$(powershell.exe -NoProfile -Command '
$cs = Get-CimInstance Win32_ComputerSystem
[math]::Round($cs.TotalPhysicalMemory/1GB,2)
' | strip_cr)
WIN_RAM_GB="${PS_RAM:-N/D}"

# Versão do Windows
PS_OS=$(powershell.exe -NoProfile -Command '
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName + " " + (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
' | strip_cr)
WIN_OS_VER="${PS_OS:-N/D}"

# Status do WSL (opcional; deixe como está se já funciona)
PS_WSL=$(powershell.exe -NoProfile -Command 'wsl.exe --status' | strip_cr || true)
WSL_STATUS="${PS_WSL:-N/D}"

fi

# Gera o Markdown
{
  echo "# Informações do Sistema"
  echo
  echo "_Gerado em: $(date '+%Y-%m-%d %H:%M:%S')_"
  echo
  echo "## Ambiente Linux/WSL"
  echo "- **Kernel**: \`${KERNEL}\`"
  echo "- **Distro**: ${DISTRO}"
  echo "- **É WSL?**: $([[ $IS_WSL -eq 1 ]] && echo "Sim" || echo "Não")"
  echo
  echo "### CPU (visão Linux dentro do WSL)"
  echo "- **Modelo**: ${CPU_MODEL:-N/D}"
  echo "- **CPUs lógicas (threads)**: ${CPU_CORES:-N/D}"
  echo "- **Threads por núcleo**: ${CPU_THREADS_PER_CORE:-N/D}"
  echo "- **CPU max MHz**: ${CPU_MAX_MHZ:-N/D}"
  echo "- **CPU min MHz**: ${CPU_MIN_MHZ:-N/D}"
  echo
  echo "### Memória (visão Linux dentro do WSL)"
  echo "- **Memória total visível pelo WSL**: ${MEM_TOTAL_GB} GB"
  echo
  if [[ $IS_WSL -eq 1 ]] && have powershell.exe; then
    echo "## Host Windows (via PowerShell)"
    echo "- **Windows**: ${WIN_OS_VER}"
    echo
    echo "### CPU (host)"
    echo "- **Modelo**: ${WIN_CPU_NAME}"
    echo "- **Núcleos (físicos)**: ${WIN_CPU_CORES}"
    echo "- **Lógicos (threads)**: ${WIN_CPU_LOGICAL}"
    echo "- **Clock Máx (MHz)**: ${WIN_CPU_MAX_MHZ}"
    echo "- **Clock Atual (MHz)**: ${WIN_CPU_CURR_MHZ}"
    echo
    echo "### Memória (host)"
    echo "- **RAM física total**: ${WIN_RAM_GB} GB"
    echo
    echo "### Status do WSL"
    echo '```'
    echo "${WSL_STATUS}"
    echo '```'
  fi

  echo
  echo "## Observações"
  echo "- Em WSL, os números vistos pelo Linux podem refletir **limites da VM** e não os valores físicos reais."
  echo "- Quando possível, este relatório usa PowerShell para exibir dados do **host Windows**, que costumam ser mais fiéis."
} > "$OUT_FILE"

echo "Arquivo gerado: $OUT_FILE"

# ============================
# [NEW] Exportar system_info.json (além do .md)
# ============================

_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//
/\\n}"
  s="${s//
/}"
  echo "$s"
}

_write_system_info_json() {
  # Detecta diretório onde está o MD (usa o mesmo)
  local out_dir="."
  if [[ -n "$SYSTEM_INFO_MD_PATH" ]]; then
    out_dir="$(dirname "$SYSTEM_INFO_MD_PATH")"
  elif [[ -f "./system_info.md" ]]; then
    out_dir="."
  fi
  local out_json="${out_dir}/system_info.json"

  # Coletas portáveis
  local os kernel arch
  os="$(uname -s 2>/dev/null || echo N/D)"
  kernel="$(uname -r 2>/dev/null || echo N/D)"
  arch="$(uname -m 2>/dev/null || echo N/D)"

  local cpu_model cores threads
  cpu_model="$(lscpu 2>/dev/null | awk -F: '/Model name/ {sub(/^ +/,"",$2); print $2}' | head -n1)"
  [[ -z "$cpu_model" ]] && cpu_model="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ //')"
  cores="$(lscpu 2>/dev/null | awk -F: '/^CPU\(s\)/ {gsub(/ /,"",$2); print $2}' | head -n1)"
  threads="$(nproc 2>/dev/null || echo N/D)"

  local mem_total_mb
  mem_total_mb="$(free -m 2>/dev/null | awk '/Mem:/ {print $2}')"
  [[ -z "$mem_total_mb" ]] && mem_total_mb="N/D"

  local gpus
  gpus="$(lspci 2>/dev/null | grep -E 'VGA|3D' | sed 's/^ *//')"
  [[ -z "$gpus" ]] && gpus="N/D"

  local now iso
  now="$(date +"%d/%m/%Y %H:%M:%S")"
  iso="$(date -Iseconds)"

  {
    echo "{"
    echo "  \"datetime\": {\"human\": \"$( _json_escape "$now" )\", \"iso\": \"$( _json_escape "$iso" )\"},"
    echo "  \"os\": \"$( _json_escape "$os" )\","
    echo "  \"kernel\": \"$( _json_escape "$kernel" )\","
    echo "  \"arch\": \"$( _json_escape "$arch" )\","
    echo "  \"cpu\": {"
    echo "    \"model\": \"$( _json_escape "$cpu_model" )\","
    echo "    \"cores_reported\": \"$( _json_escape "$cores" )\","
    echo "    \"threads_nproc\": \"$( _json_escape "$threads" )\""
    echo "  },"
    echo "  \"memory_mb_total\": \"$( _json_escape "$mem_total_mb" )\","
    echo "  \"gpu\": \"$( _json_escape "$gpus" )\""
    echo "}"
  } > "$out_json"

  echo "🧾 system_info.json gerado em: $out_json"
}

# Tente inferir caminho do MD se o script já o escreveu
# Se seu script define explicitamente, set SYSTEM_INFO_MD_PATH antes de chamar esta função.
if [[ -z "$SYSTEM_INFO_MD_PATH" && -f "./system_info.md" ]]; then
  SYSTEM_INFO_MD_PATH="./system_info.md"
fi

_write_system_info_json
