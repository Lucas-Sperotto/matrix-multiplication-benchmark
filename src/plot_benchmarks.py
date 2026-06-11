#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import os
import sys
from pathlib import Path


def die(message: str) -> None:
    print(f"Erro: {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gera graficos dos CSVs de benchmark.")
    parser.add_argument("out_dir", help="Diretorio de saida da execucao")
    parser.add_argument("--logx", action="store_true", help="Usar escala logaritmica no eixo X")
    parser.add_argument("--logy", action="store_true", help="Usar escala logaritmica no eixo Y")
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        metavar="LINGUAGEM",
        help="Excluir uma serie pelo rotulo, por exemplo: Python, C_O3 ou 'C++ -O3'",
    )
    return parser.parse_args(argv[1:])


def normalize_label(label: str) -> str:
    return label.strip().replace(" -O3", "_O3").replace("-O3", "_O3")


ARGS = parse_args(sys.argv)
out_dir = Path(ARGS.out_dir)
out_dir.mkdir(parents=True, exist_ok=True)
mpl_config_dir = Path(os.environ.get("MPLCONFIGDIR", Path.cwd() / ".cache" / "matplotlib"))
mpl_config_dir.mkdir(parents=True, exist_ok=True)
os.environ["MPLCONFIGDIR"] = str(mpl_config_dir)

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
    excluded = {normalize_label(label) for label in ARGS.exclude}
    known_labels = set(FILES)
    unknown = excluded - known_labels
    for label in sorted(unknown):
        print(f"Aviso: --exclude ignorado; serie desconhecida: {label}")

    data: dict[str, list[dict[str, float]]] = {}
    for label, path in FILES.items():
        if label in excluded:
            continue
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
    plotted = False
    for label, rows in series:
        points = [
            (row["N"], row[metric])
            for row in rows
            if (not ARGS.logx or row["N"] > 0) and (not ARGS.logy or row[metric] > 0)
        ]
        if not points:
            print(f"Aviso: serie {label} ignorada em {metric}; sem valores positivos para escala log.")
            continue

        xs = [point[0] for point in points]
        ys = [point[1] for point in points]
        plt.plot(xs, ys, marker="o", label=label)
        plotted = True

    if not plotted:
        plt.close()
        print(f"Aviso: nenhuma serie plotavel para {metric}.")
        return

    plt.xlabel("N (matriz com NxN elementos)")
    plt.ylabel("Tempo (s)")
    plt.title(title)
    if ARGS.logx:
        plt.xscale("log")
    if ARGS.logy:
        plt.yscale("log")
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
        label_c = prefer_c.replace("_O3", " -O3")
        label_cpp = prefer_cpp.replace("_O3", " -O3")
        subset = [(label, data[label]) for label in (prefer_c, prefer_cpp) if label in data]
        title_suffix = f"{label_c} vs {label_cpp}"
        plot_series(
            metric,
            subset,
            f"grafico_{metric}_C_vs_CPP.png",
            f"{title_suffix} - {TITLES[metric]}",
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
        subset = [(label, data[label]) for label in ("C", "C++") if label in data]
        plot_series(
            metric,
            subset,
            f"grafico_{metric}_C_vs_CPP_sem_O3.png",
            f"C vs C++ sem -O3 - {TITLES[metric]}",
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
