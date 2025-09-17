# Matrix Multiplication Benchmark

Este repositório contém códigos para realizar um **benchmark de multiplicação de matrizes** em várias linguagens de programação (**C, C++, Python, Java** – com expansão planejada para Rust e Elixir).  
O objetivo é comparar o desempenho de cada linguagem em uma operação intensiva de cálculo: a multiplicação de matrizes quadradas de diferentes tamanhos.

---

## 🎯 Objetivo

- Avaliar o **tempo de execução** e o **uso de memória** na multiplicação de matrizes.
- Comparar implementações equivalentes entre diferentes linguagens.
- Construir uma base colaborativa de resultados, permitindo que qualquer pessoa rode os testes em sua máquina e contribua com seus dados.

---

## 🚀 Como começar

Clone o repositório:

```bash
git clone https://github.com/<usuario>/<repo>.git
cd <repo>
````

Execute os benchmarks:

- **Linux/WSL**:

  ```bash
  chmod +x run_all.sh
  ./run_all.sh
  ```

- **Windows (PowerShell)**:

  ```powershell
  .\run_all.ps1
  ```

Os resultados serão salvos em:

```bash
out/<NOME_DA_EXECUCAO>/
```

com arquivos `resultado_c.csv`, `resultado_cpp.csv`, `resultado_java.csv`, `resultado_python.csv`.

---

## 📊 Gráficos automáticos

Ao final da execução no Linux/WSL, o script `run_all.sh` chama automaticamente o `plot_benchmarks.py`, que gera gráficos comparativos para:

- **TCS**: Tempo de Cálculo da Multiplicação
- **TAM**: Tempo de Alocação de Memória
- **TDM**: Tempo de Desalocação de Memória (quando disponível na linguagem)

Cada gráfico inclui também uma **curva de referência** baseada em $N^3$, representando a complexidade teórica.

---

## Resultados Esperados

- C e C++ tendem a ter desempenho mais rápido em operações intensivas de CPU.
- Rust oferece segurança de memória com um impacto mínimo no desempenho.
- Python, por ser interpretado, tende a ser mais lento.
- Elixir e Java podem variar em desempenho dependendo da implementação e do uso de paralelismo.

---

## 📚 Documentação complementar

- [EXECUTION.md](EXECUTION.md) → Guia completo de execução (Linux/WSL e Windows).
- [CONTRIBUTING.md](CONTRIBUTING.md) → Como rodar localmente e contribuir com seus resultados.
- [OPERATIONS.md](OPERATIONS.md) → Análise teórica do número de operações na multiplicação de matrizes.

---

## 👥 Colaboração

- Projeto iniciado por [**Lucas Kriesel Sperotto**](https://github.com/Lucas-Sperotto).
- Expansão com a participação de [**Marcos Adriano Silva David**](https://github.com/MarcosAS3).
- Aberto para contribuições de estudantes, pesquisadores e entusiastas.

Sinta-se à vontade para contribuir com melhorias ou incluir outras linguagens para comparação. Basta abrir uma issue ou enviar um pull request. Veja [CONTRIBUTING.md](CONTRIBUTING.md) para saber como participar.

---

## 📄 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---
