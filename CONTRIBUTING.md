# Contribuindo

Uma proposta central deste projeto é reunir resultados de máquinas diferentes em uma base comparável.

Há dois fluxos distintos:

- resultados do benchmark principal, descritos abaixo;
- código para Rust, Julia e Elixir na branch `tcc-lic-thassio`, descrito em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

## Como Gerar Resultados

Siga [EXECUTION.md](EXECUTION.md).

Use um nome de execução descritivo:

```text
out/<autor-ou-id>-<maquina>-<os>-<B>-<data>/
```

Exemplos:

```text
out/marcos-ryzen7-5700u-linux-3000-2026-04-25/
out/ana-i5-1135g7-win11-1000-2026-04-25/
```

## Checklist Antes do Pull Request

Rode:

```bash
python3 scripts/validate_run.py out/<run_id>
```

Confirme que a pasta contém:

- `resultado_c.csv`
- `resultado_c_O3.csv`
- `resultado_cpp.csv`
- `resultado_cpp_O3.csv`
- `resultado_java.csv`
- `resultado_python.csv`
- `system_info.md`
- `system_info.json`
- `run_manifest.json`
- gráficos `grafico_*.png`

Confirme também que a raiz do projeto não recebeu arquivos gerados como:

- `resultado_*.csv`
- `matriz_c`
- `matriz_cpp`
- `*.class`

## Enviando Resultados

```bash
git add out/<run_id>
git commit -m "Adiciona resultados <maquina/os/B>"
git push
```

Abra um Pull Request descrevendo:

- máquina/processador
- sistema operacional
- valor de `B`
- observações relevantes, se houver

## Contribuindo com Código

Para mudanças de código, preserve o contrato publicável:

```text
B Npts M escala out_csv
```

E preserve o cabeçalho CSV:

```csv
N,TCS,TAM,TDM
```

Mudanças em Rust, Julia, Elixir, BLAS, paralelismo ou análise estatística são bem-vindas, mas devem ser integradas ao fluxo principal apenas quando seguirem o mesmo contrato e passarem no validador.

## Fork para Rust, Julia e Elixir

Os protótipos em `experiments/` ainda não estão prontos. Para esta trilha, o fork do aluno é o remoto `origin` e o repositório original é o remoto `upstream`:

```bash
git clone https://github.com/SEU_USUARIO/matrix-multiplication-benchmark.git
cd matrix-multiplication-benchmark
git remote add upstream https://github.com/Lucas-Sperotto/matrix-multiplication-benchmark.git
git fetch upstream tcc-lic-thassio
git switch --create tcc-lic-thassio --track upstream/tcc-lic-thassio
git push --set-upstream origin tcc-lic-thassio
```

Se a branch já tiver sido copiada pelo GitHub, apenas troque para ela e configure o rastreamento:

```bash
git switch tcc-lic-thassio
git branch --set-upstream-to=upstream/tcc-lic-thassio
```

Antes de cada etapa, atualize `tcc-lic-thassio` a partir de `upstream/tcc-lic-thassio`. Crie e envie um PR por linguagem, sempre com base em `tcc-lic-thassio`:

```text
feat/rust-benchmark
feat/julia-benchmark
feat/elixir-benchmark
```

A ordem é Rust, depois Julia e por último Elixir. Não abra os PRs contra `main`, não reúna as três linguagens em um único PR e não inclua a integração dos runners nesta fase.

## Critérios para os PRs de linguagens extras

Além do contrato `B Npts M escala out_csv` e do cabeçalho `N,TCS,TAM,TDM`, cada implementação deve:

- gerar pontos lineares e logarítmicos entre `100` e `B`;
- executar um warm-up descartado para cada `N`;
- registrar a média de exatamente `M` repetições;
- usar relógio monotônico de alta resolução;
- multiplicar manualmente, sem biblioteca numérica ou paralelismo;
- validar as nove combinações dos índices inicial, central e final;
- rejeitar entrada inválida em `stderr` com código diferente de zero;
- aceitar um caminho de saída cujo diretório contenha espaços;
- passar pelo harness da linguagem.

Exemplo para Rust:

```bash
python3 scripts/test_extra_language.py --language Rust -- ./build/extra/matriz_rust
```

Os comandos equivalentes para Julia e Elixir, a metodologia completa e as instalações oficiais estão em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

Mantenha o arquivo em `experiments/` até o mantenedor aceitar explicitamente sua promoção. Só então ele deve ser movido para `src/` e testado novamente. Uma integração posterior pode adicionar as linguagens como opções dos runners e registrá-las no manifesto, sem torná-las dependências obrigatórias do fluxo atual. O validador e o plotador já aceitam os três CSVs quando presentes.

## Checklist de código antes do Pull Request

```bash
git status
git diff --check
python3 scripts/test_extra_language.py --language LINGUAGEM -- COMANDO_BASE
```

No PR, informe a versão da toolchain, os comandos executados e o resultado dos testes. Não versione executáveis, caches, arquivos `.beam` nem CSVs locais. O template em `.github/pull_request_template.md` reúne o checklist de revisão.
