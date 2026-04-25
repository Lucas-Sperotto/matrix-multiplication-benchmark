#!/usr/bin/env python3
from __future__ import annotations

import csv
import os
import sys
from pathlib import Path


def die(message: str) -> None:
    print(f"Erro: {message}", file=sys.stderr)
    raise SystemExit(1)


if len(sys.argv) != 2:
    die("uso: plot_benchmarks.py <diretorio_de_saida>")

out_dir = Path(sys.argv[1])
out_dir.mkdir(parents=True, exist_ok=True)
mpl_config_dir = out_dir / ".matplotlib"
mpl_config_dir.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("MPLCONFIGDIR", str(mpl_config_dir))

try:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
except Exception as exc:  # pragma: no cover - depends on local environment
    die(
        "matplotlib nao esta instalado ou esta quebrado. "
        "Instale as dependencias com: python3 -m pip install -r requirements.txt "
        f"({exc})"
    )


FILES = {
    "C": out_dir / "resultado_c.csv",
    "C_O3": out_dir / "resultado_c_O3.csv",
    "C++": out_dir / "resultado_cpp.csv",
    "C++_O3": out_dir / "resultado_cpp_O3.csv",
    "Java": out_dir / "resultado_java.csv",
    "Python": out_dir / "resultado_python.csv",
}

METRICS = ["TCS", "TAM", "TDM"]
TITLES = {
    "TCS": "Tempo de Calculo da Multiplicacao",
    "TAM": "Tempo de Alocacao de Memoria",
    "TDM": "Tempo de Desalocacao de Memoria",
}


def read_csv(path: Path) -> list[dict[str, float]]:
    text = path.read_text(encoding="utf-8-sig")
    sample = text[:1024]
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters=",;")
    except csv.Error:
        dialect = csv.excel

    rows: list[dict[str, float]] = []
    reader = csv.DictReader(text.splitlines(), dialect=dialect)
    if reader.fieldnames is None:
        return rows

    fieldnames = [name.strip() for name in reader.fieldnames]
    missing = [col for col in ("N", "TCS", "TAM", "TDM") if col not in fieldnames]
    if missing:
        print(f"Aviso: {path} ignorado; colunas ausentes: {', '.join(missing)}")
        return rows

    for line_number, row in enumerate(reader, start=2):
        try:
            rows.append(
                {
                    "N": float(str(row["N"]).strip()),
                    "TCS": float(str(row["TCS"]).strip()),
                    "TAM": float(str(row["TAM"]).strip()),
                    "TDM": float(str(row["TDM"]).strip()),
                }
            )
        except (TypeError, ValueError):
            print(f"Aviso: linha invalida ignorada em {path}:{line_number}")

    return sorted(rows, key=lambda item: item["N"])


def load_data() -> dict[str, list[dict[str, float]]]:
    data: dict[str, list[dict[str, float]]] = {}
    for label, path in FILES.items():
        if path.exists():
            rows = read_csv(path)
            if rows:
                data[label] = rows

    if not data:
        die(f"nenhum CSV valido encontrado em {out_dir}")
    return data


def plot_series(metric: str, series: list[tuple[str, list[dict[str, float]]]], output_name: str, title: str) -> None:
    if not series:
        print(f"Aviso: nenhuma serie disponivel para {metric}.")
        return

    plt.figure()
    for label, rows in series:
        xs = [row["N"] for row in rows]
        ys = [row[metric] for row in rows]
        plt.plot(xs, ys, marker="o", label=label)

    plt.xlabel("N (matriz com NxN elementos)")
    plt.ylabel("Tempo (s)")
    plt.title(title)
    plt.grid(True, alpha=0.3)
    plt.legend()
    output_path = out_dir / output_name
    plt.savefig(output_path, dpi=160, bbox_inches="tight")
    plt.close()
    print(f"{metric}: salvo em {output_path}")


def main() -> int:
    data = load_data()

    for metric in METRICS:
        plot_series(
            metric,
            [(label, rows) for label, rows in data.items()],
            f"grafico_{metric}_todas_linguagens.png",
            f"Comparacao por linguagem - {TITLES[metric]}",
        )

    for metric in METRICS:
        prefer_c = "C_O3" if "C_O3" in data else "C"
        prefer_cpp = "C++_O3" if "C++_O3" in data else "C++"
        subset = [(label, data[label]) for label in (prefer_c, prefer_cpp) if label in data]
        plot_series(
            metric,
            subset,
            f"grafico_{metric}_C_vs_CPP.png",
            f"C vs C++ - {TITLES[metric]}",
        )

    for metric in METRICS:
        subset = [(label, data[label]) for label in ("C", "C_O3", "C++", "C++_O3") if label in data]
        plot_series(
            metric,
            subset,
            f"grafico_{metric}_C_CPP_com_e_sem_O3.png",
            f"C e C++ (com e sem -O3) - {TITLES[metric]}",
        )

    for metric in METRICS:
        subset = [(label, rows) for label, rows in data.items() if label != "Python"]
        plot_series(
            metric,
            subset,
            f"grafico_{metric}_sem_python.png",
            f"Todas as linguagens exceto Python - {TITLES[metric]}",
        )

    print(f"Concluido. Graficos em: {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
