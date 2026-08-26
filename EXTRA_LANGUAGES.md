# Trilha Rust, Julia e Elixir

Este guia prepara a contribuicao do aluno responsavel por Rust, Julia e Elixir. A base de trabalho e a branch `tcc-lic-thassio`; as implementacoes existentes em `experiments/` sao apenas prototipos e ainda nao atendem ao contrato publicavel.

O trabalho deve seguir esta ordem, com um Pull Request por linguagem:

1. `feat/rust-benchmark`
2. `feat/julia-benchmark`
3. `feat/elixir-benchmark`

Cada PR deve usar `tcc-lic-thassio` como branch de destino. Somente comece a linguagem seguinte depois de atualizar a base com o PR anterior aceito. A integracao dos extras nos orquestradores, manifesto, graficos e execucoes publicaveis e uma etapa posterior e opcional; ela nao deve ser misturada aos tres PRs de implementacao.

## 1. Preparar o ambiente

### Ubuntu ou WSL (recomendado)

Dependencias basicas:

```bash
sudo apt update
sudo apt install -y build-essential curl default-jdk git python3 python3-pip python3-venv

python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Rust deve ser instalado pelo [`rustup` oficial](https://www.rust-lang.org/tools/install):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"
rustup default stable
rustup component add rustfmt
rustc --version
cargo --version
```

Elixir deve usar exatamente Elixir 1.20.3 com Erlang/OTP 28.4. Execute o [`install.sh` oficial](https://elixir-lang.org/install/) e ajuste o `PATH`:

```bash
cd /tmp
curl -fsSO https://elixir-lang.org/install.sh
sh install.sh elixir@1.20.3 otp@28.4

installs_dir="$HOME/.elixir-install/installs"
export PATH="$installs_dir/elixir/1.20.3-otp-28/bin:$installs_dir/otp/28.4/bin:$PATH"

elixir --version
erl -s erlang halt
```

Para tornar o ajuste permanente, adicione estas linhas ao final de `~/.bashrc` (ou do arquivo de configuracao do seu shell) e abra um novo terminal:

```bash
installs_dir="$HOME/.elixir-install/installs"
export PATH="$installs_dir/elixir/1.20.3-otp-28/bin:$installs_dir/otp/28.4/bin:$PATH"
```

Julia deve ser instalada pelo [`juliaup` oficial](https://julialang.org/downloads/):

```bash
curl -fsSL https://install.julialang.org | sh
```

Abra um novo terminal e confira:

```bash
juliaup status
julia --version
```

Por fim, na raiz do repositorio:

```bash
./scripts/check_extra_toolchains.sh
python3 scripts/test_extra_language.py --language Python -- python3 src/matriz_python.py
```

O segundo comando testa o harness contra a implementacao Python de referencia. Ele nao testa Rust, Julia ou Elixir.

O ambiente virtual evita misturar o Matplotlib do sistema com versoes de NumPy instaladas no perfil do usuario. Ative-o novamente com `source .venv/bin/activate` sempre que for executar o fluxo completo do repositorio.

### macOS

Instale primeiro as ferramentas de linha de comando e depois use os mesmos instaladores oficiais de sistemas Unix:

```bash
xcode-select --install
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
curl -fsSL https://install.julialang.org | sh

cd /tmp
curl -fsSO https://elixir-lang.org/install.sh
sh install.sh elixir@1.20.3 otp@28.4
```

Adicione ao `~/.zshrc` o mesmo `PATH` de Elixir/OTP mostrado para Ubuntu, abra um novo terminal e confira `rustc --version`, `elixir --version` e `julia --version`.

### Windows nativo

WSL oferece o ambiente mais proximo do fluxo Linux. Para trabalhar nativamente no PowerShell:

```powershell
# Rust; aceite a instalacao das ferramentas MSVC se o instalador solicitar.
Invoke-WebRequest https://win.rustup.rs/x86_64 -OutFile rustup-init.exe
.\rustup-init.exe

# Elixir 1.20.3 e Erlang/OTP 28.4.
curl.exe -fsSO https://elixir-lang.org/install.bat
.\install.bat elixir@1.20.3 otp@28.4
$installs_dir = "$env:USERPROFILE\.elixir-install\installs"
$env:PATH = "$installs_dir\elixir\1.20.3-otp-28\bin;$installs_dir\otp\28.4\bin;$env:PATH"

# Julia e juliaup.
winget install --name Julia --id 9NJNWW8PVKMN -e -s msstore
```

O ajuste de `$env:PATH` acima vale para a sessao atual. Torne os dois diretorios do Elixir permanentes nas variaveis de ambiente do usuario e abra um novo PowerShell. Depois confira:

```powershell
rustc --version
elixir --version
julia --version
```

## 2. Criar o fork a partir da branch correta

No GitHub, crie seu fork de `Lucas-Sperotto/matrix-multiplication-benchmark`. Se a tela oferecer a opcao de copiar somente a branch principal, desmarque-a. Em seguida, substitua `SEU_USUARIO` abaixo pelo seu usuario:

```bash
git clone https://github.com/SEU_USUARIO/matrix-multiplication-benchmark.git
cd matrix-multiplication-benchmark
git remote add upstream https://github.com/Lucas-Sperotto/matrix-multiplication-benchmark.git
git fetch upstream tcc-lic-thassio
git switch --create tcc-lic-thassio --track upstream/tcc-lic-thassio
git push --set-upstream origin tcc-lic-thassio
```

Se `tcc-lic-thassio` ja existir localmente porque o GitHub copiou todas as branches, use em vez do `git switch --create`:

```bash
git switch tcc-lic-thassio
git branch --set-upstream-to=upstream/tcc-lic-thassio
```

Confira a configuracao. `origin` deve apontar para o seu fork e `upstream` para o repositorio original:

```bash
git remote -v
git branch --show-current
git status
```

Antes de abrir cada branch de linguagem, sincronize a base:

```bash
git switch tcc-lic-thassio
git fetch upstream
git merge --ff-only upstream/tcc-lic-thassio
git push origin tcc-lic-thassio
```

Crie somente a branch da etapa atual:

```bash
# Primeira etapa
git switch --create feat/rust-benchmark

# Depois que o PR de Rust for aceito e a base for sincronizada
git switch --create feat/julia-benchmark

# Depois que o PR de Julia for aceito e a base for sincronizada
git switch --create feat/elixir-benchmark
```

Ao abrir cada PR, selecione explicitamente:

- repositorio de destino: `Lucas-Sperotto/matrix-multiplication-benchmark`;
- branch de destino (base): `tcc-lic-thassio`;
- branch de origem (compare): a `feat/...` correspondente no seu fork.

Nunca abra esses PRs contra `main` e nao misture duas linguagens no mesmo PR.

## 3. Contrato obrigatorio

Toda implementacao recebe exatamente cinco argumentos posicionais:

```text
B Npts M escala out_csv
```

- `B`: maior dimensao, inteiro entre `100` e `100000`;
- `Npts`: quantidade de pontos, inteiro entre `2` e `10000`;
- `M`: quantidade de repeticoes medidas, inteiro entre `1` e `100000`;
- `escala`: `0` para logaritmica ou `1` para linear;
- `out_csv`: caminho do CSV, inclusive quando o diretorio contem espacos.

Os `Npts` valores de `N` vao de `100` a `B`, incluindo as duas extremidades, em ordem nao decrescente. Na escala linear, use pontos igualmente espacados; na logaritmica, use uma progressao geometrica. Arredonde cada ponto ao inteiro mais proximo, como nas implementacoes de referencia.

As formulas de referencia, para `i` entre `0` e `Npts - 1`, sao:

```text
linear:      100 + (B - 100) * i / (Npts - 1)
logaritmica: 100 * (B / 100) ** (i / (Npts - 1))
```

Como todos os valores sao positivos, use arredondamento de metade para cima (`floor(x + 0.5)`). Pontos repetidos depois do arredondamento sao permitidos e devem permanecer no CSV.

Argumentos ausentes, extras ou invalidos devem produzir mensagem em `stderr`, terminar com codigo diferente de zero e nao criar o CSV de saida. Crie os diretorios pais de `out_csv` quando necessario.

O arquivo deve ser sobrescrito e usar exatamente:

```csv
N,TCS,TAM,TDM
```

Ele deve conter exatamente `Npts` linhas de dados. Os tempos sao segundos, com ponto decimal, finitos e nao negativos:

- `TAM`: alocacao e inicializacao das duas entradas e do resultado;
- `TCS`: somente a multiplicacao manual;
- `TDM`: liberacao explicita em Rust; `0.0` em Julia e Elixir por causa do gerenciamento automatico de memoria.

## 4. Metodologia comum

Para cada `N`:

1. aloque `A`, `B` e `C` e inicialize `A[i,j] = i + j`, considerando indices logicos iniciados em zero;
2. inicialize `B` como identidade;
3. multiplique manualmente com tres lacos, sem BLAS, `matmul`, pacotes numericos, paralelismo ou uma operacao pronta de multiplicacao;
4. valide nove posicoes de `C`, combinando os indices logicos `0`, `N/2` e `N-1` em linhas e colunas;
5. execute uma rodada completa de warm-up e descarte seus tempos;
6. execute exatamente `M` rodadas medidas e grave a media aritmetica separada de `TAM`, `TCS` e `TDM`.

Use um relogio monotonicamente crescente e de alta resolucao. A validacao fica fora de `TCS`. Se uma alocacao, escrita ou verificacao falhar, encerre com codigo diferente de zero e explique a falha em `stderr`.

## 5. Criterios por linguagem

### Rust

- mantenha os dados em buffers planos `Vec<i32>` e indexe por `i * N + j`;
- trate overflow no calculo do tamanho antes de alocar;
- cronometre com `std::time::Instant`;
- use `drop` para tornar a liberacao explicita e medir `TDM`;
- nao adicione crates: o prototipo deve continuar compilavel apenas com `rustc`.

Trabalhe primeiro em `experiments/matriz_rust.rs`. Os comandos abaixo so devem ser executados depois que o arquivo aceitar o contrato; o prototipo atual ignora a CLI e tenta dimensoes muito grandes:

```bash
mkdir -p build/extra
rustfmt --check experiments/matriz_rust.rs
rustc --edition=2021 -C opt-level=3 -D warnings experiments/matriz_rust.rs -o build/extra/matriz_rust

./build/extra/matriz_rust 144 3 1 1 "out/tmp-extra-rust/resultado_rust.csv"
python3 scripts/test_extra_language.py --language Rust -- ./build/extra/matriz_rust
```

### Julia

- preserve a multiplicacao explicita; nao use o operador `*` para matrizes nem `LinearAlgebra.mul!`;
- use `time_ns()` para medir intervalos e converta nanossegundos para segundos;
- considere a indexacao nativa iniciada em 1 ao gerar os mesmos valores logicos das outras linguagens;
- mantenha `TDM=0.0` e nao inclua uma coleta forcada do GC na metrica;
- use apenas a biblioteca padrao.

Trabalhe primeiro no nome historico `experiments/matriz_Julia.jl`. Nao execute o prototipo atual antes de adaptar a CLI: ele tambem percorre dimensoes fixas ate `10000`.

```bash
julia experiments/matriz_Julia.jl 144 3 1 1 "out/tmp-extra-julia/resultado_julia.csv"
python3 scripts/test_extra_language.py --language Julia -- julia experiments/matriz_Julia.jl
```

### Elixir

- reestruture o prototipo atual, que nao e uma implementacao de referencia;
- use uma representacao com acesso indexado previsivel e documente a escolha no PR;
- cronometre com `System.monotonic_time/0` e converta com `System.convert_time_unit/3`;
- mantenha a multiplicacao explicita e `TDM=0.0`;
- use apenas Elixir/Erlang padrao, sem dependencias Hex.

Scripts `.exs` nao exigem uma etapa separada de build. Trabalhe primeiro em `experiments/matriz_multiplication.exs`; o prototipo atual nao compila e nao deve ser usado como smoke test antes da reescrita:

```bash
mix format --check-formatted experiments/matriz_multiplication.exs
elixir experiments/matriz_multiplication.exs 144 3 1 1 "out/tmp-extra-elixir/resultado_elixir.csv"
python3 scripts/test_extra_language.py --language Elixir -- elixir experiments/matriz_multiplication.exs
```

## 6. O que o teste automatizado cobre

O separador `--` e obrigatorio. Tudo depois dele e o comando-base da implementacao; o harness acrescenta os cinco argumentos do contrato. Ele exercita argumentos invalidos e casos pequenos nas escalas linear e logaritmica, valida o codigo de saida e inspeciona o CSV.

O harness e a verificacao manual de codigo sao os criterios desta fase. `scripts/validate_run.py` valida uma execucao completa do fluxo principal e, por isso, nao substitui `test_extra_language.py` durante o desenvolvimento isolado.

**Limite conhecido do harness:** o CSV de saida carrega apenas tempos, nunca valores de matriz, entao `test_extra_language.py` nao tem como detectar uma multiplicacao aritmeticamente incorreta — uma implementacao com `verify_sample` (ou equivalente) quebrado, incompleto ou nunca chamado pode passar em todos os testes automatizados desde que produza um CSV bem formado. A corretude aritmetica depende inteiramente da revisao manual do codigo de verificacao amostral durante o PR (ver checklist em `.github/pull_request_template.md`).

## 7. Commits, PR e promocao para `src/`

Antes de enviar:

```bash
git status
git diff --check
python3 scripts/test_extra_language.py --language LINGUAGEM -- COMANDO_BASE
git add experiments/ARQUIVO_DA_LINGUAGEM
git commit -m "Implementa benchmark em LINGUAGEM"
git push --set-upstream origin BRANCH_FEAT
```

Inclua no PR as versoes da ferramenta, os comandos executados e a saida resumida dos testes. Nao versione executaveis, arquivos `.beam`, caches nem resultados locais.

O arquivo deve permanecer em `experiments/` durante a primeira revisao. Mova-o para o nome padronizado abaixo somente depois de aceite explicito do mantenedor:

```text
src/matriz_rust.rs
src/matriz_julia.jl
src/matriz_elixir.exs
```

Apos a promocao, repita o teste apontando para `src/`. Exemplos:

```bash
rustc --edition=2021 -C opt-level=3 -D warnings src/matriz_rust.rs -o build/extra/matriz_rust
python3 scripts/test_extra_language.py --language Rust -- ./build/extra/matriz_rust

python3 scripts/test_extra_language.py --language Julia -- julia src/matriz_julia.jl
python3 scripts/test_extra_language.py --language Elixir -- elixir src/matriz_elixir.exs
```

Somente depois dos tres PRs aceitos deve ser avaliado um quarto PR, por exemplo `feat/extra-languages-integration`, para tornar as linguagens opcionais nos runners e registrar comandos, versoes e saidas no manifesto. O validador e o plotador desta branch ja reconhecem CSVs extras opcionais; o PR de integracao deve confirmar esse fluxo de ponta a ponta. As seis saidas atuais de C, C++, Java e Python devem continuar funcionando sem que as toolchains extras estejam instaladas.

## 8. Referencias oficiais de instalacao

- [Rustup — instalacao de Rust](https://www.rust-lang.org/tools/install)
- [Elixir e Erlang/OTP — instalacao](https://elixir-lang.org/install/)
- [Juliaup — instalacao de Julia](https://julialang.org/downloads/)
- [GitHub — trabalhar com forks](https://docs.github.com/en/pull-requests/how-tos/work-with-forks)
