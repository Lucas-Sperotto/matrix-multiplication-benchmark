# Como Executar

Este guia é operacional: como instalar, rodar e validar. Para o desenho experimental (métricas, controles, limitações, ameaças à validade), veja [METHODOLOGY.md](METHODOLOGY.md).

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

Instale o ambiente de referência recomendado, Elixir 1.20.3 e Erlang/OTP 28.4, com o script oficial. Os runners registram a versão encontrada, mas ainda não impõem esse par:

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

`check_extra_toolchains.sh` é um script Bash: em Windows nativo (fora de WSL/Git Bash), não há como executá-lo diretamente; confira `rustc --version`, `erl -version`, `elixir --version` e `julia --version` manualmente. Os comandos de macOS e Windows, inclusive o `PATH` persistente de Elixir/OTP, estão em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

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

- `--run-name`: nome da pasta em `out/`; o caminho final (`out/<run-name>/`) deve ser inteiramente inexistente — até um diretório vazio é rejeitado, pois a promoção poderia aninhar o staging dentro dele. A execução escreve primeiro em um diretório de trabalho temporário (`out/.running-<run-name>/`) e só o promove ao nome final depois que todos os benchmarks, a validação e a geração de gráficos terminarem com sucesso — ver "Execuções incompletas" abaixo
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

- `TCS`: janela de cálculo da multiplicação
- `TAM`: janela de alocação e inicialização das matrizes
- `TDM`: tempo de desalocação; em Java, Python, Julia e Elixir é registrado como `0.0`

As fronteiras não são idênticas em todas as implementações: C, C++, Java, Python, Rust e Julia alocam e inicializam/zeram o resultado em TAM; **apenas o Elixir** constrói o resultado dentro de TCS, por imutabilidade da linguagem. Para cada valor de `N`, cada benchmark faz 1 rodada de warm-up cujos tempos são descartados e depois registra a média de `M` repetições. O desenho completo, incluindo JIT/GC, layout e ameaças à validade, está em [METHODOLOGY.md](METHODOLOGY.md).

## Executar Rust, Julia e Elixir isoladamente (desenvolvimento)

Fora do runner, os comandos abaixo continuam úteis para testar uma implementação isoladamente contra o harness de contrato:

```bash
mkdir -p build/linux
rustfmt --check src/matriz_rust.rs
rustc --edition=2021 -C opt-level=3 -D warnings src/matriz_rust.rs -o build/linux/matriz_rust
python3 tests/test_extra_language.py --language Rust -- ./build/linux/matriz_rust

python3 tests/test_extra_language.py --language Julia -- julia src/matriz_Julia.jl

python3 tests/test_extra_language.py --language Elixir -- elixir src/matriz_multiplication.exs
```

O separador `--` informa ao harness onde começa o comando-base; ele próprio acrescenta `B Npts M escala out_csv`. Use a implementação Python como teste de referência do harness:

```bash
python3 tests/test_extra_language.py --language Python -- python3 src/matriz_python.py
```

Cada implementação faz um warm-up por `N`, calcula a média de exatamente `M` repetições, usa multiplicação manual com três iterações aninhadas e valida as nove combinações dos índices inicial, central e final. Rust mede `TDM` ao executar `drop`; Julia e Elixir registram `TDM=0.0`. Veja o desenho experimental em [METHODOLOGY.md](METHODOLOGY.md), os critérios específicos em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md) e a arquitetura de integração em [INTEGRATION_PLAN.md](INTEGRATION_PLAN.md).

**Atenção ao tempo de execução do Elixir**: validações exploratórias locais foram consideravelmente mais lentas que as demais implementações, mas não constituem uma coleta formal preservada. Evite `--with-elixir`/`--with-all-extras` com `B` grande sem testar antes com um `B` pequeno no seu ambiente.

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

## Execuções incompletas

`run_all.sh`/`run_all.ps1` escrevem toda a execução em `out/.running-<run-name>/` e só a promovem (renomeiam) para `out/<run-name>/` depois que **todos** os benchmarks solicitados, `system_info`, os gráficos e `validate_run.py` terminarem com sucesso. Parâmetros inválidos, dependências centrais ausentes, falha do matplotlib ou colisão de nome são detectados antes de criar o staging. Depois que o staging existe, qualquer falha — compilação, toolchain extra ausente, benchmark, metadados, gráficos ou validação — aborta com código diferente de zero, e:

- `out/<run-name>/` (o nome final) **não é criado**; uma execução parcial nunca aparece com o nome de uma execução completa;
- `out/.running-<run-name>/` permanece no disco com o que já tinha sido gerado até a falha, útil para diagnóstico; falhas detectadas antes da criação do staging naturalmente não deixam esse diretório;
- rodar novamente com o mesmo `--run-name`/`-RunName` falha explicitamente enquanto esse diretório de trabalho existir — o script não sobrescreve nem reaproveita silenciosamente uma tentativa anterior incompleta. Remova o diretório manualmente (ou use outro nome) depois de inspecioná-lo.

Um caminho final `out/<run-name>/` já existente também é sempre rejeitado, mesmo vazio. Escolha outro identificador ou remova manualmente apenas um diretório que você tenha confirmado que não contém resultados a preservar.

Este mecanismo não depende de rename entre sistemas de arquivos diferentes: a promoção move o diretório dentro do próprio `out/`.

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
