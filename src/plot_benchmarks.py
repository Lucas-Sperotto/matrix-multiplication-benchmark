#!/usr/bin/env python3
import os
import sys
import math
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
from typing import Dict, List

# ============================
# Configuração da curva de referência (edite aqui)
# f_ref(N) = SCALE * N**POWER
# Também pode sobrescrever por variáveis de ambiente:
#   REF_SCALE, REF_POWER
# ============================
#SCALE = float(os.environ.get("REF_SCALE", "1.0E-7"))
#POWER = float(os.environ.get("REF_POWER", "2.0"))

#def f_ref(n_values):
#    """Função de referência editável (por padrão: SCALE * N**POWER)."""
#    return [SCALE * (float(n) ** POWER) for n in n_values]

# ============================
# Entrada
# ============================
if len(sys.argv) < 2:
    print("Uso: plot_benchmarks.py <diretório_de_saida>")
    sys.exit(1)

out_dir = Path(sys.argv[1])

files = {
    "C": out_dir / "resultado_c.csv",
    "C_OT": out_dir / "resultado_c_ot.csv",
    "C++": out_dir / "resultado_cpp.csv",
    "C++_OT": out_dir / "resultado_cpp_ot.csv",
    "Java": out_dir / "resultado_java.csv",
    "Python": out_dir / "resultado_python.csv",
}

# ============================
# Utilitários de leitura
# ============================
def read_csv_flex(path: Path) -> pd.DataFrame:
    try:
        df = pd.read_csv(path)
    except Exception:
        df = pd.read_csv(path, sep=";")
    df.columns = [str(c).strip() for c in df.columns]
    return df

def detect_N_column(df: pd.DataFrame) -> str:
    prefs = ("n", "size", "dim", "order", "tamanho", "matrix_size")
    for c in df.columns:
        if str(c).strip().lower() in prefs:
            return c
    return df.columns[0]

def ensure_numeric(df: pd.DataFrame, cols: List[str]) -> pd.DataFrame:
    df = df.copy()
    for c in cols:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")
    return df

# ============================
# Carrega dados disponíveis
# ============================
dfs: Dict[str, pd.DataFrame] = {}
for lang, path in files.items():
    if path.exists():
        df = read_csv_flex(path)
        # normaliza e força numérico em colunas de interesse
        df = ensure_numeric(df, df.columns.tolist())
        dfs[lang] = df

if not dfs:
    print("Nenhum CSV encontrado no diretório informado.")
    sys.exit(1)

ncols = {lang: detect_N_column(df) for lang, df in dfs.items()}

# Métricas fixas
METRICS = ["TCS", "TAM", "TDM"]  # cálculo, alocação, desalocação
TITLES = {
    "TCS": "Tempo de Cálculo da Multiplicação",
    "TAM": "Tempo de Alocação de Memória",
    "TDM": "Tempo de Desalocação de Memória",
}

# ============================
# Função de plot genérica por métrica
# ============================
def plot_metric(metric: str):
    """Plota um gráfico da métrica especificada para todas as linguagens que tiverem a coluna.
       Para TDM, linguagens sem a coluna são ignoradas."""
    any_series = False
    plt.figure()

    # Para construir a curva de referência precisamos de um eixo N razoável.
    # Vamos acumular todos os N que aparecem nas linguagens com a métrica.
    all_N_values = set()

    for lang, df in dfs.items():
        ncol = ncols[lang]
        # precisa existir a métrica no CSV dessa linguagem
        if metric not in df.columns:
            # TDM: ignorar linguagens sem esta coluna
            continue

        # Série dessa linguagem
        # ordena por N e remove NaN
        sub = df[[ncol, metric]].dropna()
        if sub.empty:
            continue
        sub = sub.sort_values(by=ncol)
        # plota
        plt.plot(sub[ncol], sub[metric], marker="o", label=lang)
        any_series = True
        all_N_values.update(sub[ncol].tolist())

    if not any_series:
        # nada para plotar para essa métrica
        plt.close()
        print(f"Aviso: nenhuma linguagem disponível para a métrica {metric}.")
        return

    # Curva de referência (pontilhada) usando todos os N únicos encontrados
    #N_sorted = sorted(all_N_values)
    #yref = f_ref(N_sorted)

    # Apenas para informar no rótulo a forma da função
    #ref_label = f"ref: {SCALE}·N^{POWER}"
    #plt.plot(N_sorted, yref, linestyle="--", label=ref_label)

    plt.xlabel("N (matriz com NxN elementos)")
    plt.ylabel(f"{metric} (s)")
    plt.title(f"Comparação por linguagem - {TITLES.get(metric, metric)}")
    plt.legend()
    out_img = out_dir / f"grafico_{metric}.png"
    plt.savefig(out_img, dpi=160, bbox_inches="tight")
    plt.close()
    print(f"✅ {metric}: salvo em {out_img}")

# ============================
# Gera os três gráficos
# ============================
for m in METRICS:
    plot_metric(m)

print(f"Concluído. Gráficos em: {out_dir}")
