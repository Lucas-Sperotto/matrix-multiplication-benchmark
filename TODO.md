# TODO – Benchmark de Multiplicação de Matrizes

Tarefas ainda abertas da branch `tcc-lic-thassio`.

Itens concluídos são registrados nos commits e relatórios em `docs/`. A auditoria independente de pré-entrega está em `docs/PRE_RELEASE_AUDIT.md`.

Última revisão: **2026-08-26**.

## 1. Aceitação final antes do PR para `main`

Prioridade imediata. O aluno deve seguir integralmente `docs/STUDENT_VALIDATION.md`.

- [ ] Reproduzir os testes em fork/checkout limpo da branch `tcc-lic-thassio` e registrar o SHA exato testado.
- [ ] Executar o harness de contrato nas sete linguagens: C, C++, Java, Python, Rust, Julia e Elixir.
- [ ] Executar os testes de corretude não identidade nas sete linguagens.
- [ ] Executar `tests/test_point_generation.py` e `tests/test_validate_run.py`.
- [ ] Executar smoke Linux/WSL do núcleo e de `--with-all-extras`.
- [ ] Executar `tests/test_matriz_elixir.exs` e o harness do Elixir em ambiente com Elixir/OTP instalado.
- [ ] Executar `run_all.ps1` ponta a ponta em Windows nativo, incluindo promoção no NTFS.
- [ ] Confirmar rejeição de `run-name` inseguro (`../escape`, `a/b`) nos dois runners.
- [ ] Registrar no PR final sistema, hardware, versões das toolchains, comandos executados e limitações.
- [ ] Abrir o PR final do fork com base `main` e head `tcc-lic-thassio` somente se não houver teste obrigatório falhando.

## 2. Decisões metodológicas para a coleta formal

Não bloqueiam a validação de software, mas devem ser resolvidas antes da bateria experimental definitiva.

- [ ] Definir se `TEXEC = TAM + TCS + TDM` será usado como métrica derivada; manter TAM/TCS/TDM separados.
- [ ] Verificar empiricamente a estabilização do JIT do Java e documentar o comportamento observado.
- [ ] Fixar ou declarar formalmente versões de Rust e Julia; decidir se Elixir 1.20.3 / OTP 28.4 é requisito ou ambiente recomendado.
- [ ] Definir número de repetições, número de execuções independentes e se tempos brutos por repetição serão preservados.
- [ ] Definir protocolo ambiental: carga de fundo, prioridade/afinidade, governor/turbo, temperatura e ordem aleatória/contrabalanceada.
- [ ] Definir como interpretar a assimetria de otimização: C/C++ com e sem `-O3`, Rust em `opt-level=3` e runtimes gerenciados sem variante pareada.
- [ ] Definir faixas práticas de `B`, `Npts` e `M` por linguagem/hardware, em especial para Elixir.
- [ ] Preservar comandos e dados brutos de futuras sondagens de bounds-check, GC e variância antes de citá-las como resultado científico.

## 3. Robustez e portabilidade não bloqueantes

- [ ] Definir tratamento uniforme de espaços em branco nos argumentos numéricos.
- [ ] Avaliar casos-limite reproduzíveis de arredondamento em ponto flutuante; não alterar a política metade-para-cima sem evidência.
- [ ] Decidir se `validate_run.py` deve rejeitar qualquer `resultado_*.csv` arbitrário ausente do manifesto, além dos nomes conhecidos.
- [ ] Tornar `tests/test_point_generation.py` uma regressão realmente cruzada entre linguagens; hoje a fórmula canônica é comparada diretamente apenas com Python.
- [ ] Fortalecer a proveniência do manifesto com estado `dirty`/diff e identidade/caminho das toolchains.
- [ ] Verificar `scripts/gen_sysinfo_md.sh` em macOS/BSD (`date -Iseconds` não é portável).
- [ ] Considerar uma suíte oficial de smoke test automatizada.
- [ ] Considerar GitHub Actions após a aceitação manual multi-runtime.
- [ ] Avaliar separadamente a remoção dos resultados históricos em `out/teste/`.
- [ ] Considerar README em inglês após estabilização/publicação.

## 4. Extensões futuras – fora do escopo do TCC atual

- [ ] Variante NumPy para Python.
- [ ] BLAS em C/C++ no contrato comum.
- [ ] Paralelismo com OpenMP/threads.
- [ ] Medição de memória RSS.
- [ ] Relatório automático em Markdown a partir de uma execução.
- [ ] Medição de energia quando houver infraestrutura adequada.
