## Resumo

<!-- Explique objetivamente o que está sendo proposto e por quê. -->

## Tipo de Pull Request

- [ ] Desenvolvimento/correção com base em `tcc-lic-thassio`
- [ ] Promoção final do TCC de `tcc-lic-thassio` para `main`
- [ ] Outro (explique abaixo)

**Branch base:**  
**Branch de origem/head:**  
**SHA validado:**  

## Escopo

<!-- Linguagens, runners, documentação ou outro escopo afetado. -->

## Validação executada

```text
# Cole os comandos relevantes e o resultado resumido.
```

### Ambiente/toolchains

```text
# Sistema operacional, CPU e versões de gcc/g++, Java/JVM, Python,
# Rust, Julia, Elixir/OTP conforme aplicável.
```

## Checklist técnico

- [ ] Li o diff completo do PR e confirmei que a branch base está correta.
- [ ] `git diff --check` não reporta problemas.
- [ ] O contrato CLI permanece `B Npts M escala out_csv`.
- [ ] O CSV permanece exatamente `N,TCS,TAM,TDM`.
- [ ] Argumentos inválidos falham com código diferente de zero e mensagem em `stderr`.
- [ ] O caminho `out_csv` cria diretórios pais quando necessário.
- [ ] A multiplicação permanece manual O(N³), sem BLAS/paralelismo no fluxo principal.
- [ ] Os testes de corretude não identidade aplicáveis passaram.
- [ ] `tests/test_point_generation.py` e `tests/test_validate_run.py` passaram.
- [ ] Os smoke tests aplicáveis terminaram com `scripts/validate_run.py` aprovado.
- [ ] Não incluí binários, caches nem resultados locais acidentais.
- [ ] Atualizei a documentação se o contrato, uso ou metodologia mudou.

## Checklist adicional para promoção final a `main`

Preencha somente quando este PR promover a versão final do TCC.

- [ ] Segui `docs/STUDENT_VALIDATION.md` em um fork/checkout limpo.
- [ ] Registrei o SHA exato testado.
- [ ] Validei C, C++, Java, Python, Rust, Julia e Elixir, ou documentei explicitamente qualquer impedimento antes de solicitar merge.
- [ ] Executei o runner Linux/WSL com núcleo e com todas as extras.
- [ ] Executei `run_all.ps1` ponta a ponta em Windows nativo ou registrei a limitação para decisão do orientador.
- [ ] O PR tem `main` como base e `tcc-lic-thassio` validada como origem.
- [ ] Não fiz otimização isolada de linguagem durante a fase de validação final.

## Limitações / observações

<!-- Registre diferenças de ambiente, testes não executados e decisões que o revisor precisa conhecer. -->
