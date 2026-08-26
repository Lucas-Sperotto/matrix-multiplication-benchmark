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


def declare_output(run_dir: Path, language: str, output: str) -> None:
    manifest_path = run_dir / "run_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["languages"].append({"name": language, "flags": "", "output": output})
    manifest_path.write_text(json.dumps(manifest), encoding="utf-8")


def run_validator(run_dir: Path, *, relative: bool = False) -> subprocess.CompletedProcess[str]:
    argument = run_dir.name if relative else str(run_dir)
    return subprocess.run(
        [sys.executable, str(VALIDATE_RUN), argument],
        capture_output=True,
        text=True,
        cwd=run_dir.parent if relative else None,
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

        relative_dir = root / "relativo"
        build_valid_run(relative_dir)
        result = run_validator(relative_dir, relative=True)
        expect(
            result.returncode == 0,
            f"caminho relativo deveria passar, mas falhou: {result.stderr}",
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

        orphan_dir = root / "extra-nao-declarado"
        build_valid_run(orphan_dir)
        write_csv(orphan_dir / "resultado_rust.csv", N_SERIES)
        result = run_validator(orphan_dir)
        expect(
            result.returncode != 0,
            "CSV extra nao declarado no manifesto deveria ser rejeitado, mas passou",
            failures,
        )
        expect(
            "nao declarado" in result.stderr,
            f"mensagem de erro nao menciona CSV nao declarado: {result.stderr}",
            failures,
        )

        declared_extra_dir = root / "extra-declarado"
        build_valid_run(declared_extra_dir)
        write_csv(declared_extra_dir / "resultado_rust.csv", N_SERIES)
        declare_output(declared_extra_dir, "Rust", "resultado_rust.csv")
        result = run_validator(declared_extra_dir)
        expect(
            result.returncode == 0,
            f"CSV extra declarado deveria passar, mas falhou: {result.stderr}",
            failures,
        )

    if failures:
        print("FALHA em tests/test_validate_run.py:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(
        "validate_run.py aceita caminhos relativos e extras declarados; "
        "rejeita CSVs truncados, series divergentes e extras orfaos."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
