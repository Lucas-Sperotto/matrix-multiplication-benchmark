# Matrix Multiplication Benchmark

Benchmark reprodutível de multiplicação de matrizes quadradas. O núcleo executa C, C++, Java e Python; Rust, Julia e Elixir podem ser incluídas explicitamente como linguagens opcionais.

O objetivo é comparar implementações funcional e algoritmicamente equivalentes de multiplicação matricial manual O(N³) sob um contrato comum de entrada/saída, preservando características relevantes de compiladores, runtimes e representações de dados de cada ecossistema.

## Execução rápida

Linux/WSL:

```bash
python3 -m pip install -r requirements.txt
./run_all.sh --batch --run-name meu_teste-linux-100 --B 100 --Npts 2 --M 1 --escala 1
```

Windows PowerShell:

```powershell
python -m pip install -r requirements.txt
.\run_all.ps1 -Batch -RunName meu_teste-win-100 -B 100 -Npts 2 -M 1 -Escala 1
```

Também é possível rodar os runners sem parâmetros para usar o modo interativo.

`run-name`/`RunName` aceita apenas letras, números, `_`, `.`, `-` e não pode conter `..` nem separadores de caminho. Isso mantém todas as execuções confinadas a `out/`.

## Rust, Julia e Elixir

Sem flags extras, nenhuma dessas toolchains é exigida. Para incluí-las:

```bash
./run_all.sh --batch --run-name meu_teste-all-100 --B 100 --Npts 2 --M 1 --escala 1 --with-all-extras
```

```powershell
.\run_all.ps1 -Batch -RunName meu_teste-all-100 -B 100 -Npts 2 -M 1 -Escala 1 -WithAllExtras
```

Também existem flags individuais: `--with-rust`, `--with-julia`, `--with-elixir` e, no PowerShell, `-WithRust`, `-WithJulia`, `-WithElixir`.

Quando uma linguagem extra é solicitada, sua toolchain é verificada **antes** da criação do staging e antes da execução do núcleo. Dependência solicitada e ausente é erro, nunca omissão silenciosa.

## Saídas

Uma execução bem-sucedida termina em `out/<run_id>/` com:

- seis CSVs centrais (`C`, `C -O3`, `C++`, `C++ -O3`, `Java`, `Python`);
- CSVs opcionais das extras solicitadas;
- `system_info.md`;
- `system_info.json`;
- `run_manifest.json`;
- `grafico_*.png`.

Enquanto está em andamento, a execução usa `out/.running-<run_id>/`. O nome final só é promovido depois que benchmarks, metadados, gráficos e validação terminarem com sucesso.

Todos os CSVs usam exatamente:

```csv
N,TCS,TAM,TDM
```

- `N`: dimensão da matriz `N x N`;
- `TCS`: tempo de cálculo;
- `TAM`: tempo de alocação/inicialização;
- `TDM`: tempo de desalocação explícita; é `0.0` nos runtimes gerenciados definidos pela metodologia.

## Validação

Depois de uma execução:

```bash
python3 scripts/validate_run.py out/<run_id>
```

Para testes de contrato e corretude, consulte `tests/` e o roteiro de validação final.

## Estrutura

```text
.
├─ src/          # implementações e gerador de gráficos
├─ experiments/  # protótipos fora do fluxo principal
├─ scripts/      # coleta de sistema, diagnóstico e validação operacional
├─ tests/        # regressões de contrato e corretude
├─ docs/         # execução, metodologia, auditorias e guias
├─ build/        # artefatos de compilação ignorados pelo Git
├─ out/          # resultados aceitos/versionáveis
├─ run_all.sh
└─ run_all.ps1
```

## Documentação

- [EXECUTION.md](docs/EXECUTION.md): instalação, execução e problemas comuns.
- [METHODOLOGY.md](docs/METHODOLOGY.md): desenho experimental, métricas e decisões.
- [THREATS_TO_VALIDITY.md](docs/THREATS_TO_VALIDITY.md): limitações e ameaças à validade.
- [EXTRA_LANGUAGES.md](docs/EXTRA_LANGUAGES.md): Rust, Julia e Elixir.
- [OPERATIONS.md](docs/OPERATIONS.md): fundamentação matemática do número de operações.
- [DIAGRAMS.md](docs/DIAGRAMS.md): arquitetura e fluxo.
- [PRE_RELEASE_AUDIT.md](docs/PRE_RELEASE_AUDIT.md): auditoria independente de pré-entrega.
- [STUDENT_VALIDATION.md](docs/STUDENT_VALIDATION.md): roteiro obrigatório do aluno antes do PR final.
- [CONTRIBUTING.md](CONTRIBUTING.md): contribuição e Pull Requests.
- [TODO.md](TODO.md): somente itens ainda abertos.

## Estado da branch de TCC

A branch `tcc-lic-thassio` é a linha de integração e validação do TCC. Antes de promovê-la para `main`, execute integralmente [STUDENT_VALIDATION.md](docs/STUDENT_VALIDATION.md) em um fork/checkout limpo e registre os resultados no Pull Request.

## Licença

MIT. Veja [LICENSE](LICENSE).
