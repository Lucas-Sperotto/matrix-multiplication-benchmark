# Como Executar

Guia operacional de instalação, execução e validação. Para desenho experimental, consulte [METHODOLOGY.md](METHODOLOGY.md).

O fluxo principal sempre executa C, C++, Java e Python. Rust, Julia e Elixir são opcionais via flag.

## Pré-requisitos

Linux/WSL:

- `gcc`, `g++`;
- JDK (`java`, `javac`);
- `python3`;
- pacotes de `requirements.txt`.

Ubuntu/Debian/WSL:

```bash
sudo apt update
sudo apt install -y gcc g++ default-jdk python3 python3-pip python3-venv
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Windows PowerShell:

- GCC/G++ via MSYS2/MinGW ou equivalente no `PATH`;
- JDK no `PATH`;
- Python no `PATH`.

```powershell
python -m pip install -r requirements.txt
```

## Toolchains extras

Rust, Julia e Elixir só são exigidos quando suas flags são informadas. Instalação detalhada e versões recomendadas estão em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

No Linux/WSL:

```bash
./scripts/check_extra_toolchains.sh
```

Em PowerShell puro, confira manualmente:

```powershell
rustc --version
julia --version
elixir --version
erl -version
```

## Linux/WSL

Interativo:

```bash
./run_all.sh
```

Batch:

```bash
./run_all.sh --batch --run-name exemplo-linux-100 --B 100 --Npts 2 --M 1 --escala 1
```

Extras:

```bash
./run_all.sh --batch --run-name exemplo-linux-all-100 --B 100 --Npts 2 --M 1 --escala 1 --with-all-extras
```

Flags individuais: `--with-rust`, `--with-julia`, `--with-elixir`.

## Windows PowerShell

```powershell
.\run_all.ps1 -Batch -RunName exemplo-win-100 -B 100 -Npts 2 -M 1 -Escala 1
```

Extras: `-WithRust`, `-WithJulia`, `-WithElixir`, `-WithAllExtras`.

## Regras de `run-name`

O identificador da execução:

- aceita somente `A-Z`, `a-z`, `0-9`, `_`, `.`, `-`;
- não pode conter `..`;
- não pode conter `/` ou `\`;
- deve ser novo: `out/<run-name>` e `out/.running-<run-name>` não podem existir.

Exemplos válidos:

```text
aluno-linux-core-100
ryzen7_B3000_20260826
```

Exemplos rejeitados:

```text
../escape
a/b
a\b
```

## Preflight e fail-fast

Antes de criar o staging, os runners verificam:

- parâmetros e `run-name`;
- toolchains centrais;
- Matplotlib;
- cada toolchain extra explicitamente solicitada.

Assim, `--with-elixir` sem `elixir` instalado falha antes de compilar/executar o núcleo e antes de criar `out/.running-*`.

Depois que o staging existe, falhas de compilação, benchmark, metadados, gráficos ou validação preservam `out/.running-<run-name>/` para diagnóstico, sem promover o diretório para o nome final.

## Contrato dos benchmarks

Cada implementação recebe:

```text
B Npts M escala out_csv
```

Exemplo isolado após compilar C:

```bash
./build/linux/matriz_c 100 2 1 1 "out/smoke-manual-c/resultado_c.csv"
```

As implementações criam os diretórios pais de `out_csv` quando necessário e sobrescrevem o arquivo.

Cabeçalho:

```csv
N,TCS,TAM,TDM
```

Para cada `N`, há um warm-up descartado e a média de exatamente `M` repetições.

C, C++, Java, Python, Rust e Julia pré-alocam/inicializam o resultado em TAM conforme a metodologia. Elixir constrói o resultado em TCS por imutabilidade; a exceção está documentada em [METHODOLOGY.md](METHODOLOGY.md).

## Artefatos

Builds:

```text
build/linux/
build/windows/
build/java/
```

Execução em andamento:

```text
out/.running-<run_id>/
```

Execução validada:

```text
out/<run_id>/
```

O runner só promove o staging depois de:

1. concluir todos os benchmarks solicitados;
2. gerar `system_info.md/json`;
3. gerar `run_manifest.json`;
4. gerar gráficos;
5. executar `scripts/validate_run.py` com sucesso.

## Validação manual

```bash
python3 scripts/validate_run.py out/<run_id>
```

O validador confere arquivos obrigatórios, manifesto, cabeçalho, número de linhas, valores numéricos/finitos/não negativos, igualdade da série de `N` e presença de gráficos.

O manifesto é autoritativo para linguagens opcionais: um CSV opcional conhecido presente e não declarado invalida a execução.

## Harness de contrato

O harness em `tests/test_extra_language.py` pode ser usado com qualquer implementação. Exemplos:

```bash
python3 tests/test_extra_language.py --language C -- ./build/linux/matriz_c
python3 tests/test_extra_language.py --language Rust -- ./build/linux/matriz_rust
python3 tests/test_extra_language.py --language Julia -- julia src/matriz_Julia.jl
python3 tests/test_extra_language.py --language Elixir -- elixir src/matriz_multiplication.exs
```

Ele cobre erros de CLI, limites, linear/log, cabeçalho/linhas/tempos, sobrescrita e criação de diretórios pais de saída.

## Validação final antes de `main`

Para a etapa do aluno, não improvise uma lista parcial de comandos. Use [STUDENT_VALIDATION.md](STUDENT_VALIDATION.md), que reúne:

- contrato das sete linguagens;
- corretude não identidade;
- regressões;
- smoke core/all-extras;
- testes de `run-name`;
- PowerShell nativo;
- checklist do PR final.

## Problemas comuns

**Dependência ausente**

Instale a ferramenta indicada. Se ela foi explicitamente solicitada como extra, o runner aborta no preflight.

**Matplotlib/NumPy quebrado no Python do sistema**

Use o `.venv` recomendado e reinstale `requirements.txt`.

**Existe `.running-<run_id>`**

Uma execução anterior começou e falhou depois do preflight. Inspecione o diretório e só depois o remova ou use outro `run-name`.

**Já existe `out/<run_id>`**

O runner nunca mistura/sobrescreve uma execução final anterior. Use outro identificador.

**Arquivos antigos com `TLM` ou sem `TDM`**

Não reutilize esses resultados no fluxo atual; gere uma nova execução.
