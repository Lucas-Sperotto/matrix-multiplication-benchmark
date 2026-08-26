# Metodologia Experimental

Este documento é a referência científica única do benchmark: o que é medido, como é medido, e quais são os limites conhecidos da comparação entre linguagens. `../README.md` e `EXECUTION.md` tratam de uso; este documento trata do desenho experimental por trás desse uso.

## Objetivo experimental

Comparar o tempo de execução de uma multiplicação de matrizes quadradas `N x N` implementada manualmente (três laços, sem bibliotecas de álgebra linear) em nove variantes de sete linguagens: C, C -O3, C++, C++ -O3, Java, Python, Rust, Julia e Elixir.

Formulação explícita do objeto de comparação, para orientar a interpretação de qualquer resultado:

> Comparam-se implementações funcional e algoritmicamente equivalentes de multiplicação matricial manual O(N³), preservando características fundamentais de representação e runtime de cada linguagem. Não se assume equivalência microarquitetural das estruturas de dados.

Ou seja: o contrato garante uma formulação algorítmica equivalente (ordem lógica `i, j, k`), a mesma série de N, o mesmo protocolo de medição (warm-up + M repetições) e o mesmo formato de saída — não garante que cada linguagem aloque objetos ou acesse memória da mesma forma internamente. Essas diferenças de representação são tratadas como parte do objeto de estudo, não como ruído a eliminar, e estão documentadas na seção "Layout de memória e tipo numérico" abaixo.

## Variável independente

`N`: dimensão da matriz quadrada `N x N`. Gerada por `Npts` pontos entre `100` e `B` (inclusive), conforme a seção "Geração de N".

## Variáveis dependentes

Para cada `N`, cada implementação registra três tempos médios, em segundos, no CSV de saída (`N,TCS,TAM,TDM`):

- **TAM** (tempo de alocação de memória): janela destinada à alocação e inicialização das matrizes.
- **TCS** (tempo de cálculo): janela destinada à multiplicação manual, sem a validação amostral.
- **TDM** (tempo de desalocação): liberação explícita de memória, quando a linguagem permite controle manual.

A fronteira formal é: **TAM** cobre a alocação e a inicialização de `A`, `B` e do resultado (quando a representação da linguagem permitir pré-alocação); **TCS** cobre exclusivamente o trabalho de multiplicação, sem alocação estrutural evitável. Nas implementações mutáveis (C, C++, Java, Python, Rust, Julia), essa fronteira está alinhada:

- C, C++, Java, Rust e Julia alocam **e inicializam/zeram** o buffer de resultado em TAM (C usa `calloc`; as demais, construtores/literais que já zeram);
- Python cria e zera a lista de resultado em `run_once`, antes de cronometrar TCS, e passa o buffer já pronto para `multiply`, que apenas o preenche.

**Elixir é a única exceção, e é estrutural, não uma pendência de implementação**: por imutabilidade, uma tupla não pode ser "reservada" e depois preenchida em `put_elem/3` sem custo O(N) por célula (ver "Layout de memória e tipo numérico" abaixo); o resultado só passa a existir quando a comprehension de `multiply` termina, portanto sua construção fica inteiramente dentro de TCS. Isso é declarado como limitação de comparabilidade, não corrigido: forçar uma pré-alocação mutável em Elixir descaracterizaria a linguagem, contrariando o princípio central deste estudo (preservar características inevitáveis de cada runtime).

TAM/TCS/TDM têm significado operacional diferente conforme o modelo de memória da linguagem:

- **C, C++, Rust**: a implementação provoca uma liberação determinística dentro da janela medida (`free`, `vector::swap` e `drop`, respectivamente). Os valores pertencem à mesma categoria nominal, mas ainda refletem mecanismos de ownership e alocadores diferentes; não são custos internamente idênticos.
- **Java, Julia e Elixir**: memória gerenciada por coleta de lixo. **Python usa gerenciamento automático por contagem de referências, complementado por GC cíclico.** Nas quatro implementações, o benchmark não cronometra a liberação e registra `TDM = 0.0` por definição. Isso não significa "liberação instantânea"; significa "fase não medida pelo protocolo atual". Comparar esses zeros diretamente com o TDM de C/C++/Rust como se representassem o mesmo mecanismo é um erro de interpretação.

Uma métrica derivada, `TEXEC = TAM + TCS + TDM`, é uma candidata razoável para agregar as três fases reportadas, mas **não foi adotada** — permanece uma decisão em aberto (ver `TODO.md`). Se adotada, `TEXEC` deve ser nomeada e entendida como **tempo agregado das fases instrumentadas** (ou "tempo agregado instrumentado"), nunca como "tempo total de execução": ela soma apenas as três janelas explicitamente cronometradas pelo protocolo, não o tempo de parede (wall-clock) do processo. Em runtimes gerenciados, isso é uma diferença relevante, não apenas terminológica — trabalho de GC pode ser adiado para fora da janela instrumentada, parte do gerenciamento de memória pode ocorrer fora de TAM/TCS/TDM, e a construção do resultado em Elixir já está estruturalmente dentro de TCS (ver acima). `TEXEC`, se usada, é portanto uma métrica **derivada das fases explicitamente instrumentadas**, não uma medição independente de tempo de parede — e não deve ser citada como equivalente ao tempo total do processo em nenhuma linguagem. Nenhuma nova medição de wall-clock foi introduzida para suportar `TEXEC`; se isso for considerado necessário no futuro, permanece registrado apenas como extensão possível em `TODO.md`. Se adotada, TAM/TCS/TDM devem continuar sendo reportados como métricas diagnósticas, não substituídos por `TEXEC`.

## Controles experimentais

As sete implementações — C e C++ geram duas variantes de compilação cada, totalizando nove séries — compartilham:

- o mesmo contrato de linha de comando (`B Npts M escala out_csv`, ver `EXTRA_LANGUAGES.md` seção 3);
- a mesma série de `N` (mesma fórmula e mesma regra de arredondamento — ver abaixo);
- a mesma inicialização lógica: `A[i,j] = i + j` e `B` como matriz identidade, usando índices lógicos 0-based (Rust, C, C++, Python e Java já são 0-based nativamente; Julia é 1-based e Elixir usa uma tupla plana indexada manualmente — ambas fazem a conversão explícita para os mesmos valores lógicos, documentada no código);
- uma formulação algoritmicamente equivalente: três iterações aninhadas na ordem lógica `i, j, k`, com `soma += A[i,k] * B[k,j]`, sem multiplicação matricial pronta, BLAS ou paralelismo;
- a mesma validação amostral: nove posições do resultado (combinações de índices lógicos `0`, `N/2`, `N-1`), fora da janela de TCS;
- o mesmo protocolo de warm-up + M repetições (ver abaixo);
- o mesmo cabeçalho de CSV (`N,TCS,TAM,TDM`) e a mesma unidade (segundos).

## Geração de N

Para `i` de `0` a `Npts - 1`:

```text
linear:      N_i = 100 + (B - 100) * i / (Npts - 1)
logaritmica: N_i = 100 * (B / 100) ** (i / (Npts - 1))
```

O arredondamento pode produzir valores de `N` repetidos, especialmente quando `B` está próximo de 100 e `Npts` é grande. Essas repetições são permitidas, permanecem no CSV e são medições independentes na ordem gerada.

Como todos os valores são positivos, o arredondamento usado é **metade-para-cima**, `floor(x + 0.5)`, implementado de forma equivalente nas sete implementações (e, portanto, nas duas compilações de C e C++):

| Linguagem | Técnica | Equivalente a metade-para-cima para valores positivos? |
| --- | --- | --- |
| C | `(int)(x + 0.5)` (truncamento após soma) | Sim |
| C++ | `std::round(x)` (metade para longe de zero) | Sim |
| Java | `Math.round(x)` (documentado como metade-para-cima) | Sim |
| Python | `math.floor(x + 0.5)` | Sim (o `round()` nativo do Python usa metade-para-par e **não** foi usado, exatamente para evitar essa divergência) |
| Rust | `(x + 0.5).floor() as usize` | Sim |
| Julia | `floor(Int, x + 0.5)` | Sim |
| Elixir | `floor(x + 0.5)` (`Kernel.floor/1`) | Sim |

Essa consistência foi verificada manualmente comparando a série de N produzida por C, Python, Rust, Julia e Elixir para o caso `B=101, Npts=3, escala=1` (que gera um ponto exatamente em `x.5`): todas as cinco produziram `N = [100, 101, 101]`. `tests/test_point_generation.py` fixa o caso como regressão automatizada da fórmula canônica e da referência Python; ele não executa sozinho uma comparação entre linguagens. Em execuções completas, `scripts/validate_run.py` exige séries de N idênticas entre todos os CSVs declarados.

## Warm-up e número de repetições

Para cada `N`: uma rodada completa de warm-up cujos tempos são calculados e descartados, seguida de exatamente `M` rodadas cujos tempos entram na média aritmética simples gravada no CSV.

O warm-up existe para reduzir efeitos de primeira execução — em particular, compilação JIT do Java, especialização por tipo do Julia e aquecimento de alocador/cache/runtime nas demais linguagens. O BeamAsm já traduz o módulo Elixir no carregamento, antes desse warm-up. A suficiência de uma rodada **não foi validada empiricamente com uma ferramenta de introspecção de JIT** (por exemplo, `java -XX:+PrintCompilation`) neste projeto; permanece uma limitação declarada, não uma garantia medida. Ver "Ameaças à validade interna".

`M` reduz ruído de medição via média aritmética simples. Os tempos individuais de cada repetição **não são preservados** — apenas a média por `N` é gravada no CSV. Isso significa que o projeto, no estado atual, não permite calcular desvio padrão, percentis ou intervalo de confiança a partir de uma única execução; essa é uma limitação conhecida registrada no `TODO.md`.

## Validação matemática

Duas camadas independentes, nenhuma delas suficiente sozinha:

1. **Validação amostral interna** (dentro de cada implementação, fora da janela de TCS): nove posições do resultado — combinações dos índices lógicos `0`, `N/2`, `N-1` em linha e coluna — comparadas contra o valor esperado `i + j` (consequência de `B` ser a matriz identidade). Se qualquer posição divergir, a implementação encerra com código de saída diferente de zero e mensagem em `stderr`, sem gravar aquele `N` no CSV.
2. **Harness de contrato externo** (`tests/test_extra_language.py`, usado nas linguagens extras durante o desenvolvimento): testa CLI, formato de CSV, casos de erro e a série de N — mas **não tem acesso aos valores da matriz calculados**, apenas aos tempos. Ele não pode, por construção, detectar uma multiplicação matematicamente incorreta cuja verificação amostral interna esteja ausente, incompleta, ou seja tautológica. Essa é uma limitação estrutural conhecida do harness, não um bug: o CSV não carrega a matriz de resultado para não contaminar a medição de tempo com I/O adicional. A defesa contra esse cenário é a revisão manual de código durante o Pull Request (ver checklist em `.github/pull_request_template.md`).

Ambas as camadas usam a matriz identidade como segundo operando, o que torna a verificação simples (resultado esperado = primeiro operando) sem alterar a complexidade do algoritmo. Isso também significa que a verificação amostral **não teria como distinguir uma multiplicação correta de uma cópia direta do primeiro operando** — uma implementação que apenas copiasse `A` para o resultado passaria na validação amostral e no harness.

**Terceira camada, adicionada para fechar essa lacuna**: `tests/` reúne um teste de corretude por linguagem, cada um chamando a função de multiplicação de produção (não uma reimplementação) com um caso pequeno e conhecido **não identidade** (`A=[[1,2],[3,4]]`, `B=[[5,6],[7,8]]`, resultado esperado `[[19,22],[43,50]]`), fora de qualquer janela de benchmark. Não são substitutos do harness de contrato nem do benchmark — são testes de corretude isolados. Mecanismo por linguagem, do menos ao mais invasivo:

- **Python**: nenhuma mudança; o módulo já usa `if __name__ == "__main__":`, então importá-lo não dispara a CLI.
- **Rust**: um módulo `#[cfg(test)] mod tests { ... }` aditivo no fim de `src/matriz_rust.rs`, compilado apenas por `rustc --test`, sem nenhum efeito no build de produção.
- **C, C++**: arquivos de teste separados em `tests/` que incluem o `.c`/`.cpp` de produção com `#define main <nome>_main` antes do `#include`, reusando a função `multiply()` estática sem duplicá-la nem alterar o arquivo de produção.
- **Julia**: uma guarda `if abspath(PROGRAM_FILE) == @__FILE__` ao redor da chamada de `main()` no fim de `src/matriz_Julia.jl`, permitindo que `tests/test_matriz_julia.jl` inclua o arquivo sem disparar a CLI — idioma padrão da linguagem para esse cenário.
- **Java**: `multiply` deixou de ser `private` (passou a ter visibilidade de pacote), permitindo que `tests/TestMatrizJava.java`, no mesmo pacote default, o chame diretamente. `verifySample` continua privado porque o teste de corretude não precisa acessá-lo.
- **Elixir** (mudança mais real entre as sete): `build_matrix`/`multiply` deixaram de ser `defp` e passaram a `def`; a chamada de `MatrizElixir.main/1` no fim do arquivo passou a ser condicionada a uma variável de ambiente (`MATRIZ_ELIXIR_SKIP_MAIN`), permitindo que `tests/test_matriz_elixir.exs` carregue o módulo via `Code.require_file/1` sem invocar `main/1` (que chamaria `System.halt/1`). Nenhuma das duas mudanças altera o comportamento de uma invocação real (`elixir matriz_multiplication.exs ...`).

## Compilação e flags

| Linguagem | Comando | Observação |
| --- | --- | --- |
| C | `gcc -std=c11 -Wall -Wextra` (e variante `-O3`) | Warnings não são erro |
| C++ | `g++ -std=c++17 -Wall -Wextra` (e variante `-O3`) | Warnings não são erro |
| Java | `javac` sem flags extras | O runner usa a JVM disponível no `PATH`; a validação local usou HotSpot. Nenhum coletor de lixo é fixado por flag — a JVM roda com o GC padrão do ambiente |
| Python | Interpretado, sem etapa de compilação | O runner usa `python3` (Linux/WSL) ou `python` (Windows); a validação local usou CPython sem JIT habilitado |
| Rust | `rustc --edition=2021 -C opt-level=3 -D warnings` | Warnings **são** erro de compilação; único caso onde o build falha por warning |
| Julia | Interpretado/JIT, sem etapa de build separada | Ver "JIT" abaixo |
| Elixir | Interpretado/JIT via BEAM, sem etapa de build separada (`.exs`) | Ver "JIT" abaixo |

As versões de `gcc`, `g++`, `java`, `javac`, Python e, quando usadas, `rustc`, `julia` e `elixir` são registradas em `run_manifest.json.tools` a cada execução real do runner. Rust e Julia não têm versão mínima fixada. Elixir 1.20.3/Erlang OTP 28.4 é o ambiente recomendado na documentação, mas os runners ainda não impõem essas versões e não registram OTP separadamente; portanto, ele também não está tecnicamente pinado. A versão efetivamente encontrada no `PATH` prevalece.

`run_manifest.json.tools.java` registra a saída completa (multi-linha) de `java -version`, não apenas a primeira linha — permitindo identificar vendor/VM (ex.: "OpenJDK 64-Bit Server VM") quando a JVM os reporta ali. `run_manifest.json.tools.java_gc` registra o coletor de lixo efetivamente ativo, obtido por uma sondagem best-effort com `java -XX:+PrintFlagsFinal -version`, checando quais das flags conhecidas de seleção de coletor HotSpot (`UseG1GC`, `UseParallelGC`, `UseSerialGC`, `UseShenandoahGC`, `UseZGC`, `UseEpsilonGC`) estão ativas. Essa sondagem é best-effort e não portátil: JVMs que não sejam HotSpot (OpenJ9, GraalVM native, por exemplo) podem não suportar a flag de diagnóstico ou expor esses nomes; qualquer falha grava `"N/D"` sem abortar a execução. O runner não fixa nem altera parâmetro algum de GC — apenas registra o que já está ativo por padrão no ambiente.

C e C++ são medidos com e sem `-O3`; Rust é integrado apenas com `-C opt-level=3`; Java, Python, Julia e Elixir não têm uma variante pareada equivalente no runner. Assim, a influência de `-O3` pode ser analisada dentro de C/C++, mas essa dimensão de otimização não é simétrica entre as sete linguagens.

## Relógios

Todas as janelas usam APIs destinadas à medição de duração, mas cada runtime fornece sua própria implementação:

| Linguagem | Relógio usado |
| --- | --- |
| C | `clock_gettime(CLOCK_MONOTONIC)` em POSIX; `QueryPerformanceCounter` em Windows |
| C++ | `std::chrono::steady_clock` |
| Java | `System.nanoTime()` |
| Python | `time.perf_counter()` |
| Rust | `std::time::Instant` |
| Julia | `time_ns()` |
| Elixir | `System.monotonic_time()` com conversão de unidade |

## JIT

Nos runtimes usados durante a validação local, três modelos de compilação just-in-time distintos estão em jogo e não são semanticamente equivalentes entre si:

- **Java (HotSpot)**: compilação em camadas (tiered compilation), por método, após um número de invocações/iterações de laço ultrapassar um limiar interno da JVM. Uma única rodada de warm-up pode não ser suficiente para atingir código totalmente otimizado (C2) antes das `M` repetições medidas começarem, especialmente para `N` pequeno. Não verificado empiricamente neste projeto.
- **Julia**: especialização por **assinatura de tipo**, não por valor. `multiply!`/`run_once` são compilados uma única vez, na primeira chamada (dentro do warm-up do primeiro `N` processado), e reaproveitados para todos os `N` subsequentes sem nova compilação, porque o tipo dos argumentos (`Matrix{Int32}` para as matrizes, `Int` para `n`) não muda entre chamadas. O warm-up por `N`, embora redundante do ponto de vista de compilação após o primeiro `N`, ainda é mantido por consistência com as demais linguagens e para aquecer efeitos de alocador/cache.
- **Elixir/BEAM (BeamAsm, Erlang/OTP ≥ 24)**: traduz o código BEAM no **carregamento** do módulo, antes dos laços da aplicação — não há o mesmo perfil de compilação incremental por chamada do HotSpot, nem especialização por tipo como no Julia.

Os runners não exigem HotSpot, CPython ou BeamAsm nominalmente; eles executam os comandos disponíveis no `PATH`. Se outro runtime compatível for usado, suas características precisam ser registradas e consideradas na análise.

## Gerenciamento automático e GC

Java, Julia e Elixir usam coleta de lixo automática; CPython combina contagem de referências com um coletor de ciclos. Em nenhuma das quatro implementações o código força uma coleta (`System.gc()`, `gc.collect()`, `GC.gc()`, `:erlang.garbage_collect/0`) dentro de TAM, TCS ou TDM — forçar coleta dentro da métrica inflaria e desestabilizaria artificialmente um número que deveria refletir o comportamento natural do benchmark.

Isso não elimina a interferência do gerenciamento automático: liberações por contagem de referências e coletas não forçadas podem ocorrer durante uma janela cronometrada como consequência da pressão de alocação natural do benchmark. Dois casos foram observados durante a validação local das implementações. Os comandos completos, o estado da máquina e os dados brutos dessas sondagens não foram preservados; portanto, os números abaixo são relatos diagnósticos aproximados, não resultados experimentais formais do TCC:

- **Julia**: isolando a fase de alocação (`run_once`'s TAM) para `N=1400` e medindo com `@time`, o tempo relatado em GC chegou a ~70% do tempo total da fase em chamadas repetidas — o coletor reagindo à alocação e ao descarte de matrizes grandes a cada chamada. A fase de cálculo (`multiply!`, que não aloca) não mostrou tempo de GC nas mesmas medições.
- **Elixir**: pelo mesmo motivo, mas agravado pela representação escolhida (ver seção seguinte) — construir a tupla plana passa por uma lista intermediária que gera lixo imediatamente após a conversão. Comparando três execuções completas idênticas (mesmos `N`, `M`), o tempo médio de alocação (TAM) reportado no CSV variou por um fator de até ~3x entre execuções independentes.

**Consequência prática**: TAM de Java, Python, Julia e Elixir deve ser interpretado como a janela de alocação observada sob o gerenciamento automático daquele runtime, não como um custo isolado e universal de alocar N² inteiros. Mesmo C, C++ e Rust usam mecanismos/alocadores distintos, de modo que a decomposição exige cautela em todas as linguagens.

## Layout de memória e tipo numérico

| Linguagem | Representação | Contíguo? | Tipo do elemento |
| --- | --- | --- | --- |
| C | `int*` alocado com `malloc`, indexado `i*N+j` | Sim (row-major) | `int` (tipicamente 32 bits) |
| C++ | `std::vector<int>`, indexado `i*N+j` | Sim (row-major) | `int` (tipicamente 32 bits) |
| Java | `int[][]` (array de arrays) | Não | `int` (32 bits) |
| Python | `list[list[int]]` | Não | `int` (precisão arbitrária) |
| Rust | `Vec<i32>` plano, indexado `i*N+j` | Sim (row-major) | `i32` (32 bits) |
| Julia | `Matrix{Int32}` nativo (2D) | Sim, mas **column-major** | `Int32` (32 bits); índices/dimensões permanecem `Int` nativo (64 bits nas plataformas 64-bit validadas) |
| Elixir | Tupla plana única, indexada `i*N+j` | Não assumido; estrutura interna do runtime | Inteiro nativo do BEAM (precisão arbitrária) |

Divergências relevantes, mantidas ou ainda pendentes de decisão em vez de ocultadas para uniformizar a comparação:

- **Java (`int[][]`)**: array de arrays, não um buffer contíguo. Decisão original do projeto, documentada desde antes da integração das linguagens extras. Afeta localidade de cache de forma diferente de C/C++/Rust.
- **Julia (column-major)**: `Matrix{Int32}` é armazenado por colunas internamente, ao contrário do layout row-major de C/C++/Rust. A ordem lógica de laços `i, j, k` foi mantida igual à das demais linguagens para preservar a equivalência algorítmica exigida pelo contrato, mesmo essa não sendo a ordem mais favorável ao layout column-major do Julia (a ordem idiomática para column-major seria diferente, tipicamente com `j` ou `k` mais externo). Isso significa que o acesso a `mat1[i,k]` variando `k` é **não contíguo** em Julia, ao contrário do acesso equivalente em C.
- **Julia (`Int32` para elementos)**: decisão formalizada — os elementos de `mat1`/`mat2`/`res` usam `Int32` (32 bits), aproximando a largura de dado de C/C++/Java/Rust. Índices, dimensão `n` e contadores de laço **permanecem `Int`** nativo (64 bits nas plataformas 64-bit validadas): a mudança é estritamente sobre o tipo do elemento armazenado, não sobre a linguagem indexar de forma diferente. No laço quente, o acumulador é declarado explicitamente `Int32(0)` (não o literal `0`, que Julia inferiria como `Int` nas plataformas usadas) para evitar que a soma de produtos `Int32` seja promovida para a largura nativa "pela porta dos fundos". Validado sem risco de overflow (valor máximo de qualquer célula é `i+j ≤ ~199998`, muito abaixo do limite de `Int32`) e também com `julia --check-bounds=yes`, que não altera o resultado (apenas reintroduz a checagem de limites que `@inbounds` remove por padrão).
- **Elixir (tupla plana)**: entre listas encadeadas, tuplas aninhadas, `:array` do Erlang e tupla plana, esta última apresentou o melhor compromisso avaliado para leitura O(1) e construção O(N²) via lista + `List.to_tuple/1`, sem atualizações repetidas com `put_elem/3` — isso é uma decisão de representação entre as alternativas avaliadas neste projeto, não uma prova de unicidade assintótica. Não se assume equivalência do layout físico com um array C. Como a tupla é imutável, o resultado (`res`) só passa a existir quando a comprehension de `multiply` termina; sua construção fica inteiramente dentro de **TCS**, não de TAM. Essa fronteira é inerente à representação adotada e é a única exceção remanescente à regra formal de TAM/TCS (ver "Variáveis dependentes" acima) — C, C++, Java, Python, Rust e Julia já alocam e inicializam o resultado em TAM.
- **Rust (bounds-check)**: o laço quente de `multiply` usa `unsafe`/`get_unchecked` para evitar a checagem de limites inserida por padrão na indexação segura. Em uma sondagem exploratória local não preservada como artefato, manter a checagem aumentou TCS em aproximadamente 40% para `N=1400`. A segurança dessa escolha depende de um invariante verificado por revisão de código (índices sempre dentro de `0..N`, documentado com um comentário `SAFETY` no código-fonte), não pelo compilador — essa é uma aproximação deliberada do custo de acesso de C/C++, e **não representa o comportamento de uma implementação Rust idiomática genérica**, que manteria a checagem de limites ativa. Julia tem uma situação análoga com `@inbounds`; uma sondagem local relatou diferença de ~65-70% de TCS para o mesmo `N` com `--check-bounds=yes`. Esses percentuais são diagnósticos, não resultados formais reproduzíveis.

## Hardware e sistema operacional

Não fixados pelo projeto — cada execução real registra o hardware/SO em `system_info.md`, `system_info.json` (via `scripts/gen_sysinfo_md.sh` no Linux/WSL, ou diretamente no PowerShell no Windows) e `run_manifest.json.system` (plataforma, arquitetura, versão do Python). Resultados de máquinas diferentes não são diretamente comparáveis em valor absoluto — apenas em tendência/escalonamento relativo — a menos que hardware e SO sejam controlados explicitamente entre execuções que se pretende comparar.

O runner executa as variantes em ordem fixa — C, C -O3, C++, C++ -O3, Java, Python e depois as extras solicitadas — sem randomização ou contrabalanceamento. Também não fixa afinidade/prioridade de CPU, carga de fundo, governor de frequência, turbo, temperatura ou estado térmico. Esses fatores devem ser controlados no protocolo da coleta final ou declarados como fontes de variação.

## Limitações

- Sem preservação de tempos brutos por repetição: impossível calcular desvio padrão, percentis ou intervalo de confiança a partir de uma única execução (`out/<run_id>/`).
- Sem verificação empírica de que o warm-up único estabiliza o JIT do Java.
- Sem versões efetivamente fixadas de Rust e Julia; Elixir/OTP têm versões recomendadas, mas não impostas pelos runners.
- `TDM=0.0` de quatro das nove séries não é diretamente comparável ao TDM medido nas outras cinco.
- Fronteira de TAM/TCS divergente apenas em Elixir: por imutabilidade, `res` só existe ao fim da construção em TCS. Nas demais seis implementações, TAM já cobre alocação e inicialização/zeragem do resultado.
- Compilações não pareadas: C/C++ têm variantes com e sem `-O3`, enquanto Rust só entra otimizado e os runtimes gerenciados não têm uma variante equivalente no runner.
- Ordem de execução fixa e ausência de controles ambientais de CPU/carga/temperatura.
- Coletor de lixo da JVM registrado por sondagem best-effort (`java_gc` no manifesto), não garantido em toda JVM não HotSpot; cai em `"N/D"` quando não detectável, sem abortar a execução.

## Ameaças à validade interna

- **Compilação JIT não estabilizada**: se o warm-up único não for suficiente para o JIT do Java atingir código totalmente otimizado, parte das `M` repetições medidas pode incluir execução em bytecode interpretado ou parcialmente otimizado, inflando o tempo medido de forma não uniforme entre valores de `N`.
- **GC não forçado, mas presente**: coletas automáticas durante uma janela cronometrada (mais relevante para TAM em Julia e Elixir, conforme medido) introduzem variância que a média de `M` repetições suaviza, mas não elimina, e cujo desvio padrão não é reportado.
- **Fronteira de fase diferente em Elixir**: construir o resultado em TCS (em vez de TAM, como nas outras seis implementações) adiciona a essa fase um trabalho estrutural inevitável que as demais atribuem a TAM.
- **Ordem e ambiente não controlados**: deriva térmica, turbo, governor, processos concorrentes e a posição fixa de cada linguagem podem introduzir viés sistemático entre séries.
- **Bounds-check removido em Rust e Julia**: os resultados de TCS dessas duas linguagens refletem uma variante com checagem de limites desativada por invariante verificado manualmente, não o comportamento padrão/mais seguro de cada linguagem — comparações devem declarar isso explicitamente.

## Ameaças à validade externa

- **Hardware e SO não controlados entre execuções**: resultados de diferentes colaboradores (ver `CONTRIBUTING.md`) refletem máquinas diferentes; comparações de valor absoluto entre `out/<run_id>/` de pessoas diferentes não são válidas sem normalização.
- **Versões de toolchain não impostas**: o comportamento de otimização pode mudar entre versões; Rust e Julia não têm versão recomendada fixa, e a combinação Elixir/OTP recomendada não é verificada automaticamente nem registrada por completo.
- **Viabilidade do Elixir em N grande**: validações exploratórias locais indicaram execução muito mais lenta no Elixir. Sem uma coleta formal preservada, isso é apenas um alerta operacional; ainda assim, reduzir `B` apenas para essa linguagem sem declarar a mudança criaria viés de seleção.
- **Uma única arquitetura testada por execução**: nada nas implementações é específico de uma arquitetura de CPU, mas nenhuma validação cruzada entre arquiteturas (x86_64 vs ARM, por exemplo) foi conduzida como parte deste projeto.

## Reprodutibilidade

Cada execução real do runner (`run_all.sh`/`run_all.ps1`) produz, em `out/<run_id>/`:

- os CSVs de cada linguagem executada (`N,TCS,TAM,TDM`);
- `system_info.md`/`system_info.json` (hardware e SO);
- `run_manifest.json` (parâmetros, versões de toolchain, e exatamente quais linguagens rodaram — ver `EXECUTION.md`);
- `grafico_*.png` (visualização);

e é verificada por `scripts/validate_run.py`. O validador exige os seis CSVs centrais, valida toda saída declarada e rejeita os três nomes opcionais conhecidos quando presentes sem declaração. Ele não rejeita hoje um CSV arbitrário de nome desconhecido.

Os runners escrevem em um diretório de trabalho temporário (`out/.running-<run_id>/`) e só o promovem (renomeiam) para `out/<run_id>/` depois que todos os benchmarks solicitados, a geração de `system_info`/gráficos e `validate_run.py` tiverem sucesso. Uma execução abortada nunca aparece como um `out/<run_id>/` completo. Se a falha ocorrer depois da criação do staging, ele permanece com o prefixo `.running-` para diagnóstico e uma nova tentativa com o mesmo `--run-name`/`-RunName` falha explicitamente; erros detectados antes desse ponto (parâmetros, dependências centrais, matplotlib ou colisão) não criam staging. Ver `EXECUTION.md` para o comportamento observável desse mecanismo.

O conjunto fornece rastreabilidade útil, mas não é autocontido nem suficiente para reprodução exata: o manifesto guarda parâmetros, flags, versões resumidas e `commit_hash`, porém não guarda o comando literal, caminho dos executáveis, versão separada de OTP, estado `dirty` nem o diff local. Um `commit_hash` sozinho não identifica alterações não commitadas que possam ter sido executadas.

O procedimento de reprodução mínimo está em `EXECUTION.md`. Para aproximar uma execução específica, use os mesmos `B`, `Npts`, `M`, `escala`, flags, commit, toolchains, hardware e condições ambientais. Reprodutibilidade bit-a-bit não é garantida; fortalecer a captura de proveniência antes da coleta final permanece no `TODO.md`.
