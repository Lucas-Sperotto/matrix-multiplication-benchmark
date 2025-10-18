#!/bin/bash

# ----------------------------
# Verificação e instalação de requisitos
# ----------------------------

check_install() {
    PKG=$1
    CMD=$2
    if ! command -v "$CMD" &> /dev/null; then
        echo "Instalando pacote: $PKG..."
        sudo apt update && sudo apt install -y "$PKG"
    else
        echo "✅ [$PKG] já está instalado."
    fi
}

#
# ----------------------------
# [NEW] Parse de flags simples
# ----------------------------
print_usage() {
    cat <<EOF
Uso: $0 [opções]
  --nmax <INT>    Tamanho máximo da matriz (Nmax)
  --k <INT>       Quantidade de pontos (K)
  --help          Mostra esta ajuda

Se --nmax e --k não forem informados, o script pergunta interativamente.
EOF
}

NMAX_FLAG=""
K_FLAG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --nmax)
      NMAX_FLAG="$2"; shift 2;;
    --k)
      K_FLAG="$2"; shift 2;;
    --help|-h)
      print_usage; exit 0;;
    *)
      echo "⚠️  Opção desconhecida: $1"; print_usage; exit 1;;
  esac
done

# ----------------------------
# [NEW] Função para calcular sequência de N sem zero
# Regra: step = round(Nmax / (K+1)); N = {2*step, 3*step, ..., (K+1)*step}
# Garante último = Nmax; remove duplicados; ordena
# ----------------------------
compute_n_sizes() {
  local nmax="$1"
  local k="$2"
  if [[ -z "$nmax" || -z "$k" ]]; then
    echo "❌ compute_n_sizes: parâmetros insuficientes" >&2
    return 1
  fi
  if (( k < 1 )); then
    echo "❌ K deve ser >= 1" >&2
    return 1
  fi

  local div=$(( k + 1 ))
  local step=$(( ( nmax + div/2 ) / div ))
  if (( step < 1 )); then step=1; fi

  local arr=()
  local i
  for (( i=2; i<=k+1; i++ )); do
    arr+=( $(( i * step )) )
  done

  local last_idx=$(( ${#arr[@]} - 1 ))
  arr[$last_idx]=$nmax

  mapfile -t arr < <(printf "%s\n" "${arr[@]}" | sort -n | uniq)

  N_SIZES=("${arr[@]}")
}

# ----------------------------
# Entrada de parâmetros
# ----------------------------

if [[ -n "$NMAX_FLAG" ]]; then
  B="$NMAX_FLAG"
  echo "📥 Nmax (via --nmax): $B"
else
  read -p "Digite o tamanho máximo de Matriz (Nmax): " B
fi

read -p "Escolha o tipo de escala gráfica: [0] = Logaritmica, [1] = Linear: " ESCALA

if [[ -n "$K_FLAG" ]]; then
  Npts="$K_FLAG"
  echo "📥 K (via --k): $Npts"
else
  read -p "Digite a quantidade de pontos (K): " Npts
fi

read -p "Digite a quantidade de execuções para o cálculo da média (M): " M

# ----------------------------
# [NEW] Cálculo da sequência de N sem zero
# ----------------------------
compute_n_sizes "$B" "$Npts" || { echo "Falha ao calcular N_SIZES"; exit 1; }
echo "-----------------------------------"
echo "Sequência de N calculada (sem zero): ${N_SIZES[*]}"
echo "-----------------------------------"

# ----------------------------
# Criação do diretório de saída
# ----------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT_DIR="out/exec_${TIMESTAMP}"
mkdir -p "$OUT_DIR"
echo "Resultados serão salvos em $OUT_DIR"
echo "-----------------------------------"

# [NEW] Salva a sequência de N para referência
printf "%s\n" "${N_SIZES[@]}" > "$OUT_DIR/N_values.txt"
echo "Lista de N salva em: $OUT_DIR/N_values.txt"

# ----------------------------
# Exemplo de uso (mais abaixo você substituirá o loop antigo por este)
# ----------------------------
# for N in "${N_SIZES[@]}"; do
#   ./bin/matriz_c "$N" "$M" ...
# done
