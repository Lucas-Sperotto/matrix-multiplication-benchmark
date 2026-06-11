#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import math
import sys
from pathlib import Path


EXPECTED_CSVS = [
    "resultado_c.csv",
    "resultado_c_O3.csv",
    "resultado_cpp.csv",
    "resultado_cpp_O3.csv",
    "resultado_java.csv",
    "resultado_python.csv",
]
EXPECTED_HEADER = ["N", "TCS", "TAM", "TDM"]


def fail(message: str) -> None:
    print(f"ERRO: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_csv(path: Path) -> None:
    if not path.exists():
        fail(f"CSV ausente: {path}")

    with path.open(newline="", encoding="utf-8-sig") as file:
        reader = csv.reader(file)
        try:
            header = next(reader)
        except StopIteration:
            fail(f"CSV vazio: {path}")

        header = [cell.strip() for cell in header]
        if header != EXPECTED_HEADER:
            fail(f"Cabecalho invalido em {path}: {header}. Esperado: {EXPECTED_HEADER}")

        rows = 0
        previous_n: int | None = None
        for line_number, row in enumerate(reader, start=2):
            if not row or all(not cell.strip() for cell in row):
                continue
            if len(row) != len(EXPECTED_HEADER):
                fail(f"Linha {line_number} de {path} tem {len(row)} colunas; esperado {len(EXPECTED_HEADER)}")

            try:
                n = int(row[0])
                tcs = float(row[1])
                tam = float(row[2])
                tdm = float(row[3])
            except ValueError as exc:
                fail(f"Linha {line_number} de {path} contem valor nao numerico: {exc}")

            if n < 1:
                fail(f"Linha {line_number} de {path} tem N invalido: {n}")
            if previous_n is not None and n < previous_n:
                fail(f"Linha {line_number} de {path} tem N fora de ordem: {n} apos {previous_n}")
            if tcs < 0 or tam < 0 or tdm < 0:
                fail(f"Linha {line_number} de {path} tem tempo negativo")
            if not all(math.isfinite(value) for value in (tcs, tam, tdm)):
                fail(f"Linha {line_number} de {path} contem NaN ou Inf")

            previous_n = n
            rows += 1

    if rows == 0:
        fail(f"CSV sem dados: {path}")


def validate_json(path: Path, required_keys: list[str]) -> None:
    if not path.exists():
        fail(f"Arquivo ausente: {path}")

    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        fail(f"JSON invalido em {path}: {exc}")

    for key in required_keys:
        if key not in data:
            fail(f"Chave obrigatoria ausente em {path}: {key}")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Uso: validate_run.py <out/run_id>", file=sys.stderr)
        return 1

    run_dir = Path(argv[1])
    if not run_dir.is_dir():
        fail(f"Diretorio de execucao nao encontrado: {run_dir}")

    for filename in EXPECTED_CSVS:
        validate_csv(run_dir / filename)

    system_info_md = run_dir / "system_info.md"
    if not system_info_md.exists() or system_info_md.stat().st_size == 0:
        fail(f"Arquivo ausente ou vazio: {system_info_md}")

    validate_json(run_dir / "system_info.json", ["generated_at"])
    validate_json(run_dir / "run_manifest.json", ["run_id", "generated_at", "parameters", "languages", "tools"])

    pngs = list(run_dir.glob("grafico_*.png"))
    if not pngs:
        fail(f"Nenhum grafico gerado em {run_dir}")

    print(f"Validacao concluida com sucesso: {run_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
