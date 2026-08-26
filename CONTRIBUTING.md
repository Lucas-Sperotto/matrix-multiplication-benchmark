# Contribuindo

Uma proposta central deste projeto é reunir resultados de máquinas diferentes em uma base comparável.

Há dois fluxos distintos:

- resultados do benchmark, descritos abaixo;
- mudanças de código e metodologia, inclusive Rust, Julia e Elixir, descritas em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

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

Se alguma flag extra foi usada, confirme também o CSV correspondente (`resultado_rust.csv`, `resultado_julia.csv` e/ou `resultado_elixir.csv`) e sua entrada em `run_manifest.json`. Não reutilize um `run_id`: os runners rejeitam diretórios não vazios para impedir mistura de resultados.

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

## Fork e mudanças em Rust, Julia e Elixir

As três implementações já foram aceitas em `src/` e integradas aos runners como opções por flag. Para novas mudanças, o fork do aluno é o remoto `origin` e o repositório original é o remoto `upstream`:

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

Antes de criar uma branch, atualize `tcc-lic-thassio` a partir de `upstream/tcc-lic-thassio`. Use uma branch focada por mudança, sempre com base em `tcc-lic-thassio`. As branches abaixo registram a sequência histórica da implementação inicial:

```text
feat/rust-benchmark
feat/julia-benchmark
feat/elixir-benchmark
```

Novos PRs não devem reabrir essa sequência: nomeie a branch pelo escopo real (`fix/rust-...`, `docs/methodology-...`, por exemplo), não reúna assuntos independentes e confirme explicitamente a branch-base antes de enviar.

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
rustc --edition=2021 -C opt-level=3 -D warnings src/matriz_rust.rs -o build/linux/matriz_rust
python3 scripts/test_extra_language.py --language Rust -- ./build/linux/matriz_rust
```

Os comandos equivalentes para Julia e Elixir, a metodologia completa e as instalações oficiais estão em [EXTRA_LANGUAGES.md](EXTRA_LANGUAGES.md).

Os arquivos publicáveis atuais são `src/matriz_rust.rs`, `src/matriz_Julia.jl` e `src/matriz_multiplication.exs`. Os runners só os executam quando a flag correspondente é informada; sem flags, nenhuma toolchain extra é exigida. CSVs extras devem aparecer no manifesto exatamente quando forem executados.

## Checklist de código antes do Pull Request

```bash
git status
git diff --check
python3 scripts/test_extra_language.py --language LINGUAGEM -- COMANDO_BASE
```

No PR, informe a versão da toolchain, os comandos executados e o resultado dos testes. Não versione executáveis, caches, arquivos `.beam` nem CSVs locais. O template em `.github/pull_request_template.md` reúne o checklist de revisão.
