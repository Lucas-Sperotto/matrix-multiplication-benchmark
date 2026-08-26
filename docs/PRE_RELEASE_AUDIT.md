# Auditoria Final de Pré-Entrega

Data: 2026-08-26

## 1. Escopo e ponto de partida

Auditoria independente executada sobre `tcc-lic-thassio` após a integração e estabilização das linguagens extras.

Ponto de partida:

- branch: `tcc-lic-thassio`;
- SHA inicial auditado: `7b773d70d5e40968630e08e9c67e654b8eee403d`;
- relação com `main` no início: 30 commits à frente e 0 atrás;
- `main` era ancestral direto da branch, sem divergência acumulada.

Foram revisados os runners Linux/WSL e PowerShell, o contrato CSV/CLI, as sete implementações em `src/`, o validador, o gerador de gráficos, os testes, a documentação operacional/metodológica e o fluxo de contribuição.

Esta auditoria não teve como objetivo otimizar uma linguagem nem redesenhar o experimento.

## 2. Achados

### P0 — `run-name` permitia path traversal

`run_all.sh` e `run_all.ps1` compunham `out/<run-name>` diretamente. Valores com separadores ou `..` podiam escapar da árvore esperada ou produzir caminhos ambíguos.

**Correção:** os dois runners agora aceitam apenas `[A-Za-z0-9_.-]` e rejeitam qualquer ocorrência de `..`. A validação ocorre antes da criação do staging.

### P1 — C e C++ não cumpriam todo o contrato de `out_csv`

O contrato documentado exige criar os diretórios pais de `out_csv`. Java, Python, Rust, Julia e Elixir já faziam isso; C e C++ apenas tentavam abrir o arquivo.

**Correção:** C ganhou criação recursiva e portável dos diretórios pais para caminhos relativos/absolutos usuais; C++17 passou a usar `std::filesystem::create_directories`.

### P1 — template de PR incompatível com a entrega final

O template ainda refletia a fase histórica Rust → Julia → Elixir e afirmava que a base deveria ser `tcc-lic-thassio`, nunca `main`. Isso contradizia o fluxo final planejado.

**Correção:** template tornado genérico e passou a distinguir desenvolvimento interno de promoção final do TCC.

### P2 — toolchains extras eram verificadas tarde

Uma extra explicitamente solicitada só era checada depois de compilar/executar o núcleo, podendo deixar um staging parcial por uma dependência que já era sabidamente ausente.

**Correção:** preflight de `rustc`, `julia` e `elixir` antes de criar `out/.running-*` quando a flag correspondente é solicitada. Falhas durante o benchmark continuam preservando staging para diagnóstico.

### P2 — regressões de contrato não cobriam explicitamente todo o risco

A regra metade-para-cima tinha regressão dedicada apenas na referência Python, embora todas as implementações devam produzir a mesma série. O harness genérico também dependia da criação de diretório pai de forma implícita.

**Correção:** o harness agora exige explicitamente `B=101`, `Npts=3`, escala linear, com série `[100, 101, 101]`, além de um caso nomeado de criação de diretórios aninhados inexistentes.

### P2 — teste de criação de diretório pai era implícito

O harness acabava dependendo desse comportamento em alguns casos, mas não havia um teste nomeado com diagnóstico específico.

**Correção:** regressão explícita com diretórios aninhados inexistentes; casos de sucesso e sobrescrita agora testam somente suas responsabilidades. O teste de arredondamento x.5 também passa pelo mesmo harness.

### P2 — ausência de roteiro único para o aluno

Os comandos estavam distribuídos entre `EXECUTION.md`, `EXTRA_LANGUAGES.md`, comentários dos testes e relatórios.

**Correção:** criado `STUDENT_VALIDATION.md` como roteiro de aceitação do fork até o PR para `main`.

## 3. Conferências sem alteração de código

A leitura direta confirmou:

- Java, Python, Rust, Julia e Elixir já criam o diretório pai de `out_csv`;
- Julia mantém elementos `Int32` e índices/dimensões `Int`;
- C, C++, Java, Python, Rust e Julia pré-alocam/zeram o resultado em TAM segundo a política documentada;
- Elixir permanece a exceção estrutural documentada, construindo o resultado em TCS;
- `validate_run.py` resolve o diretório da execução e valida manifesto, CSVs, número de linhas, tempos finitos/não negativos e igualdade da série de `N`;
- `plot_benchmarks.py` inclui automaticamente as séries extras presentes;
- PowerShell continua com verificação explícita de `$LASTEXITCODE` nas invocações críticas;
- `main` não foi alterada nesta auditoria.

## 4. Testes executados pelo auditor

Em ambiente local isolado, usando exatamente o conteúdo proposto para C, C++ e o harness:

```text
gcc -std=c11 -Wall -Wextra src/matriz_c.c -o build/matriz_c -lm
gcc -std=c11 -Wall -Wextra -O3 src/matriz_c.c -o build/matriz_c_O3 -lm
g++ -std=c++17 -Wall -Wextra src/matriz_cpp.cpp -o build/matriz_cpp
g++ -std=c++17 -Wall -Wextra -O3 src/matriz_cpp.cpp -o build/matriz_cpp_O3
python3 -m py_compile tests/test_extra_language.py
python3 tests/test_extra_language.py --language C -- ./build/matriz_c
python3 tests/test_extra_language.py --language C-O3 -- ./build/matriz_c_O3
python3 tests/test_extra_language.py --language C++ -- ./build/matriz_cpp
python3 tests/test_extra_language.py --language C++-O3 -- ./build/matriz_cpp_O3
```

Resultado: contrato aprovado para C/C++ com e sem `-O3`, incluindo o caso x.5 `[100,101,101]`, criação de diretórios aninhados e caminho com espaços.

Também foram executados:

```text
bash -n run_all.sh
run_all.sh com run-name ../escape
run_all.sh com run-name a/b
```

Resultado: sintaxe Bash válida e ambos os nomes inseguros rejeitados antes da execução.

## 5. Limitações desta auditoria

O ambiente desta auditoria não materializou o checkout completo do GitHub e, portanto, não substitui a validação independente do aluno.

Não foram declarados como executados aqui:

- smoke completo das sete linguagens;
- Elixir em runtime real;
- PowerShell ponta a ponta em Windows nativo;
- bateria experimental formal.

Esses pontos são deliberadamente transferidos para o roteiro `STUDENT_VALIDATION.md`.

## 6. Itens mantidos para depois

Não foram tratados como bloqueadores de entrega:

- política uniforme para espaços em branco em argumentos numéricos;
- estudo de casos-limite de arredondamento em ponto flutuante;
- coleta de repetições brutas em vez de somente médias;
- protocolo ambiental definitivo da coleta experimental;
- CI multi-runtime;
- compatibilidade do script de system-info com `date` BSD/macOS;
- remoção dos resultados históricos em `out/teste/`;
- extensões BLAS, paralelismo, RSS e energia.

Esses itens permanecem em `TODO.md` quando ainda relevantes.

## 7. Classificação

**READY FOR STUDENT VALIDATION**

A branch está adequada para ser entregue ao aluno para uma validação independente em fork. A promoção para `main` deve ocorrer somente depois de ele executar o roteiro, especialmente Elixir e PowerShell nativo, registrar o SHA/ambiente e abrir o PR final sem testes obrigatórios falhando.
