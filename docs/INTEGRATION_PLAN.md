# Plano de Integração — Rust, Julia e Elixir ao Fluxo Publicável

Branch: `feat/extra-languages-integration` (base: `tcc-lic-thassio`, já com Rust/Julia/Elixir aceitos em `src/` via PRs #9, #10, #11).

Este documento foi escrito antes das alterações e preserva as decisões arquiteturais da integração. A implementação e os testes descritos abaixo foram concluídos posteriormente na mesma branch.

---

## 1. Arquitetura

### Decisão: B (opcional, auto-detectado) **como mecanismo**, acionado por C (flags explícitas) — não A

**A (obrigatórias) está descartada**: violaria diretamente o critério "execução continua funcionando sem as toolchains extras" — qualquer máquina sem Rust/Julia/Elixir instalados quebraria o fluxo principal, inclusive para quem só quer C/C++/Java/Python. Descartada sem ressalvas.

**B pura (auto-detecção silenciosa, sempre ativa) também está descartada como padrão**: se `./run_all.sh --batch ...` incluísse Rust automaticamente sempre que `rustc` estivesse no `PATH`, dois colaboradores rodando o **mesmo comando** obteriam conjuntos de CSVs diferentes dependendo do que cada um tem instalado por acaso — isso viola diretamente "resultados devem permanecer reproduzíveis". Detecção automática *silenciosa e sempre ativa* é o oposto de reprodutibilidade.

**C pura (só flags, sem detecção) também não basta sozinha**: uma flag por si só não resolve o que fazer quando a toolchain está ausente.

**Arquitetura escolhida — híbrida, com o gatilho em C e o mecanismo em B:**

- **Comportamento padrão (sem flags) permanece idêntico ao atual**: só C, C++, Java, Python. Zero mudança de comportamento observável para quem não usa as novas flags — reprodutibilidade total preservada, nenhuma dependência nova é exigida.
- **Novas flags explícitas** ativam cada linguagem extra individualmente:
  - Bash: `--with-rust`, `--with-julia`, `--with-elixir`, e `--with-all-extras` (atalho para as três).
  - PowerShell: `-WithRust`, `-WithJulia`, `-WithElixir`, `-WithAllExtras`.
- **Quando uma flag é passada, a detecção (B) decide o que fazer**: se a toolchain correspondente existe no `PATH`, ela compila/executa normalmente; se não existe, **aborta a execução inteira com erro claro em stderr e código de saída ≠ 0** — porque pedir uma linguagem explicitamente e não conseguir entregá-la é uma falha, não uma omissão silenciosa. Isso satisfaz literalmente "erros de uma linguagem solicitada explicitamente devem abortar a execução".
- **Sem a flag, a ausência da toolchain é irrelevante** — o script nunca tenta detectar nem executar aquela linguagem, então "ausência de linguagem opcional não pode invalidar execução principal" é satisfeito por construção (a pergunta nunca chega a ser feita).

Isso resolve a tensão aparente entre B e C: a auto-detecção não decide *se* uma linguagem roda (isso é decisão explícita do usuário via flag), só decide *como reagir* quando a linguagem foi pedida mas a toolchain não está lá.

### Onde a checagem "abortar em erro explícito" já existe de graça

`run_all.sh` já roda sob `set -euo pipefail`; qualquer comando que falhe aborta o script inteiro. O padrão `need_cmd` foi reaproveitado para `rustc`/`julia`/`elixir` somente quando a flag correspondente é usada. Em `run_all.ps1`, comandos nativos (`.exe`) que retornam código de saída ≠ 0 não disparam `$ErrorActionPreference = "Stop"` automaticamente; a revisão encontrou essa lacuna também no fluxo central. Por isso, todas as compilações, execuções, geração de gráficos e validação passam por `Assert-LastExitCode`.

### Ordem de execução

Rust/Julia/Elixir rodam **depois** que os seis CSVs principais já foram gerados com sucesso. Assim, uma falha em uma extra explicitamente pedida preserva esses CSVs e encerra o script com código ≠ 0. Metadados e gráficos ainda não são produzidos nesse cenário, portanto a pasta parcial não é uma execução validada.

### Manifesto: registrar exatamente o que rodou

`languages` no `run_manifest.json` ganha uma entrada por linguagem extra **somente se ela de fato rodou com sucesso** (nunca uma entrada "tentativa" ou "pulada"). `tools` ganha `rustc`/`julia`/`elixir` com a saída de `--version`, mesma convenção já usada para gcc/g++/java/javac/python. Isso satisfaz "manifesto deve registrar exatamente o que foi executado" e "versões das toolchains devem ser registradas" ao mesmo tempo, sem estrutura nova — só mais entradas nas mesmas duas listas/objetos que já existem.

### Compatibilidade do validador e do plotador

Ambos já reconheciam as séries extras, mas o smoke test revelou um ajuste necessário no validador:

- `validate_run.py`: `EXPECTED_CSVS` (6 obrigatórios) permanece intocado e `manifest_csvs()` continua iterando toda a lista `languages`. `run_dir` passou a ser resolvido uma vez para não misturar caminhos relativos e absolutos; além disso, o manifesto tornou-se autoritativo, então um CSV extra presente mas não declarado é rejeitado.
- `plot_benchmarks.py`: `FILES` já contém `"Rust"`, `"Julia"`, `"Elixir"` apontando para os nomes de arquivo corretos; `load_data()` já filtra por `path.exists()`, então só entram no gráfico séries realmente presentes. **Nenhuma alteração necessária.**

O runner também passou a rejeitar caminhos finais de execução já existentes, inclusive diretórios vazios, impedindo que um CSV antigo seja incorporado aos gráficos ou que a promoção aninhe o staging em uma pasta preexistente com o mesmo `run_id`.

---

## 2. Alterações por arquivo

| Arquivo | Mudança necessária | Prioridade |
|---|---|---|
| `run_all.sh` | Parsing de `--with-rust`, `--with-julia`, `--with-elixir`, `--with-all-extras`; `need_cmd` condicional; compilar Rust (`--edition=2021 -C opt-level=3 -D warnings`, mesma política usada na validação do PR) em `build/linux/matriz_rust`; executar Rust/Julia/Elixir com o contrato padrão; estender a lista `languages` e o objeto `tools` do manifesto só com o que rodou. | **P0** |
| `run_all.ps1` | Mesma coisa com `-WithRust`/`-WithJulia`/`-WithElixir`/`-WithAllExtras`; compilar Rust em `build\windows\matriz_rust.exe`; checar `$LASTEXITCODE` após todos os comandos nativos críticos. | **P0** |
| `scripts/validate_run.py` | Normalizar `run_dir`, validar todos os CSVs declarados e rejeitar CSV extra órfão do manifesto. | **P0** |
| `scripts/gen_sysinfo_md.sh` | Nenhuma. Não depende de quais linguagens rodaram. | — |
| `src/plot_benchmarks.py` | Nenhuma. Já reconhece as três séries e já ignora as ausentes. | — |
| `run_manifest.json` (formato produzido) | Passa a poder ter 7, 8 ou 9 entradas em `languages` (6 fixas + até 3 opcionais) e 5 a 8 chaves em `tools`, dependendo das flags usadas. Nenhuma mudança de *schema*, só de cardinalidade. | **P0** (consequência das mudanças acima) |
| `README.md` | Atualizar "Trilha Rust, Julia e Elixir": elas deixam de ser só uma trilha de PR e passam a ser executáveis opcionalmente via flag; documentar `--with-rust`/`--with-julia`/`--with-elixir`/`--with-all-extras`. | **P1** |
| `EXECUTION.md` | Reescrever "Executar os protótipos de novas linguagens" (não são mais protótipos fora do fluxo) com exemplos de uso das novas flags em batch e a lista de artefatos (`build/linux/matriz_rust`, `build\windows\matriz_rust.exe`). Atualizar a seção "Artefatos". | **P1** |
| `TODO.md` | Marcar os itens da seção 8 ("Prompt 7") como concluídos conforme implementados; deixar em aberto só o que continuar pendente (ex.: `METHODOLOGY.md`, smoke test oficial, correção de C/C++ não criarem diretório pai). | **P1** |
| `DIAGRAMS.md` | Ajustar o diagrama "Integração de Nova Linguagem ao Fluxo Principal": hoje ele sugere sempre adicionar a `EXPECTED_CSVS`/sempre atualizar o manifesto incondicionalmente, o que não reflete mais o modelo opcional-por-flag. Ajuste textual pontual, não uma reescrita. | **P2** |
| `CONTRIBUTING.md`, `EXTRA_LANGUAGES.md` | Atualizar caminhos, estado de aceite e fluxo atual das contribuições. | **P1** |
| `METHODOLOGY.md`, `docs/THREATS_TO_VALIDITY.md`, suíte de smoke test oficial | Fora de escopo desta integração — rastreados separadamente em `TODO.md`. | **P2/P3** (fora desta PR) |
| `src/matriz_c.c`, `src/matriz_cpp.cpp` (não criam diretório pai) | Achado real, mas ortogonal a esta integração — `run_all.sh`/`run_all.ps1` já criam `OUT_DIR` antes de invocar qualquer binário, então o fluxo integrado nunca expõe essa lacuna. Não corrigido nesta PR. | **P2** (fora desta PR) |

---

## 3. Compatibilidade

- **Invocação sem flags novas e com `run_id` novo**: produz os mesmos 6 CSVs, manifesto e gráficos do núcleo. Qualquer caminho final já existente agora é rejeitado para impedir contaminação ou aninhamento entre execuções.
- **`out/<run_id>/` de execuções antigas**: continua válido quando o manifesto declara todos os CSVs presentes; um CSV extra órfão passa a ser rejeitado explicitamente.
- **Toolchains extras ausentes, sem flag**: nenhum impacto — nunca são sequer verificadas.
- **Toolchains extras ausentes, com flag**: comportamento novo e intencional — aborta com erro claro, código de saída 1. Não é uma quebra de compatibilidade porque não existia comportamento anterior para essas flags (elas não existiam).
- **`experiments/` vs `src/`**: os runners passam a referenciar `src/matriz_rust.rs`, `src/matriz_Julia.jl`, `src/matriz_multiplication.exs` — os caminhos já corretos pós-aceite, sem ambiguidade com versões antigas em `experiments/` (que não existem mais nesses nomes).

---

## 4. Testes executados após a implementação

1. **Regressão do fluxo padrão**: aprovada com 6 CSVs, 6 entradas em `languages`, 5 ferramentas e `validate_run.py` aprovado.
2. **Todas as extras juntas**: aprovada com 9 CSVs, 9 entradas em `languages`, 8 ferramentas e gráficos contendo as séries extras.
3. **Toolchain ausente com flag explícita**: `PATH` restrito com `--with-rust` abortou com código 1 e mensagem `Dependencia ausente: rustc`; os 6 CSVs centrais permaneceram na pasta parcial.
4. **Reutilização de `run_id`**: rejeitada antes de compilar ou sobrescrever artefatos.
5. **Regressões**: `tests/test_point_generation.py`, `tests/test_validate_run.py`, lint Python, `bash -n` e parser do Windows PowerShell aprovados.
6. **Windows nativo**: execução ponta a ponta ainda pendente e registrada em `TODO.md`.

---

## 5. Riscos

| Risco | Mitigação |
|---|---|
| Quebrar o fluxo padrão para quem não usa as flags novas | Extras ficam num bloco condicional adicionado *depois* do fluxo de 6 linguagens existente; nenhuma linha do fluxo atual é reordenada ou removida — só adição. Teste de regressão #1 cobre isso diretamente. |
| `run_all.ps1` não abortar de fato numa falha nativa (lacuna do `$LASTEXITCODE`) | Checagem explícita após todas as compilações, benchmarks, plotador e validador. |
| Reutilização de um `run_id` incorporar CSV extra antigo | Runners rejeitam qualquer destino final já existente; validador rejeita CSV extra ausente do manifesto. |
| Divergência futura de arredondamento entre uma extra e o núcleo passar despercebida | Já coberta pela checagem de série de N consistente em `validate_run.py`, que já se aplica a qualquer CSV incluído no manifesto — nenhuma proteção nova necessária, só confirmar que continua ativa (teste #3). |
| Tempo de execução do fluxo completo aumentar muito com `--with-all-extras` (Elixir é sensivelmente mais lento para N grande, conforme medido na revisão da implementação) | Documentar isso explicitamente em `EXECUTION.md`; não é um bug, é uma característica real da linguagem que o usuário deve conhecer antes de usar `--with-all-extras` com `B` grande. |
| Falha de compilação do Rust silenciosamente ignorada | `set -e` já garante abort; `rustc ... -D warnings` já transforma warnings em erro, preservando a mesma rigidez usada na validação do PR. |
| Confundir "não instalado" com "instalado mas quebrado" | `need_cmd`/`Require-Command` cobre "não encontrado no PATH"; uma falha de compilação/execução real (toolchain presente mas quebrada) já aborta via `set -e`/`$LASTEXITCODE` de qualquer forma — a distinção não muda a ação (sempre aborta), só a mensagem. |

---

## 6. Plano de rollback

- Toda a mudança fica isolada em `feat/extra-languages-integration`, que não é `tcc-lic-thassio` nem `main`. Se algo se mostrar problemático após revisão, basta não mesclar a branch — nenhum efeito no restante do projeto.
- Caso já mesclada e um problema apareça depois, os commits separados de runner, documentação e rastreamento permitem `git revert` por responsabilidade. A rejeição de destino final já existente e as checagens de código de saída devem ser avaliadas explicitamente antes de qualquer rollback, pois protegem também o núcleo.
- Nenhuma mudança de schema em `run_manifest.json` foi introduzida (só cardinalidade), então execuções já coletadas com o formato novo continuam válidas mesmo se o rollback remover a capacidade de *gerar* novas entradas — `validate_run.py` não differencia execuções "antigas" (6 linguagens) de "novas" (7-9 linguagens).
