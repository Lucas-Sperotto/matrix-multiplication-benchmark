# Matrix Multiplication Benchmark

Este repositório contém códigos para realizar um **benchmark de multiplicação de matrizes** em várias linguagens de programação: **C, C++, Python, Java, Rust, e Elixir**. O objetivo é comparar o desempenho de cada linguagem ao executar uma operação intensiva de cálculo — a multiplicação de matrizes — em diferentes tamanhos.

## Objetivo

O objetivo deste projeto é avaliar o tempo de execução e o consumo de memória das linguagens de programação durante a multiplicação de duas matrizes quadradas. O código foi implementado de maneira semelhante em cada linguagem para garantir a comparabilidade dos resultados.

## Linguagens Suportadas

- C
- C++
- Python
- Java
- Rust
- Elixir

## Como Executar

### Pré-requisitos

Para executar os testes, você precisará ter as seguintes ferramentas instaladas:

- **C**: `gcc`
- **C++**: `g++`
- **Python**: `python3`
- **Java**: `JDK`
- **Rust**: `rustc`
- **Elixir**: `elixir`

No Ubuntu, você pode instalar as dependências com os seguintes comandos:

```bash
    sudo apt update
    sudo apt install build-essential python3 default-jdk elixir
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Compilando e Executando os Códigos

1. **C**:
   ```bash
   gcc matriz_c.c -o matriz_c
   ./matriz_c
   
2. **C++**:
   ```bash
   g++ matriz_cpp.cpp -o matriz_cpp
   ./matriz_cpp

3. **Python**:
   ```bash
   python3 matriz_python.py

4. **Java**:
   ```bash
   javac MatrixMultiplication.java
   java MatrixMultiplication

5. **Rust**:
   ```bash
   rustc matriz_rust.rs
   ./matriz_rust

6. **Elixir**:
   ```bash
   elixir matriz_multiplication.exs

## Estrutura do Código

Cada arquivo implementa a multiplicação de duas matrizes **N × N**. A função de multiplicação segue a estrutura de três loops `for`, padrão para algoritmos de multiplicação de matrizes, garantindo consistência na comparação entre linguagens.

## Parâmetros do Teste

O valor de **N** (o tamanho da matriz) pode ser ajustado dentro de cada código.  
Em testes iniciais, foram utilizados **N = 500**, **N = 1000**, **N = 5000**, com medições de tempo e uso de memória.

## Medição de Desempenho

### Tempo de Execução

O tempo de execução é medido diretamente nos códigos com funções de medição específicas para cada linguagem.

### Uso de Memória

Para monitorar o uso de memória em tempo real, recomendamos o uso dos seguintes comandos:

```bash
    /usr/bin/time -v ./matriz_c
```
    
Ou monitore os processos usando o `htop` ou `top` para acompanhamento em tempo real.

## Resultados Esperados

- C e C++ tendem a ter desempenho mais rápido em operações intensivas de CPU.
- Rust oferece segurança de memória com um impacto mínimo no desempenho.
- Python, por ser interpretado, tende a ser mais lento.
- Elixir e Java podem variar em desempenho dependendo da implementação e do uso de paralelismo.

## Contribuição

Sinta-se à vontade para contribuir com melhorias ou incluir outras linguagens para comparação. Basta abrir uma issue ou enviar um pull request.

## Colaboração

Este projeto foi desenvolvido em colaboração entre [Lucas Kriesel Sperotto](https://github.com/Lucas-Sperotto) e [Marcos Adriano](https://github.com/MarcosAS3). A execução dos testes de desempenho e a coleta de dados foram realizadas por ambos, garantindo que o processo fosse colaborativo e justo.


## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para mais detalhes.
