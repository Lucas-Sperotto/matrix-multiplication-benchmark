# Contribuindo

Uma proposta central deste projeto é reunir resultados de máquinas diferentes em uma base comparável.

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
