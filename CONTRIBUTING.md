# Contribuindo

Este projeto separa dois tipos de contribuição:

1. resultados de benchmark;
2. mudanças de código/documentação.

Mudanças que afetem desenho experimental devem atualizar `docs/METHODOLOGY.md`; limitações relevantes devem ser refletidas em `docs/THREATS_TO_VALIDITY.md`.

## Gerar resultados

Siga [docs/EXECUTION.md](docs/EXECUTION.md). Use um `run-name` descritivo e seguro, sem espaços ou separadores de caminho, por exemplo:

```text
lucas-ryzen7-linux-B3000-20260826
```

O runner gera e valida `out/<run_id>/`. Não misture arquivos de execuções distintas.

Antes de versionar um resultado:

```bash
python3 scripts/validate_run.py out/<run_id>
git status --short
```

Não versione executáveis, caches, `build/` ou diretórios `.running-*`.

## Mudanças de código

Preserve o contrato:

```text
B Npts M escala out_csv
```

e o cabeçalho:

```csv
N,TCS,TAM,TDM
```

A multiplicação principal permanece manual O(N³), sem BLAS ou paralelismo, salvo em experimentos explicitamente fora do fluxo principal.

Antes de abrir um PR de desenvolvimento:

```bash
git status
git diff --check
python3 tests/test_point_generation.py
python3 tests/test_validate_run.py
```

Rode também o harness e os testes de corretude das linguagens afetadas.

## Fork e remotos

No fork do colaborador:

```bash
git clone https://github.com/SEU_USUARIO/matrix-multiplication-benchmark.git
cd matrix-multiplication-benchmark
git remote add upstream https://github.com/Lucas-Sperotto/matrix-multiplication-benchmark.git
git fetch upstream
```

`origin` deve apontar para o fork; `upstream`, para o repositório original.

## PRs de desenvolvimento

Durante desenvolvimento/correções do TCC, use `tcc-lic-thassio` como base:

```bash
git switch tcc-lic-thassio
git merge --ff-only upstream/tcc-lic-thassio
git switch -c fix/descricao-curta
```

Não reutilize as branches históricas `feat/rust-benchmark`, `feat/julia-benchmark` e `feat/elixir-benchmark` para novos trabalhos; elas registram a sequência inicial já encerrada.

No PR, informe:

- base e head;
- objetivo;
- toolchains afetadas;
- comandos de teste;
- resultados;
- limitações conhecidas.

## Critérios de contrato por implementação

Cada implementação deve:

- aceitar exatamente `B Npts M escala out_csv`;
- gerar `Npts` pontos entre `100` e `B`;
- usar arredondamento metade-para-cima conforme o contrato;
- criar diretórios pais de `out_csv` quando necessário;
- sobrescrever o CSV;
- executar um warm-up descartado por `N`;
- medir exatamente `M` repetições;
- usar relógio monotônico de alta resolução;
- multiplicar manualmente;
- validar as nove posições amostrais;
- falhar em `stderr` com código diferente de zero para entrada inválida.

O harness pode ser executado para qualquer uma das sete linguagens. Exemplo:

```bash
python3 tests/test_extra_language.py --language Rust -- ./build/linux/matriz_rust
```

Os testes 2×2 não identidade complementam o harness porque o benchmark principal usa matriz identidade como segundo operando.

## Promoção final do TCC para `main`

Este fluxo é uma **exceção deliberada** à regra anterior.

Depois que `tcc-lic-thassio` estiver estabilizada, o aluno deve:

1. criar/sincronizar um fork limpo;
2. executar integralmente [docs/STUDENT_VALIDATION.md](docs/STUDENT_VALIDATION.md);
3. registrar SHA, ambiente e resultados;
4. abrir um Pull Request com:
   - base: `main`;
   - head: `tcc-lic-thassio` do fork.

O template de PR possui uma seção específica para essa promoção.

Não faça otimizações ou mudanças metodológicas oportunistas durante a etapa final de validação. Se um defeito real for encontrado, corrija-o em commit separado, repita os testes afetados e descreva o desvio no PR.

## Revisão

O revisor deve verificar tanto o código quanto o escopo científico. Passar no harness não substitui a leitura das rotinas de multiplicação e verificação.

Para a promoção final, um teste obrigatório falhando é motivo para não fazer merge até que a causa seja compreendida e corrigida ou formalmente retirada do critério pelo orientador.
