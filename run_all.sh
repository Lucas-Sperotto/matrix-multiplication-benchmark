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

# ============================
# [NEW] Execução por linguagem usando N_SIZES[@]
# ============================

# Pastas padrões (ajuste se necessário)
BIN_DIR="./bin"
SRC_DIR="./"

mkdir -p "$BIN_DIR"

# ----------------------------
# [NEW] Localização dos executáveis/entradas por linguagem
#    Ajuste os caminhos/nomes conforme seu projeto.
# ----------------------------
C_BIN="$BIN_DIR/matriz_c"
C_O3_BIN="$BIN_DIR/matriz_c_O3"
CPP_BIN="$BIN_DIR/matriz_cpp"
CPP_O3_BIN="$BIN_DIR/matriz_cpp_O3"
JAVA_MAIN_CLASS="MatrizJava"            # ajuste: nome da classe com 'main'
JAVA_CP="$BIN_DIR"                       # ajuste: classpath onde .class foi gerado
PY_FILE="$SRC_DIR/matriz_python.py"      # ajuste: caminho do script Python

# ----------------------------
# [NEW] Função para invocar cada linguagem de modo unificado
#    Se a sua assinatura de argumentos for diferente,
#    ajuste apenas aqui por linguagem.
# ----------------------------
invoke_prog() {
  local lang="$1"   # C | C_O3 | CPP | CPP_O3 | JAVA | PYTHON
  local N="$2"
  local Mreps="$3"
  local Escala="$4"
  local Out="$5"

  case "$lang" in
    C)
      if [[ -x "$C_BIN" ]]; then
        "$C_BIN" "$N" "$Mreps" "$Escala" "$Out"
      else
        echo "⚠️  Binário não encontrado/executável: $C_BIN (pulando C)"
        return 2
      fi
      ;;
    C_O3)
      if [[ -x "$C_O3_BIN" ]]; then
        "$C_O3_BIN" "$N" "$Mreps" "$Escala" "$Out"
      else
        echo "⚠️  Binário não encontrado/executável: $C_O3_BIN (pulando C_O3)"
        return 2
      fi
      ;;
    CPP)
      if [[ -x "$CPP_BIN" ]]; then
        "$CPP_BIN" "$N" "$Mreps" "$Escala" "$Out"
      else
        echo "⚠️  Binário não encontrado/executável: $CPP_BIN (pulando CPP)"
        return 2
      fi
      ;;
    CPP_O3)
      if [[ -x "$CPP_O3_BIN" ]]; then
        "$CPP_O3_BIN" "$N" "$Mreps" "$Escala" "$Out"
      else
        echo "⚠️  Binário não encontrado/executável: $CPP_O3_BIN (pulando CPP_O3)"
        return 2
      fi
      ;;
    JAVA)
      # Opção A: se você tiver JAR: java -jar "$BIN_DIR/matriz_java.jar" ...
      # Opção B: se você compila .class no BIN_DIR, rode com -cp:
      if command -v java >/dev/null 2>&1; then
        if [[ -d "$JAVA_CP" ]]; then
          java -cp "$JAVA_CP" "$JAVA_MAIN_CLASS" "$N" "$Mreps" "$Escala" "$Out"
        else
          echo "⚠️  Classpath Java não encontrado: $JAVA_CP (pulando JAVA)"
          return 2
        fi
      else
        echo "⚠️  Java não instalado (pulando JAVA)"
        return 2
      fi
      ;;
    PYTHON)
      if command -v python3 >/dev/null 2>&1 && [[ -f "$PY_FILE" ]]; then
        # Ajuste os parâmetros conforme a CLI do seu script Python:
        python3 "$PY_FILE" "$N" "$Mreps" "$Escala" "$Out"
        # Exemplo alternativo (se o seu Python usar flags):
        # python3 "$PY_FILE" --n "$N" --m "$Mreps" --escala "$Escala" --out "$Out"
      else
        echo "⚠️  Python3 ou arquivo não encontrado: $PY_FILE (pulando PYTHON)"
        return 2
      fi
      ;;
    *)
      echo "❌ Linguagem desconhecida em invoke_prog: $lang"
      return 1
      ;;
  esac
}

# ----------------------------
# [NEW] Função que executa uma linguagem iterando sobre N_SIZES
# ----------------------------
run_lang_over_Ns() {
  local lang="$1"      # C | C_O3 | CPP | CPP_O3 | JAVA | PYTHON
  local csv_expected="$2"  # nome do CSV esperado dentro do OUT_DIR (para futura retomada)
  local had_error=0

  echo ""
  echo "▶️  Executando: $lang"
  for N in "${N_SIZES[@]}"; do
    echo "   • N=$N  (M=$M, ESCALA=$ESCALA)"
    if ! invoke_prog "$lang" "$N" "$M" "$ESCALA" "$OUT_DIR"; then
      echo "   ⚠️  Falha ao executar $lang para N=$N"
      had_error=1
      break
    fi
  done

  # Apenas informa; não forçamos existência do CSV aqui,
  # pois cada binário pode já escrever/append no arquivo por conta própria.
  if [[ -n "$csv_expected" && -f "$OUT_DIR/$csv_expected" ]]; then
    echo "✅ Arquivo gerado/atualizado: $OUT_DIR/$csv_expected"
  else
    echo "ℹ️  (Atenção) Não encontrei $csv_expected após rodada de $lang."
    echo "    Se o binário gera o CSV com outro nome/local, ajuste 'csv_expected' ao chamar run_lang_over_Ns."
  fi

  return $had_error
}

# ----------------------------
# [NEW] Execução sequencial nas linguagens
#     (ajuste a ordem como preferir)
# ----------------------------

# C
run_lang_over_Ns "C" "resultado_c.csv"

# C (O3)
run_lang_over_Ns "C_O3" "resultado_c_O3.csv"

# C++
run_lang_over_Ns "CPP" "resultado_cpp.csv"

# C++ (O3)
run_lang_over_Ns "CPP_O3" "resultado_cpp_O3.csv"

# Java
run_lang_over_Ns "JAVA" "resultado_java.csv"

# Python
run_lang_over_Ns "PYTHON" "resultado_python.csv"

# ----------------------------
# [NEW] Geração de gráficos (opcional)
# ----------------------------
if command -v python3 >/dev/null 2>&1; then
  if [[ -f "plot_benchmarks.py" ]]; then
    echo ""
    echo "📊 Gerando gráficos em: $OUT_DIR"
    python3 plot_benchmarks.py "$OUT_DIR" || echo "⚠️  Falha ao gerar gráficos."
  else
    echo "ℹ️  Arquivo plot_benchmarks.py não encontrado (pulando gráficos)."
  fi
else
  echo "ℹ️  Python3 não encontrado (pulando gráficos)."
fi

