#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import math
import sys
from pathlib import Path, PurePosixPath, PureWindowsPath


EXPECTED_CSVS = [
    "resultado_c.csv",
    "resultado_c_O3.csv",
    "resultado_cpp.csv",
    "resultado_cpp_O3.csv",
    "resultado_java.csv",
    "resultado_python.csv",
]
OPTIONAL_CSVS = [
    "resultado_rust.csv",
    "resultado_julia.csv",
    "resultado_elixir.csv",
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


def validate_json(path: Path, required_keys: list[str]) -> dict[str, object]:
    if not path.exists():
        fail(f"Arquivo ausente: {path}")

    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        fail(f"JSON invalido em {path}: {exc}")

    if not isinstance(data, dict):
        fail(f"JSON em {path} deve conter um objeto na raiz")

    for key in required_keys:
        if key not in data:
            fail(f"Chave obrigatoria ausente em {path}: {key}")

    return data


def safe_manifest_output(run_dir: Path, output: object, language_index: int) -> Path:
    context = f"languages[{language_index}].output"
    if not isinstance(output, str) or not output or output != output.strip():
        fail(f"{context} deve ser um caminho relativo nao vazio")
    if any(ord(character) < 32 for character in output):
        fail(f"{context} contem caractere de controle")

    windows_path = PureWindowsPath(output)
    normalized = output.replace("\\", "/")
    parts = normalized.split("/")
    if windows_path.is_absolute() or windows_path.drive or normalized.startswith("/"):
        fail(f"{context} nao pode ser absoluto: {output}")
    if any(part in ("", ".", "..") for part in parts):
        fail(f"{context} contem segmento de caminho inseguro: {output}")

    relative_path = PurePosixPath(*parts)
    if relative_path.suffix.lower() != ".csv":
        fail(f"{context} deve apontar para um arquivo CSV: {output}")

    run_root = run_dir.resolve()
    try:
        output_path = (run_root / Path(*relative_path.parts)).resolve()
        output_path.relative_to(run_root)
    except (OSError, RuntimeError, ValueError):
        fail(f"{context} aponta para fora do diretorio da execucao: {output}")

    return output_path


def manifest_csvs(run_dir: Path, manifest: dict[str, object]) -> list[Path]:
    languages = manifest["languages"]
    if not isinstance(languages, list):
        fail("run_manifest.json: languages deve ser uma lista")

    paths: list[Path] = []
    seen: dict[str, int] = {}
    for index, language in enumerate(languages):
        if not isinstance(language, dict):
            fail(f"run_manifest.json: languages[{index}] deve ser um objeto")
        if "output" not in language:
            fail(f"run_manifest.json: languages[{index}] nao declara output")

        path = safe_manifest_output(run_dir, language["output"], index)
        duplicate_key = str(path).casefold()
        if duplicate_key in seen:
            first_index = seen[duplicate_key]
            fail(
                "run_manifest.json: saida CSV duplicada em "
                f"languages[{first_index}] e languages[{index}]: {language['output']}"
            )
        seen[duplicate_key] = index
        paths.append(path)

    return paths


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Uso: validate_run.py <out/run_id>", file=sys.stderr)
        return 1

    run_dir = Path(argv[1])
    if not run_dir.is_dir():
        fail(f"Diretorio de execucao nao encontrado: {run_dir}")

    csv_paths = [run_dir / filename for filename in EXPECTED_CSVS]

    system_info_md = run_dir / "system_info.md"
    if not system_info_md.exists() or system_info_md.stat().st_size == 0:
        fail(f"Arquivo ausente ou vazio: {system_info_md}")

    validate_json(run_dir / "system_info.json", ["generated_at"])
    manifest = validate_json(
        run_dir / "run_manifest.json",
        ["run_id", "generated_at", "parameters", "languages", "tools"],
    )
    csv_paths.extend(manifest_csvs(run_dir, manifest))
    csv_paths.extend(run_dir / filename for filename in OPTIONAL_CSVS if (run_dir / filename).exists())

    validated: set[str] = set()
    for path in csv_paths:
        path_key = str(path.resolve()).casefold()
        if path_key not in validated:
            validate_csv(path)
            validated.add(path_key)

    pngs = list(run_dir.glob("grafico_*.png"))
    if not pngs:
        fail(f"Nenhum grafico gerado em {run_dir}")

    print(f"Validacao concluida com sucesso: {run_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
