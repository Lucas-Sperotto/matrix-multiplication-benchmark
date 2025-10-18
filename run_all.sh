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

# ----------------------------
# [NEW] Parse de flags simples
# ----------------------------
print_usage() {
    cat <<EOF
Uso: $0 [opções]
  --nmax <INT>        Tamanho máximo da matriz (Nmax)
  --k <INT>           Quantidade de pontos (K)
  --exec-name <NOME>  Nome da execução (pasta em out/<NOME>)
  --resume <modo>     auto | continue | restart | cancel
  --help              Mostra esta ajuda

Se --nmax e --k não forem informados, o script pergunta interativamente.
Se --exec-name for informado, os resultados vão para out/<NOME>; caso exista, ativa lógica de retomada.
EOF
}

NMAX_FLAG=""
K_FLAG=""
EXEC_NAME_FLAG=""
RESUME_ACTION=""   # auto|continue|restart|cancel|"" (interativo)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --nmax)       NMAX_FLAG="$2"; shift 2;;
    --k)          K_FLAG="$2"; shift 2;;
    --exec-name)  EXEC_NAME_FLAG="$2"; shift 2;;
    --resume)     RESUME_ACTION="$2"; shift 2;;
    --help|-h)    print_usage; exit 0;;
    *)            echo "⚠️  Opção desconhecida: $1"; print_usage; exit 1;;
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

  # força último = nmax
  local last_idx=$(( ${#arr[@]} - 1 ))
  arr[$last_idx]=$nmax

  # remove duplicados e ordena
  mapfile -t arr < <(printf "%s\n" "${arr[@]}" | sort -n | uniq)

  # exporta para variável global
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
# [NEW] Definição do diretório de saída (execução)
# ----------------------------
if [[ -n "$EXEC_NAME_FLAG" ]]; then
  OUT_DIR="out/$EXEC_NAME_FLAG"
else
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  OUT_DIR="out/exec_${TIMESTAMP}"
fi
mkdir -p "$OUT_DIR"
echo "Resultados serão salvos em $OUT_DIR"
echo "-----------------------------------"

# [NEW] Salva a sequência de N para referência
printf "%s\n" "${N_SIZES[@]}" > "$OUT_DIR/N_values.txt"
echo "Lista de N salva em: $OUT_DIR/N_values.txt"

# ============================
# [NEW] Localização dos binários/entradas por linguagem
# ============================
BIN_DIR="./bin"
SRC_DIR="./"
mkdir -p "$BIN_DIR"

C_BIN="$BIN_DIR/matriz_c"
C_O3_BIN="$BIN_DIR/matriz_c_O3"
CPP_BIN="$BIN_DIR/matriz_cpp"
CPP_O3_BIN="$BIN_DIR/matriz_cpp_O3"
JAVA_MAIN_CLASS="MatrizJava"     # ajuste se necessário
JAVA_CP="$BIN_DIR"               # ajuste se necessário
PY_FILE="$SRC_DIR/matriz_python.py"


# Gera system_info.md e system_info.json dentro da pasta da execução
if [[ -x "./gen_sysinfo_md.sh" ]]; then
  ./gen_sysinfo_md.sh "$OUT_DIR" || echo "⚠️ Não foi possível gerar system_info.* em $OUT_DIR"
else
  echo "ℹ️ gen_sysinfo_md.sh não está executável; rode: chmod +x gen_sysinfo_md.sh"
fi



# ----------------------------
# [NEW] Chamada unificada por linguagem
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
        echo "⚠️  Binário não encontrado/executável: $C_BIN (pulando C)"; return 2
      fi
      ;;
    C_O3)
      if [[ -x "$C_O3_BIN" ]]; then
        "$C_O3_BIN" "$N" "$Mreps" "$Escala" "$Out"
      else
        echo "⚠️  Binário não encontrado/executável: $C_O3_BIN (pulando C_O3)"; return 2
      fi
      ;;
    CPP)
      if [[ -x "$CPP_BIN" ]]; then
        "$CPP_BIN" "$N" "$Mreps" "$Escala" "$Out"
      else
        echo "⚠️  Binário não encontrado/executável: $CPP_BIN (pulando CPP)"; return 2
      fi
      ;;
    CPP_O3)
      if [[ -x "$CPP_O3_BIN" ]]; then
        "$CPP_O3_BIN" "$N" "$Mreps" "$Escala" "$Out"
      else
        echo "⚠️  Binário não encontrado/executável: $CPP_O3_BIN (pulando CPP_O3)"; return 2
      fi
      ;;
    JAVA)
      if command -v java >/dev/null 2>&1; then
        if [[ -d "$JAVA_CP" ]]; then
          java -cp "$JAVA_CP" "$JAVA_MAIN_CLASS" "$N" "$Mreps" "$Escala" "$Out"
        else
          echo "⚠️  Classpath Java não encontrado: $JAVA_CP (pulando JAVA)"; return 2
        fi
      else
        echo "⚠️  Java não instalado (pulando JAVA)"; return 2
      fi
      ;;
    PYTHON)
      if command -v python3 >/dev/null 2>&1 && [[ -f "$PY_FILE" ]]; then
        python3 "$PY_FILE" "$N" "$Mreps" "$Escala" "$Out"
      else
        echo "⚠️  Python3 ou arquivo não encontrado: $PY_FILE (pulando PYTHON)"; return 2
      fi
      ;;
    *)
      echo "❌ Linguagem desconhecida em invoke_prog: $lang"; return 1;;
  esac
}

# ----------------------------
# [NEW] Execução de uma linguagem sobre N_SIZES
# ----------------------------
run_lang_over_Ns() {
  local lang="$1"          # C | C_O3 | CPP | CPP_O3 | JAVA | PYTHON
  local csv_expected="$2"  # nome do CSV esperado em $OUT_DIR
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

  if [[ -n "$csv_expected" && -f "$OUT_DIR/$csv_expected" ]]; then
    echo "✅ Arquivo gerado/atualizado: $OUT_DIR/$csv_expected"
  else
    echo "ℹ️  (Atenção) Não encontrei $csv_expected após rodada de $lang."
    echo "    Se o binário gera o CSV com outro nome/local, ajuste 'csv_expected' ao chamar run_lang_over_Ns."
  fi

  return $had_error
}

# ----------------------------
# [NEW] Geração de gráficos
# ----------------------------
generate_plots() {
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
}

# ============================
# [NEW] RESUME: detecção e retomada por linguagem
# ============================
LANGS=(C C_O3 CPP CPP_O3 JAVA PYTHON)
declare -A CSV_MAP=(
  ["C"]="resultado_c.csv"
  ["C_O3"]="resultado_c_O3.csv"
  ["CPP"]="resultado_cpp.csv"
  ["CPP_O3"]="resultado_cpp_O3.csv"
  ["JAVA"]="resultado_java.csv"
  ["PYTHON"]="resultado_python.csv"
)

# CSV completo = (linhas == 1 + |N_SIZES|)
csv_is_complete() {
  local csv="$1"
  local expected_lines=$(( ${#N_SIZES[@]} + 1 ))
  [[ -f "$csv" ]] || return 1
  local actual_lines
  actual_lines=$(wc -l < "$csv")
  [[ "$actual_lines" -eq "$expected_lines" ]]
}

# Lista Ns faltantes comparando a 1ª coluna do CSV com N_SIZES
csv_list_missing_ns() {
  local csv="$1"
  mapfile -t ns_in_csv < <(awk -F',' 'NR>1 {print $1}' "$csv" | sed 's/[^0-9]//g' | awk 'NF' | sort -n | uniq)
  local tmp_all tmp_csv
  tmp_all=$(mktemp); tmp_csv=$(mktemp)
  printf "%s\n" "${N_SIZES[@]}" | sort -n | uniq > "$tmp_all"
  printf "%s\n" "${ns_in_csv[@]}" | sort -n | uniq > "$tmp_csv"
  local missing_list
  missing_list=$(comm -23 "$tmp_all" "$tmp_csv" | xargs)
  rm -f "$tmp_all" "$tmp_csv"
  echo "$missing_list"
}

print_resume_status() {
  echo ""
  echo "📂 Execução: $OUT_DIR"
  echo "🧮 Esperado por linguagem: ${#N_SIZES[@]} pontos + cabeçalho (= $(( ${#N_SIZES[@]} + 1 )) linhas)"
  echo "-----------------------------------"
  for L in "${LANGS[@]}"; do
    local csv="$OUT_DIR/${CSV_MAP[$L]}"
    if [[ -f "$csv" ]]; then
      if csv_is_complete "$csv"; then
        echo "✅ $L — completo  (${CSV_MAP[$L]})"
      else
        local miss; miss=$(csv_list_missing_ns "$csv")
        if [[ -n "$miss" ]]; then
          echo "⏳ $L — incompleto (${CSV_MAP[$L]}), faltam N: $miss"
        else
          echo "⏳ $L — incompleto (${CSV_MAP[$L]}), faltam todos os N"
        fi
      fi
    else
      echo "❌ $L — não iniciado (ausente: ${CSV_MAP[$L]})"
    fi
  done
  echo "-----------------------------------"
}

ask_resume_action() {
  local choice
  while true; do
    echo -n "Deseja [C]ontinuar, [R]einiciar ou [X] Cancelar? "
    read -r choice
    case "${choice^^}" in
      C) RESUME_ACTION="continue"; break;;
      R) RESUME_ACTION="restart";  break;;
      X) RESUME_ACTION="cancel";   break;;
      *) echo "Opção inválida. Use C, R ou X.";;
    esac
  done
}

run_lang_missing_ns() {
  local lang="$1"
  local csv="$2"
  local miss
  if [[ -f "$csv" ]]; then
    miss=$(csv_list_missing_ns "$csv")
  else
    miss="${N_SIZES[*]}"
  fi

  if [[ -z "$miss" ]]; then
    echo "✅ $lang já está completo (nada a fazer)."
    return 0
  fi

  echo "▶️  Retomando $lang — executando somente faltantes: $miss"
  local had_error=0
  for N in $miss; do
    echo "   • N=$N  (M=$M, ESCALA=$ESCALA)"
    if ! invoke_prog "$lang" "$N" "$M" "$ESCALA" "$OUT_DIR"; then
      echo "   ⚠️  Falha ao executar $lang para N=$N"
      had_error=1
      break
    fi
  done
  return $had_error
}

# ============================
# [NEW] README da execução (OUT_DIR/README.md)
# Requer: OUT_DIR, B (Nmax), Npts (K), N_SIZES[@], M, ESCALA,
#         LANGS[@], CSV_MAP[], csv_is_complete(), csv_list_missing_ns()
# ============================

detect_git_commit() {
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git rev-parse --short HEAD 2>/dev/null || echo "N/D"
  else
    echo "N/D"
  fi
}

detect_hostname() {
  hostname 2>/dev/null || echo "N/D"
}

find_system_info_md() {
  # prioriza dentro do OUT_DIR; senão tenta raiz do repo
  if [[ -f "$OUT_DIR/system_info.md" ]]; then
    echo "./system_info.md"
  elif [[ -f "system_info.md" ]]; then
    echo "../system_info.md"
  else
    echo ""
  fi
}

collect_plot_files() {
  # lista PNGs diretos do OUT_DIR (sem recursão) e retorna em PLots[@]
  mapfile -t PLOTS < <(find "$OUT_DIR" -maxdepth 1 -type f -name "*.png" -printf "%f\n" | sort)
}

print_lang_status_line() {
  local L="$1"
  local csv="$OUT_DIR/${CSV_MAP[$L]}"

  if [[ -f "$csv" ]]; then
    if csv_is_complete "$csv"; then
      echo "- **$L**: ✅ completo \`(${CSV_MAP[$L]})\`"
    else
      local miss; miss=$(csv_list_missing_ns "$csv")
      if [[ -n "$miss" ]]; then
        echo "- **$L**: ⏳ incompleto \`(${CSV_MAP[$L]})\` — faltam **N =** \`$miss\`"
      else
        echo "- **$L**: ⏳ incompleto \`(${CSV_MAP[$L]})\` (sem dados)"
      fi
    fi
  else
    echo "- **$L**: ❌ não iniciado (ausente: \`${CSV_MAP[$L]}\`)"
  fi
}

write_results_readme() {
  local now iso
  now="$(date +"%d/%m/%Y %H:%M:%S")"
  iso="$(date -Iseconds)"
  local host commit
  host="$(detect_hostname)"
  commit="$(detect_git_commit)"
  local sys_link
  sys_link="$(find_system_info_md)"

  collect_plot_files

  {
    echo "# Resultados — $(basename "$OUT_DIR")"
    echo
    echo "**Data:** $now  \`$iso\`  "
    echo "**Host:** $host  "
    echo "**Commit:** \`$commit\`  "
    if [[ -n "$sys_link" ]]; then
      echo "**Sistema:** [system_info.md]($sys_link)"
    else
      echo "**Sistema:** (arquivo \`system_info.md\` não encontrado)"
    fi
    echo
    echo "## Parâmetros"
    echo "- **Nmax:** $B"
    echo "- **K (qtde de pontos):** $Npts"
    echo "- **Lista de N:** \`${N_SIZES[*]}\`"
    echo "- **M (repetições):** $M"
    echo "- **Escala:** $([[ "$ESCALA" == "0" ]] && echo "Logarítmica" || echo "Linear") (\`$ESCALA\`)"
    echo
    echo "## Status por linguagem"
    for L in "${LANGS[@]}"; do
      print_lang_status_line "$L"
    done
    echo
    echo "## Gráficos"
    if (( ${#PLOTS[@]} > 0 )); then
      for p in "${PLOTS[@]}"; do
        echo "- [$p](./$p)"
      done
    else
      echo "_Nenhum gráfico (.png) encontrado em \`$(basename "$OUT_DIR")\`._"
    fi
    echo
    echo "> **Observação:** este README é gerado automaticamente pelo \`run_all.sh\` ao final de cada execução ou retomada."
  } > "$OUT_DIR/README.md"

  echo "📝 README gerado/atualizado em: $OUT_DIR/README.md"
}

# ============================
# [NEW] Manifesto em JSON (OUT_DIR/run_manifest.json)
# Requer: OUT_DIR, B, Npts, N_SIZES[@], M, ESCALA, LANGS[@], CSV_MAP[], csv_is_complete(), csv_list_missing_ns()
# ============================

json_escape() {
  # escape simples para aspas e backslashes
  local s=${1//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s"
}

build_lang_status_json() {
  # Gera um array JSON com objetos { "lang": "...", "csv": "...", "complete": true|false, "missing": [ ... ] }
  local first=1
  printf '['
  for L in "${LANGS[@]}"; do
    local csv="$OUT_DIR/${CSV_MAP[$L]}"
    local complete="false"
    local missing_arr="[]"

    if [[ -f "$csv" ]]; then
      if csv_is_complete "$csv"; then
        complete="true"
      else
        local miss; miss=$(csv_list_missing_ns "$csv")
        if [[ -n "$miss" ]]; then
          # transforma "10 20 30" em [10,20,30]
          local list=""
          for n in $miss; do
            if [[ -z "$list" ]]; then list="$n"; else list="$list,$n"; fi
          done
          missing_arr="[$list]"
        fi
      fi
    fi

    if (( first )); then first=0; else printf ','; fi
    printf '{'
    printf '"lang":"%s",'   "$(json_escape "$L")"
    printf '"csv":"%s",'    "$(json_escape "${CSV_MAP[$L]}")"
    printf '"complete":%s,' "$complete"
    printf '"missing":%s'   "$missing_arr"
    printf '}'
  done
  printf ']'
}

collect_plot_files_json() {
  # Retorna array JSON com nomes de PNG em OUT_DIR
  mapfile -t _PLOTS_LOCAL < <(find "$OUT_DIR" -maxdepth 1 -type f -name "*.png" -printf "%f\n" | sort)
  if (( ${#_PLOTS_LOCAL[@]} == 0 )); then
    printf '[]'
    return
  fi
  local first=1
  printf '['
  for p in "${_PLOTS_LOCAL[@]}"; do
    if (( first )); then first=0; else printf ','; fi
    printf '"%s"' "$(json_escape "$p")"
  done
  printf ']'
}

write_run_manifest() {
  local now iso host commit sys_link
  now="$(date +"%d/%m/%Y %H:%M:%S")"
  iso="$(date -Iseconds)"
  host="$(hostname 2>/dev/null || echo "N/D")"
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    commit="$(git rev-parse --short HEAD 2>/dev/null || echo "N/D")"
  else
    commit="N/D"
  fi

  # system_info.md preferencialmente em OUT_DIR
  if [[ -f "$OUT_DIR/system_info.md" ]]; then
    sys_link="system_info.md"
  elif [[ -f "system_info.md" ]]; then
    sys_link="../system_info.md"
  else
    sys_link=""
  fi

  # lista de N em JSON
  local ns_json="[]"
  if (( ${#N_SIZES[@]} > 0 )); then
    local first=1
    ns_json='['
    for n in "${N_SIZES[@]}"; do
      if (( first )); then first=0; else ns_json+=", "; fi
      ns_json+="$n"
    done
    ns_json+=']'
  fi

  # status por linguagem
  local langs_json
  langs_json="$(build_lang_status_json)"

  # gráficos
  local plots_json
  plots_json="$(collect_plot_files_json)"

  {
    printf '{'
    printf '"exec_name":"%s",'  "$(json_escape "$(basename "$OUT_DIR")")"
    printf '"out_dir":"%s",'    "$(json_escape "$OUT_DIR")"
    printf '"datetime":"%s",'   "$(json_escape "$now")"
    printf '"datetime_iso":"%s",' "$(json_escape "$iso")"
    printf '"host":"%s",'       "$(json_escape "$host")"
    printf '"git_commit":"%s",' "$(json_escape "$commit")"
    printf '"system_info":"%s",' "$(json_escape "$sys_link")"
    printf '"params":{'
      printf '"Nmax":%s,'   "$B"
      printf '"K":%s,'      "$Npts"
      printf '"M":%s,'      "$M"
      printf '"escala":"%s",' "$ESCALA"
      printf '"N_sizes":%s' "$ns_json"
    printf '},'
    printf '"languages":%s,' "$langs_json"
    printf '"plots":%s' "$plots_json"
    printf '}'
  } > "$OUT_DIR/run_manifest.json"

  echo "🧾 Manifesto gerado/atualizado: $OUT_DIR/run_manifest.json"
}


# ----------------------------
# [NEW] Função para rodar TODAS as linguagens (pipeline completo)
# ----------------------------
run_all_languages() {
  run_lang_over_Ns "C"       "resultado_c.csv"
  run_lang_over_Ns "C_O3"    "resultado_c_O3.csv"
  run_lang_over_Ns "CPP"     "resultado_cpp.csv"
  run_lang_over_Ns "CPP_O3"  "resultado_cpp_O3.csv"
  run_lang_over_Ns "JAVA"    "resultado_java.csv"
  run_lang_over_Ns "PYTHON"  "resultado_python.csv"
  generate_plots
}

# ----------------------------
# [NEW] Fluxo principal de retomada (antes da execução completa)
# ----------------------------
has_any_csv=0
for L in "${LANGS[@]}"; do
  if [[ -f "$OUT_DIR/${CSV_MAP[$L]}" ]]; then
    has_any_csv=1; break
  fi
done

if (( has_any_csv == 1 )); then
  print_resume_status

  if [[ -z "$RESUME_ACTION" || "$RESUME_ACTION" == "auto" ]]; then
    ask_resume_action
  fi

  case "$RESUME_ACTION" in
    continue)
      echo "➡️  Ação: continuar (executar faltantes por linguagem e seguir)."
      for L in "${LANGS[@]}"; do
        run_lang_missing_ns "$L" "$OUT_DIR/${CSV_MAP[$L]}"
      done
      generate_plots
      write_results_readme
      write_run_manifest
      echo "✔️  Retomada concluída."
      exit 0
      ;;
    restart)
      echo "🧹 Ação: reiniciar — apagando CSVs e reexecutando todas as linguagens."
      for L in "${LANGS[@]}"; do
        rm -f "$OUT_DIR/${CSV_MAP[$L]}"
      done
      # cai para execução completa abaixo
      ;;
    cancel)
      echo "🛑 Ação: cancelar. Nada será executado."
      exit 0
      ;;
    *)
      echo "⚠️  Ação desconhecida em --resume: '$RESUME_ACTION'"; exit 1;;
  esac
else
  echo "ℹ️  Nenhum CSV encontrado em $OUT_DIR — iniciando execução completa."
fi

# ----------------------------
# Execução COMPLETA (sem retomada)
# ----------------------------
run_all_languages
write_results_readme
write_run_manifest
