#!/usr/bin/env python3
"""Testa o contrato de linha de comando e CSV de uma linguagem extra.

O comando informado deve aceitar, nessa ordem, os argumentos
``B Npts M escala out_csv``. O harness acrescenta esses argumentos ao
comando-base recebido depois de ``--``.
"""

from __future__ import annotations

import argparse
import csv
import math
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence


EXPECTED_HEADER = ["N", "TCS", "TAM", "TDM"]
TIMEOUT_SECONDS = 120


class ContractError(RuntimeError):
    """Indica que a implementacao testada violou o contrato."""


@dataclass(frozen=True)
class ProcessResult:
    returncode: int
    stdout: str
    stderr: str


def parse_cli(argv: Sequence[str]) -> tuple[str, list[str]]:
    parser = argparse.ArgumentParser(
        description="Valida uma implementacao extra do benchmark.",
        usage="%(prog)s --language NOME -- COMANDO [ARGUMENTOS_DO_COMANDO...]",
    )
    parser.add_argument("--language", required=True, help="nome exibido nos resultados")

    try:
        separator = argv.index("--")
    except ValueError:
        separator = -1

    if separator < 0:
        if "--help" in argv or "-h" in argv:
            parser.parse_args(list(argv))
        raise ContractError("use '--' antes do comando que sera testado")

    options = parser.parse_args(list(argv[:separator]))
    command = list(argv[separator + 1 :])

    language = options.language.strip()
    if not language:
        raise ContractError("--language nao pode ser vazio")
    if not command:
        raise ContractError("informe um comando depois de '--'")

    return language, command


def shorten(text: str, limit: int = 4_000) -> str:
    if len(text) <= limit:
        return text
    return f"{text[:limit]}\n... (saida truncada pelo harness)"


def process_details(result: ProcessResult) -> str:
    return (
        f"codigo de saida: {result.returncode}\n"
        f"stdout:\n{shorten(result.stdout) or '(vazio)'}\n"
        f"stderr:\n{shorten(result.stderr) or '(vazio)'}"
    )


def run_command(command: Sequence[str], arguments: Sequence[str]) -> ProcessResult:
    invocation = [*command, *arguments]
    try:
        completed = subprocess.run(
            invocation,
            check=False,
            capture_output=True,
            encoding="utf-8",
            errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
    except FileNotFoundError as exc:
        raise ContractError(f"comando nao encontrado: {command[0]}") from exc
    except PermissionError as exc:
        raise ContractError(f"comando sem permissao de execucao: {command[0]}") from exc
    except subprocess.TimeoutExpired as exc:
        raise ContractError(
            f"comando excedeu o limite de {TIMEOUT_SECONDS} segundos: {' '.join(invocation)}"
        ) from exc

    return ProcessResult(completed.returncode, completed.stdout, completed.stderr)


def assert_error_case(
    command: Sequence[str], case_name: str, arguments: Sequence[str], output_path: Path | None
) -> None:
    result = run_command(command, arguments)
    if result.returncode == 0:
        raise ContractError(
            f"caso '{case_name}' deveria falhar, mas terminou com sucesso\n{process_details(result)}"
        )
    if not result.stderr.strip():
        raise ContractError(
            f"caso '{case_name}' falhou sem explicar o erro em stderr\n"
            f"{process_details(result)}"
        )
    if output_path is not None and output_path.exists():
        raise ContractError(
            f"caso '{case_name}' criou o CSV mesmo apos falhar: {output_path}\n"
            f"{process_details(result)}"
        )


def validate_csv(path: Path, expected_points: Sequence[int]) -> None:
    if not path.is_file():
        raise ContractError(f"CSV nao foi criado: {path}")

    try:
        with path.open("r", encoding="utf-8", newline="") as csv_file:
            rows = list(csv.reader(csv_file))
    except (OSError, UnicodeError, csv.Error) as exc:
        raise ContractError(f"nao foi possivel ler o CSV {path}: {exc}") from exc

    if not rows:
        raise ContractError(f"CSV vazio: {path}")
    if rows[0] != EXPECTED_HEADER:
        raise ContractError(
            f"cabecalho invalido em {path}: {rows[0]!r}; esperado {EXPECTED_HEADER!r}"
        )

    data_rows = rows[1:]
    if len(data_rows) != len(expected_points):
        raise ContractError(
            f"{path} tem {len(data_rows)} linhas de dados; esperado {len(expected_points)}"
        )

    actual_points: list[int] = []
    for line_number, row in enumerate(data_rows, start=2):
        if len(row) != len(EXPECTED_HEADER):
            raise ContractError(
                f"linha {line_number} de {path} tem {len(row)} colunas; esperado 4"
            )

        try:
            n = int(row[0])
        except ValueError as exc:
            raise ContractError(
                f"N nao inteiro na linha {line_number} de {path}: {row[0]!r}"
            ) from exc

        try:
            times = [float(value) for value in row[1:]]
        except ValueError as exc:
            raise ContractError(
                f"tempo nao numerico na linha {line_number} de {path}: {row[1:]!r}"
            ) from exc

        if not all(math.isfinite(value) for value in times):
            raise ContractError(f"NaN ou infinito na linha {line_number} de {path}: {times!r}")
        if any(value < 0.0 for value in times):
            raise ContractError(f"tempo negativo na linha {line_number} de {path}: {times!r}")

        actual_points.append(n)

    if actual_points != list(expected_points):
        raise ContractError(
            f"pontos incorretos em {path}: {actual_points}; esperado {list(expected_points)}"
        )


def assert_success_case(
    command: Sequence[str], case_name: str, scale: int, expected_points: Sequence[int], case_dir: Path
) -> None:
    output_path = case_dir / "resultado.csv"
    result = run_command(command, ["144", "3", "1", str(scale), str(output_path)])
    if result.returncode != 0:
        raise ContractError(
            f"caso '{case_name}' falhou inesperadamente\n{process_details(result)}"
        )
    validate_csv(output_path, expected_points)


def assert_overwrite_case(command: Sequence[str], case_dir: Path) -> None:
    """Confirma que uma segunda execucao substitui, em vez de anexar, o CSV."""
    output_path = case_dir / "resultado.csv"
    arguments = ["100", "2", "1", "1", str(output_path)]

    first = run_command(command, arguments)
    if first.returncode != 0:
        raise ContractError(
            "caso 'sobrescrita do CSV' falhou na primeira execucao\n"
            f"{process_details(first)}"
        )

    second = run_command(command, arguments)
    if second.returncode != 0:
        raise ContractError(
            "caso 'sobrescrita do CSV' falhou na segunda execucao\n"
            f"{process_details(second)}"
        )

    validate_csv(output_path, [100, 100])


def run_contract(language: str, command: Sequence[str]) -> None:
    with tempfile.TemporaryDirectory(prefix="benchmark extra language ") as temporary:
        root = Path(temporary)

        assert_error_case(command, "argumentos ausentes", [], None)

        invalid_cases = (
            ("B abaixo do minimo", ["99", "3", "1", "1"]),
            ("Npts abaixo do minimo", ["144", "1", "1", "1"]),
            ("M abaixo do minimo", ["144", "3", "0", "1"]),
            ("escala invalida", ["144", "3", "1", "2"]),
            ("argumento nao numerico", ["abc", "3", "1", "1"]),
        )
        for index, (case_name, prefix) in enumerate(invalid_cases, start=1):
            case_dir = root / f"erro {index}"
            case_dir.mkdir(parents=True)
            output_path = case_dir / "resultado.csv"
            assert_error_case(command, case_name, [*prefix, str(output_path)], output_path)

        extra_argument_dir = root / "erro argumentos extras"
        extra_argument_dir.mkdir(parents=True)
        extra_argument_output = extra_argument_dir / "resultado.csv"
        assert_error_case(
            command,
            "argumentos extras",
            ["144", "3", "1", "1", str(extra_argument_output), "extra"],
            extra_argument_output,
        )

        assert_success_case(command, "escala linear", 1, [100, 122, 144], root / "escala linear")
        assert_success_case(command, "escala logaritmica", 0, [100, 120, 144], root / "escala logaritmica")
        assert_overwrite_case(command, root / "sobrescrita do CSV")

    print(f"Contrato de {language} validado com sucesso.")


def main(argv: Sequence[str]) -> int:
    try:
        language, command = parse_cli(argv)
        run_contract(language, command)
    except ContractError as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
