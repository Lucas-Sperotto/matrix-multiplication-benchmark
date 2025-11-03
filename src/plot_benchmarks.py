#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
plot_benchmarks.py <out_dir> [--logx] [--logy] [--exclude C,C_O3,...]

- Lê os CSVs padronizados em <out_dir>:
  C            -> resultado_c.csv
  C_O3         -> resultado_c_O3.csv
  C++          -> resultado_cpp.csv
  C++_O3       -> resultado_cpp_O3.csv
  Java         -> resultado_java.csv
  Python       -> resultado_python.csv

- Normaliza colunas:
  * N (auto-detecção, case-insensitive)
  * TCS (tempo de cálculo)
  * TAM (tempo de alocação)
  * TDM (tempo de desalocação) — se inexistente, cria com 0.0
  * Conserta "TLM" -> "TDM" se vier assim

- Gera gráficos padrão:
  1) c_cpp_o3.png                  (C e C++ com/sem O3)
  2) todas.png                     (todas as linguagens)
  3) sem_python.png                (todas menos Python)

- Escreve <out_dir>/plots_generated.txt listando os PNGs criados.
"""

import sys
import argparse
from pathlib import Path
from typing import Dict, List, Tuple

import pandas as pd
import matplotlib.pyplot as plt

# ============================
# Mapeamento de arquivos por linguagem
# ============================
LANG_FILE = {
    "C": "resultado_c.csv",
    "C_O3": "resultado_c_O3.csv",
    "C++": "resultado_cpp.csv",
    "C++_O3": "resultado_cpp_O3.csv",
    "Java": "resultado_java.csv",
    "Python": "resultado_python.csv",
}

# Ordem “canônica” para exibição
LANG_ORDER = ["C", "C_O3", "C++", "C++_O3", "Java", "Python"]

# ============================
# Args / CLI
# ============================
def parse_args():
    p = argparse.ArgumentParser(description="Gera gráficos de benchmarks a partir dos CSVs de uma execução.")
    p.add_argument("out_dir", help="Diretório com os CSVs de resultados")
    p.add_argument("--logx", action="store_true", help="Usar escala logarítmica no eixo X")
    p.add_argument("--logy", action="store_true", help="Usar escala logarítmica no eixo Y")
    p.add_argument("--exclude", default="", help="Lista de linguagens a excluir (ex.: C,C_O3,Python)")
    return p.parse_args()

# ============================
# Utilitários de leitura
# ============================
def detect_N_column(df: pd.DataFrame) -> str:
    """
    Detecta o nome da coluna N (case-insensitive) entre candidatos comuns.
    """
    if df is None or df.empty:
        raise ValueError("DataFrame vazio para detecção da coluna N.")
    # preferências em lower-case
    prefs = ["n", "size", "tamanho", "dim", "dimensao"]
    cols_l = {c.lower(): c for c in df.columns}
    for k in prefs:
        if k in cols_l:
            return cols_l[k]
    # fallback: tenta a primeira coluna
    return df.columns[0]

def normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Normaliza colunas: garante N, TCS, TAM, TDM.
    Corrige 'TLM' -> 'TDM' se necessário.
    Cria TDM=0.0 quando ausente.
    """
    cols = {c.lower(): c for c in df.columns}

    # Corrige TLM -> TDM
    if "tlm" in cols and "tdm" not in cols:
        df.rename(columns={cols["tlm"]: "TDM"}, inplace=True)
        cols = {c.lower(): c for c in df.columns}

    # Garante TDM
    if "tdm" not in cols:
        df["TDM"] = 0.0
        cols = {c.lower(): c for c in df.columns}

    required_any = []
    # Detecta N
    ncol = detect_N_column(df)
    required_any.append(ncol)
    # TCS
    if "tcs" in cols:
        required_any.append(cols["tcs"])
    else:
        raise ValueError("Coluna TCS não encontrada no CSV.")
    # TAM (opcional para plot de TCS, mas mantemos se houver)
    if "tam" in cols:
        required_any.append(cols["tam"])
    # TDM garantido
    required_any.append("TDM")

    # Reordena pelo N detectado se estiver fora de ordem
    try:
        df = df.sort_values(by=ncol)
    except Exception:
        pass

    # Elimina linhas com NaN em colunas essenciais
    df = df.dropna(subset=[ncol, cols.get("tcs", "TCS")], how="any")
    return df

def read_csv_flex(path: Path) -> pd.DataFrame:
    """
    Lê CSV aceitando separador vírgula e ponto e vírgula.
    Normaliza colunas para uso nos gráficos.
    """
    if not path.exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {path}")

    # tenta leitura padrão
    try:
        df = pd.read_csv(path)
    except Exception:
        # tenta com sep=';'
        df = pd.read_csv(path, sep=';')

    df = normalize_columns(df)
    return df

# ============================
# Gráficos
# ============================
def configure_axes(ax, logx: bool, logy: bool, xlabel="N", ylabel="TCS (s)"):
    ax.grid(True, alpha=0.3)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    if logx:
        ax.set_xscale("log")
    if logy:
        ax.set_yscale("log")

def plot_group(
    out_dir: Path,
    datasets: Dict[str, pd.DataFrame],
    selection: List[str],
    title: str,
    outfile: str,
    logx: bool,
    logy: bool,
):
    # Filtra apenas linguagens presentes e com dados
    sel = [l for l in selection if l in datasets and not datasets[l].empty]
    if not sel:
        # nada para plotar; evita gerar PNG vazio
        return None

    fig, ax = plt.subplots(figsize=(8, 5))
    for lang in sel:
        df = datasets[lang]
        ncol = detect_N_column(df)
        # TCS é a métrica central dos gráficos padrão
        tcs_col = next((c for c in df.columns if c.lower() == "tcs"), "TCS")
        ax.plot(df[ncol], df[tcs_col], marker="o", label=lang)

    ax.set_title(title)
    configure_axes(ax, logx, logy, xlabel="N", ylabel="Tempo de cálculo (TCS)")
    ax.legend()
    out_path = out_dir / outfile
    fig.tight_layout()
    fig.savefig(out_path, dpi=150)
    plt.close(fig)
    return out_path.name

# ============================
# Main
# ============================
def main():
    args = parse_args()
    out_dir = Path(args.out_dir).resolve()
    if not out_dir.exists():
        print(f"❌ Diretório não encontrado: {out_dir}")
        sys.exit(1)

    exclude = set([s.strip() for s in args.exclude.split(",") if s.strip()])
    # Carrega datasets
    datasets: Dict[str, pd.DataFrame] = {}
    for lang in LANG_ORDER:
        if lang in exclude:
            continue
        path = out_dir / LANG_FILE[lang]
        try:
            df = read_csv_flex(path)
            # sanity: precisa ter ao menos 2 linhas úteis
            if len(df.index) >= 1:
                datasets[lang] = df
            else:
                print(f"ℹ️ Sem dados úteis para {lang}: {path.name}")
        except FileNotFoundError:
            # ok, pode não existir se a linguagem não foi rodada
            continue
        except Exception as e:
            print(f"⚠️ Falha ao ler/normalizar {path.name}: {e}")

    generated: List[str] = []

    # 1) C e C++ com/sem O3
    sel_c_cpp = [l for l in ["C", "C_O3", "C++", "C++_O3"] if l in datasets]
    png = plot_group(
        out_dir, datasets, sel_c_cpp,
        title="C e C++ com e sem O3 (TCS × N)",
        outfile="c_cpp_o3.png",
        logx=args.logx, logy=args.logy
    )
    if png: generated.append(png)

    # 2) Todas as linguagens
    sel_all = [l for l in LANG_ORDER if l in datasets]
    png = plot_group(
        out_dir, datasets, sel_all,
        title="Todas as linguagens (TCS × N)",
        outfile="todas.png",
        logx=args.logx, logy=args.logy
    )
    if png: generated.append(png)

    # 3) Todas as linguagens menos Python
    sel_no_py = [l for l in LANG_ORDER if l in datasets and l != "Python"]
    if sel_no_py:
        png = plot_group(
            out_dir, datasets, sel_no_py,
            title="Todas as linguagens (sem Python) — TCS × N",
            outfile="sem_python.png",
            logx=args.logx, logy=args.logy
        )
        if png: generated.append(png)

    # Índice simples dos PNGs (o run_all.sh já usa isso p/ README/manifest)
    try:
        idx = out_dir / "plots_generated.txt"
        with idx.open("w", encoding="utf-8") as f:
            for name in generated:
                f.write(f"{name}\n")
        if generated:
            print(f"📊 Gerados: {', '.join(generated)}")
        else:
            print("ℹ️ Nenhum gráfico foi gerado (datasets ausentes ou vazios).")
    except Exception as e:
        print(f"⚠️ Não foi possível escrever plots_generated.txt: {e}")

if __name__ == "__main__":
    main()
