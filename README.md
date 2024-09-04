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

Cada arquivo implementa a multiplicação de duas matrizes \(N \times N\). A função de multiplicação segue a estrutura de três loops `for`, padrão para algoritmos de multiplicação de matrizes, garantindo consistência na comparação entre linguagens.

## Parâmetros do Teste

O valor de \(N\) (o tamanho da matriz) pode ser ajustado dentro de cada código.  
Em testes iniciais, foram utilizados \(N = 500\), \(N = 1000\), \(N = 5000\), com medições de tempo e uso de memória.

## Medição de Desempenho

### Tempo de Execução

O tempo de execução é medido diretamente nos códigos com funções de medição específicas para cada linguagem.


