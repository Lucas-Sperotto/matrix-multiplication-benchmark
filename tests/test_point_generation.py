#!/usr/bin/env python3
"""Regressao: confirma que a geracao de pontos N da referencia Python usa
arredondamento metade-para-cima (floor(x + 0.5)), a mesma regra documentada
em docs/EXTRA_LANGUAGES.md e usada por C/C++/Java, inclusive em pontos x.5
exatos onde o round() nativo do Python (metade-para-par) divergiria.
"""

from __future__ import annotations

import math
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PYTHON_REFERENCE = ROOT / "src" / "matriz_python.py"

# (B, Npts, escala, descricao)
CASES = [
    (101, 3, 1, "linear com ponto x.5 exato (100.5)"),
    (100, 2, 1, "linear minimo, sem colisao x.5"),
    (144, 3, 0, "logaritmica basica"),
    (103, 5, 1, "linear com multiplos passos fracionarios"),
]


def expected_points(b: int, npts: int, escala: int, a: float = 100.0) -> list[int]:
    """Formula canonica de docs/EXTRA_LANGUAGES.md: metade-para-cima."""
    if escala == 1:
        step = (b - a) / (npts - 1)
        return [math.floor(a + step * i + 0.5) for i in range(npts)]
    ratio = (b / a) ** (1.0 / (npts - 1))
    return [math.floor(a * (ratio**i) + 0.5) for i in range(npts)]


def run_reference(b: int, npts: int, escala: int, out_csv: Path) -> list[int]:
    result = subprocess.run(
        [sys.executable, str(PYTHON_REFERENCE), str(b), str(npts), "1", str(escala), str(out_csv)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"referencia Python falhou para B={b} Npts={npts} escala={escala}: {result.stderr}"
        )
    lines = out_csv.read_text(encoding="utf-8").splitlines()
    return [int(line.split(",")[0]) for line in lines[1:]]


def main() -> int:
    failures: list[str] = []

    with tempfile.TemporaryDirectory(prefix="point-generation-test ") as tmp:
        root = Path(tmp)
        for b, npts, escala, desc in CASES:
            expected = expected_points(b, npts, escala)
            out_csv = root / f"pontos-{b}-{npts}-{escala}.csv"
            actual = run_reference(b, npts, escala, out_csv)
            if actual != expected:
                failures.append(
                    f"B={b} Npts={npts} escala={escala} [{desc}]: "
                    f"obtido {actual}; esperado {expected} (regra: metade-para-cima)"
                )

    if failures:
        print("FALHA: geracao de pontos nao segue a regra documentada (metade-para-cima):", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(f"Geracao de pontos consistente com a regra documentada em {len(CASES)} casos, incluindo x.5 exato.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
