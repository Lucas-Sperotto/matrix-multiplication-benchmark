# Executando com Docker Compose

Este projeto inclui um `docker-compose.yml` que permite executar os benchmarks de multiplicação de matrizes em qualquer linguagem sem precisar instalar as linguagens localmente.

## Pré-requisitos

- Docker
- Docker Compose

## Linguagens Disponíveis

- **Java** - OpenJDK 11
- **C** - GCC latest
- **C++** - GCC latest  
- **Python** - Python 3.9
- **Rust** - Rust latest
- **Elixir** - Elixir latest
- **Julia** - Julia latest

## Como Executar

### Executar uma linguagem específica:

```bash
# Java
docker-compose --profile java up

# Python
docker-compose --profile python up

# Rust
docker-compose --profile rust up

# C
docker-compose --profile c up

# C++
docker-compose --profile cpp up

# Elixir
docker-compose --profile elixir up

# Julia
docker-compose --profile julia up
```

### Executar múltiplas linguagens:

```bash
# Java e Python
docker-compose --profile java --profile python up

# C, C++ e Rust
docker-compose --profile c --profile cpp --profile rust up
```

### Executar todas as linguagens:

```bash
docker-compose --profile all up
```

## Limpeza

Para remover containers e imagens criadas:

```bash
# Parar e remover containers
docker-compose down

# Remover imagens (opcional)
docker-compose down --rmi all
```

## Notas

- Os resultados dos benchmarks são salvos nos arquivos `resultado_*.dat`
- Cada container executa de forma isolada
- Os arquivos de código fonte são montados como volume, então mudanças locais são refletidas nos containers