# Como Executar

Este guia cobre o fluxo principal do MVP: C, C++, Java e Python.

Rust, Julia, Elixir e BLAS existem como experimentos em `experiments/`, mas ainda não fazem parte do fluxo publicável.

## Pré-requisitos

Linux/WSL:

- `gcc`
- `g++`
- `java`
- `javac`
- `python3`
- pacotes Python de `requirements.txt`

Ubuntu/Debian/WSL:

```bash
sudo apt update
sudo apt install -y gcc g++ default-jdk python3 python3-pip
python3 -m pip install -r requirements.txt
```

Windows PowerShell:

- GCC/G++ via MSYS2/MinGW ou toolchain equivalente disponível no `PATH`
- Java JDK disponível no `PATH`
- Python disponível no `PATH`

```powershell
python -m pip install -r requirements.txt
```

## Execução Linux/WSL

Modo interativo:

```bash
./run_all.sh
```

Modo batch:

```bash
./run_all.sh --batch --run-name exemplo-linux-100 --B 100 --Npts 2 --M 1 --escala 1
```

Parâmetros:

- `--run-name`: nome da pasta em `out/`
- `--B`: maior valor de `N`
- `--Npts`: quantidade de pontos entre `100` e `B`
- `--M`: repetições para média
- `--escala`: `0` para logarítmica, `1` para linear

## Execução Windows

Modo interativo:

```powershell
.\run_all.ps1
```

Modo batch:

```powershell
.\run_all.ps1 -Batch -RunName exemplo-win-100 -B 100 -Npts 2 -M 1 -Escala 1
```

## Contrato dos Benchmarks

Cada benchmark principal aceita:

```text
B Npts M escala out_csv
```

Exemplo:

```bash
./build/linux/matriz_c 300 3 1 1 out/teste/resultado_c.csv
```

Todos escrevem CSV com:

```csv
N,TCS,TAM,TDM
```

Campos:

- `TCS`: tempo de cálculo da multiplicação
- `TAM`: tempo de alocação e inicialização das matrizes
- `TDM`: tempo de desalocação; em Java e Python é registrado como `0.0`

Para cada valor de `N`, cada benchmark faz 1 rodada de warm-up não cronometrada e depois registra a média de `M` repetições. O warm-up ajuda a reduzir efeitos da primeira execução, especialmente no Java por causa do JIT.

A implementação Java usa `int[][]`, que é um array de arrays e não um buffer contíguo. Esse desenho é intencional para a versão Java atual e deve ser levado em conta na interpretação dos resultados.

## Artefatos

Os scripts compilam para:

```text
build/linux/
build/windows/
build/java/
```

Os resultados ficam em:

```text
out/<run_id>/
```

Nenhum `resultado_*.csv`, executável ou `.class` deve ser criado na raiz do projeto.

## Validação

```bash
python3 scripts/validate_run.py out/<run_id>
```

O validador confere:

- CSVs esperados
- cabeçalho `N,TCS,TAM,TDM`
- valores numéricos
- `system_info.md`
- `system_info.json`
- `run_manifest.json`
- gráficos `grafico_*.png`

## Problemas Comuns

Dependência ausente:

```text
Dependencia ausente: gcc
```

Instale a dependência indicada e execute novamente.

Pacote Python ausente:

```bash
python3 -m pip install -r requirements.txt
```

Resultados antigos com `TLM`:

Arquivos gerados antes do MVP podem usar `TLM` ou não ter `TDM`. Gere uma nova execução para usar o formato publicável.
