# Validação Final pelo Aluno

Este roteiro é a etapa de aceitação da branch `tcc-lic-thassio` antes do Pull Request final para `main`.

O objetivo não é otimizar novamente as implementações. O aluno deve reproduzir os testes em um fork limpo, registrar o ambiente e abrir o PR somente se os critérios abaixo forem satisfeitos.

## 1. Preparar o fork

No GitHub, crie um fork de `Lucas-Sperotto/matrix-multiplication-benchmark` preservando todas as branches. Depois:

```bash
git clone https://github.com/SEU_USUARIO/matrix-multiplication-benchmark.git
cd matrix-multiplication-benchmark
git remote add upstream https://github.com/Lucas-Sperotto/matrix-multiplication-benchmark.git
git fetch upstream
git switch tcc-lic-thassio
git reset --hard upstream/tcc-lic-thassio
git push --force-with-lease origin tcc-lic-thassio
```

O `--force-with-lease` acima é aceitável apenas no fork recém-preparado do aluno, para fazer a branch do fork coincidir exatamente com a branch de referência. Não use force push no repositório original.

Registre:

```bash
git branch --show-current
git rev-parse HEAD
git status --short
git remote -v
```

Critério: branch `tcc-lic-thassio`, `git status --short` vazio e SHA igual ao `upstream/tcc-lic-thassio`.

## 2. Preparar dependências

Siga [EXECUTION.md](EXECUTION.md) e [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md). Para Linux/WSL, é recomendado usar `.venv`:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
./scripts/check_extra_toolchains.sh
```

Registre as versões disponíveis:

```bash
gcc --version | head -n 1
g++ --version | head -n 1
javac -version
java -version
python3 --version
rustc --version
julia --version
elixir --version
erl -version
```

Se uma toolchain opcional não estiver disponível, não trate isso como sucesso parcial: instale-a antes da validação final das sete linguagens ou registre claramente a limitação no PR.

## 3. Compilar as implementações

Linux/WSL:

```bash
mkdir -p build/linux build/java

gcc -std=c11 -Wall -Wextra src/matriz_c.c -o build/linux/matriz_c -lm
gcc -std=c11 -Wall -Wextra -O3 src/matriz_c.c -o build/linux/matriz_c_O3 -lm

g++ -std=c++17 -Wall -Wextra src/matriz_cpp.cpp -o build/linux/matriz_cpp
g++ -std=c++17 -Wall -Wextra -O3 src/matriz_cpp.cpp -o build/linux/matriz_cpp_O3

javac -d build/java src/matriz_java.java

rustfmt --check src/matriz_rust.rs
rustc --edition=2021 -C opt-level=3 -D warnings src/matriz_rust.rs -o build/linux/matriz_rust
```

Julia e Elixir são executados diretamente pelos respectivos runtimes.

## 4. Testar o contrato CLI/CSV

O mesmo harness é intencionalmente aplicável às sete implementações:

```bash
python3 tests/test_extra_language.py --language C -- ./build/linux/matriz_c
python3 tests/test_extra_language.py --language C++ -- ./build/linux/matriz_cpp
python3 tests/test_extra_language.py --language Java -- java -cp build/java matriz_java
python3 tests/test_extra_language.py --language Python -- python3 src/matriz_python.py
python3 tests/test_extra_language.py --language Rust -- ./build/linux/matriz_rust
python3 tests/test_extra_language.py --language Julia -- julia src/matriz_Julia.jl
python3 tests/test_extra_language.py --language Elixir -- elixir src/matriz_multiplication.exs
```

O harness verifica, entre outros pontos, limites de entrada, erro em `stderr`, escalas linear/logarítmica, sobrescrita do CSV e criação automática de diretórios pais de `out_csv`.

## 5. Testar corretude matemática não identidade

```bash
mkdir -p build/tests

gcc -std=c11 -Wall -Wextra -Wno-unused-function \
  tests/test_matriz_c.c -o build/tests/test_matriz_c -lm
./build/tests/test_matriz_c

g++ -std=c++17 -Wall -Wextra -Wno-unused-function \
  tests/test_matriz_cpp.cpp -o build/tests/test_matriz_cpp
./build/tests/test_matriz_cpp

javac -d build/java src/matriz_java.java tests/TestMatrizJava.java
java -cp build/java TestMatrizJava

python3 tests/test_matriz_python.py

rustc --edition=2021 --test src/matriz_rust.rs -o build/tests/test_matriz_rust
./build/tests/test_matriz_rust

julia tests/test_matriz_julia.jl
julia --check-bounds=yes tests/test_matriz_julia.jl

elixir tests/test_matriz_elixir.exs
```

Todos devem usar o caso pequeno não identidade definido nos testes e terminar com código zero.

## 6. Executar regressões do projeto

```bash
python3 -m py_compile scripts/*.py src/*.py tests/*.py
python3 tests/test_point_generation.py
python3 tests/test_validate_run.py
bash -n run_all.sh
git diff --check
```

No Windows, valide também que `run_all.ps1` é aceito pelo parser e, principalmente, execute-o de ponta a ponta em PowerShell nativo.

## 7. Smoke tests do runner

Use nomes novos em cada tentativa.

Núcleo:

```bash
./run_all.sh --batch \
  --run-name aluno-linux-core-100 \
  --B 100 --Npts 2 --M 1 --escala 1
```

Todas as extras:

```bash
./run_all.sh --batch \
  --run-name aluno-linux-all-100 \
  --B 100 --Npts 2 --M 1 --escala 1 \
  --with-all-extras
```

Cada execução bem-sucedida deve terminar em `out/<run_id>/`, nunca em `.running-<run_id>`, e o próprio runner deve concluir `scripts/validate_run.py` com sucesso.

Teste também duas falhas de segurança/robustez:

```bash
./run_all.sh --batch --run-name ../escape --B 100 --Npts 2 --M 1 --escala 1
./run_all.sh --batch --run-name a/b --B 100 --Npts 2 --M 1 --escala 1
```

Ambas devem falhar antes de criar qualquer saída fora de `out/`.

Se possível, teste a ausência deliberada de uma toolchain extra pedida. A falha deve ocorrer no preflight, antes da criação do staging.

## 8. Windows PowerShell nativo

Esta é uma validação particularmente importante porque a rodada anterior não teve execução completa em Windows nativo:

```powershell
.\run_all.ps1 -Batch -RunName aluno-win-core-100 -B 100 -Npts 2 -M 1 -Escala 1
.\run_all.ps1 -Batch -RunName aluno-win-all-100 -B 100 -Npts 2 -M 1 -Escala 1 -WithAllExtras
```

Confirme compilação, execução, `system_info`, manifesto, gráficos, validação e promoção final no NTFS.

Teste também:

```powershell
.\run_all.ps1 -Batch -RunName "../escape" -B 100 -Npts 2 -M 1 -Escala 1
```

Deve falhar antes de gerar resultados.

## 9. Estado final antes do PR

Resultados de smoke locais são ignorados pelo `.gitignore`; não versione caches ou binários.

```bash
git status --short
git diff --check
git log --oneline --decorate -5
```

Se o aluno não alterou código, `git status --short` deve permanecer vazio. Se alguma correção realmente necessária foi feita durante a validação, ela deve estar em commit separado, explicada e testada antes do PR.

## 10. Pull Request final

O PR final é uma exceção deliberada ao fluxo histórico das branches de implementação:

- repositório base: `Lucas-Sperotto/matrix-multiplication-benchmark`;
- **base:** `main`;
- **compare/head:** `tcc-lic-thassio` do fork do aluno;
- objetivo: promover a versão validada do TCC para a branch publicável.

No corpo do PR, registre:

- SHA testado;
- sistema operacional/hardware;
- versões das sete toolchains;
- comandos executados;
- quais testes passaram;
- qualquer limitação restante;
- confirmação de que não houve otimização metodológica durante a validação.

**Não abra o PR para `main` se houver teste obrigatório falhando.**
