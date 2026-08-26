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

Cada flag exige a toolchain correspondente no `PATH` (`rustc`, `julia`, `elixir`). Se uma linguagem for pedida explicitamente e a toolchain estiver ausente ou a execução falhar, o script inteiro aborta com erro claro — pedir algo explicitamente e não entregá-lo é tratado como falha, não como omissão silenciosa. Sem a flag correspondente, a ausência da toolchain é irrelevante: ela nunca é verificada. Detalhes da arquitetura de integração em [INTEGRATION_PLAN.md](INTEGRATION_PLAN.md) e do contrato de cada linguagem em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

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

Para cada valor de `N`, os benchmarks executam uma rodada de warm-up não cronometrada e depois calculam a média de `M` repetições cronometradas. O warm-up reduz efeitos da primeira execução, especialmente no Java por causa do JIT, e `M` suaviza variações pontuais do sistema.

`TAM` inclui alocação e inicialização das matrizes, `TCS` mede apenas a multiplicação, e `TDM` mede a liberação quando a linguagem permite controle explícito. A versão Java usa `int[][]`, que é um array de arrays e não um buffer contíguo; isso é comportamento padrão da implementação Java deste benchmark e deve ser considerado ao comparar cache locality com C/C++.

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
- [CONTRIBUTING.md](CONTRIBUTING.md): como contribuir com resultados ou código.
- [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md): contrato, validação e histórico de integração de Rust, Julia e Elixir.
- [OPERATIONS.md](OPERATIONS.md): análise teórica de operações.
- [TODO.md](TODO.md): plano de melhorias e próximas fases.

## Licença

Este projeto está licenciado sob a licença MIT. Veja [LICENSE](LICENSE).
