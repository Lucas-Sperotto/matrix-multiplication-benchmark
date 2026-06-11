#!/usr/bin/env python3
# **********************************************************************
# Projeto: Benchmark de Multiplicação de Matrizes
# Descrição: Multiplicação de matrizes N x N em Python puro, medindo
#            tempo de alocação (TAM), cálculo (TCS) e desalocação (TDM).
#            TDM é sempre 0.0 pois Python não possui desalocação manual.
#
# Linguagem: Python
#
# Autores: Lucas Kriesel Sperotto, Marcos Adriano Silva David
# Data: 05/09/2024
#
# Parâmetros (CLI): B Npts M Escala out_csv
#  - B: tamanho máximo da matriz; N varia de 100 até B
#  - Npts: número de pontos na escala (mín. 2)
#  - M: repetições para calcular a média
#  - Escala: 0=logarítmica, 1=linear
#  - out_csv: caminho do arquivo CSV de saída
# **********************************************************************
from __future__ import annotations

import csv
import sys
import time
from pathlib import Path


def parse_int(text: str, name: str, min_value: int, max_value: int) -> int:
    try:
        value = int(text)
    except ValueError as exc:
        raise ValueError(f"Parametro invalido para {name}: {text}") from exc

    if value < min_value or value > max_value:
        raise ValueError(f"Parametro invalido para {name}: {text}")
    return value


def make_points(b: int, npts: int, escala: int, a: float = 100.0) -> list[int]:
    if escala == 1:
        step = (b - a) / (npts - 1)
        return [round(a + step * i) for i in range(npts)]

    ratio = (b / a) ** (1.0 / (npts - 1))
    return [round(a * (ratio**i)) for i in range(npts)]


def multiply(mat1: list[list[int]], mat2: list[list[int]], n: int) -> list[list[int]]:
    res = [[0] * n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            total = 0
            for k in range(n):
                total += mat1[i][k] * mat2[k][j]
            res[i][j] = total
    return res


def verify_sample(res: list[list[int]], n: int) -> None:
    idxs = (0, n // 2, n - 1)
    for i in idxs:
        for j in idxs:
            if res[i][j] != i + j:
                raise RuntimeError(f"Erro na multiplicacao para N={n} em [{i},{j}]")


def run_once(n: int) -> tuple[float, float, float]:
    start_alloc = time.perf_counter()
    mat1 = [[i + j for j in range(n)] for i in range(n)]
    mat2 = [[1 if i == j else 0 for j in range(n)] for i in range(n)]
    end_alloc = time.perf_counter()

    start_calc = time.perf_counter()
    res = multiply(mat1, mat2, n)
    end_calc = time.perf_counter()

    verify_sample(res, n)
    return end_calc - start_calc, end_alloc - start_alloc, 0.0


def main(argv: list[str]) -> int:
    if len(argv) != 6:
        print(f"Uso: python {argv[0]} <B> <Npts> <M> <Escala> <out_csv>", file=sys.stderr)
        print(f"Exemplo: python {argv[0]} 4000 12 5 1 out/execucao/resultado_python.csv", file=sys.stderr)
        return 1

    try:
        b = parse_int(argv[1], "B", 100, 100000)
        npts = parse_int(argv[2], "Npts", 2, 10000)
        m_count = parse_int(argv[3], "M", 1, 100000)
        escala = parse_int(argv[4], "Escala", 0, 1)
        out_csv = Path(argv[5])
    except ValueError as exc:
        print(exc, file=sys.stderr)
        return 1

    out_csv.parent.mkdir(parents=True, exist_ok=True)

    with out_csv.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file, lineterminator="\n")
        writer.writerow(["N", "TCS", "TAM", "TDM"])

        for n in make_points(b, npts, escala):
            run_once(n)

            time_calc = 0.0
            time_alloc = 0.0
            time_free = 0.0

            for _ in range(m_count):
                calc, alloc, free = run_once(n)
                time_calc += calc
                time_alloc += alloc
                time_free += free

            writer.writerow(
                [
                    n,
                    f"{time_calc / m_count:.6e}",
                    f"{time_alloc / m_count:.6e}",
                    f"{time_free / m_count:.6e}",
                ]
            )
            print(f"Resultados para N = {n} salvos.")

    print(f"Todos os resultados foram salvos em {out_csv}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
