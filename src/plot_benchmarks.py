#!/usr/bin/env python3
import os
import sys
from pathlib import Path
from typing import Dict, List
import pandas as pd
import matplotlib.pyplot as plt

# ============================
# Entrada
# ============================
if len(sys.argv) < 2:
    print("Uso: plot_benchmarks.py <diretorio_de_saida>")
    sys.exit(1)

out_dir = Path(sys.argv[1])

files = {
    "C": out_dir / "resultado_c.csv",
    "C_O3": out_dir / "resultado_c_O3.csv",
    "C++": out_dir / "resultado_cpp.csv",
    "C++_O3": out_dir / "resultado_cpp_O3.csv",
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
    prefs = ("n", "size", "dim", "order", "tamanho", "matrix_size", "N")
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
        # normaliza nomes e força numérico
        df = ensure_numeric(df, df.columns.tolist())

        # compatibilidade: se vier "TLM", mapeia para "TDM"
        if "TDM" not in df.columns and "TLM" in df.columns:
            df["TDM"] = df["TLM"]

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
# Plot genérico por métrica (todas as linguagens)
# ============================
def plot_metric(metric: str):
    """
    Plota a métrica especificada para todas as linguagens que tiverem a coluna.
    (Mantido do original; apenas acrescentei salvamento com nome alternativo explícito)
    """
    any_series = False
    plt.figure()

    for lang, df in dfs.items():
        ncol = ncols[lang]
        if metric not in df.columns:
            continue
        sub = df[[ncol, metric]].dropna().sort_values(by=ncol)
        if sub.empty:
            continue
        plt.plot(sub[ncol], sub[metric], marker="o", label=lang)
        any_series = True

    if not any_series:
        plt.close()
        print(f"Aviso: nenhuma linguagem disponível para a métrica {metric}.")
        return

    plt.xlabel("N (matriz com NxN elementos)")
    plt.ylabel(f"Tempo (s)")
    plt.title(f"Comparação por linguagem - {TITLES.get(metric, metric)}")
    plt.legend()
    #out_img_default = out_dir / f"grafico_{metric}.png"
    #plt.savefig(out_img_default, dpi=160, bbox_inches="tight")
    # ===== NOVO: também salvo com um nome mais explícito para a demanda "Todas as Linguagens"
    out_img_alias = out_dir / f"grafico_{metric}_todas_linguagens.png"
    plt.savefig(out_img_alias, dpi=160, bbox_inches="tight")
    plt.close()
    print(f"✅ {metric}: salvo em {out_img_alias}")

# ============================
# Plot específico: apenas C vs C++ (preferindo _O3)
# ============================
def plot_metric_subset(metric: str):
    """
    Plota somente C e C++ para a métrica dada.
    Preferência por versões _O3; se não houver, usa as versões normais.
    (Mantido do original)
    """
    prefer_c = "C_O3" if "C_O3" in dfs else "C"
    prefer_cpp = "C++_O3" if "C++_O3" in dfs else "C++"

    series = []
    for lang in (prefer_c, prefer_cpp):
        if lang in dfs and metric in dfs[lang].columns:
            ncol = ncols[lang]
            sub = dfs[lang][[ncol, metric]].dropna().sort_values(by=ncol)
            if not sub.empty:
                series.append((lang, sub))

    if len(series) == 0:
        print(f"Aviso: nenhuma série C/C++ disponível para {metric}.")
        return
    if len(series) == 1:
        print(f"Aviso: apenas uma série C/C++ encontrada para {metric}: {series[0][0]}.")

    plt.figure()
    # re-obter ncol dentro do loop, pois C e C++ podem ter nomes de coluna N diferentes
    for lang, sub in series:
        ncol_local = detect_N_column(sub) if "N" not in sub.columns else "N"
        # se detect_N_column pegar algo inesperado, usa a 1a coluna como N
        ncol_local = ncol_local if ncol_local in sub.columns else sub.columns[0]
        plt.plot(sub[ncol_local], sub[metric], marker="o", label=lang)

    plt.xlabel("N (matriz com NxN elementos)")
    plt.ylabel(f"Tempo (s)")
    plt.title(f"C vs C++ - {TITLES.get(metric, metric)}")
    plt.legend()
    out_img = out_dir / f"grafico_{metric}_C_vs_CPP.png"
    plt.savefig(out_img, dpi=160, bbox_inches="tight")
    plt.close()
    print(f"✅ {metric} (C vs C++): salvo em {out_img}")

# ============================
# ===== NOVO: C e C++ com e sem O3 =====
# ============================
def plot_metric_c_cpp_all_variants(metric: str):
    """
    NOVO:
    Plota C e C++ com e sem O3 (até 4 curvas): C, C_O3, C++, C++_O3.
    Só plota as séries/arquivos que existirem para a métrica.
    """
    variants = ["C", "C_O3", "C++", "C++_O3"]
    series = []

    for lang in variants:
        if lang in dfs and metric in dfs[lang].columns:
            ncol = ncols[lang]
            sub = dfs[lang][[ncol, metric]].dropna().sort_values(by=ncol)
            if not sub.empty:
                series.append((lang, sub))

    if not series:
        print(f"Aviso: nenhuma série C/C++ (com/sem O3) disponível para {metric}.")
        return

    plt.figure()
    for lang, sub in series:
        ncol_local = detect_N_column(sub) if "N" not in sub.columns else "N"
        ncol_local = ncol_local if ncol_local in sub.columns else sub.columns[0]
        plt.plot(sub[ncol_local], sub[metric], marker="o", label=lang)

    plt.xlabel("N (matriz com NxN elementos)")
    plt.ylabel(f"Tempo (s)")
    plt.title(f"C e C++ (com e sem -O3) - {TITLES.get(metric, metric)}")
    plt.legend()
    out_img = out_dir / f"grafico_{metric}_C_CPP_com_e_sem_O3.png"
    plt.savefig(out_img, dpi=160, bbox_inches="tight")
    plt.close()
    print(f"✅ {metric} (C/C++ com e sem O3): salvo em {out_img}")

# ============================
# ===== NOVO: Todas as linguagens menos Python =====
# ============================
def plot_metric_all_minus_python(metric: str):
    """
    NOVO:
    Plota todas as linguagens disponíveis EXCETO Python para a métrica.
    Mantém a mesma lógica de leitura e ordenação do plot genérico.
    """
    any_series = False
    plt.figure()

    for lang, df in dfs.items():
        if lang.lower() == "python":
            continue  # exclui Python
        ncol = ncols[lang]
        if metric not in df.columns:
            continue
        sub = df[[ncol, metric]].dropna().sort_values(by=ncol)
        if sub.empty:
            continue
        plt.plot(sub[ncol], sub[metric], marker="o", label=lang)
        any_series = True

    if not any_series:
        plt.close()
        print(f"Aviso: nenhuma linguagem (sem Python) disponível para a métrica {metric}.")
        return

    plt.xlabel("N (matriz com NxN elementos)")
    plt.ylabel(f"Tempo (s)")
    plt.title(f"Todas as linguagens (exceto Python) - {TITLES.get(metric, metric)}")
    plt.legend()
    out_img = out_dir / f"grafico_{metric}_sem_python.png"
    plt.savefig(out_img, dpi=160, bbox_inches="tight")
    plt.close()
    print(f"✅ {metric} (sem Python): salvo em {out_img}")

# ============================
# Execução
# ============================
for m in METRICS:
    # 1) Todas as linguagens (mantido + alias de nome)
     plot_metric(m)

for m in METRICS:
    # 2) C vs C++ preferindo -O3 (mantido)
    plot_metric_subset(m)

for m in METRICS:
    # 3) NOVO: C e C++ com e sem -O3 (até 4 séries)
    plot_metric_c_cpp_all_variants(m)

for m in METRICS:
    # 4) NOVO: Todas as linguagens menos Python
    plot_metric_all_minus_python(m)

print(f"Concluído. Gráficos em: {out_dir}")
