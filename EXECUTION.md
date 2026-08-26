# Como Executar

Este guia cobre o fluxo principal: C, C++, Java e Python, sempre executados, e Rust, Julia e Elixir, opcionais via flag.

BLAS existe como experimento em `experiments/` e ainda não faz parte do fluxo publicável.

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

Essas toolchains são opcionais: sem as flags `--with-rust`/`--with-julia`/`--with-elixir`, `run_all.sh` e `run_all.ps1` continuam executando apenas as seis variantes de sempre, sem exigir nenhuma delas. No Ubuntu ou WSL, instale Rust estável com `rustup`:

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

- `--run-name`: nome da pasta em `out/`; o diretório deve ser novo ou estar vazio para impedir mistura de execuções
- `--B`: maior valor de `N`
- `--Npts`: quantidade de pontos entre `100` e `B`
- `--M`: repetições para média
- `--escala`: `0` para logarítmica, `1` para linear
- `--with-rust` / `--with-julia` / `--with-elixir`: incluem a linguagem correspondente (exige a toolchain no `PATH`; se pedida e ausente ou se a execução falhar, o script inteiro aborta)
- `--with-all-extras`: equivalente às três flags acima juntas

## Execução Windows

Modo interativo:

```powershell
.\run_all.ps1
```

Modo batch:

```powershell
.\run_all.ps1 -Batch -RunName exemplo-win-100 -B 100 -Npts 2 -M 1 -Escala 1
```

Com as extras opcionais: `-WithRust`, `-WithJulia`, `-WithElixir` ou `-WithAllExtras`, mesma semântica do Linux/WSL.

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
- `TDM`: tempo de desalocação; em Java, Python, Julia e Elixir é registrado como `0.0`

Para cada valor de `N`, cada benchmark faz 1 rodada de warm-up não cronometrada e depois registra a média de `M` repetições. O warm-up ajuda a reduzir efeitos da primeira execução, especialmente no Java por causa do JIT.

A implementação Java usa `int[][]`, que é um array de arrays e não um buffer contíguo. Esse desenho é intencional para a versão Java atual e deve ser levado em conta na interpretação dos resultados.

## Executar Rust, Julia e Elixir isoladamente (desenvolvimento)

Fora do runner, os comandos abaixo continuam úteis para testar uma implementação isoladamente contra o harness de contrato:

```bash
mkdir -p build/linux
rustfmt --check src/matriz_rust.rs
rustc --edition=2021 -C opt-level=3 -D warnings src/matriz_rust.rs -o build/linux/matriz_rust
python3 scripts/test_extra_language.py --language Rust -- ./build/linux/matriz_rust

python3 scripts/test_extra_language.py --language Julia -- julia src/matriz_Julia.jl

python3 scripts/test_extra_language.py --language Elixir -- elixir src/matriz_multiplication.exs
```

O separador `--` informa ao harness onde começa o comando-base; ele próprio acrescenta `B Npts M escala out_csv`. Use a implementação Python como teste de referência do harness:

```bash
python3 scripts/test_extra_language.py --language Python -- python3 src/matriz_python.py
```

Cada implementação faz um warm-up por `N`, calcula a média de exatamente `M` repetições, usa multiplicação manual com três laços e valida as nove combinações dos índices inicial, central e final. Rust mede `TDM` ao executar `drop`; Julia e Elixir registram `TDM=0.0`. Veja a metodologia completa em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md) e a arquitetura de integração ao runner em [INTEGRATION_PLAN.md](INTEGRATION_PLAN.md).

**Atenção ao tempo de execução do Elixir**: a multiplicação manual em Elixir é ordens de magnitude mais lenta que C/Rust/Julia para o mesmo `N` (aritmética genérica do BEAM em vez de inteiros nativos). Evite `--with-elixir`/`--with-all-extras` com `B` grande sem testar antes com um `B` pequeno.

## Artefatos

Os scripts compilam para:

```text
build/linux/    # inclui matriz_rust quando --with-rust é usado
build/windows/  # inclui matriz_rust.exe quando -WithRust é usado
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

O manifesto é a fonte autoritativa para as linguagens opcionais: um CSV de Rust, Julia ou Elixir presente no diretório, mas não declarado em `run_manifest.json`, invalida a execução. Use sempre um `run-name` novo em vez de reaproveitar uma pasta antiga.

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
