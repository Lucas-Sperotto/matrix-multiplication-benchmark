# Relatório de Estabilização Final — Pré-Congelamento Experimental

Data: 2026-08-26

Nota de consolidação: este relatório foi redigido durante a rodada técnica, antes da organização final dos arquivos e da criação dos commits. A Seção 1 registra deliberadamente o ponto de partida; caminhos e estado do Git foram atualizados nas seções seguintes para refletir a organização consolidada em `docs/` e `tests/`.

## 1. Branch e SHA iniciais

- Branch de trabalho: `feat/extra-languages-integration` (base `tcc-lic-thassio`, fast-forward limpo: 4 commits à frente, 0 atrás no início da tarefa).
- SHA inicial: `11d230f6f7c9e7246dc7cf58da7700079bb4eb8a`.
- Estado inicial de `git status --short`: `CONTRIBUTING.md`, `DIAGRAMS.md`, `EXECUTION.md`, `EXTRA_LANGUAGES.md`, `README.md`, `TODO.md` já modificados e `METHODOLOGY.md`, `docs/THREATS_TO_VALIDITY.md` já novos (não commitados), remanescentes de uma auditoria de documentação anterior nesta mesma sessão de trabalho. Nenhum arquivo de `src/` estava modificado no início desta tarefa.
- Nenhum commit foi criado durante a rodada técnica registrada aqui; a consolidação em commits e o Pull Request foram executados em etapa posterior, sem alterar diretamente as branches protegidas `main` ou `tcc-lic-thassio` e sem rebase/force-push.

## 2. Problemas confirmados (por leitura direta do código, não por memória)

1. Julia usava `Matrix{Int}` (64 bits nas plataformas 64-bit validadas) para os elementos das matrizes, divergindo da largura de 32 bits usada por C/C++/Java/Rust.
2. C alocava `res` em TAM via `malloc`, sem inicializá-lo (conteúdo indeterminado até `multiply` sobrescrevê-lo em TCS).
3. Python criava e zerava `res` dentro de `multiply()`, ou seja, dentro da janela de TCS, não de TAM.
4. `run_all.ps1` já tinha `Assert-LastExitCode` após toda invocação nativa crítica — confirmado por leitura completa do arquivo; não era, de fato, um problema, apenas pendente de confirmação/documentação.
5. O cabeçalho de `src/matriz_multiplication.exs` afirmava que a tupla plana era "a única" representação capaz de preservar as complexidades exigidas — alegação de unicidade não sustentada pela comparação de apenas quatro alternativas.
6. `run_manifest.json` capturava só a primeira linha de `java -version` (perdendo informação de vendor/VM) e não registrava o coletor de lixo (GC) ativo da JVM.
7. Uma execução que falhasse no meio do caminho (toolchain ausente, erro de benchmark, falha de validação) escrevia diretamente em `out/<run_id>/`, deixando artefatos parciais em um diretório com o mesmo nome que uma execução completa teria.
8. A documentação já tratava `TEXEC = TAM + TCS + TDM` com cautela, mas não usava a nomenclatura formal "tempo agregado das fases instrumentadas" pedida.
9. Nenhuma das sete implementações tinha um teste interno com matriz não identidade; a validação amostral usa `B` como identidade e não distingue multiplicação correta de cópia do primeiro operando.

## 3. Alterações feitas

- **Julia (`src/matriz_Julia.jl`)**: elementos de `mat1`/`mat2`/`res` convertidos para `Matrix{Int32}`; acumulador do laço quente tornado `Int32(0)` explícito (evita promoção implícita a 64 bits); inicialização com conversões explícitas `Int32(...)`; índices, dimensão `n` e contadores permanecem `Int`. Adicionada guarda `if abspath(PROGRAM_FILE) == abspath(@__FILE__)` ao redor da chamada de `main()`, permitindo reuso em teste sem alterar a invocação normal via CLI.
- **C (`src/matriz_c.c`)**: `res` passou de `malloc` para `calloc` (aloca e zera em TAM); `mat1`/`mat2` mantidos em `malloc` (todo elemento é sobrescrito uma única vez, zerar seria trabalho duplicado).
- **Python (`src/matriz_python.py`)**: criação/zeragem de `res` movida de dentro de `multiply()` para `run_once()` (janela de TAM); `multiply` passou a receber `res` como parâmetro e mutá-lo in place, sem retornar novo objeto.
- **Elixir (`src/matriz_multiplication.exs`)**: reescrito o parágrafo de justificativa da representação (Tarefa 4), removendo a alegação de unicidade; `build_matrix/2` e `multiply/3` tornadas públicas (`def`, não mais `defp`); adicionada guarda por variável de ambiente (`MATRIZ_ELIXIR_SKIP_MAIN`) ao redor da chamada de `MatrizElixir.main/1` no rodapé, permitindo reuso em teste sem alterar a invocação normal.
- **Java (`src/matriz_java.java`)**: apenas `multiply` deixou de ser `private` (passou a ter visibilidade de pacote), permitindo reuso por uma classe de teste no mesmo pacote default; `verifySample` permanece privado.
- **Rust (`src/matriz_rust.rs`)**: adicionado um módulo `#[cfg(test)] mod tests { ... }` aditivo ao final do arquivo, com um teste unitário 2×2 não identidade, compilado apenas por `rustc --test` (sem efeito no build de produção, verificado).
- **`run_all.sh`/`run_all.ps1`**: (a) diretório de trabalho `out/.running-<run_id>` promovido para `out/<run_id>` somente após todos os benchmarks, `system_info`, gráficos e `validate_run.py` terem sucesso; o nome final deve ser inteiramente inexistente, mesmo que o caminho preexistente seja um diretório vazio, e o nome de trabalho também não pode existir; (b) `run_manifest.json.tools.java` passou a registrar a saída completa (multi-linha) de `java -version`; novo campo `run_manifest.json.tools.java_gc`, obtido por sondagem best-effort (`java -XX:+PrintFlagsFinal -version`, checando uma lista fechada de flags de seleção de coletor HotSpot), com fallback `"N/D"`.
- **`scripts/gen_sysinfo_md.sh`**: a saída UTF-16LE de `wsl.exe --status` passou a ser decodificada para UTF-8 antes de entrar em uma variável Bash, evitando bytes NUL/surrogates inválidos e permitindo gerar `system_info.json` de forma válida em WSL.
- **`tests/` (novo diretório)**: um teste de corretude por linguagem (caso 2×2 não identidade, `A=[[1,2],[3,4]]`, `B=[[5,6],[7,8]]`, esperado `[[19,22],[43,50]]`), reusando a função de multiplicação de produção, fora da janela de benchmark: `test_matriz_c.c`, `test_matriz_cpp.cpp`, `TestMatrizJava.java`, `test_matriz_python.py`, `test_matriz_julia.jl`, `test_matriz_elixir.exs` (Rust ficou como teste interno em `src/matriz_rust.rs`, não em `tests/`).
- **Documentação**: os guias foram consolidados em `docs/`; `docs/METHODOLOGY.md` e `docs/THREATS_TO_VALIDITY.md` refletem a nova fronteira TAM/TCS, o tipo `Int32` do Julia, o registro de GC da JVM, a nomenclatura formal de `TEXEC` e os novos testes de corretude. `README.md`, `CONTRIBUTING.md`, `TODO.md`, `docs/EXTRA_LANGUAGES.md`, `docs/EXECUTION.md`, `docs/DIAGRAMS.md` e `docs/INTEGRATION_PLAN.md` foram alinhados à organização e à semântica final dos runners.

## 4. Organização consolidada dos arquivos

- Guias e registros técnicos: `docs/DIAGRAMS.md`, `docs/EXECUTION.md`, `docs/EXTRA_LANGUAGES.md`, `docs/INTEGRATION_PLAN.md`, `docs/METHODOLOGY.md`, `docs/OPERATIONS.md`, `docs/THREATS_TO_VALIDITY.md`, além deste relatório e do plano de estabilização.
- Testes: os três harnesses/regressões `test_extra_language.py`, `test_point_generation.py` e `test_validate_run.py` foram movidos de `scripts/` para `tests/`, junto aos seis testes novos de corretude não identidade. Todas as referências de execução foram atualizadas.
- Scripts operacionais: `scripts/validate_run.py`, `scripts/gen_sysinfo_md.sh` e os demais utilitários de execução permanecem em `scripts/`; o validador não foi movido para preservar o contrato dos runners.
- Código e orquestração: alterações em `src/matriz_Julia.jl`, `src/matriz_c.c`, `src/matriz_java.java`, `src/matriz_multiplication.exs`, `src/matriz_python.py`, `src/matriz_rust.rs`, `run_all.sh`, `run_all.ps1` e `.gitignore`.

## 5. Decisões metodológicas

- **TAM/TCS**: fronteira formal declarada como "TAM cobre alocação e inicialização de A, B e do resultado, quando a representação permitir pré-alocação; TCS cobre exclusivamente o cálculo". C e Python foram alinhados a essa regra. Elixir permanece como única exceção, por ser estrutural (imutabilidade), não corrigível sem descaracterizar a linguagem.
- **Julia `Int32`**: decisão formalizada — elementos em 32 bits, índices/dimensão/contadores em `Int` nativo (64 bits nas plataformas 64-bit validadas). Validado sem risco de overflow e com `julia --check-bounds=yes`.
- **GC da JVM**: não fixado por flag (sem justificativa científica para forçar um coletor), mas passou a ser registrado por sondagem best-effort no manifesto, com fallback explícito quando não detectável.
- **`TEXEC`**: formalizado como "tempo agregado das fases instrumentadas"/"tempo agregado instrumentado" — uma métrica derivada das três janelas medidas, explicitamente não equivalente ao tempo de parede do processo. Continua não adotada como métrica oficial (decisão em aberto, registrada em `TODO.md`).
- **Elixir**: a escolha da tupla plana passou a ser descrita como o melhor compromisso entre as alternativas avaliadas neste projeto, não como solução assintoticamente única.
- **Execuções incompletas**: arquitetura de diretório de trabalho (`out/.running-<run_id>`) com promoção (rename/Move-Item) somente após sucesso completo, preferida em vez de alternativas com rename entre filesystems ou marcação pós-hoc, por manter a operação de promoção dentro do mesmo `out/` e depender apenas do `set -e`/`Assert-LastExitCode` já existentes.

## 6. Diferenças inevitáveis preservadas (não alteradas nesta rodada)

Conforme a lista explícita de restrições: `int[][]` do Java; column-major do Julia; listas/inteiros do runtime em Python; imutabilidade do Elixir; modelos de GC/JIT de cada linguagem; bounds-check obrigatório em Java/Python/Elixir (`elem/2`); ausência de bounds-check em C/C++; ordem algorítmica `i,j,k`; multiplicação manual O(N³); ausência de BLAS/paralelismo; contrato CLI; cabeçalho CSV; regra de geração de N; warm-up de uma rodada; `M` repetições medidas. `unsafe`/`get_unchecked` do Rust e `@inbounds` do Julia foram mantidos (documentados, validados com `--check-bounds=yes` no caso do Julia). A construção do resultado em TCS no Elixir foi preservada como exceção estrutural declarada, não simulada como mutável.

## 7. Testes executados

- **A) Higiene git**: `git diff --check` (sem problemas de whitespace), `git status --short`.
- **B) `py_compile`**: `python3 -m py_compile scripts/*.py src/*.py tests/*.py` — sem erros.
- **C) Regressão existente**: `tests/test_point_generation.py` e `tests/test_validate_run.py` — ambos aprovados.
- **D) Harness por linguagem extra**: `tests/test_extra_language.py --language Rust` e `--language Julia` — ambos aprovados contra os binários/scripts recompilados com as mudanças desta rodada.
- **E) Caso de arredondamento** `B=101 Npts=3 M=1 escala=1`: executado nas seis implementações disponíveis no ambiente (C, C++, Java, Python, Rust, Julia) — todas produziram `N=[100,101,101]`.
- **F) Testes de corretude não identidade** (caso 2×2 conhecido): executados e aprovados em C, C++, Java, Python, Rust (`rustc --test`) e Julia (com e sem `--check-bounds=yes`).
- **G) `bash -n run_all.sh`**: sintaxe válida.
- **H) Smoke sem extras**: execução completa `--batch --run-name smoke-noextras --B 100 --Npts 2 --M 1 --escala 1` — gerou os 6 CSVs, manifesto (com `java_gc` e `java` multi-linha), `system_info`, gráficos, `validate_run.py` aprovado, e promoção de `out/.running-smoke-noextras` para `out/smoke-noextras` confirmada.
- **I) Smoke `--with-rust`**: execução completa aprovada; `run_manifest.json.tools.java_gc = "UseG1GC"` e `rustc` registrado corretamente.
- **J) Smoke `--with-all-extras`**: Rust e Julia executaram com sucesso; Elixir ausente no ambiente causou abort esperado (ver item K).
- **K) Falha por toolchain ausente**: `--with-all-extras` sem Elixir instalado abortou com código de saída 1, mensagem clara ("Dependencia ausente: elixir"), `out/.running-smoke-allextras` preservado com os artefatos parciais (até Julia), `out/smoke-allextras` nunca criado.
- **L) Falha deliberada de benchmark**: um `julia` falso (shim de PATH, sem alterar nenhum arquivo do projeto) forçado a retornar código 3 durante `--with-julia` — script abortou com código 3, `out/.running-smoke-failjulia` preservado com os artefatos até Python, `out/smoke-failjulia` nunca criado.
- **M) PowerShell**: o parser do Windows PowerShell disponível via WSL aceitou `run_all.ps1` sem erros de sintaxe. O arquivo também foi revisado integralmente, mas a execução ponta a ponta em Windows nativo (compilação, benchmarks, validação e promoção no NTFS) não foi realizada — permanece registrada como limitação em `TODO.md`.

Ambiente de teste: sandbox Linux/WSL. `matplotlib` do `python3` de sistema estava quebrado (incompatibilidade NumPy 1.x/2.x, alheia a este projeto); os smoke tests usaram o `.venv` do próprio projeto, que tem `matplotlib` funcional. Uma tentativa revelou que `wsl.exe --status` emitia UTF-16LE e quebrava o JSON; `scripts/gen_sysinfo_md.sh` foi corrigido para decodificar essa saída antes de exportá-la, e a geração de `system_info.json` foi revalidada com acentos e sem bytes NUL.

## 8. Resultados dos testes

Todos os testes executáveis neste ambiente passaram. Nenhuma regressão foi introduzida nas implementações disponíveis localmente. O comportamento de execução incompleta foi confirmado em cenários de falha, sempre preservando o staging e sem criar o destino final; depois da correção de UTF-16LE, o smoke principal voltou a alcançar validação e promoção com sucesso.

## 9. Testes que não puderam ser executados

- `tests/test_matriz_elixir.exs` (teste de corretude não identidade do Elixir): Elixir não está instalado neste ambiente. O arquivo foi escrito e revisado, mas não executado.
- Smoke test real com `--with-elixir`/`--with-all-extras` completo (incluindo Elixir): mesma causa.
- Execução ponta a ponta de `run_all.ps1` em Windows nativo: o parser do Windows PowerShell aprovou a sintaxe via WSL, mas o fluxo completo não foi exercitado no NTFS.
- Verificação de `-XX:+PrintFlagsFinal`/`java_gc` em JVMs não HotSpot (OpenJ9, GraalVM native): não há esse ambiente disponível para teste; o fallback `"N/D"` não foi exercitado contra uma JVM real que o produza, apenas por inspeção de código.

## 10. Riscos remanescentes

- A sintaxe e a estrutura da promoção de diretório em `run_all.ps1` foram verificadas, mas o fluxo completo nunca foi executado em Windows nativo; um comportamento específico do PowerShell/NTFS (por exemplo, bloqueio de arquivo por antivírus) ainda pode divergir do Linux.
- A detecção de GC da JVM depende de uma flag de diagnóstico HotSpot (`-XX:+PrintFlagsFinal`) e de uma lista fechada de nomes de flag; uma JVM futura com um coletor novo, não incluído na lista, resultaria em `"N/D"` mesmo com um coletor identificável — comportamento conservador, mas não exaustivo.
- O teste de corretude do Elixir não foi validado neste ambiente; um erro de sintaxe ou de lógica nesse arquivo específico só seria descoberto na primeira execução em um ambiente com Elixir instalado.
- `tests/` introduz mudanças reais de visibilidade em Java (`private` → package-private) e Elixir (`defp` → `def`, mais uma guarda de ambiente); embora documentadas como deliberadas e sem efeito de comportamento na CLI, são as duas alterações desta rodada com maior potencial de superfície nova, e dependem da revisão humana confirmar que a justificativa (permitir teste sem duplicar código) é aceitável para o TCC.

## 11. Itens que ainda impedem o congelamento experimental total

Nenhum dos 14 itens desta tarefa permanece pendente de implementação. Os itens abaixo, já rastreados em `TODO.md`, são decisões metodológicas ou de infraestrutura fora do escopo desta tarefa e continuam em aberto:

- Versões de Rust/Julia/Elixir-OTP não fixadas formalmente nos runners.
- `M` não ampliado e tempos brutos por repetição não preservados (sem desvio padrão/variância reportável).
- Protocolo ambiental da coleta final (carga de fundo, afinidade, governor/turbo, ordem das linguagens) não definido.
- Sanitização de `--run-name`/`-RunName` contra path traversal ainda não implementada.
- Verificação empírica formal (não apenas diagnóstica) de que o warm-up único estabiliza o JIT do Java.
- `run_all.ps1` nunca testado em PowerShell/Windows nativo real.
- Teste de corretude do Elixir nunca executado por falta de toolchain neste ambiente.

## 12. Recomendação final

**PRONTO COM LIMITAÇÕES DOCUMENTADAS.**

Justificativa: os itens explicitamente solicitados nesta tarefa foram implementados, testados no que o ambiente permite e documentados de forma consistente entre código e os documentos vivos (`docs/METHODOLOGY.md`, `docs/THREATS_TO_VALIDITY.md`, `docs/EXTRA_LANGUAGES.md`, `docs/EXECUTION.md` e `TODO.md`). As correções foram verificadas empiricamente nas implementações executáveis localmente, sem regressão detectada, e a arquitetura de execução incompleta foi validada em cenários reais de falha.

As limitações que impedem a classificação "PRONTO PARA CONGELAMENTO EXPERIMENTAL" sem ressalvas são de ambiente de teste: ausência de Elixir e falta de execução ponta a ponta em Windows nativo. Nenhuma delas foi contornada por afirmação não verificada — ambas estão explicitamente marcadas nas Seções 7 e 9 e no `TODO.md`. Antes da coleta experimental formal, recomenda-se: (1) executar `tests/test_matriz_elixir.exs` e um smoke `--with-elixir` completo em um ambiente com Elixir instalado; (2) executar `run_all.ps1` uma vez em Windows nativo para confirmar a promoção de diretório no NTFS.

## 13. Consolidação no Git

O snapshot detalhado usado na auditoria foi preservado na Seção 1 pelo SHA inicial `11d230f`. Depois da revisão, as mudanças foram organizadas por responsabilidade em commits convencionais na branch `feat/extra-languages-integration`; os movimentos de documentação e testes foram incluídos com origem e destino no mesmo commit para preservar a detecção de renames.

Antes da publicação, o diff staged de cada commit foi verificado com `git diff --cached --check` e inspecionado para impedir trailers ou referências indevidas de coautoria. A branch protegida `tcc-lic-thassio` permaneceu inalterada diretamente e foi usada apenas como base do Pull Request.
