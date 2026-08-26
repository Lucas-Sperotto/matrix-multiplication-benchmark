#!/usr/bin/env python3
"""Teste de corretude (nao de desempenho) para src/matriz_python.py.

O modulo de producao ja tem `if __name__ == "__main__":`, entao importa-lo
aqui nao dispara a CLI. Reusa multiply() com um caso conhecido nao
identidade, fora da janela de benchmark.

Executar:
    python3 tests/test_matriz_python.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

import matriz_python  # noqa: E402


def main() -> int:
    mat1 = [[1, 2], [3, 4]]
    mat2 = [[5, 6], [7, 8]]
    res = [[0, 0], [0, 0]]
    expected = [[19, 22], [43, 50]]

    matriz_python.multiply(mat1, mat2, res, 2)

    if res != expected:
        print(f"FALHA: res={res}, esperado={expected}", file=sys.stderr)
        return 1

    print("OK: matriz_python multiply() caso nao identidade 2x2")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
