# Plano de Estabilização Final — Pré-Congelamento Experimental

Data: 2026-08-26
Branch: `feat/extra-languages-integration` (base `tcc-lic-thassio`, fast-forward limpo, 4 commits à frente, 0 atrás)
SHA inicial: `11d230f6f7c9e7246dc7cf58da7700079bb4eb8a`

Este plano precede qualquer alteração de código desta rodada. Baseado em leitura integral e fresca de todos os documentos e arquivos listados na tarefa — nenhuma conclusão vem de memória de turnos anteriores.

---

## 1. Estado atual confirmado

- `git status --short` mostrava, antes desta tarefa: `CONTRIBUTING.md`, `DIAGRAMS.md`, `EXECUTION.md`, `EXTRA_LANGUAGES.md`, `README.md`, `TODO.md` modificados e `METHODOLOGY.md`, `docs/THREATS_TO_VALIDITY.md` novos — todos de uma auditoria de documentação anterior, ainda sem commit, mais refinamentos que você já aplicou por fora (achados sobre fronteira TAM/TCS de C/Python, cautela sobre citar percentuais de diagnóstico como evidência, `Assert-LastExitCode` já estendido a todo o `run_all.ps1`).
- `TODO.md`, `METHODOLOGY.md` e `docs/THREATS_TO_VALIDITY.md` já documentam corretamente, em texto, a maior parte dos problemas que esta tarefa pede para corrigir — o trabalho real está em fechar a lacuna entre o que está *documentado como pendente* e o que está *implementado*.
- `run_all.ps1`, ao ser relido por completo agora, **já tem `Assert-LastExitCode` após toda invocação nativa crítica** (gcc, g++, os 4 executáveis C/C++, javac, java, python, rustc, executável Rust, julia, elixir, plotador, validador). A Tarefa 3 deste pedido já está tecnicamente satisfeita no código; falta apenas confirmar isso por leitura (feito) e não regredir.

## 2. Problemas confirmados (por leitura direta do código, não por suposição)

| # | Problema | Onde | Evidência |
|---|---|---|---|
| 1 | Julia usa `Matrix{Int}` (64 bits nas plataformas 64-bit validadas) para elementos | `src/matriz_Julia.jl:50,73,116-118` | Lido integralmente; nenhum bloqueador numérico (valores máximos ~199998, muito abaixo do limite de `Int32`) |
| 2 | C aloca `res` em TAM mas não inicializa | `src/matriz_c.c:163` | `res = (int *)malloc(...)`, sem laço de zeragem |
| 3 | Python cria/zera `res` dentro de `multiply()`, ou seja, em TCS | `src/matriz_python.py:53-56,79` | `res = [[0] * n for _ in range(n)]` está dentro da função chamada dentro da janela `start_calc`/`end_calc` |
| 4 | `run_all.ps1` já cobre exit code em todas as chamadas nativas críticas | `run_all.ps1:129-307` | Confirmado por leitura linha a linha — **não é mais um problema**, apenas precisa de confirmação documental |
| 5 | Comentário de `src/matriz_multiplication.exs` alega unicidade absoluta | `src/matriz_multiplication.exs:37-40` | "é a única que preserva..." |
| 6 | Manifesto captura só a primeira linha de `java -version` e não tenta identificar o GC ativo | `run_all.sh:284`, `run_all.ps1:253` | `run(["java","-version"]).splitlines()[0]`; `First-Line { java -version }` |
| 7 | Execução parcial pode aparecer em `out/<run_id>/` indistinguível de uma execução completa | `run_all.sh:163-176,326-330`, `run_all.ps1:104-118,305-307` | Escreve direto em `$OUT_DIR`/`$OutDir` desde o início; nada promove/isola o resultado só ao final |
| 8 | `TEXEC` já é bem ressalvado em `METHODOLOGY.md`, mas não usa o termo formal pedido | `METHODOLOGY.md:41` | Falta nomear explicitamente como "tempo agregado das fases instrumentadas" |
| 9 | Nenhuma das sete implementações tem teste interno com matriz não identidade | `src/*` | Confirmado por leitura: todas usam apenas a matriz identidade como segundo operando, inclusive na validação amostral |

## 3. Arquivos que pretendo alterar

**Código:**
- `src/matriz_Julia.jl` — elementos das matrizes para `Int32`; acumulador do laço quente explicitamente `Int32` para não herdar `Int` (64 bits nas plataformas 64-bit validadas) por promoção implícita do literal `0`; guarda `if abspath(PROGRAM_FILE) == abspath(@__FILE__)` ao redor da chamada de `main()` no rodapé, para permitir um teste externo incluir o arquivo sem disparar a CLI.
- `src/matriz_c.c` — trocar `malloc` por `calloc` só para `res` (uma linha), mantendo `mat1`/`mat2` sem zerar antes (evita a dupla escrita já identificada e corrigida no Rust).
- `src/matriz_python.py` — mover a criação de `res` para dentro de `run_once` (janela de TAM); `multiply` passa a receber `res` já alocado e preenchê-lo, sem retornar novo objeto.
- `src/matriz_multiplication.exs` — reescrever o parágrafo de justificativa (item 5); tornar `multiply/3` e `build_matrix/2` públicas (`def` em vez de `defp`) e adicionar uma guarda por variável de ambiente (`MATRIZ_ELIXIR_SKIP_MAIN`) ao redor da chamada de `main/1` no rodapé, estritamente para permitir reuso em teste externo sem mudar o comportamento de invocação normal. `verify_sample/2` permanece privado porque o teste não precisa acessá-lo.
- `src/matriz_rust.rs` — adicionar um módulo `#[cfg(test)] mod tests { ... }` ao final do arquivo (compilado apenas por `rustc --test`, nunca pelo build de produção usado pelo runner).
- `src/matriz_java.java` — remover o modificador `private` apenas de `multiply` (fica `static`, com visibilidade de pacote), permitindo uma classe de teste no mesmo pacote chamá-lo; `verifySample` não precisa ser exposto.
- `run_all.sh`, `run_all.ps1` — diretório de trabalho `out/.running-<run_id>` promovido para `out/<run_id>` só após `validate_run.py` aprovar; verificação de colisão tanto no nome final quanto no nome de trabalho; captura completa de `java -version` e detecção best-effort do GC ativo via `-XX:+PrintFlagsFinal` com *fallback* `"N/D"`.

**Novos arquivos de teste** (não framework, scripts/binários pequenos e isolados, todos fora da janela de benchmark):
- `tests/test_matriz_c.c`, `tests/test_matriz_cpp.cpp` — reusam as funções `static` originais via `#define main matriz_main` + `#include` do arquivo de produção; não tocam no contrato CLI.
- `tests/TestMatrizJava.java` — compilada junto com `src/matriz_java.java`, chama `matriz_java.multiply(...)` diretamente.
- `tests/test_matriz_python.py` — importa `src/matriz_python.py` como módulo (já protegido por `if __name__ == "__main__":`, nenhuma mudança necessária lá).
- `tests/test_matriz_elixir.exs` — usa `Code.require_file/1` com a guarda de ambiente para carregar `MatrizElixir` sem disparar `main/1`.
- Teste de Rust: interno, dentro do próprio `src/matriz_rust.rs` (`#[cfg(test)]`), executado com `rustc --test`.
- Teste de Julia: `tests/test_matriz_julia.jl`, faz uma asserção manual e usa `include(".../src/matriz_Julia.jl")` protegido pela guarda `PROGRAM_FILE`.

**Documentação:**
- `METHODOLOGY.md` — atualizar a seção de TAM/TCS (C e Python alinhados; só Elixir permanece como exceção estrutural), formalizar `TEXEC` como "tempo agregado das fases instrumentadas", registrar `Int32` no Julia, registrar GC da JVM quando detectável, mencionar os testes de corretude não identidade e a arquitetura de promoção atômica.
- `docs/THREATS_TO_VALIDITY.md` — atualizar a matriz e as quatro categorias: mover os itens resolvidos (fronteira TAM/TCS de C/Python, tipo do Julia, alegação de unicidade do Elixir, GC da JVM) da categoria "deveriam ser corrigidas" para um registro de que já foram corrigidos, mantendo as demais categorias como estão.
- `TODO.md` — remover os itens resolvidos nesta rodada; manter os que continuam pendentes (versões não fixadas de Rust/Julia, protocolo ambiental da coleta final, `M`/tempos brutos, smoke test oficial, Windows nativo, etc.).
- `EXECUTION.md` — documentar `out/.running-<run_id>` e a promoção só ao final; documentar `Int32` no Julia se relevante para o usuário final (breve).
- `README.md` — uma frase sobre a promoção atômica em "Saídas", nada além disso (mantém-se overview/quick start).
- `EXTRA_LANGUAGES.md` — ajustar a nota sobre fronteira TAM/TCS (hoje cita só Elixir como exceção "estrutural"; C/Python deixam de ser exceção).
- `DIAGRAMS.md` — ajustar o diagrama de "Estados de uma Execução" e o de fluxo dos orquestradores para refletir o diretório de trabalho e a promoção final.
- `INTEGRATION_PLAN.md` — **não altero**, é um registro histórico da integração anterior; a tarefa só pede mudança ali "se houver necessidade de registrar divergência relevante da arquitetura implementada", e a arquitetura de promoção é aditiva à integração já registrada, não uma divergência dela.

## 4. Alterações propostas (resumo por tarefa numerada do pedido)

1. **Julia `Int32`**: sem bloqueador concreto encontrado; único cuidado real é o acumulador do laço quente não herdar `Int` por promoção implícita — resolvido tornando-o explicitamente `Int32`. Índices/dimensões/contadores permanecem `Int`.
2. **Fronteira TAM/TCS**: C ganha `calloc` só para `res`; Python move a criação de `res` para `run_once`; C++/Java/Rust/Julia não mudam (já corretos); Elixir não muda (exceção estrutural documentada, não uma correção).
3. **PowerShell**: já resolvido no código atual; ação = confirmar e documentar, sem alterar `run_all.ps1` além do necessário para a Tarefa 6 (promoção de diretório).
4. **Elixir — afirmação excessiva**: reescrever o parágrafo do cabeçalho; nenhuma mudança de algoritmo ou representação.
5. **JVM/GC**: capturar `java -version` completo (não só a primeira linha) e tentar detectar o coletor ativo via `-XX:+PrintFlagsFinal`, registrando `N/D` sem abortar se a sondagem falhar ou se a JVM não suportar a flag.
6. **Execuções incompletas**: diretório de trabalho `out/.running-<run_id>`, promovido para `out/<run_id>` só após `validate_run.py` aprovar; nenhuma promoção acontece se qualquer etapa falhar antes (`set -e`/`$ErrorActionPreference`+`Assert-LastExitCode` já garantem que o script nunca alcança a linha de promoção em caso de erro). Colisão verificada tanto no nome final (não pode existir, mesmo vazio) quanto no nome de trabalho (não pode já existir — indicaria execução anterior incompleta com o mesmo `run-name`, tratada como erro explícito, não sobrescrita silenciosa).
7. **TEXEC**: formalizar nome "tempo agregado das fases instrumentadas" em `METHODOLOGY.md`; não adicionar nova medição de wall-clock.
8. **Testes de corretude não identidade**: um caso 2×2 conhecido (`[[1,2],[3,4]] × [[5,6],[7,8]] = [[19,22],[43,50]]`), reaproveitando a rotina de multiplicação real de cada linguagem, fora da janela de benchmark, sem mudar o contrato CLI principal.

## 5. Riscos

| Risco | Mitigação |
|---|---|
| Mudar `Int` para `Int32` no Julia alterar TCS de forma que pareça uma "otimização" fora do escopo pedido | É exatamente o efeito documentado e pedido pela tarefa (footprint/cache); será registrado como decisão metodológica, não otimização oportunista |
| `calloc`/mover `res` no Python mudar sutilmente o comportamento em caso de falha de alocação | `calloc` tem a mesma convenção de retorno `NULL` que `malloc`; o `if (mat1 == NULL \|\| ...)` existente já cobre `res`. Em Python, listas não falham por "alocação" da mesma forma; comportamento de erro não muda. |
| Tornar `multiply` (Java) e `multiply`/`build_matrix` (Elixir) menos privados abrir superfície indevida | Java: de `private static` para `static` (ainda não público, só visível no pacote default). Elixir: de `defp` para `def`, mudança de visibilidade real, mas sem efeito comportamental — documentado explicitamente como alteração deliberada para permitir teste, não uma mudança de API pretendida para uso externo. |
| Guardas `PROGRAM_FILE`/variável de ambiente para suprimir `main()` alterarem o comportamento de invocação normal | Ambas as guardas são concebidas para serem `true`/executar `main()` em qualquer invocação direta (`julia arquivo.jl args`, `elixir arquivo.exs args`), idêntica ao comportamento atual; só desviam quando o arquivo é explicitamente incluído por outro script, cenário que não existe hoje no fluxo de produção. |
| Renomear `out/.running-<run_id>` para `out/<run_id>` falhar por bloqueio de SO/antivírus após validação ter passado | Risco residual de baixa probabilidade, não mitigado com retry (evitaria engenharia além do pedido); documentado como limitação conhecida — o diretório de trabalho continua íntegro e diagnosticável se isso ocorrer. |
| `#[cfg(test)]` no Rust ou testes em C/C++ via `#include` introduzirem *warnings* que quebrem o build de produção (`-D warnings`) | O build de produção do runner nunca passa `--test` nem inclui os arquivos de teste; `#[cfg(test)]` é compilado apenas sob `rustc --test`, nunca no comando de produção. Testes de C/C++ são arquivos **separados** em `tests/`, nunca compilados pelo runner. |
| Detecção de GC da JVM (`-XX:+PrintFlagsFinal`) falhar ou não expor as flags esperadas em alguma JVM não HotSpot | Captura de falha com *fallback* `"N/D"`; a ausência de uma flag conhecida não aborta a execução. |
| Escopo da Tarefa 8 para Elixir exigir tornar funções privadas em públicas | Único caso entre as sete linguagens que exige mudança de visibilidade real (não apenas remoção de `private` como em Java); documentado explicitamente como a exceção mais invasiva, justificada pela ausência de um mecanismo de teste interno em scripts `.exs` sem essa mudança. |

## 6. Testes necessários (após a implementação)

Higiene: `git diff --check`, `git status --short`, `python3 -m py_compile scripts/*.py src/*.py tests/*.py`.
Regressão: `tests/test_point_generation.py`, `tests/test_validate_run.py`.
Harness por linguagem extra: Rust, Julia, Elixir (via `tests/test_extra_language.py`).
Caso de arredondamento `B=101 Npts=3 M=1 escala=1` → `N=[100,101,101]` em todas as sete.
Testes novos de multiplicação não identidade nas sete linguagens.
`bash -n run_all.sh`; análise sintática de `run_all.ps1` pelo parser do Windows PowerShell disponível via WSL. A execução ponta a ponta em Windows nativo permanece pendente, como registrado em `TODO.md`.
Smoke sem extras; smoke `--with-rust`; smoke `--with-all-extras`; falha por toolchain ausente (confirmando diretório `.running-` preservado e nenhum `out/<run_id>` espúrio); falha proposital de um benchmark (mesma confirmação).

## 7. Itens que NÃO serão alterados nesta rodada

Tudo listado na Seção 9 do pedido: `int[][]` do Java, column-major do Julia, listas/inteiros do Python, imutabilidade do Elixir, modelos de GC/JIT de cada runtime, bounds-check obrigatório onde é característica do runtime, ausência de bounds-check em C/C++, ordem `i,j,k`, algoritmo O(N³) manual, ausência de BLAS/paralelismo, contrato CLI, cabeçalho CSV, regra de geração de N, warm-up de uma rodada, `M` repetições. `unsafe`/`get_unchecked` do Rust e `@inbounds` do Julia permanecem, com o teste `--check-bounds=yes` (Julia) sendo executado como checagem, não como mudança de comportamento padrão. Nenhuma versão de toolchain será fixada nos runners (permanece decisão em aberto no `TODO.md`). Nenhuma nova medição de wall-clock. `INTEGRATION_PLAN.md` não será reescrito.

---

Encerrado o plano. Início da implementação a seguir.
