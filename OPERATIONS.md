# Análise de Operações na Multiplicação de Matrizes

Este documento detalha o número de operações necessárias para a multiplicação de duas matrizes $`N \times N`$ utilizando um algoritmo cúbico de três laços `for`).  
Ele serve de **fundamentação teórica** para interpretar os resultados experimentais deste projeto.

## Estimativa do Número Total de Operações

A multiplicação de matrizes tem complexidade cúbica, $`O(N^3)`$. O número total de operações pode ser estimado da seguinte maneira:

1. **Número de operações por multiplicação de uma linha por uma coluna**:
   - Para cada célula do resultado, calculamos o produto de $`N`$ pares de elementos e somamos os resultados. Isso resulta em $`N`$ multiplicações e $`N-1`$ somas para cada célula.

2. **Número total de células na matriz resultado**:
   - A matriz resultado é $`N \times N`$, portanto contém $`N^2`$ células.

3. **Número total de operações (somas e multiplicações)**:
   - Para cada célula, fazemos $`N`$ multiplicações e $`N-1`$ somas. O número total de operações para a multiplicação das duas matrizes será aproximadamente:
   $`
   N^2 \times (2N - 1)
  `$

4. **Fórmula final**:
   $`
   \text{Operações totais} = N^2 \times (2N - 1)
   `$

### Exemplo para $`N = 1000`$

$`
\text{Operações totais} = 1000^2 \times (2 \times 1000 - 1) = 1.000.000 \times 1999 = 1.999.000.000 \, \text{operações}
`$

Para grandes valores de $`N`$, a fórmula pode ser aproximada por:
$`
\text{Aproximadamente} \approx 2N^3
`$

### Análise Detalhada: Leituras, Escritas, Somas e Multiplicações

#### Operações básicas

1. **Leitura**: Leitura dos elementos das duas matrizes.
2. **Escrita**: Escrita do resultado na matriz de saída.
3. **Soma**: Somar os produtos parciais ao elemento da matriz de saída.
4. **Multiplicação**: Multiplicação de elementos correspondentes das duas matrizes.

#### Número total de operações

1. **Leituras**:
   - Para calcular cada elemento da matriz resultado, precisamos ler $`N`$ elementos de cada matriz. Isso resulta em $`2N^3`$ leituras no total.

2. **Escritas**:
   - Como a matriz resultado tem $`N^2`$ células, fazemos $`N^2`$ operações de escrita.

3. **Multiplicações**:
   - Para cada célula da matriz resultado, fazemos $`N`$ multiplicações. O total de multiplicações é $`N^3`$.

4. **Somas**:
   - Para cada célula, realizamos $`N-1`$ somas. O total de somas é $`N^3 - N^2`$.

### Resumo

| Operação       | Fórmula                | Aproximação para grandes \(N\) |
|----------------|------------------------|--------------------------------|
| Leituras       | $`2N^3`$               | $`2N^3`$                      |
| Escritas       | $`N^2`$                | $`N^2`$                       |
| Multiplicações | $`N^3`$                | $`N^3`$                       |
| Somas          | $`N^3 - N^2`$          | $`N^3`$                       |

### Exemplo calculo do numero de operações para $`N = 1000`$

1. **Leituras**:
   $`
   2 \times 1000^3 = 2 \times 1.000.000.000 = 2.000.000.000 \, \text{leituras}
   `$

2. **Escritas**:
   $`
   1000^2 = 1.000.000 \, \text{escritas}
   `$

3. **Multiplicações**:
   $`
   1000^3 = 1.000.000.000 \, \text{multiplicações}
   `$

4. **Somas**:
   $`
   1000^3 - 1000^2 = 1.000.000.000 - 1.000.000 = 999.000.000 \, \text{somas}
   `$

---

## Relação com os benchmarks

Nos gráficos gerados pelo script `plot_benchmarks.py`, a curva de referência $`(N^3)`$ aparece como linha pontilhada, representando essa complexidade teórica.  
Os resultados experimentais devem se aproximar (em escala) desse crescimento.

---
