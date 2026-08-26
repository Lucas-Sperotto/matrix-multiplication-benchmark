# TODO – Benchmark de Multiplicação de Matrizes

Tarefas pendentes da branch `tcc-lic-thassio`. Itens já concluídos não aparecem aqui — o histórico de decisões e aceites está nos commits, em `docs/INTEGRATION_PLAN.md` (arquitetura de integração das linguagens extras) e em `docs/METHODOLOGY.md` (decisões metodológicas já registradas).

Última revisão: **2026-08-26**.

---

## 1. Contrato e execução

- [ ] **C e C++**: criar o diretório pai de `out_csv` quando ele ainda não existir, como já fazem Java/Python/Rust/Julia/Elixir.
- [ ] Adicionar regressão no harness/testes para execução com caminho de saída em diretório pai inexistente.
- [ ] Sanitizar `--run-name`/`-RunName` nos dois runners: rejeitar caminhos absolutos, separadores, `..` e caracteres fora de `[A-Za-z0-9_.-]`; adicionar regressão de path traversal.
- [ ] Definir e testar o tratamento de espaços em branco nos argumentos numéricos, hoje divergente entre Java (`Integer.parseInt`, rejeita) e C/C++ (`strtol`/`std::stol`, aceita à esquerda).
- [ ] Avaliar uma função de arredondamento explícita em C para casos-limite de ponto flutuante; preservar a política metade-para-cima e não alterar código sem um caso reproduzível de divergência.
- [ ] Definir se `validate_run.py` deve rejeitar todo `resultado_*.csv` ausente do manifesto; hoje ele rejeita apenas os seis nomes centrais e os três opcionais conhecidos, ignorando nomes arbitrários.

## 2. Corretude do algoritmo

O harness de contrato valida CLI/CSV/tempos/série N, mas não prova sozinho que a multiplicação está matematicamente correta (a matriz identidade como segundo operando não distingue multiplicação de cópia — ver `docs/METHODOLOGY.md`, "Validação matemática"). `tests/` já cobre isso com um caso 2×2 não identidade por linguagem, fora da janela de benchmark; itens realmente pendentes:

- [ ] Executar `tests/test_matriz_elixir.exs` em um ambiente com Elixir instalado (não disponível no ambiente usado na rodada de estabilização de 2026-08-26) e confirmar o resultado.
- [ ] Validar `tests/test_matriz_elixir.exs`/`tests/TestMatrizJava.java`/os testes de Rust/Julia em CI, não apenas manualmente.

## 3. Decisões metodológicas em aberto

- [ ] Avaliar se a métrica derivada `TEXEC = TAM + TCS + TDM` (nomenclatura formalizada em `docs/METHODOLOGY.md` como "tempo agregado das fases instrumentadas") deve ser adotada para análise agregada; se sim, manter TAM/TCS/TDM como métricas diagnósticas.
- [ ] Verificar empiricamente, por exemplo com `java -XX:+PrintCompilation`, se um warm-up por N estabiliza o JIT do Java; hoje isso é uma suposição declarada, não uma garantia medida.
- [ ] Fixar ou declarar formalmente versões testadas de Rust e Julia. Para Elixir/OTP, decidir se 1.20.3/28.4 é requisito ou apenas ambiente recomendado; se for requisito, validar nos runners e registrar a versão de OTP separadamente no manifesto.
- [ ] Considerar aumentar `M` nos experimentos finais e preservar tempos brutos por repetição para analisar estabilidade/variância (hoje só a média é gravada).
- [ ] Preservar comandos, ambiente e dados brutos das sondagens de bounds-check/GC/variância antes de citar percentuais como evidência científica; os valores atuais são apenas relatos diagnósticos locais.
- [ ] Definir um protocolo ambiental para a coleta final: carga de fundo, afinidade/prioridade, governor/turbo, temperatura e ordem aleatória ou contrabalanceada das linguagens.
- [ ] Definir como interpretar a assimetria de otimização: C/C++ têm séries com e sem `-O3`, Rust só entra com `opt-level=3`, e os runtimes gerenciados não têm variante pareada equivalente.
- [ ] Documentar faixas práticas de `B`/`Npts`/`M` por linguagem e hardware, com estimativas de memória/tempo para combinações inviáveis — parcialmente coberto pelo aviso sobre Elixir em `docs/EXECUTION.md`, mas sem uma tabela sistemática.
- [ ] **Elixir**: definir limites experimentais práticos de `B`/`M` antes da coleta definitiva; as validações locais indicaram execução consideravelmente mais lenta, mas ainda não há uma coleta formal preservada.

## 4. Validação e testes

- [ ] Criar uma suíte de smoke test oficial do projeto (hoje a verificação é manual: harness por linguagem + `validate_run.py` em execuções ad hoc).
- [ ] Ampliar `tests/test_point_generation.py` para uma regressão realmente cruzada; hoje ele executa apenas Python contra a fórmula canônica, enquanto a comparação com outras linguagens foi manual.
- [ ] Validar `run_all.ps1` ponta a ponta em Windows nativo; a sintaxe já foi aceita pelo parser do Windows PowerShell, mas ainda não houve execução completa em Windows nativo (compilação, benchmarks, validação e promoção no NTFS).
- [ ] Clonar o repositório em diretório limpo e reproduzir uma execução completa antes da coleta experimental final.
- [ ] Fortalecer a proveniência do manifesto: registrar comando reconstruível, caminhos/identidade das toolchains, OTP e estado `dirty`/diff. Hoje `commit_hash` não identifica alterações locais não commitadas.

## 5. Auditoria pós-integração

- [ ] Repetir uma auditoria técnica independente da branch `tcc-lic-thassio` (não `main`) após a integração das linguagens extras, registrando antes da análise: branch atual, SHA atual, `git status`, e a lista completa de implementações realmente analisadas.

## 6. Portabilidade e organização

- [ ] Verificar compatibilidade de `date -Iseconds` (usado em `scripts/gen_sysinfo_md.sh`) no macOS — `date` nativo do macOS (BSD) não implementa essa flag.
- [ ] Avaliar remoção de resultados locais históricos em `out/teste/` (ainda presente no repositório).
- [ ] Considerar GitHub Actions para smoke tests automáticos em PRs.
- [ ] Considerar README em inglês após estabilização do TCC.

## 7. Extensões futuras — fora do escopo imediato

- [ ] Variante NumPy para Python.
- [ ] BLAS em C/C++ no contrato comum (protótipo corrigido existe em `experiments/matriz_c_blas.c`, não integrado).
- [ ] Paralelismo com OpenMP/threads.
- [ ] Medição de memória RSS.
- [ ] Relatório automático em Markdown a partir de uma execução.
- [ ] Medição de energia quando houver infraestrutura adequada (RAPL, `nvidia-smi`).
