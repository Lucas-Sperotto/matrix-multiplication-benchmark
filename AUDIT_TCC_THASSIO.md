# Auditoria Técnica — branch `tcc-lic-thassio`

Data da auditoria: 2026-08-25
Data da rodada de correção: 2026-08-25
Branch auditada: `tcc-lic-thassio` (HEAD `d8bc5c6`), comparada com `main` (`d51dcb9`)
Escopo: preparação do contrato, testes e fluxo de colaboração para as implementações futuras de Rust, Julia e Elixir.

## Atualização — correção de P0/P1 de infraestrutura compartilhada (2026-08-25)

Todos os achados **P0** e **P1** foram corrigidos ou mitigados nesta rodada, com testes de regressão novos para cada um (exceto P1-3, que é uma limitação estrutural do contrato e só admite mitigação documental). Nenhum item **P2** ou **P3** foi alterado — permanecem como estavam, propositalmente fora do escopo desta rodada. Rust, Julia e Elixir continuam não implementados. Detalhes de status em cada achado abaixo; resumo de arquivos alterados na seção final.

---

## Resumo Executivo

A branch está bem estruturada como preparação de contrato/testes: `scripts/test_extra_language.py` é um harness de caixa-preta sólido, `EXTRA_LANGUAGES.md` é detalhado, e o fluxo de fork/PR está bem documentado. Nenhum bug foi encontrado nos arquivos novos que impeça o trabalho de preparação em si.

Na auditoria original, foi encontrado um **problema de correção bloqueador (P0)** nas implementações de referência que a documentação manda Thassio replicar: **Python usava arredondamento bancário (`round()`, half-to-even) enquanto C, C++ e Java usavam arredondamento "metade para cima"**, exatamente a regra que `EXTRA_LANGUAGES.md` documenta como "a mesma das implementações de referência". Isso foi confirmado empiricamente compilando e executando os quatro binários reais com os mesmos argumentos: eles geravam **séries de N diferentes** para o mesmo `B`/`Npts`/`escala`. Como o propósito central do projeto é comparar tempo de execução para o mesmo N entre linguagens, esse bug — combinado com a ausência de uma verificação cruzada entre CSVs no validador — permitia que resultados **não comparáveis** fossem aceitos como válidos, silenciosamente. A rodada de correção eliminou a divergência e adicionou a verificação cruzada antes do início das implementações de Rust, Julia e Elixir.

Além disso, `scripts/validate_run.py` e `scripts/test_extra_language.py` (ambos modificados/criados nesta branch) tinham lacunas de cobertura que permitiriam que uma implementação incorreta ou uma execução corrompida passassem despercebidas. As lacunas P1 corrigíveis receberam regressões; o ponto cego estrutural do harness foi mitigado por documentação e revisão manual obrigatória.

Na auditoria original, nenhuma alteração de código foi feita. A rodada de correção posterior resolveu ou mitigou os achados P0/P1 conforme os status registrados abaixo.

**Nota operacional (fora do escopo técnico, mas relevante):** durante esta sessão, 17 arquivos rastreados pelo Git (16 diagramas PNG e `diagramas_word_index.txt`) apareceram como removidos. A exclusão foi inicialmente interpretada como acidental e os arquivos foram restaurados; depois, o mantenedor confirmou que a remoção era intencional. Eles foram então excluídos novamente em um commit separado e permanecem recuperáveis pelo histórico Git. Isso está registrado para transparência, não é um achado técnico da branch.

---

## Quantidade de achados por prioridade

| Prioridade | Quantidade | Resolvidos | Mitigados | Pendentes |
|---|---|---|---|---|
| P0 — bloqueador | 1 | 1 | 0 | 0 |
| P1 — alta prioridade | 4 | 3 | 1 | 0 |
| P2 — melhoria recomendada | 9 | 0 | 0 | 9 (fora do escopo desta rodada) |
| P3 — melhoria futura | 4 | 0 | 0 | 4 (fora do escopo desta rodada) |
| **Total** | **18** | **4** | **1** | **13** |

---

## P0 — Bloqueadores

### P0-1 — Arredondamento divergente entre Python e C/C++/Java quebra a comparabilidade entre linguagens

**Status: RESOLVIDO (2026-08-25).** `src/matriz_python.py` corrigido para usar `math.floor(x + 0.5)` (metade-para-cima), igual a C/C++/Java. Teste de regressão novo em `scripts/test_point_generation.py`. Reproduzi o caso exato do achado (`B=101 Npts=3 escala=1`) compilando e executando o binário C real lado a lado com o Python corrigido: ambos agora produzem `N=[100,101,101]`. Também validei a execução real completa (C, C++, Java, Python) com `scripts/validate_run.py` corrigido (P1-2): as seis séries de N batem.

**Prioridade:** P0

**Arquivo(s):** `src/matriz_python.py:39-45`, `src/matriz_c.c:73-100`, `src/matriz_cpp.cpp:69-93`, `src/matriz_java.java:44-61`, `EXTRA_LANGUAGES.md:200-209`

**Problema:** A função `make_points`/`makePoints` gera os N valores de N a partir das mesmas fórmulas em todas as linguagens, mas o **arredondamento do ponto flutuante para inteiro usa regras diferentes**:

- C (`matriz_c.c:87,95`): `(int)(a + step * i + 0.5)` → trunca depois de somar 0.5 → equivalente a "metade para cima" para valores positivos.
- C++ (`matriz_cpp.cpp:80,88`): `std::round(...)` → "metade para longe de zero", que para valores positivos coincide com "metade para cima".
- Java (`matriz_java.java:51,56`): `Math.round(...)` → documentado como "metade para cima" — coincide com C/C++.
- Python (`matriz_python.py:42,45`): `round(...)` → o `round()` nativo do Python 3 usa **arredondamento bancário (metade para o par mais próximo)**, não "metade para cima".

`EXTRA_LANGUAGES.md:209` instrui explicitamente: *"Como todos os valores são positivos, use arredondamento de metade para cima (`floor(x + 0.5)`)... Arredonde cada ponto ao inteiro mais próximo, **como nas implementações de referência**"* — mas as quatro implementações de referência não concordam entre si, e a documentada é a que a implementação Python de referência não segue.

**Evidência:** Compilei e executei os quatro binários reais (não uma simulação) com os argumentos idênticos `B=101 Npts=3 M=1 escala=1`:

```
C:      N,TCS,TAM,TDM → 100, 101, 101
C++:    N,TCS,TAM,TDM → 100, 101, 101
Java:   N,TCS,TAM,TDM → 100, 101, 101
Python: N,TCS,TAM,TDM → 100, 100, 101   <-- diferente!
```

A causa raiz: com `step = (101-100)/(3-1) = 0.5`, o segundo ponto é `100 + 0.5*1 = 100.5` exatamente representável em ponto flutuante. `round(100.5)` em Python retorna `100` (100 é par), enquanto `(int)(100.5+0.5)`, `std::round(100.5)` e `Math.round(100.5)` retornam `101`.

**Impacto:** Este não é um caso extremo raro e artificial — qualquer combinação de `B`/`Npts` em que `(B-100)` seja ímpar e `(Npts-1)` seja par (ou combinações equivalentes na escala logarítmica) produz um ponto `.5` exato. Como o propósito documentado do projeto é "comparar tempos de execução entre linguagens usando o mesmo contrato de entrada" (`README.md:5`), duas linguagens medindo N=100 e N=101 respectivamente, mas rotuladas como "o mesmo ponto da série", invalidam silenciosamente qualquer gráfico ou conclusão comparativa construída sobre esses dados — o que é particularmente grave em um TCC, onde a validade estatística da comparação é o produto principal do trabalho. Além disso, bloqueia Thassio: a instrução "implemente como nas referências" não tem resposta única, porque as referências divergem entre si.

**Correção proposta:** Escolher uma única regra canônica (recomenda-se manter "metade para cima", já documentada e majoritária em 3 das 4 referências) e corrigir `src/matriz_python.py` para usar `math.floor(x + 0.5)` em vez do `round()` nativo em `make_points` (linhas 42 e 45). Isso mantém consistência com C/C++/Java e com o texto já escrito em `EXTRA_LANGUAGES.md:209`. Alternativamente, se a decisão for manter `round()` do Python por ser "mais pythônico", a documentação do contrato deve ser reescrita para refletir isso e as outras três referências deveriam ser ajustadas para usar arredondamento bancário — mas isso é mais invasivo e não recomendado.

**Teste necessário:** Adicionar um caso de regressão que gere pontos para `B=101, Npts=3, escala=1` (e o equivalente logarítmico) e verifique que todas as quatro referências produzem exatamente a mesma lista de N. Esse teste hoje não existe em nenhum lugar do repositório — nem `scripts/validate_run.py` nem `scripts/test_extra_language.py` comparam séries de N entre CSVs (ver P1-2).

---

## P1 — Alta prioridade

### P1-1 — `validate_run.py` não confere se o número de linhas do CSV bate com `Npts` do manifesto

**Status: RESOLVIDO (2026-08-25).** `validate_csv()` agora recebe `expected_rows` (extraído de `manifest["parameters"]["Npts"]` via novo helper `expected_point_count()`) e falha se a contagem de linhas não bater. Teste de regressão novo em `scripts/test_validate_run.py` (caso "truncado"): confirma que um CSV com uma linha a menos que `Npts` é rejeitado com mensagem citando `Npts`/linhas de dados.

**Prioridade:** P1

**Arquivo(s):** `scripts/validate_run.py:32-76` (`validate_csv`), `scripts/validate_run.py:154-189` (`main`)

**Problema:** `validate_csv()` verifica cabeçalho, tipos numéricos, não-negatividade, finitude e ordenação não decrescente de `N`, mas nunca compara `len(data_rows)` com `manifest["parameters"]["Npts"]` — apesar de o manifesto (que já foi lido e validado nesta mesma função `main()`) conter esse valor.

**Evidência:** Em `scripts/validate_run.py:75-76`, a única checagem de quantidade é `if rows == 0: fail(...)`. Compare com o harness de linguagens extras (`scripts/test_extra_language.py:141-144`), que **explicitamente** valida `len(data_rows) != len(expected_points)` — ou seja, o harness novo criado nesta branch é mais rigoroso que o validador principal que ele deveria complementar.

**Impacto:** Se uma implementação (C, C++, Java, Python, ou futuramente Rust/Julia/Elixir) falhar no meio da execução — por exemplo `malloc` falhando em um N grande, como já é tratado em `src/matriz_c.c:164-171` retornando código de saída 1 — o arquivo CSV já contém as linhas de N processadas até então (escritas incrementalmente a cada iteração, `matriz_c.c:276`), só que incompletas. Isoladamente, esse CSV truncado passa por `validate_csv()` sem erro, pois é sintaticamente válido. Uma execução parcial "quebrada" pode ser aceita como uma execução completa e "válida" pelo pipeline de qualidade acadêmica do projeto.

**Correção proposta:** Em `manifest_csvs()` ou em `main()`, passar `manifest["parameters"]["Npts"]` para `validate_csv()` e comparar a contagem de linhas de dados com esse valor, retornando erro em caso de divergência — mesma lógica já implementada em `test_extra_language.py:141-144`.

**Teste necessário:** Gerar uma execução com uma implementação de referência, truncar manualmente uma linha do CSV resultante, e confirmar que `validate_run.py` agora rejeita a execução.

---

### P1-2 — `validate_run.py` não confere se todos os CSVs de uma execução compartilham a mesma série de N

**Status: RESOLVIDO (2026-08-25).** `validate_csv()` agora retorna a lista de valores de N; `main()` compara as séries de todos os CSVs validados na mesma execução e falha citando explicitamente qual arquivo diverge e os valores de cada lado. Teste de regressão novo em `scripts/test_validate_run.py` (caso "divergente"): dois CSVs com o mesmo número de linhas mas um valor de N diferente são rejeitados com mensagem citando "divergem".

**Prioridade:** P1

**Arquivo(s):** `scripts/validate_run.py:32-193` (arquivo inteiro), `src/plot_benchmarks.py:131-156` (`plot_series`)

**Problema:** Cada CSV é validado de forma totalmente independente. Nada compara a lista de valores de `N` entre `resultado_c.csv`, `resultado_java.csv`, `resultado_python.csv` etc. dentro do mesmo diretório de execução.

**Evidência:** Ver P0-1: com a divergência de arredondamento já comprovada entre Python e as demais linguagens, um `run_all.sh` real e sem nenhum erro de execução pode gerar `resultado_python.csv` com N=[100,100,101] e `resultado_c.csv` com N=[100,101,101] simultaneamente, e `validate_run.py` aceitará ambos como "válidos" sem aviso. `plot_benchmarks.py:139-150` então plota as duas séries no mesmo eixo X assumindo implicitamente que os pontos "alinham", sem checar isso.

**Impacto:** Esta é a lacuna estrutural que faz o bug P0-1 (e qualquer bug futuro similar introduzido por Rust, Julia ou Elixir) passar despercebido. Sem essa checagem, o projeto não tem nenhuma defesa automática contra a classe de erro mais grave possível para um benchmark comparativo: comparar coisas diferentes como se fossem iguais.

**Correção proposta:** Em `validate_run.py`, após validar cada CSV individualmente, extrair a coluna `N` de cada um e verificar que todas as listas são idênticas (ou, no mínimo, que os CSVs obrigatórios — os 6 principais — compartilham a mesma série; os opcionais de Rust/Julia/Elixir podem ser incluídos na mesma checagem assim que existirem).

**Teste necessário:** Criar um diretório de teste com dois CSVs de séries de N diferentes e confirmar que `validate_run.py` falha explicitamente com uma mensagem que aponte a divergência.

---

### P1-3 — O harness de contrato não tem como detectar multiplicação incorreta (ponto cego de falso negativo)

**Status: MITIGADO, NÃO RESOLVIDO (2026-08-25).** Esta é uma limitação estrutural do contrato (o CSV não carrega valores de matriz por design) e não admite correção de código sem alterar o contrato publicável — fora do escopo desta rodada ("mudanças pequenas", sem alterar Rust/Julia/Elixir nem o contrato). Mitigação aplicada: adicionado item obrigatório de checklist em `.github/pull_request_template.md` exigindo que o revisor humano leia e confirme manualmente a lógica de `verify_sample`/equivalente, e uma nota explícita em `EXTRA_LANGUAGES.md`, seção 6, documentando esse limite do harness. Não há teste automatizado possível para esta mitigação (é um controle de processo, não de código); permanece um risco residual que depende de disciplina de revisão humana.

**Prioridade:** P1

**Arquivo(s):** `scripts/test_extra_language.py` (arquivo inteiro), `EXTRA_LANGUAGES.md:290-294`

**Problema:** `test_extra_language.py` testa exclusivamente o contrato de CLI e o formato do CSV (cabeçalho, tipos, sinais, contagem de pontos). Ele nunca tem acesso aos valores calculados da matriz — o CSV de saída contém apenas tempos, não resultados. A verificação de corretude aritmética (as nove posições amostrais descritas em `EXTRA_LANGUAGES.md:232`) é responsabilidade exclusiva do código interno de cada implementação, que o harness não pode auditar de fora.

**Evidência:** Em nenhum ponto de `run_contract()` (`scripts/test_extra_language.py:214-247`) há inspeção de valores de matriz — apenas `validate_csv()` (linhas 123-177), que olha somente `N,TCS,TAM,TDM`. `EXTRA_LANGUAGES.md:293-294` reconhece isso implicitamente: *"O harness e a verificação manual de código são os critérios desta fase"* — ou seja, a corretude aritmética depende inteiramente de revisão manual de código, não de teste automatizado.

**Impacto:** Uma implementação de Rust, Julia ou Elixir que tenha uma função `verify_sample`/equivalente incorreta (por exemplo, que sempre "passa", ou que nunca é de fato chamada) passaria por todos os testes automatizados do harness sem qualquer alerta, desde que produza um CSV bem formatado com tempos plausíveis. Isso é particularmente arriscado porque o *tempo* de execução de uma multiplicação "furada" (por exemplo, que pula parte do laço `k`) tende a ser *menor* que o de uma implementação correta — ou seja, o bug mais perigoso para a validade acadêmica do benchmark (medir mais rápido por computar menos) é exatamente o que o harness não consegue pegar.

**Correção proposta:** Não é possível resolver isso inteiramente de fora sem mudar o contrato (o CSV não carrega os valores da matriz por design, para não misturar I/O no tempo medido). Mitigações realistas: (a) documentar explicitamente esse limite no checklist de revisão de PR (`.github/pull_request_template.md`) como um item que o revisor humano deve auditar manualmente lendo o código de `verify_sample`, não apenas rodando o harness; (b) opcionalmente, adicionar um modo de depuração acordado (variável de ambiente ou segundo modo de saída) que imprima os 9 valores verificados em stderr para inspeção humana durante a revisão do PR — sem alterar o CSV de produção.

**Teste necessário:** Nenhum teste automatizado resolve isso sozinho; a correção proposta (b) permitiria um teste automatizado parcial que capture stderr e confira os 9 valores impressos contra o valor esperado `i+j`.

---

### P1-4 — Cobertura de casos de erro no harness é assimétrica: só testa limites inferiores

**Status: RESOLVIDO (2026-08-25).** Adicionados 7 casos novos a `invalid_cases` em `scripts/test_extra_language.py`: limite superior de B/Npts/M, B negativo, e não-numérico para Npts/M/escala (antes só B era testado). Executado com sucesso contra as referências Python, C, C++ e Java reais (compiladas nesta sessão) — todos os 12 casos de erro (5 originais + 7 novos) são corretamente rejeitados pelas quatro implementações.

**Prioridade:** P1

**Arquivo(s):** `scripts/test_extra_language.py:220-226`

**Problema:** A tupla `invalid_cases` testa exatamente cinco cenários de erro:

```python
("B abaixo do minimo", ["99", "3", "1", "1"]),
("Npts abaixo do minimo", ["144", "1", "1", "1"]),
("M abaixo do minimo", ["144", "3", "0", "1"]),
("escala invalida", ["144", "3", "1", "2"]),
("argumento nao numerico", ["abc", "3", "1", "1"]),
```

Não há nenhum caso que teste: `B`, `Npts` ou `M` **acima** do limite máximo (`100000`, `10000`, `100000` respectivamente, definidos em `EXTRA_LANGUAGES.md:194-196`); nenhum argumento negativo (`-1`); e o único teste de "não numérico" cobre apenas o argumento `B` — `Npts`, `M` e `escala` não numéricos nunca são exercitados.

**Evidência:** Contagem direta da tupla em `scripts/test_extra_language.py:220-226`; comparar com os limites documentados em `EXTRA_LANGUAGES.md:194-196` (`B` entre 100 e 100000, `Npts` entre 2 e 10000, `M` entre 1 e 100000).

**Impacto:** Uma implementação em Rust, Julia ou Elixir que valide corretamente o limite inferior mas esqueça de checar o limite superior (cenário plausível, por exemplo, ao usar um tipo sem sinal que "wraps" em vez de validar, ou ao esquecer uma cláusula `&&` no `if`) passaria despercebida pelo harness atual. Como o contrato existe justamente para impedir que alguém rode `B=100000000` sem querer e trave a máquina, essa é uma lacuna que enfraquece a própria razão de o limite existir.

**Correção proposta:** Adicionar casos simétricos de limite superior (`B=100001`, `Npts=10001`, `M=100001`) e um caso de argumento negativo (`B=-1`), além de estender o caso "não numérico" para cobrir pelo menos `Npts` e `escala`.

**Teste necessário:** Os próprios casos propostos, adicionados a `invalid_cases` em `test_extra_language.py`; rodar novamente `python3 scripts/test_extra_language.py --language Python -- python3 src/matriz_python.py` (referência já validada nesta auditoria) para confirmar que a implementação Python de referência continua passando com os novos casos, servindo de regressão para os próprios testes.

---

## P2 — Melhorias recomendadas

### P2-1 — `--run-name`/`-RunName` não é sanitizado contra path traversal

**Prioridade:** P2

**Arquivo(s):** `run_all.sh:32-34,101,130`, `run_all.ps1:57,83`

**Problema:** `RUN_NAME` (Bash) e `$RunName` (PowerShell) são inseridos diretamente na construção do caminho de saída (`OUT_DIR="out/$RUN_NAME"` / `Join-Path "out" $RunName`) sem qualquer validação de caracteres. Um valor como `../../etc/cron.d/evil` ou um caminho absoluto escaparia do diretório `out/`.

**Evidência:** `run_all.sh:130`: `OUT_DIR="out/$RUN_NAME"` — comparar com `validate_int` (linhas 73-83), que é chamado para `B`, `Npts`, `M`, `escala`, mas não existe validação equivalente para `RUN_NAME`. O mesmo padrão se repete em `run_all.ps1:83`.

**Impacto:** Baixo em uso normal (ferramenta local operada pelo próprio usuário), mas relevante porque `CONTRIBUTING.md:16-25` incentiva nomes de execução copiados/colados entre colaboradores (`out/<autor-ou-id>-<maquina>-<os>-<B>-<data>/`) — um nome mal formatado ou copiado de forma descuidada (por exemplo, contendo `../`) pode escrever fora de `out/` sem aviso.

**Correção proposta:** Validar `RUN_NAME` com uma expressão regular restritiva (ex.: `^[A-Za-z0-9_.-]+$`) antes de compor `OUT_DIR`, rejeitando barras e `..`, em ambos os scripts.

**Teste necessário:** `./run_all.sh --batch --run-name '../evil' --B 100 --Npts 2 --M 1 --escala 1` deve falhar com mensagem clara em vez de criar `evil/` fora de `out/`.

---

### P2-2 — Faixas de `B`/`Npts`/`M` permitem combinações que esgotam memória/tempo sem aviso

**Prioridade:** P2

**Arquivo(s):** `src/matriz_c.c:224-227`, `EXTRA_LANGUAGES.md:194-196`

**Problema:** O contrato permite `B` até `100000`. Uma única matriz `100000×100000` de `int` já exige ~40 GB; três matrizes (A, B, C) simultâneas ultrapassam a RAM de qualquer máquina de estudante. Multiplicação ingênua O(N³) nesse tamanho também é computacionalmente inviável (dias de execução). Não há nenhuma checagem de "bom senso" combinando `B`, `Npts` e `M`, nem aviso na documentação sobre valores realistas.

**Evidência:** Limites aceitos em `parse_int(argv[1], "B", 100, 100000, &b)` (`matriz_c.c:224`); nenhuma verificação de memória disponível em nenhum dos quatro binários de referência nem nos scripts.

**Impacto:** Um aluno testando valores "redondos" (ex.: `B=50000`) pode travar a própria máquina sem entender por quê — o processo é `malloc`, não crash imediato, então o sistema pode começar a fazer swap e parecer "travado" em vez de falhar com uma mensagem clara.

**Correção proposta:** Documentar em `EXECUTION.md`/`EXTRA_LANGUAGES.md` valores realistas de `B` por padrão de hardware (ex.: "acima de 4000 sem BLAS pode levar minutos por repetição; acima de 20000 pode esgotar a RAM") e, opcionalmente, adicionar um aviso em `stderr` (não bloqueante) quando `B` ultrapassar um limiar heurístico.

**Teste necessário:** Não é bloqueante; validação seria manual/documental. Se implementado o aviso, testar que ele aparece em `stderr` sem impedir a execução.

---

### P2-3 — Um único warm-up pode não ser suficiente para atingir o estado estável do JIT

**Prioridade:** P2

**Arquivo(s):** `src/matriz_java.java:140-141`, `README.md:67`, `EXECUTION.md:133`

**Problema:** A metodologia documentada usa exatamente uma rodada de warm-up descartada antes das `M` repetições medidas. Para a JVM, o compilador JIT (C1/C2, tiered compilation) tipicamente só compila um método "quente" após milhares de invocações ou de contagens de backedge de laço — não necessariamente garantido por uma única chamada a `runOnce`, especialmente para valores pequenos de N onde o laço `k` interno não acumula contagem suficiente de backedges.

**Evidência:** `src/matriz_java.java:140-141`: `runOnce(n);` chamado uma vez, descartado, seguido do laço de `M` repetições medidas (linhas 147-152). Não há registro de compilação JIT (`-XX:+PrintCompilation`) nem verificação de que o método `multiply` foi de fato compilado antes da medição.

**Impacto:** Para N pequenos (próximos de 100), é possível que parte das `M` repetições medidas ainda esteja rodando em bytecode interpretado ou C1, inflando o tempo do Java de forma inconsistente entre valores de N — o que é precisamente o tipo de artefato de medição que uma seção de "Metodologia" de TCC precisa antecipar e, idealmente, mostrar que foi investigado.

**Correção proposta:** Não é necessariamente um bug a corrigir na branch atual (é uma limitação conhecida de benchmarking em JVM sem JMH), mas vale registrar explicitamente essa limitação na seção de metodologia do TCC, e considerar aumentar o warm-up para N pequenos ou documentar que a alternativa rigorosa seria adotar JMH.

**Teste necessário:** Rodar `java -XX:+PrintCompilation` durante uma execução real e confirmar (ou não) que `multiply` é compilado antes do fim do warm-up, documentando o resultado como nota metodológica.

---

### P2-4 — Apenas a média de M repetições é registrada; não há desvio padrão nem dados brutos por repetição

**Prioridade:** P2

**Arquivo(s):** `src/matriz_c.c:249-282` (padrão replicado em `matriz_cpp.cpp`, `matriz_java.java`, `matriz_python.py`)

**Problema:** Cada implementação acumula `time_calc += ...` ao longo das `M` repetições e grava apenas a média no CSV final; os tempos individuais de cada repetição são descartados após o loop.

**Evidência:** `matriz_c.c:266-280`: a soma é acumulada em `time_calc`, `time_alloc`, `time_free`, e apenas a média (`time_calc / m_count`) é escrita — nenhum valor individual sobrevive.

**Impacto:** Sem desvio padrão, intervalo de confiança, mínimo/máximo, é impossível diferenciar uma diferença de médias real de ruído de medição — algo que uma banca de TCC pode razoavelmente questionar ao ver apenas curvas de médias sem barras de erro. Este item já está listado como trabalho futuro em `TODO.md:238` ("Análise estatística: desvio padrão, boxplot"), mas vale reiterar aqui porque a adição de três novas linguagens (Rust/Julia/Elixir) é o momento mais barato para já nascerem gravando os dados brutos, evitando reescrever o contrato de novo mais tarde.

**Correção proposta:** Não bloqueia o trabalho de Thassio; é uma sugestão de evolução de contrato eventual (fora do escopo dos três PRs de linguagem, que devem seguir o contrato atual). Registrar como candidato ao PR de integração futuro (`feat/extra-languages-integration`, já mencionado em `EXTRA_LANGUAGES.md:329`).

**Teste necessário:** N/A nesta fase — apenas reiteração de item já rastreado no TODO.

---

### P2-5 — Rigor de versionamento de toolchain é inconsistente entre Rust/Julia (não fixados) e Elixir (fixado)

**Prioridade:** P2

**Arquivo(s):** `EXTRA_LANGUAGES.md:29-38` (Rust), `EXTRA_LANGUAGES.md:61-72` (Julia), `EXTRA_LANGUAGES.md:40-59` (Elixir)

**Problema:** As instruções de instalação fixam uma versão exata para Elixir/Erlang (`elixir@1.20.3 otp@28.4`), mas para Rust usam apenas `rustup default stable` (a versão "stable" do dia da instalação, que muda ao longo do tempo) e para Julia apenas `curl -fsSL https://install.julialang.org | sh` (última versão via `juliaup`, sem pin).

**Evidência:** Comparar o texto literal de `EXTRA_LANGUAGES.md:34` (`rustup default stable`) e `EXTRA_LANGUAGES.md:64` (sem versão) contra `EXTRA_LANGUAGES.md:45` (`sh install.sh elixir@1.20.3 otp@28.4`).

**Impacto:** Para um TCC que pretende comparar desempenho entre linguagens de forma reprodutível, a versão exata do compilador/runtime é um parâmetro metodológico tão relevante quanto a versão do GCC (que o manifesto já registra via `run_manifest.json`). Sem versão fixada, dois PRs de Rust submetidos em datas diferentes podem usar compiladores com otimizações de codegen diferentes, dificultando comparação entre execuções.

**Correção proposta:** `EXTRA_LANGUAGES.md:296-309` já pede que o PR inclua "as versões da ferramenta" — isso mitiga parcialmente o problema via autodeclaração, mas recomenda-se adicionalmente sugerir (não obrigar) uma versão mínima/testada de Rust e Julia no próprio documento, análoga ao pin de Elixir.

**Teste necessário:** Não bloqueante; documental.

---

### P2-6 — `scripts/check_extra_toolchains.sh` exige Bash e não tem equivalente nativo documentado para Windows

**Prioridade:** P2

**Arquivo(s):** `scripts/check_extra_toolchains.sh:1`, `EXTRA_LANGUAGES.md:101-126`

**Problema:** O script de diagnóstico de toolchains é um script Bash (`#!/usr/bin/env bash`). A seção "Windows nativo" de `EXTRA_LANGUAGES.md` (linhas 101-126) descreve como instalar Rust/Elixir/Julia via PowerShell, mas nunca menciona que `check_extra_toolchains.sh` não pode ser executado nativamente nesse ambiente (exigiria WSL ou Git Bash), nem oferece um comando de diagnóstico equivalente em PowerShell.

**Evidência:** `scripts/check_extra_toolchains.sh:1` declara o interpretador; `EXTRA_LANGUAGES.md:120-126` só sugere `rustc --version`, `elixir --version`, `julia --version` individualmente para Windows nativo, sem mencionar o script de diagnóstico consolidado.

**Impacto:** Um estudante trabalhando em Windows nativo (não WSL) que siga a documentação ao pé da letra não descobre isso até tentar rodar o script e receber um erro de interpretador ausente — friccão evitável de onboarding.

**Correção proposta:** Adicionar uma nota explícita na seção "Windows nativo" indicando que `check_extra_toolchains.sh` requer WSL ou Git Bash, ou fornecer um script `.ps1` equivalente mínimo.

**Teste necessário:** N/A; documental.

---

### P2-7 — Não há verificação automatizada (CI) de que os PRs de linguagem realmente passam no harness

**Prioridade:** P2

**Arquivo(s):** `.github/` (ausência de workflows), `.github/pull_request_template.md:32`, `CONTRIBUTING.md:140-148`

**Problema:** A única barreira de qualidade para os três PRs de linguagem (`feat/rust-benchmark`, `feat/julia-benchmark`, `feat/elixir-benchmark`) é uma checklist autodeclarada no template de PR ("Executei `scripts/test_extra_language.py` para a linguagem deste PR."). Não existe nenhum workflow do GitHub Actions no repositório.

**Evidência:** `find .github -type f` retorna apenas `pull_request_template.md`; nenhum diretório `.github/workflows/` existe.

**Impacto:** Para um projeto acadêmico que aceitará contribuições externas (mesmo que de um único colaborador conhecido), depender de autodeclaração em vez de um gate automatizado aumenta o risco de uma implementação quebrada ou regressiva ser mesclada sem que o mantenedor rode manualmente o harness a cada PR. Isso também está listado como item opcional em `TODO.md:216` ("Adicionar GitHub Actions para smoke test automático em PRs"), ainda não implementado.

**Correção proposta:** Adicionar um workflow simples que, ao detectar mudanças em `experiments/*.rs`/`*.jl`/`*.exs`, tente compilar/instalar a toolchain correspondente e rode `scripts/test_extra_language.py` automaticamente. Pode ser incremental (começar só com Rust, que já tem toolchain de instalação simples via `actions-rs`/`dtolnay/rust-toolchain`).

**Teste necessário:** Após implementado, abrir um PR de teste com uma implementação propositalmente quebrada e confirmar que o CI falha.

---

### P2-8 — `Integer.parseInt` do Java é mais estrito que `strtol`/`std::stol` de C/C++ quanto a espaços em branco

**Prioridade:** P2

**Arquivo(s):** `src/matriz_java.java:32-42`, `src/matriz_c.c:56-71`, `src/matriz_cpp.cpp:46-67`

**Problema:** `strtol` (C) e `std::stol` (C++) ignoram espaços em branco à esquerda do número antes de começar a converter; `Integer.parseInt` (Java) rejeita qualquer espaço em branco, lançando `NumberFormatException` imediatamente.

**Evidência:** `matriz_c.c:62`: `value = strtol(text, &end, 10);` — comportamento padrão de `strtol` de pular espaços iniciais; `matriz_java.java:34`: `int value = Integer.parseInt(text);` — comportamento documentado da JDK de não tolerar espaços.

**Impacto:** Baixo na prática (argumentos de linha de comando raramente chegam com espaços embutidos), mas é uma divergência real de comportamento do "mesmo" contrato de validação entre as quatro referências, que nenhuma documentação menciona. Relevante citar porque Thassio pode replicar a validação de qualquer uma das quatro como "a referência" e a resposta correta não é única.

**Correção proposta:** Documentar explicitamente (uma frase em `EXTRA_LANGUAGES.md`, seção 3) que espaços em branco ao redor dos argumentos numéricos têm comportamento não especificado/não testado, para não ser motivo de disputa em revisão de PR.

**Teste necessário:** N/A; documental.

---

### P2-9 — `gen_sysinfo_md.sh` usa `date -Iseconds`, incompatível com o `date` nativo do macOS

**Prioridade:** P2 (pré-existente, não introduzido por esta branch, mas ainda não corrigido e agora mais relevante por macOS ser um caminho de instalação documentado nesta branch)

**Arquivo(s):** `scripts/gen_sysinfo_md.sh:6`, `TODO.md:196`

**Problema:** `GENERATED_AT="$(date -Iseconds)"` usa a flag `-I`/`--iso-8601`, uma extensão GNU. O `date` BSD nativo do macOS não implementa essa flag e retorna erro (`illegal option`). Como o script começa com `set -euo pipefail` (linha 2), esse erro aborta o script inteiro imediatamente.

**Evidência:** `scripts/gen_sysinfo_md.sh:2,6`; item já registrado como pendente em `TODO.md:196` ("Verificar compatibilidade do `date -Iseconds` em macOS (GNU vs BSD date)"), ainda não marcado como resolvido.

**Impacto:** `run_all.sh:169` chama esse script incondicionalmente em toda execução completa do pipeline principal. Em um Mac sem coreutils GNU instalado via Homebrew, `./run_all.sh` falha por completo nesse ponto — o que é relevante porque `EXTRA_LANGUAGES.md` (seção macOS, linhas 85-99) trata macOS como plataforma suportada para a trilha de Rust/Julia/Elixir. Um estudante em macOS não consegue gerar uma execução completa e validável do fluxo principal para comparar com suas futuras implementações.

**Correção proposta:** Substituir por uma construção portátil, por exemplo `date -u +"%Y-%m-%dT%H:%M:%SZ"`, que funciona tanto em GNU quanto em BSD `date`.

**Teste necessário:** Executar `scripts/gen_sysinfo_md.sh` em macOS (ou emular com `bin/date` BSD) e confirmar que não falha mais.

---

## P3 — Melhorias futuras

### P3-1 — `EXTRA_LANGUAGES.md` não documenta o teste de sobrescrita do CSV que o harness já executa

**Prioridade:** P3

**Arquivo(s):** `EXTRA_LANGUAGES.md:290-294`, `scripts/test_extra_language.py:192-211`

**Problema:** `assert_overwrite_case` (linhas 192-211) roda a implementação duas vezes com os mesmos argumentos e confirma que o CSV é sobrescrito (não anexado). Essa checagem existe e é executada, mas a seção 6 de `EXTRA_LANGUAGES.md` ("O que o teste automatizado cobre") não a menciona — só fala de "argumentos inválidos e casos pequenos nas escalas linear e logarítmica".

**Impacto:** Mínimo; é apenas uma lacuna de documentação de uma funcionalidade que já existe e funciona corretamente a favor do projeto.

**Correção proposta:** Acrescentar uma frase em `EXTRA_LANGUAGES.md:292` mencionando o teste de sobrescrita.

**Teste necessário:** N/A.

---

### P3-2 — Timeout de 120s do harness não é documentado

**Prioridade:** P3

**Arquivo(s):** `scripts/test_extra_language.py:23`, `EXTRA_LANGUAGES.md`

**Problema:** `TIMEOUT_SECONDS = 120` é aplicado a cada subprocesso lançado pelo harness, mas não é mencionado em nenhuma documentação.

**Impacto:** Em uma máquina lenta, o custo de start-up do runtime Julia ou da BEAM (Elixir) combinado com JIT/compilação de primeira chamada poderia, em cenários extremos, se aproximar do limite, gerando uma falha "excedeu o limite de 120 segundos" que confundiria um estudante sem contexto sobre de onde vem esse número.

**Correção proposta:** Mencionar o valor do timeout em `EXTRA_LANGUAGES.md`, seção 6.

**Teste necessário:** N/A.

---

### P3-3 — Diferença teórica de arredondamento em ponto flutuante entre a técnica de C (`x+0.5`) e `std::round` do C++

**Prioridade:** P3

**Arquivo(s):** `src/matriz_c.c:87`, `src/matriz_cpp.cpp:80`

**Problema:** A técnica `(int)(x + 0.5)` usada em C pode, para valores de ponto flutuante extremamente próximos (mas abaixo) de um `.5` exato (ex.: `0.49999999999999994`), arredondar para cima incorretamente devido à perda de precisão na soma `x + 0.5`, enquanto `std::round` do C++ não tem esse problema por examinar o valor diretamente.

**Impacto:** Teórico e de probabilidade muito baixa de ocorrer nos valores de `B`/`Npts` tipicamente usados neste projeto (diferente da divergência Python já comprovada em P0-1, que é sistemática e fácil de reproduzir). Incluído aqui apenas para registro, caso a correção de P0-1 opte por reescrever a lógica de arredondamento em C também.

**Correção proposta:** Se P0-1 for corrigido trocando a técnica de arredondamento em alguma linguagem, preferir uma função de arredondamento explícita (`std::round`, `math.floor(x+0.5)` com cuidado, ou `Math.round`) em vez da soma manual de `0.5`.

**Teste necessário:** N/A; risco teórico de baixíssima probabilidade prática.

---

### P3-4 — `out/teste/` e diretórios de execução local seguem versionados no histórico (item já rastreado, ainda não resolvido)

**Prioridade:** P3

**Arquivo(s):** `out/teste/`, `TODO.md:214`

**Problema:** Confirmado via `git ls-files out/` que `out/teste/`, `out/tmp-plan-check/` e outras pastas de execução aparentemente locais/de teste continuam commitadas no histórico, como já identificado pelo próprio mantenedor em `TODO.md:214` ("Avaliar remoção de `out/teste/` do histórico se for execução local descartável"), ainda sem `[x]`.

**Impacto:** Não é um bug introduzido por esta branch; é reiterado aqui apenas porque a auditoria pediu avaliação de "qualidade acadêmica" e organização do repositório, e o item já está identificado, mas não resolvido, no próprio TODO do projeto.

**Correção proposta:** Nenhuma ação nesta auditoria; decisão de manutenção pertence ao mantenedor conforme já planejado no TODO.

**Teste necessário:** N/A.

---

## Observação adicional descoberta durante a correção (fora do escopo P0/P1 desta rodada)

Ao validar a correção de P1-4 rodando `scripts/test_extra_language.py` contra os binários reais de C e C++ (algo que a documentação do projeto nunca pede — o harness é documentado para testar apenas as futuras linguagens extras, usando Python como autoteste do harness), descobri que `matriz_c.c` e `matriz_cpp.cpp` **não criam o diretório pai do CSV de saída** (diferente de Java, que usa `Files.createDirectories`, e de Python, que usa `Path.mkdir(parents=True)`). Isso nunca se manifesta no fluxo real porque `run_all.sh`/`run_all.ps1` sempre criam `out/<run_id>/` antes de invocar qualquer binário. Não é um item do contrato de `EXECUTION.md` (que não exige isso das quatro linguagens principais) e não é regressão desta correção — os 12 casos de erro do harness (incluindo os 7 novos de P1-4) passaram normalmente em C e C++ antes de essa limitação, pré-existente e não relacionada, aparecer no teste de sucesso "escala linear". Registrado aqui apenas para rastreabilidade; **não corrigido nesta rodada** por estar fora do escopo P0/P1 e não afetar Rust/Julia/Elixir nem o fluxo publicável atual.

## Itens investigados e descartados (sem achado)

Para que a auditoria seja auditável, registro aqui uma hipótese de bug que foi investigada empiricamente e **não se confirmou**, para não ser levantada novamente sem necessidade:

- **Eliminação de trabalho pelo otimizador `-O3` em C:** como `verify_sample` (`matriz_c.c:118-137`) só lê 9 posições do resultado, havia a hipótese de que o GCC em `-O3`, ao inlinear `multiply` e `verify_sample` no mesmo arquivo, pudesse provar que apenas 9 células do resultado são efetivamente observadas e eliminar o cálculo das demais. Testado empiricamente: compilei `matriz_c.c` com e sem `-O3` e medi `TCS` para N=100, 1050 e 2000. Em ambos os casos o tempo escala de forma consistente com o crescimento cúbico esperado (não há tempo constante nem sub-linear que indicasse eliminação de trabalho); `-O3` é mais rápido que sem otimização na mesma proporção esperada de uma vetorização/otimização de laço convencional, não de eliminação de cálculo. Não é um achado.

---

## Encerramento

Nenhuma refatoração de código, promoção de arquivo de `experiments/` para `src/`, merge, push ou reescrita de histórico foi realizada, na auditoria original nem nesta rodada de correção. Rust, Julia e Elixir continuam não implementados.

### Arquivos alterados nesta rodada de correção (2026-08-25)

- `src/matriz_python.py` — corrige arredondamento (P0-1).
- `scripts/validate_run.py` — adiciona checagem de contagem de linhas e de consistência de série de N entre CSVs (P1-1, P1-2).
- `scripts/test_extra_language.py` — amplia casos de erro testados (P1-4).
- `.github/pull_request_template.md`, `EXTRA_LANGUAGES.md` — documentam o limite de detecção de corretude do harness (mitigação de P1-3).
- `scripts/test_point_generation.py` (novo) — regressão para P0-1.
- `scripts/test_validate_run.py` (novo) — regressão para P1-1/P1-2.
- `AUDIT_TCC_THASSIO.md` — este arquivo, com status de resolução por achado.

Nenhum item P2 ou P3 foi alterado nesta rodada.
