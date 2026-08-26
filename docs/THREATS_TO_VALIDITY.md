# Ameaças à Validade — O que este benchmark realmente compara

Data: 2026-08-26
Escopo: análise de código das sete implementações (`src/matriz_c.c`, `src/matriz_cpp.cpp`, `src/matriz_java.java`, `src/matriz_python.py`, `src/matriz_rust.rs`, `src/matriz_Julia.jl`, `src/matriz_multiplication.exs`). Nenhuma implementação foi alterada para produzir este documento; nenhum número de desempenho novo foi coletado — as poucas referências a medições vêm de observações de diagnóstico já registradas em `METHODOLOGY.md` e nos documentos de aceite em `docs/reviews/`, citadas aqui com a mesma cautela.

Este documento complementa `METHODOLOGY.md` (desenho experimental) com uma resposta direta e uma matriz de engenharia: para cada elemento potencialmente relevante de desempenho, ele diz se a diferença entre linguagens é inevitável, foi introduzida pela implementação, deveria ser corrigida, ou deve apenas ser declarada como limitação.

## A pergunta central: linguagens, ou algo mais?

**As duas coisas ao mesmo tempo, e isso é inerente a qualquer benchmark cross-language que não seja puramente sintético.** Uma "linguagem de programação" não existe isolada do seu compilador/interpretador, do seu modelo de memória e das estruturas de dados que ela naturalmente oferece. Perguntar "qual linguagem é mais rápida para multiplicar matrizes" sem especificar layout, JIT, GC e bounds-checking não é uma pergunta bem-formada — é a pergunta "qual runtime, com qual representação de dados idiomática o suficiente, compilado/interpretado por qual toolchain, é mais rápido para esta tarefa". Este projeto já reconhece isso explicitamente em `METHODOLOGY.md`:

> Não se assume equivalência microarquitetural das estruturas de dados.

O que o contrato compartilhado (`EXTRA_LANGUAGES.md`) mantém **constante** entre as sete implementações é a forma algorítmica (três laços, ordem lógica `i, j, k`, sem BLAS/paralelismo), a série de `N`, o protocolo de warm-up + M repetições, e o método de validação amostral. O que ele **não** mantém constante — e não poderia, sem deixar de ser uma implementação idiomática mínima em cada linguagem — é o layout de memória, a largura do tipo numérico, o custo de indexação, o modelo de compilação/JIT e o gerenciamento de memória. A tabela abaixo separa exatamente essas duas categorias.

Isso não invalida a comparação: significa que ela deve ser lida como **"desempenho de uma implementação manual O(N³) razoavelmente idiomática em cada linguagem, sob um contrato de E/S comum"**, não como **"desempenho do algoritmo em abstrato, isolado de runtime"**. A segunda pergunta não é respondível por nenhum benchmark cross-language real.

## Análise individual por linguagem

**C** (`src/matriz_c.c`): buffers `int*` contíguos, indexação manual `i*n+j`, sem bounds-check (nunca existiu na linguagem), sem GC, liberação manual com `free`. `mat1`/`mat2` usam `malloc` (todo elemento é sobrescrito uma única vez no laço de inicialização); `res` usa **`calloc`**, alocado e zerado dentro da janela de TAM, alinhado com C++/Java/Python/Rust/Julia. Overflow de dimensão checado explicitamente antes de alocar. Compilado com e sem `-O3` (duas séries).

**C++** (`src/matriz_cpp.cpp`): `std::vector<int>` contíguo, mesma indexação manual. `std::vector`'s construtor `(n2)` zero-inicializa `res` dentro da janela de TAM — diferente de C. Sem bounds-check via `operator[]`. RAII com `swap` para forçar liberação dentro da janela de TDM. Duas séries (com/sem `-O3`).

**Java** (`src/matriz_java.java`): `int[][]` — array de arrays, não contíguo. `new int[n][n]` zero-inicializa `res` dentro de TAM (garantia da JLS). Bounds-check sempre ativo por especificação da linguagem, não desativável pelo programador. Sem controle de liberação manual (`TDM=0.0`); GC da JVM em uso não é fixado por flag (decisão deliberada, sem justificativa científica para forçar um coletor específico), mas agora **é registrado** em `run_manifest.json.tools.java_gc` por sondagem best-effort (`java -XX:+PrintFlagsFinal -version`), com fallback `"N/D"` quando não detectável. JIT do HotSpot compila em camadas, em tempo de execução, sem flag de otimização exposta ao usuário.

**Python** (`src/matriz_python.py`): `list[list[int]]`, não contíguo, inteiros nativos "boxed" (objetos `PyLongObject`, precisão arbitrária, no CPython validado). `res` é criado e zerado em `run_once`, dentro da janela de TAM; `multiply` recebe o buffer já pronto e apenas o preenche (sem retornar novo objeto), alinhado com C/C++/Java/Rust/Julia. Bounds-check sempre ativo (`IndexError`). A validação local usou CPython interpretado, sem JIT; os runners, porém, não impõem uma implementação específica de Python. No CPython, o gerenciamento combina contagem de referências com GC cíclico de apoio, não um único mecanismo de tracing como Java/Julia/Elixir.

**Rust** (`src/matriz_rust.rs`): `Vec<i32>` contíguo, indexação manual `i*n+j`. `res` é alocado e zerado em TAM via `allocate_zeroed`; `mat1`/`mat2` são construídos em uma única passagem sem zerar antes (`allocate_with`). Bounds-check da linguagem **desativado deliberadamente** no laço quente via `get_unchecked`/`get_unchecked_mut`, com invariante de segurança documentado em comentário `SAFETY` — decisão de implementação, não comportamento padrão do Rust. Ownership/RAII com `drop` explícito medido em TDM. Overflow de `N*N` checado com `checked_mul`; alocação falível via `try_reserve_exact`. `black_box` usado fora da janela cronometrada para impedir eliminação de trabalho pelo otimizador. Única série, sempre `-C opt-level=3` (sem variante "sem otimização" pareada com C/C++).

**Julia** (`src/matriz_Julia.jl`): `Matrix{Int32}` nativo, **column-major** (ao contrário do row-major de C/C++/Rust); elementos em `Int32` (32 bits, alinhado com C/C++/Java/Rust), índices/dimensão/contadores permanecem `Int` nativo (64 bits nas plataformas 64-bit usadas na validação). `res` é alocado com `zeros` (zerado) em TAM; `mat1`/`mat2` com `undef` + laço de inicialização em uma passagem, com conversão explícita para `Int32`. No laço quente, o acumulador é `Int32(0)` explícito (não o literal `0`, que seria inferido como `Int`), evitando promoção implícita de volta a 64 bits. Bounds-check desativado deliberadamente no laço quente via `@inbounds` — mesma natureza de decisão que o Rust; validado também com `julia --check-bounds=yes`, sem mudança de resultado. `TDM=0.0`, sem liberação manual; GC geracional do runtime Julia. JIT por especialização de tipo: compila na primeira chamada por assinatura de tipo, reaproveitado para todo `N` subsequente sem recompilação. Ordem de laços `i, j, k` mantida idêntica às demais linguagens mesmo não sendo a mais favorável ao layout column-major.

**Elixir** (`src/matriz_multiplication.exs`): tupla plana única de `N²` elementos, indexada `i*n+j`, escolhida entre quatro representações comparadas explicitamente no cabeçalho do código (listas, tuplas aninhadas, `:array`, tupla plana) por apresentar o melhor compromisso avaliado entre leitura O(1) e construção O(N²) sem custo de cópia por célula — uma decisão de representação entre as alternativas avaliadas, não uma prova de unicidade assintótica em Elixir de forma geral (o cabeçalho do código foi revisado para não afirmar isso). `res` só passa a existir quando a *comprehension* de `multiply` termina — construção e cálculo são inseparáveis nessa representação imutável, então `res` fica inteiramente em TCS, nunca em TAM. Esta é agora a **única** das sete implementações onde isso ocorre (C, C++, Java, Python, Rust e Julia já alocam/zeram `res` em TAM), por um motivo estrutural: imutabilidade da linguagem, não uma escolha de código corrigível. `elem/2` faz checagem de limites internamente (levanta `ArgumentError` fora do intervalo); não há uma variante "unchecked" exposta pela biblioteca padrão, ao contrário de Rust/Julia. `TDM=0.0`; GC por processo do BEAM, isolado do restante do sistema. BeamAsm (Erlang/OTP ≥ 24) compila o módulo inteiro para nativo no carregamento, antes de qualquer laço rodar — nem por chamada (Java) nem por especialização de tipo (Julia).

## Matriz comparativa

| Aspecto | C | C++ | Java | Python | Rust | Julia | Elixir |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Representação dos dados** | `int*` (malloc/calloc) | `std::vector<int>` | `int[][]` | `list[list[int]]` | `Vec<i32>` plano | `Matrix{Int32}` nativo | tupla plana |
| **Layout de memória** | Contíguo, row-major | Contíguo, row-major | Não contíguo (array de arrays) | Não contíguo (lista de listas, elementos boxed) | Contíguo, row-major | Contíguo, **column-major** | Estrutura gerenciada pelo BEAM; contiguidade física não assumida e sem noção de "row/column-major" nesse nível |
| **Tipo numérico** | `int` (~32 bits) | `int` (~32 bits) | `int` (32 bits, garantido) | `int` nativo (precisão arbitrária, boxed no CPython validado) | `i32` (32 bits) | `Int32` (32 bits); índices/dimensão em `Int` nativo (64 bits nas plataformas 64-bit validadas) | inteiro nativo BEAM (imediato para valores pequenos; precisão arbitrária se necessário) |
| **Custo de indexação** | O(1), sem checagem, 1 indireção | O(1), sem checagem via `operator[]`, 1 indireção | O(1) por dimensão, checado, 2 indireções | O(1) "lógico", checado, 2 indireções + overhead de interpretador/boxing | O(1), checagem **desativada** deliberadamente | O(1), checagem **desativada** deliberadamente | O(1) via `elem/2`, checado internamente (sem variante unchecked pública) |
| **Compilação/JIT** | AOT (gcc), com/sem `-O3` | AOT (g++), com/sem `-O3` | AOT p/ bytecode + JIT em camadas (HotSpot validado) em runtime | CPython validado: interpretado, sem JIT | AOT (rustc), sempre `opt-level=3` | JIT por especialização de tipo (1ª chamada por assinatura) | Bytecode compilado a nativo no carregamento (BeamAsm) |
| **Bounds checking** | Nenhum (UB se violado) | Nenhum via `operator[]` (UB) | Sempre ativo, não desativável | Sempre ativo (`IndexError`) | Desativado no laço quente (`unsafe`) | Desativado no laço quente (`@inbounds`) | Sempre ativo em `elem/2` (`ArgumentError`) |
| **Gerenciamento de memória** | Manual (`malloc`/`calloc`/`free`) | RAII (destrutor de `vector`) | GC (JVM, algoritmo não fixado, registrado no manifesto) | Contagem de referência + GC cíclico | RAII (ownership, `drop`) | GC geracional do runtime | GC geracional por processo (BEAM) |
| **GC** | N/A | N/A | Sim, não configurado por flag; registrado em `run_manifest.json.tools.java_gc` (sondagem best-effort) | Sim (refcounting + ciclos) | N/A | Sim | Sim, isolado por processo |
| **Temporizador** | `clock_gettime(CLOCK_MONOTONIC)` / `QueryPerformanceCounter` | `std::chrono::steady_clock` | `System.nanoTime()` | `time.perf_counter()` | `std::time::Instant` | `time_ns()` | `System.monotonic_time/0` |
| **Otimização (flags)** | Duas séries: sem flag e `-O3` | Duas séries: sem flag e `-O3` | Nenhuma flag exposta; decisão é do JIT | N/A (sem AOT) | Uma série, sempre `opt-level=3` | Sem flag explícita no contrato | Sem flag de otimização exposta ao usuário |
| **Warm-up** | 1 rodada descartada por N (idêntico em todas) | idem | idem | idem | idem | idem | idem |
| **Método de validação** | 9 posições amostrais fora de TCS (idêntico em todas) | idem | idem | idem | idem | idem | idem |
| **Algoritmo** | 3 laços, sem BLAS/paralelismo (idêntico em todas) | idem | idem | idem | idem | idem | idem |
| **Ordem dos loops** | `i, j, k` (idêntica em todas) — mas o efeito de cache depende do layout: favorável a `mat1`, desfavorável a `mat2` em row-major | idem C | idem C, com indireção extra | idem C, custo de cache secundário ao overhead de interpretação | idem C | `i, j, k` idêntica, mas o layout column-major **inverte** qual operando é cache-amigável em relação a C/C++/Rust | Sem noção direta de cache de linha/coluna nesse nível de abstração |
| **Fronteira TAM/TCS do resultado (`res`)** | Alocado e zerado em TAM (`calloc`) | Alocado e zerado em TAM | Alocado e zerado em TAM | Alocado e zerado em TAM (`run_once`), preenchido em TCS por `multiply` | Alocado e zerado em TAM | Alocado e zerado em TAM | Construído inteiramente **em TCS** (imutabilidade) — única exceção remanescente |

## Classificação das diferenças

### 1. Inevitáveis (decorrem da linguagem/runtime, não haveria como eliminar sem deixar de ser aquela linguagem)

- Modelo de compilação/JIT (AOT vs bytecode+JIT em camadas vs interpretado vs especialização por tipo vs compilação no carregamento) — é a definição de cada runtime.
- Presença ou ausência de GC, e o algoritmo de GC de cada runtime.
- API de temporizador (sete chamadas de sistema/runtime diferentes; todas monotônicas, nenhuma trocável por outra).
- Bounds-check obrigatório em Java e Python (a linguagem não oferece uma via pública para desativar) e em Elixir via `elem/2` (biblioteca padrão não expõe variante unchecked).
- `int[][]` não contíguo em Java — é a única representação nativa 2D da linguagem sem recorrer a um buffer manual fora do idiomático.
- Boxing de inteiros em Python — inerente ao modelo de objeto da linguagem para uma lista de listas "pura", sem `array`/`numpy`.
- Layout column-major do `Matrix` nativo do Julia.
- Ausência de uma flag de otimização "AOT" exposta ao usuário em Java/Python/Julia/Elixir — nenhuma dessas linguagens compila para um binário nativo controlável dessa forma no fluxo padrão.

### 2. Introduzidas pela implementação (decisão de código deste projeto, poderia ter sido diferente)

- **Rust e Julia desativam bounds-check no laço quente** (`get_unchecked`, `@inbounds`) — escolha deliberada para aproximar o custo de acesso de C/C++, documentada em comentário no código e nos aceites técnicos (`docs/reviews/`), mas não é o comportamento padrão/idiomático dessas linguagens.
- **Rust é a única implementação sem uma série "sem otimização"** pareada com C/C++ — decisão de projeto (poderia compilar também com `-C opt-level=0`).
- **GC da JVM não fixado por flag** — decisão deliberada de não forçar um coletor específico sem justificativa científica (ver categoria 4); é registrado no manifesto (ver categoria "corrigidas nesta rodada" abaixo), mas continua não configurado.

### 3. Deveriam ser corrigidas (ação concreta recomendada, sem alterar o objeto de comparação)

Nenhum item remanescente nesta categoria após a rodada de estabilização final de 2026-08-26 (ver subseção seguinte). Itens de metodologia em aberto que não dependem de correção de código de comparação entre linguagens (versões de toolchain não fixadas, `M`/variância, protocolo ambiental da coleta) continuam rastreados em `TODO.md`.

#### Corrigido na rodada de estabilização final de 2026-08-26

Os itens abaixo estavam nesta categoria (2 ou 3) na versão anterior deste documento e foram corrigidos:

- **`res` em TCS em Python** → movido para TAM (`run_once` cria e zera o buffer antes de chamar `multiply`, que passou a recebê-lo por parâmetro e mutá-lo in place).
- **`res` não inicializado em C** → `malloc` trocado por `calloc` apenas para `res`; `mat1`/`mat2` continuam com `malloc` (todo elemento é sobrescrito uma única vez, zerar antes seria trabalho duplicado).
- **Julia com `Int` nos elementos (64 bits nas plataformas 64-bit validadas)** → elementos convertidos para `Matrix{Int32}`; índices, dimensão e contadores permanecem `Int` nativo. Acumulador do laço quente tornado `Int32(0)` explícito para não reintroduzir a largura nativa por promoção implícita. Validado sem overflow e com `--check-bounds=yes`.
- **Alegação de unicidade no cabeçalho do Elixir** → reescrita para descrever a tupla plana como o melhor compromisso **entre as alternativas avaliadas neste projeto**, sem alegar unicidade assintótica.
- **GC da JVM não registrado** → `run_manifest.json.tools.java_gc` agora registra o coletor ativo via sondagem best-effort (`java -XX:+PrintFlagsFinal -version`), com fallback `"N/D"`; `run_manifest.json.tools.java` passou a registrar a saída completa de `java -version` (não só a primeira linha), expondo vendor/VM quando reportados ali. Nenhum parâmetro de GC foi fixado ou alterado — apenas passou a ser observável.
- **Ausência de teste com matriz não identidade** → adicionado um teste de corretude por linguagem: seis arquivos em `tests/` e um módulo `#[cfg(test)]` no próprio código Rust, todos chamando a função de multiplicação de produção com um caso 2×2 conhecido e não identidade, fora da janela de benchmark (ver `METHODOLOGY.md`, "Validação matemática").

### 4. Devem ser apenas declaradas como limitação (não há correção de código razoável sem comprometer o objeto de comparação)

- `int[][]` de Java e a ausência de buffer contíguo — corrigir mudaria a representação para algo não idiomático em Java (um `int[]` plano manual), o que já foi conscientemente rejeitado pelo projeto desde antes da integração das linguagens extras.
- `res` de Elixir construído em TCS por imutabilidade — não há como "pré-alocar" um valor em uma linguagem sem estruturas mutáveis; forçar isso descaracterizaria a implementação como "Elixir idiomático".
- Column-major do Julia com ordem de laços `i, j, k` preservada — trocar a ordem para ser cache-amigável ao column-major quebraria a "mesma formulação algorítmica" exigida pelo contrato entre as sete linguagens.
- Boxing de inteiros em Python — evitável apenas trocando a representação para `array.array`/bytes manuais, o que deixaria de ser "Python puro com listas", mudando o que está sendo medido.
- Ausência de bounds-check em C/C++ — é o comportamento definidor dessas linguagens; não há nada a declarar como "corrigível", apenas como contraste inerente frente a Java/Python/Elixir.
- Rust e Julia sem checagem de limites no laço quente **permanecendo como está** (a alternativa de reativar a checagem para uma comparação "seguro vs seguro" é uma decisão de metodologia futura, não uma correção — ver `TODO.md` sobre preservar essa distinção explicitamente ao relatar resultados).
- Assimetria de otimização entre as sete implementações (C/C++ pareadas com/sem `-O3`; Rust fixo em `opt-level=3`; runtimes gerenciados sem eixo de otimização controlável) — inerente à forma como cada ecossistema de build funciona; já rastreado como decisão metodológica em aberto no `TODO.md`, não uma correção de código.
- Modelo de GC por processo do BEAM (Elixir) vs GC único da JVM (Java) vs GC do runtime Julia — três mecanismos de coleta de lixo genuinamente diferentes; nenhum é "mais correto", apenas diferente.

## Relação com outros documentos

Este documento não substitui `METHODOLOGY.md`; ele detalha, no nível de código, a base factual das seções "Layout de memória e tipo numérico" e "Ameaças à validade interna/externa" de lá. Itens da seção 3 acima que ainda não foram implementados estão rastreados em `TODO.md`. As decisões de aceite técnico de Rust e Julia (`docs/reviews/RUST_BENCHMARK_ACCEPTANCE.md`, `docs/reviews/JULIA_BENCHMARK_ACCEPTANCE.md`) já antecipavam parte desta análise; este documento a generaliza para as sete implementações e a formaliza como referência única de ameaças à validade.
