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

gcc matriz_c.c -o matriz_c
./matriz_c

g++ matriz_cpp.cpp -o matriz_cpp
./matriz_cpp

python3 matriz_python.py

javac MatrixMultiplication.java
java MatrixMultiplication

rustc matriz_rust.rs
./matriz_rust

elixir matriz_multiplication.exs




