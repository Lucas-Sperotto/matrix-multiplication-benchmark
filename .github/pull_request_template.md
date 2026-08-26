## Resumo

<!-- Explique objetivamente o que mudou e por que. -->

## Escopo

- Linguagem: <!-- Rust, Julia, Elixir ou N/A -->
- Branch de origem: <!-- feat/rust-benchmark, feat/julia-benchmark ou feat/elixir-benchmark -->
- Branch de destino: `tcc-lic-thassio`

## Validacao executada

```text
# Cole os comandos e o resultado resumido.
```

Versoes das ferramentas:

```text
# rustc --version, elixir --version ou julia --version
```

## Checklist

- [ ] Este PR trata de uma unica linguagem ou de um unico objetivo bem delimitado.
- [ ] A base do PR e `tcc-lic-thassio`, nao `main`.
- [ ] A CLI segue `B Npts M escala out_csv`.
- [ ] O CSV usa exatamente `N,TCS,TAM,TDM`.
- [ ] Ha um warm-up descartado e a media de exatamente `M` repeticoes.
- [ ] A multiplicacao e manual, com validacao das nove posicoes amostrais.
- [ ] Argumentos invalidos falham em `stderr` com codigo diferente de zero.
- [ ] Executei `scripts/test_extra_language.py` para a linguagem deste PR.
- [ ] Revisor: li o codigo de `verify_sample`/equivalente e confirmo que ele calcula e compara os 9 valores esperados corretamente. O harness automatizado nao consegue detectar multiplicacao aritmeticamente incorreta (o CSV nao carrega valores de matriz), entao essa checagem e manual e obrigatoria.
- [ ] Nao inclui binarios, caches nem resultados locais.
- [ ] O codigo permanece em `experiments/`, salvo aceite explicito para promove-lo a `src/`.
- [ ] Atualizei a documentacao quando houve mudanca de contrato ou de uso.

## Observacoes para revisao

<!-- Registre decisoes de representacao de matriz, limitacoes conhecidas e pontos que merecem atencao. -->
