# Matrix Multiplication Benchmark

Benchmark reprodutível de multiplicação de matrizes quadradas em C, C++, Java e Python.

O objetivo é comparar tempos de execução entre linguagens usando o mesmo contrato de entrada e o mesmo formato de saída, permitindo que colaboradores rodem os testes localmente e compartilhem seus resultados em `out/<run_id>/`.

## Execução Rápida

Linux/WSL:

```bash
python3 -m pip install -r requirements.txt
./run_all.sh --batch --run-name meu_teste-linux-100 --B 100 --Npts 2 --M 1 --escala 1
```

Windows PowerShell:

```powershell
python -m pip install -r requirements.txt
.\run_all.ps1 -Batch -RunName meu_teste-win-100 -B 100 -Npts 2 -M 1 -Escala 1
```

Também é possível rodar `./run_all.sh` ou `.\run_all.ps1` sem parâmetros para usar o modo interativo.

## Saídas

Cada execução gera uma pasta em `out/<run_id>/` com:

- `resultado_c.csv`
- `resultado_c_O3.csv`
- `resultado_cpp.csv`
- `resultado_cpp_O3.csv`
- `resultado_java.csv`
- `resultado_python.csv`
- `system_info.md`
- `system_info.json`
- `run_manifest.json`
- `grafico_*.png`

Todos os CSVs seguem o mesmo cabeçalho:

```csv
N,TCS,TAM,TDM
```

Onde:

- `N`: dimensão da matriz `N x N`
- `TCS`: tempo de cálculo da multiplicação
- `TAM`: tempo de alocação e inicialização das matrizes
- `TDM`: tempo de desalocação; em Java e Python é registrado como `0.0`

## Estrutura

```text
.
├─ src/          # código-fonte dos benchmarks e gerador de gráficos
├─ experiments/  # versões ainda fora do fluxo publicável
├─ scripts/      # coleta de sistema e validação de execuções
├─ build/        # artefatos de compilação ignorados pelo Git
├─ out/          # resultados versionáveis por execução
├─ run_all.sh    # execução Linux/WSL
└─ run_all.ps1   # execução Windows PowerShell
```

## Validação

Depois de uma execução:

```bash
python3 scripts/validate_run.py out/<run_id>
```

O validador confere CSVs esperados, cabeçalhos, valores numéricos, metadados e gráficos.

## Documentação

- [EXECUTION.md](EXECUTION.md): guia completo de execução.
- [CONTRIBUTING.md](CONTRIBUTING.md): como contribuir com resultados.
- [OPERATIONS.md](OPERATIONS.md): análise teórica de operações.
- [TODO.md](TODO.md): plano de melhorias e próximas fases.

## Licença

Este projeto está licenciado sob a licença MIT. Veja [LICENSE](LICENSE).
