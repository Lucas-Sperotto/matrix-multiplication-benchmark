#!/usr/bin/env python3
"""Regressao para scripts/validate_run.py: confirma que uma execucao
sintetica valida passa, que um CSV com menos linhas que Npts e rejeitado,
e que series de N divergentes entre CSVs da mesma execucao sao rejeitadas.
"""

from __future__ import annotations

import csv
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VALIDATE_RUN = ROOT / "scripts" / "validate_run.py"

CSV_NAMES = [
    "resultado_c.csv",
    "resultado_c_O3.csv",
    "resultado_cpp.csv",
    "resultado_cpp_O3.csv",
    "resultado_java.csv",
    "resultado_python.csv",
]
N_SERIES = [100, 122, 144]


def write_csv(path: Path, n_values: list[int]) -> None:
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(["N", "TCS", "TAM", "TDM"])
        for n in n_values:
            writer.writerow([n, "1.000000e-03", "1.000000e-04", "0.000000e+00"])


def build_valid_run(run_dir: Path) -> None:
    run_dir.mkdir(parents=True, exist_ok=True)
    for name in CSV_NAMES:
        write_csv(run_dir / name, N_SERIES)

    (run_dir / "system_info.md").write_text("# Informacoes\n", encoding="utf-8")
    (run_dir / "system_info.json").write_text(
        json.dumps({"generated_at": "2026-08-25T00:00:00Z"}), encoding="utf-8"
    )
    manifest = {
        "run_id": "fixture",
        "generated_at": "2026-08-25T00:00:00Z",
        "parameters": {"B": 144, "Npts": len(N_SERIES), "M": 1, "escala": 1},
        "languages": [{"name": "C", "flags": "", "output": name} for name in CSV_NAMES],
        "tools": {},
    }
    (run_dir / "run_manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    (run_dir / "grafico_teste.png").write_bytes(b"\x89PNG\r\n")


def run_validator(run_dir: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(VALIDATE_RUN), str(run_dir)],
        capture_output=True,
        text=True,
    )


def expect(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []

    with tempfile.TemporaryDirectory(prefix="validate-run-test ") as tmp:
        root = Path(tmp)

        valid_dir = root / "valido"
        build_valid_run(valid_dir)
        result = run_validator(valid_dir)
        expect(
            result.returncode == 0,
            f"execucao sintetica valida deveria passar, mas falhou: {result.stderr}",
            failures,
        )

        truncated_dir = root / "truncado"
        build_valid_run(truncated_dir)
        write_csv(truncated_dir / "resultado_python.csv", N_SERIES[:-1])
        result = run_validator(truncated_dir)
        expect(
            result.returncode != 0,
            "CSV com menos linhas que Npts deveria ser rejeitado, mas passou",
            failures,
        )
        expect(
            "Npts" in result.stderr or "linhas de dados" in result.stderr,
            f"mensagem de erro nao menciona contagem de linhas/Npts: {result.stderr}",
            failures,
        )

        divergent_dir = root / "divergente"
        build_valid_run(divergent_dir)
        write_csv(divergent_dir / "resultado_python.csv", [100, 121, 144])
        result = run_validator(divergent_dir)
        expect(
            result.returncode != 0,
            "series de N divergentes entre CSVs deveria ser rejeitada, mas passou",
            failures,
        )
        expect(
            "divergem" in result.stderr,
            f"mensagem de erro nao menciona divergencia de series: {result.stderr}",
            failures,
        )

    if failures:
        print("FALHA em scripts/test_validate_run.py:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print("validate_run.py rejeita CSVs truncados e series de N divergentes; aceita execucao valida.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
