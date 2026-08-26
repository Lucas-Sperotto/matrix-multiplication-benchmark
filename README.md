# Matrix Multiplication Benchmark

Benchmark reprodutível de multiplicação de matrizes quadradas. O núcleo publicável executa C, C++, Java e Python; Rust, Julia e Elixir podem ser incluídas explicitamente como linguagens opcionais.

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

## Rust, Julia e Elixir (opcionais)

Rust, Julia e Elixir foram aceitas em `src/` e podem ser incluídas na execução via flags — sem elas, o fluxo continua igual ao de sempre (C, C++, Java, Python), sem exigir nenhuma toolchain extra:

```bash
./run_all.sh --batch --run-name meu_teste-linux-100 --B 100 --Npts 2 --M 1 --escala 1 --with-rust --with-julia --with-elixir
# ou, equivalente:
./run_all.sh --batch --run-name meu_teste-linux-100 --B 100 --Npts 2 --M 1 --escala 1 --with-all-extras
```

```powershell
.\run_all.ps1 -Batch -RunName meu_teste-win-100 -B 100 -Npts 2 -M 1 -Escala 1 -WithAllExtras
```

Cada flag exige a toolchain correspondente no `PATH` (`rustc`, `julia`, `elixir`). Se uma linguagem for pedida explicitamente e a toolchain estiver ausente ou a execução falhar, o script inteiro aborta com erro claro — pedir algo explicitamente e não entregá-lo é tratado como falha, não como omissão silenciosa. Sem a flag correspondente, a ausência da toolchain é irrelevante: ela nunca é verificada. Detalhes da arquitetura de integração em [INTEGRATION_PLAN.md](docs/INTEGRATION_PLAN.md) e do contrato de cada linguagem em [EXTRA_LANGUAGES.md](docs/EXTRA_LANGUAGES.md).

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

Com `--with-rust`/`--with-julia`/`--with-elixir`/`--with-all-extras`, a pasta também recebe `resultado_rust.csv`, `resultado_julia.csv` e/ou `resultado_elixir.csv`, e `run_manifest.json` lista exatamente as linguagens que rodaram (nunca uma linguagem opcional não solicitada).

A pasta `out/<run_id>/` só é criada com esse nome final depois que toda a execução termina com sucesso (benchmarks, validação e gráficos); uma execução abortada no meio nunca aparece com o nome de uma execução completa. O identificador não pode ser reutilizado, mesmo que o destino existente esteja vazio. Detalhes em [EXECUTION.md](docs/EXECUTION.md).

Todos os CSVs seguem o mesmo cabeçalho:

```csv
N,TCS,TAM,TDM
```

Onde:

- `N`: dimensão da matriz `N x N`
- `TCS`: tempo de cálculo da multiplicação
- `TAM`: tempo de alocação e inicialização das matrizes
- `TDM`: tempo de desalocação; em Java, Python, Julia e Elixir é registrado como `0.0`

## Metodologia

Cada `N` é medido com uma rodada de warm-up descartada seguida da média de `M` repetições. O desenho experimental completo — variáveis, controles, JIT, GC, layout de memória por linguagem, limitações e ameaças à validade — está em [METHODOLOGY.md](docs/METHODOLOGY.md).

## Estrutura

```text
.
├─ src/          # código-fonte dos benchmarks e gerador de gráficos
├─ experiments/  # versões ainda fora do fluxo publicável
├─ scripts/      # coleta de sistema e validador operacional
├─ tests/        # regressões de contrato e corretude
├─ docs/         # guias, metodologia, diagramas e registros técnicos
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

- [EXECUTION.md](docs/EXECUTION.md): guia completo de execução.
- [METHODOLOGY.md](docs/METHODOLOGY.md): desenho experimental, métricas, limitações e ameaças à validade.
- [CONTRIBUTING.md](CONTRIBUTING.md): como contribuir com resultados ou código.
- [EXTRA_LANGUAGES.md](docs/EXTRA_LANGUAGES.md): contrato, validação e histórico de integração de Rust, Julia e Elixir.
- [OPERATIONS.md](docs/OPERATIONS.md): fundamentação matemática do número de operações.
- [DIAGRAMS.md](docs/DIAGRAMS.md): diagramas de arquitetura e fluxo.
- [TODO.md](TODO.md): tarefas pendentes.

## Licença

Este projeto está licenciado sob a licença MIT. Veja [LICENSE](LICENSE).
