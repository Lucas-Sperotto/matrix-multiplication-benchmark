#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-.}"
mkdir -p "$OUT_DIR"

MD="$OUT_DIR/system_info.md"
JSON="$OUT_DIR/system_info.json"

strip_cr() { sed 's/\r$//' ; }

pretty_bytes() {
  local kb=$1
  if [[ -z "$kb" || "$kb" == "0" ]]; then echo "N/D"; return; fi
  local mb=$(( kb / 1024 ))
  local gb=$(( mb / 1024 ))
  if (( gb > 0 )); then echo "${gb} GB"; elif (( mb > 0 )); then echo "${mb} MB"; else echo "${kb} KB"; fi
}

# --------- Coletas Linux/WSL ----------
OS="$(uname -s || true)"
KERNEL="$(uname -r || true)"
ARCH="$(uname -m || true)"
HOST="$(hostname || true)"

CPU_MODEL="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ //')"
[[ -z "$CPU_MODEL" ]] && CPU_MODEL="$(lscpu 2>/dev/null | awk -F: '/Model name/ {sub(/^ /,"",$2); print $2}' | head -n1)"
CPU_CORES="$(lscpu 2>/dev/null | awk -F: '/^CPU\(s\):/ {gsub(/ /,"",$2); print $2}' | head -n1)"
CPU_THREADS="$CPU_CORES"  # fallback; pode ser refinado com lscpu -p e contagem

MEM_KB="$(grep -m1 MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')"
MEM_HUMAN="$(pretty_bytes "$MEM_KB")"

GPU_DESC=""
if command -v nvidia-smi >/dev/null 2>&1; then
  GPU_DESC="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | paste -sd ', ' -)"
fi
if [[ -z "$GPU_DESC" ]] && command -v lspci >/dev/null 2>&1; then
  GPU_DESC="$(lspci 2>/dev/null | grep -i ' vga ' -i -e '3d controller' | sed 's/^.*: //; s/(rev .*//; s/Controller//I' | paste -sd ', ' -)"
fi
[[ -z "$GPU_DESC" ]] && GPU_DESC="N/D"

# --------- Versões de toolchain ----------
GCC_VER="$(gcc --version 2>/dev/null | head -n1 || true)"
GPP_VER="$(g++ --version 2>/dev/null | head -n1 || true)"
JAVA_VER="$(java -version 2>&1 | head -n1 || true)"
PY_VER="$(python3 --version 2>/dev/null || true)"

# --------- Data/hora ----------
NOW_HUMAN="$(date +"%d/%m/%Y %H:%M:%S")"
NOW_ISO="$(date -Iseconds)"

# --------- Git (opcional) ----------
GIT_COMMIT="N/D"
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo "N/D")"
fi

# --------- MD ----------
{
  echo "# System Info"
  echo
  echo "**Data:** $NOW_HUMAN  \`$NOW_ISO\`  "
  echo "**Host:** $HOST  "
  echo "**OS:** $OS  "
  echo "**Kernel:** $KERNEL  "
  echo "**Arch:** $ARCH  "
  echo
  echo "## CPU"
  echo "- Modelo: $CPU_MODEL"
  echo "- Núcleos (lógicos): ${CPU_THREADS:-N/D}"
  echo
  echo "## Memória"
  echo "- Total: ${MEM_HUMAN:-N/D}"
  echo
  echo "## GPU"
  echo "- Descrição: $GPU_DESC"
  echo
  echo "## Ferramentas"
  echo "- gcc: ${GCC_VER:-N/D}"
  echo "- g++: ${GPP_VER:-N/D}"
  echo "- Java: ${JAVA_VER:-N/D}"
  echo "- Python: ${PY_VER:-N/D}"
  echo
  echo "## Git"
  echo "- Commit: \`$GIT_COMMIT\`"
} > "$MD"

# --------- JSON ----------
json_escape() {
  local s=${1//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s"
}

{
  printf '{'
  printf '"datetime":"%s",'   "$(json_escape "$NOW_HUMAN")"
  printf '"datetime_iso":"%s",' "$(json_escape "$NOW_ISO")"
  printf '"host":"%s",'       "$(json_escape "$HOST")"
  printf '"os":"%s",'         "$(json_escape "$OS")"
  printf '"kernel":"%s",'     "$(json_escape "$KERNEL")"
  printf '"arch":"%s",'       "$(json_escape "$ARCH")"
  printf '"cpu_model":"%s",'  "$(json_escape "$CPU_MODEL")"
  printf '"cpu_threads":"%s",' "$(json_escape "${CPU_THREADS:-N/D}")"
  printf '"mem_total_kb":"%s",' "$(json_escape "${MEM_KB:-0}")"
  printf '"mem_total_human":"%s",' "$(json_escape "$MEM_HUMAN")"
  printf '"gpu":"%s",'        "$(json_escape "$GPU_DESC")"
  printf '"gcc":"%s",'        "$(json_escape "$GCC_VER")"
  printf '"gpp":"%s",'        "$(json_escape "$GPP_VER")"
  printf '"java":"%s",'       "$(json_escape "$JAVA_VER")"
  printf '"python":"%s",'     "$(json_escape "$PY_VER")"
  printf '"git_commit":"%s"'  "$(json_escape "$GIT_COMMIT")"
  printf '}'
} > "$JSON"

echo "📝 Gerado: $MD"
echo "🧾 Gerado: $JSON"

