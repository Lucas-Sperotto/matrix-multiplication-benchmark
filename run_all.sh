#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BATCH=0
RUN_NAME=""
B=""
NPTS=""
M_COUNT=""
ESCALA=""

usage() {
  cat <<'EOF'
Uso:
  ./run_all.sh
  ./run_all.sh --batch --run-name <id> --B <max> --Npts <pontos> --M <repeticoes> --escala <0|1>

Escala:
  0 = logaritmica
  1 = linear
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --batch)
      BATCH=1
      shift
      ;;
    --run-name)
      RUN_NAME="${2:-}"
      shift 2
      ;;
    --B|--b)
      B="${2:-}"
      shift 2
      ;;
    --Npts|--npts)
      NPTS="${2:-}"
      shift 2
      ;;
    --M|--m)
      M_COUNT="${2:-}"
      shift 2
      ;;
    --escala)
      ESCALA="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argumento desconhecido: $1" >&2
      usage
      exit 1
      ;;
  esac
done

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Dependencia ausente: $cmd" >&2
    echo "Instale as dependencias conforme EXECUTION.md e tente novamente." >&2
    exit 1
  fi
}

validate_int() {
  local name="$1"
  local value="$2"
  local min="$3"
  local max="$4"

  if [[ ! "$value" =~ ^[0-9]+$ ]] || (( value < min || value > max )); then
    echo "Parametro invalido para $name: $value" >&2
    exit 1
  fi
}

check_python_runtime() {
  local mpl_cache="$ROOT_DIR/.cache/matplotlib"
  mkdir -p "$mpl_cache"
  MPLCONFIGDIR="$mpl_cache" python3 - <<'PY'
try:
    import matplotlib  # noqa: F401
except Exception as exc:
    raise SystemExit(
        "Dependencia Python ausente ou quebrada: matplotlib. "
        "Instale com: python3 -m pip install -r requirements.txt\n"
        f"Detalhe: {exc}"
    )
PY
}

if [[ "$BATCH" -eq 0 ]]; then
  read -r -p "Digite o nome da execucao (ENTER para timestamp): " RUN_NAME
  read -r -p "Digite o tamanho maximo de matriz (B): " B
  read -r -p "Escolha a escala [0]=Logaritmica, [1]=Linear: " ESCALA
  read -r -p "Digite o numero de pontos na escala (Npts): " NPTS
  read -r -p "Digite a quantidade de repeticoes para media (M): " M_COUNT
fi

if [[ -z "$RUN_NAME" ]]; then
  RUN_NAME="$(date '+%Y%m%d_%H%M%S')"
fi

if [[ -z "$B" || -z "$NPTS" || -z "$M_COUNT" || -z "$ESCALA" ]]; then
  echo "Parametros obrigatorios ausentes." >&2
  usage
  exit 1
fi

validate_int "B" "$B" 100 100000
validate_int "Npts" "$NPTS" 2 10000
validate_int "M" "$M_COUNT" 1 100000
validate_int "escala" "$ESCALA" 0 1

need_cmd gcc
need_cmd g++
need_cmd javac
need_cmd java
need_cmd python3
check_python_runtime

OUT_DIR="out/$RUN_NAME"
BUILD_LINUX="build/linux"
BUILD_JAVA="build/java"
mkdir -p "$OUT_DIR" "$BUILD_LINUX" "$BUILD_JAVA"

echo "Resultados serao salvos em $OUT_DIR"
echo "Artefatos de compilacao em build/"
echo "-----------------------------------"

echo "Compilando C..."
gcc src/matriz_c.c -o "$BUILD_LINUX/matriz_c" -lm
gcc src/matriz_c.c -o "$BUILD_LINUX/matriz_c_O3" -lm -O3

echo "Compilando C++..."
g++ src/matriz_cpp.cpp -o "$BUILD_LINUX/matriz_cpp"
g++ src/matriz_cpp.cpp -o "$BUILD_LINUX/matriz_cpp_O3" -O3

echo "Compilando Java..."
javac -d "$BUILD_JAVA" src/matriz_java.java

echo "Executando C..."
"$BUILD_LINUX/matriz_c" "$B" "$NPTS" "$M_COUNT" "$ESCALA" "$OUT_DIR/resultado_c.csv"

echo "Executando C -O3..."
"$BUILD_LINUX/matriz_c_O3" "$B" "$NPTS" "$M_COUNT" "$ESCALA" "$OUT_DIR/resultado_c_O3.csv"

echo "Executando C++..."
"$BUILD_LINUX/matriz_cpp" "$B" "$NPTS" "$M_COUNT" "$ESCALA" "$OUT_DIR/resultado_cpp.csv"

echo "Executando C++ -O3..."
"$BUILD_LINUX/matriz_cpp_O3" "$B" "$NPTS" "$M_COUNT" "$ESCALA" "$OUT_DIR/resultado_cpp_O3.csv"

echo "Executando Java..."
java -cp "$BUILD_JAVA" matriz_java "$B" "$NPTS" "$M_COUNT" "$ESCALA" "$OUT_DIR/resultado_java.csv"

echo "Executando Python..."
python3 src/matriz_python.py "$B" "$NPTS" "$M_COUNT" "$ESCALA" "$OUT_DIR/resultado_python.csv"

echo "Capturando informacoes de sistema..."
bash scripts/gen_sysinfo_md.sh "$OUT_DIR/system_info.md" "$OUT_DIR/system_info.json"

export RUN_ID="$RUN_NAME"
export PARAM_B="$B"
export PARAM_NPTS="$NPTS"
export PARAM_M="$M_COUNT"
export PARAM_ESCALA="$ESCALA"
export MANIFEST_PATH="$OUT_DIR/run_manifest.json"

python3 - <<'PY'
import json
import os
import platform
import subprocess
from datetime import datetime, timezone

def run(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True).strip()
    except Exception:
        return "N/D"

data = {
    "run_id": os.environ["RUN_ID"],
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "commit_hash": run(["git", "rev-parse", "HEAD"]),
    "system": {
        "platform": platform.platform(),
        "machine": platform.machine(),
        "python": platform.python_version(),
    },
    "parameters": {
        "B": int(os.environ["PARAM_B"]),
        "Npts": int(os.environ["PARAM_NPTS"]),
        "M": int(os.environ["PARAM_M"]),
        "escala": int(os.environ["PARAM_ESCALA"]),
    },
    "tools": {
        "gcc": run(["gcc", "--version"]).splitlines()[0],
        "g++": run(["g++", "--version"]).splitlines()[0],
        "java": run(["java", "-version"]).splitlines()[0],
        "javac": run(["javac", "-version"]),
        "python": run(["python3", "--version"]),
    },
    "languages": [
        {"name": "C", "flags": "", "output": "resultado_c.csv"},
        {"name": "C", "flags": "-O3", "output": "resultado_c_O3.csv"},
        {"name": "C++", "flags": "", "output": "resultado_cpp.csv"},
        {"name": "C++", "flags": "-O3", "output": "resultado_cpp_O3.csv"},
        {"name": "Java", "flags": "", "output": "resultado_java.csv"},
        {"name": "Python", "flags": "", "output": "resultado_python.csv"},
    ],
}

with open(os.environ["MANIFEST_PATH"], "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

echo "Gerando graficos..."
python3 src/plot_benchmarks.py "$OUT_DIR"

echo "Validando execucao..."
python3 scripts/validate_run.py "$OUT_DIR"

echo "-----------------------------------"
echo "Finalizado. Arquivos em: $OUT_DIR"
