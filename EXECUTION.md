# Como Executar

Este guia cobre o fluxo principal do MVP: C, C++, Java e Python.

Rust, Julia, Elixir e BLAS existem como experimentos em `experiments/`, mas ainda não fazem parte do fluxo publicável. Para preparar as três novas linguagens sem confundi-las com uma execução oficial, siga [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

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

## Toolchains de Rust, Julia e Elixir

Essas toolchains são opcionais: `run_all.sh` e `run_all.ps1` continuam executando apenas as seis variantes atuais. No Ubuntu ou WSL, instale Rust estável com `rustup`:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"
rustup default stable
```

Instale Elixir 1.20.3 e Erlang/OTP 28.4 com o script oficial:

```bash
cd /tmp
curl -fsSO https://elixir-lang.org/install.sh
sh install.sh elixir@1.20.3 otp@28.4

installs_dir="$HOME/.elixir-install/installs"
export PATH="$installs_dir/elixir/1.20.3-otp-28/bin:$installs_dir/otp/28.4/bin:$PATH"
```

Instale Julia e `juliaup`:

```bash
curl -fsSL https://install.julialang.org | sh
```

Abra um novo terminal quando o instalador solicitar e diagnostique o ambiente:

```bash
./scripts/check_extra_toolchains.sh
```

Os comandos de macOS e Windows, inclusive o `PATH` persistente de Elixir/OTP, estão em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

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

## Executar os protótipos de novas linguagens

Os comandos abaixo são voltados ao desenvolvimento e não tornam os protótipos parte do fluxo principal. Eles só devem produzir um CSV válido depois que o aluno implementar o contrato.

> **Atenção:** não execute os protótipos atuais antes da adaptação. Rust e Julia ignoram a CLI e tentam dimensões fixas de até `10000`; Elixir contém erros de compilação. Os comandos desta seção são critérios pós-implementação.

Rust tem uma etapa de compilação:

```bash
mkdir -p build/extra
rustfmt --check experiments/matriz_rust.rs
rustc --edition=2021 -C opt-level=3 -D warnings experiments/matriz_rust.rs -o build/extra/matriz_rust
./build/extra/matriz_rust 144 3 1 1 "out/tmp-extra-rust/resultado_rust.csv"
python3 scripts/test_extra_language.py --language Rust -- ./build/extra/matriz_rust
```

Julia e Elixir executam seus scripts diretamente:

```bash
julia experiments/matriz_Julia.jl 144 3 1 1 "out/tmp-extra-julia/resultado_julia.csv"
python3 scripts/test_extra_language.py --language Julia -- julia experiments/matriz_Julia.jl

elixir experiments/matriz_multiplication.exs 144 3 1 1 "out/tmp-extra-elixir/resultado_elixir.csv"
python3 scripts/test_extra_language.py --language Elixir -- elixir experiments/matriz_multiplication.exs
```

O separador `--` informa ao harness onde começa o comando-base; ele próprio acrescenta `B Npts M escala out_csv`. Use a implementação Python como teste de referência do harness:

```bash
python3 scripts/test_extra_language.py --language Python -- python3 src/matriz_python.py
```

Cada implementação nova deve fazer um warm-up por `N`, calcular a média de exatamente `M` repetições, usar multiplicação manual com três laços e validar as nove combinações dos índices inicial, central e final. Rust mede `TDM` ao executar `drop`; Julia e Elixir registram `TDM=0.0`. Veja todos os critérios e o fluxo de PR em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

Mesmo depois de aprovado, o arquivo só deve sair de `experiments/` para `src/` com aceite explícito do mantenedor. A inclusão opcional nos runners e no manifesto pertence a um PR de integração posterior.

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
