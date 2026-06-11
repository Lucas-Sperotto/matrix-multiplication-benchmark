# Diagramas de Execucao e Arquitetura

Este documento descreve os fluxos do benchmark publicavel de multiplicacao de matrizes:
C, C++, Java e Python executados por `run_all.sh` ou `run_all.ps1`.

Os diagramas usam Mermaid. No GitHub, eles sao renderizados automaticamente em arquivos Markdown.

## Escopo do Fluxo Publicavel

- Codigo-fonte principal: `src/`
- Orquestradores: `run_all.sh` e `run_all.ps1`
- Scripts auxiliares: `scripts/`
- Saida padrao de cada execucao: `out/<run_id>/`
- Experimentos em `experiments/` ainda nao fazem parte do fluxo publicavel.

## Visao Geral

```mermaid
flowchart LR
    Usuario[Usuario] --> Runner[run_all.sh ou run_all.ps1]

    Runner --> Parametros[Entrada: run_name, B, Npts, M, escala]
    Runner --> Deps[Checagem de dependencias]
    Runner --> Build[Compilacao]
    Runner --> Exec[Execucao dos benchmarks]
    Runner --> Meta[Coleta de metadados]
    Runner --> Plot[Geracao de graficos]
    Runner --> Val[Validacao]

    Build --> CBin[build/linux ou build/windows: matriz_c]
    Build --> CO3Bin[build/linux ou build/windows: matriz_c_O3]
    Build --> CppBin[build/linux ou build/windows: matriz_cpp]
    Build --> CppO3Bin[build/linux ou build/windows: matriz_cpp_O3]
    Build --> JavaClass[build/java: matriz_java.class]

    Exec --> Csvs[(resultado_*.csv)]
    Meta --> SysInfo[(system_info.md e system_info.json)]
    Meta --> Manifest[(run_manifest.json)]
    Plot --> Pngs[(grafico_*.png)]
    Val --> Status[Execucao aprovada ou erro detalhado]

    Csvs --> OutDir["out/<run_id>/"]
    SysInfo --> OutDir
    Manifest --> OutDir
    Pngs --> OutDir
```

## Componentes e Responsabilidades

| Componente | Responsabilidade |
| --- | --- |
| `run_all.sh` | Orquestra execucao Linux/WSL: valida parametros, compila, executa, coleta sistema, gera manifest, plota e valida. |
| `run_all.ps1` | Orquestra execucao Windows PowerShell com o mesmo contrato do fluxo Linux/WSL. |
| `src/matriz_c.c` | Benchmark C, incluindo versao compilada normal e `-O3`. |
| `src/matriz_cpp.cpp` | Benchmark C++, incluindo versao compilada normal e `-O3`. |
| `src/matriz_java.java` | Benchmark Java com `int[][]`, compilado para `build/java/`. |
| `src/matriz_python.py` | Benchmark Python puro. |
| `src/plot_benchmarks.py` | Le CSVs de uma execucao e gera graficos PNG para TCS, TAM e TDM. |
| `scripts/gen_sysinfo_md.sh` | Gera `system_info.md` e `system_info.json` em Linux/WSL. |
| `scripts/validate_run.py` | Valida CSVs, metadados JSON/MD e existencia dos graficos. |

## Sequencia Ponta a Ponta

```mermaid
sequenceDiagram
    actor U as Usuario
    participant R as run_all
    participant B as build
    participant C as Benchmarks
    participant S as Sistema
    participant P as plot_benchmarks.py
    participant V as validate_run.py
    participant O as out/run_id/

    U->>R: Informa parametros ou usa modo interativo
    R->>R: Normaliza run_name e valida B, Npts, M, escala
    R->>R: Confere gcc, g++, Java, Python e matplotlib
    R->>B: Compila C, C -O3, C++, C++ -O3 e Java

    loop Para cada variante
        R->>C: Executa com B Npts M escala out_csv
        C->>C: Warm-up por N
        C->>C: M repeticoes cronometradas por N
        C->>O: Grava resultado_*.csv
    end

    R->>S: Coleta informacoes de sistema
    S->>O: Grava system_info.md e system_info.json
    R->>O: Grava run_manifest.json
    R->>P: Gera graficos a partir dos CSVs
    P->>O: Grava grafico_*.png
    R->>V: Valida out/run_id/
    V->>O: Le CSVs, JSONs, MD e PNGs
    V-->>R: Sucesso ou erro
    R-->>U: Caminho final da execucao
```

## Fluxo do Orquestrador Linux/WSL

```mermaid
flowchart TD
    A[Inicio: ./run_all.sh] --> B{Modo batch?}
    B -- Nao --> C[Solicita run_name, B, escala, Npts e M]
    B -- Sim --> D[Le argumentos CLI]
    C --> E[Define run_name por timestamp se vazio]
    D --> E
    E --> F{Parametros obrigatorios presentes?}
    F -- Nao --> F1[Mostra uso e encerra]
    F -- Sim --> G[Valida intervalos: B, Npts, M, escala]
    G --> H[Checa gcc, g++, javac, java e python3]
    H --> I[Checa matplotlib com MPLCONFIGDIR em .cache/matplotlib]
    I --> J["Cria out/<run_id>/, build/linux/ e build/java/"]
    J --> K[Compila C e C -O3]
    K --> L[Compila C++ e C++ -O3]
    L --> M[Compila Java]
    M --> N[Executa 6 benchmarks]
    N --> O[Coleta system_info.md e system_info.json]
    O --> P[Gera run_manifest.json]
    P --> Q[Gera graficos PNG]
    Q --> R[Valida execucao]
    R --> S["Finaliza com caminho de out/<run_id>/"]
```

## Fluxo do Orquestrador Windows PowerShell

```mermaid
flowchart TD
    A["Inicio: .\run_all.ps1"] --> B[Configura UTF-8, StrictMode e Stop on error]
    B --> C{Parametro -Batch foi usado?}
    C -- Nao --> D[Solicita run_name, B, escala, Npts e M]
    C -- Sim --> E[Usa parametros informados na CLI]
    D --> F[Define run_name por timestamp se vazio]
    E --> F
    F --> G[Valida B, Npts, M e Escala]
    G --> H[Checa gcc, g++, java, javac e python]
    H --> I[Checa matplotlib]
    I --> J["Cria out/<run_id>/, build/windows/ e build/java/"]
    J --> K[Compila C e C -O3 para .exe]
    K --> L[Compila C++ e C++ -O3 para .exe]
    L --> M[Compila Java]
    M --> N[Executa C, C -O3, C++, C++ -O3, Java e Python]
    N --> O[Gera system_info.md e system_info.json via PowerShell]
    O --> P[Gera run_manifest.json]
    P --> Q[Executa plot_benchmarks.py]
    Q --> R[Executa validate_run.py]
    R --> S["Finaliza com caminho de out/<run_id>/"]
```

## Contrato dos Benchmarks

Todos os benchmarks principais recebem os mesmos argumentos:

```text
B Npts M escala out_csv
```

| Argumento | Significado | Regras atuais |
| --- | --- | --- |
| `B` | Maior valor de `N` | Inteiro entre `100` e `100000` |
| `Npts` | Quantidade de pontos de medicao | Inteiro entre `2` e `10000` |
| `M` | Repeticoes cronometradas para media | Inteiro entre `1` e `100000` |
| `escala` | Geracao dos pontos de `N` | `0` logaritmica, `1` linear |
| `out_csv` | Caminho do CSV de saida | Arquivo dentro de `out/<run_id>/` |

Saida CSV comum:

```csv
N,TCS,TAM,TDM
```

| Coluna | Significado |
| --- | --- |
| `N` | Dimensao da matriz quadrada `N x N` |
| `TCS` | Tempo medio de calculo da multiplicacao |
| `TAM` | Tempo medio de alocacao e inicializacao das matrizes |
| `TDM` | Tempo medio de desalocacao; em Java e Python e `0.0` |

## Ciclo Interno de um Benchmark

```mermaid
flowchart TD
    A[main] --> B[Valida argc e converte B, Npts, M, escala]
    B --> C[Gera lista de N com make_points]
    C --> D[Abre out_csv]
    D --> E[Escreve cabecalho N,TCS,TAM,TDM]
    E --> F{Ainda ha N?}
    F -- Nao --> Z[Fecha CSV e encerra]
    F -- Sim --> G[Seleciona N atual]
    G --> H[Warm-up: run_once sem entrar na media final]
    H --> I[Zera acumuladores de TAM, TCS e TDM]
    I --> J{m menor que M?}
    J -- Sim --> K[run_once cronometrado]
    K --> L[Acumula tempos]
    L --> J
    J -- Nao --> M[Calcula medias: tempo acumulado / M]
    M --> N[Grava linha no CSV]
    N --> F
```

## Detalhe de `run_once`

```mermaid
flowchart TD
    A[run_once N] --> B[Checa tamanho da matriz]
    B --> C[TAM inicio]
    C --> D[Aloca mat1, mat2 e res]
    D --> E[Inicializa mat1 com i + j]
    E --> F[Inicializa mat2 como identidade]
    F --> G[TAM fim]
    G --> H[TCS inicio]
    H --> I[Multiplica mat1 x mat2]
    I --> J[TCS fim]
    J --> K[Verifica amostras do resultado]
    K --> L{Resultado valido?}
    L -- Nao --> X[Erro e encerramento]
    L -- Sim --> M[TDM inicio]
    M --> N[Libera memoria quando aplicavel]
    N --> O[TDM fim]
    O --> P[Retorna tempos]
```

Observacoes:

- Em C e C++, as matrizes principais usam buffers contiguos em memoria.
- Em Java, a matriz e `int[][]`, ou seja, um array de arrays.
- Em Python, as matrizes sao listas de listas.
- Como `mat2` e identidade, o resultado esperado e igual a `mat1`; por isso a amostra verificada deve retornar `i + j`.

## Geracao dos Pontos de N

```mermaid
flowchart TD
    A[make_points B, Npts, escala] --> B{escala == 1?}
    B -->|Sim: linear| C["step = (B - 100) / (Npts - 1)"]
    C --> D["N_i = round(100 + step * i)"]
    B -->|Nao: logaritmica| E["ratio = (B / 100)^(1 / (Npts - 1))"]
    E --> F["N_i = round(100 * ratio^i)"]
    D --> G[Lista com Npts valores]
    F --> G
```

## Algoritmo de Multiplicacao

```mermaid
flowchart TD
    A[Inicio multiply] --> B[i = 0]
    B --> C{i menor que N?}
    C -- Nao --> Z[Fim]
    C -- Sim --> D[j = 0]
    D --> E{j menor que N?}
    E -- Nao --> F[i++]
    F --> C
    E -- Sim --> G[sum = 0]
    G --> H[k = 0]
    H --> I{k menor que N?}
    I -- Sim --> J["sum += mat1[i,k] * mat2[k,j]"]
    J --> K[k++]
    K --> I
    I -- Nao --> L["res[i,j] = sum"]
    L --> M[j++]
    M --> E
```

## Fluxo de Dados e Artefatos

```mermaid
flowchart LR
    subgraph Inputs[Entradas]
        Params[Parametros: B, Npts, M, escala]
        Sources[src/matriz_*.c cpp java py]
    end

    subgraph Build[Artefatos de compilacao]
        BLinux[build/linux/]
        BWin[build/windows/]
        BJava[build/java/]
    end

    subgraph Out["out/<run_id>/"]
        Csv[resultado_c.csv<br/>resultado_c_O3.csv<br/>resultado_cpp.csv<br/>resultado_cpp_O3.csv<br/>resultado_java.csv<br/>resultado_python.csv]
        Sys[system_info.md<br/>system_info.json]
        Manifest[run_manifest.json]
        Graphs[grafico_*.png]
    end

    Params --> Build
    Sources --> Build
    Build --> Csv
    Params --> Manifest
    Csv --> Graphs
    Csv --> Validate[validate_run.py]
    Sys --> Validate
    Manifest --> Validate
    Graphs --> Validate
```

## Geracao dos Graficos

```mermaid
flowchart TD
    A[plot_benchmarks.py out_dir] --> B[Prepara MPLCONFIGDIR]
    B --> C[Carrega matplotlib com backend Agg]
    C --> D[Mapeia CSVs esperados por linguagem]
    D --> E[Aplica exclusoes via --exclude, se houver]
    E --> F[Le CSVs existentes]
    F --> G{Ha dados validos?}
    G -- Nao --> X[Erro: nenhum CSV valido encontrado]
    G -- Sim --> H[Para cada metrica: TCS, TAM, TDM]
    H --> I[Grafico todas as linguagens]
    H --> J[Grafico C vs C++ preferindo -O3 quando disponivel]
    H --> K[Grafico C e C++ com e sem -O3]
    H --> L[Grafico C vs C++ sem -O3]
    H --> M[Grafico todas as linguagens exceto Python]
    I --> N[Salva PNG em out_dir]
    J --> N
    K --> N
    L --> N
    M --> N
```

## Validacao da Execucao

```mermaid
flowchart TD
    A["validate_run.py out/<run_id>"] --> B{Diretorio existe?}
    B -- Nao --> X[Erro]
    B -- Sim --> C[Valida CSVs esperados]
    C --> D[Confere cabecalho N,TCS,TAM,TDM]
    D --> E[Confere linhas numericas]
    E --> F[Confere N positivo e monotonicamente nao decrescente]
    F --> G[Confere tempos nao negativos e finitos]
    G --> H[Confere system_info.md nao vazio]
    H --> I[Valida system_info.json com generated_at]
    I --> J[Valida run_manifest.json com chaves obrigatorias]
    J --> K{Existe ao menos um grafico_*.png?}
    K -- Nao --> X
    K -- Sim --> L[Validacao concluida com sucesso]
```

## Estrutura do Diretorio de Saida

```mermaid
flowchart TD
    A["out/<run_id>/"] --> B[CSVs de resultado]
    A --> C[Metadados]
    A --> D[Graficos]

    B --> B1[resultado_c.csv]
    B --> B2[resultado_c_O3.csv]
    B --> B3[resultado_cpp.csv]
    B --> B4[resultado_cpp_O3.csv]
    B --> B5[resultado_java.csv]
    B --> B6[resultado_python.csv]

    C --> C1[system_info.md]
    C --> C2[system_info.json]
    C --> C3[run_manifest.json]

    D --> D1[grafico_TCS_*.png]
    D --> D2[grafico_TAM_*.png]
    D --> D3[grafico_TDM_*.png]
```

## Manifest da Execucao

```mermaid
flowchart TD
    A[run_manifest.json] --> B[run_id]
    A --> C[generated_at UTC]
    A --> D[commit_hash]
    A --> E[system]
    A --> F[parameters]
    A --> G[tools]
    A --> H[languages]

    E --> E1[platform]
    E --> E2[machine]
    E --> E3[python]

    F --> F1[B]
    F --> F2[Npts]
    F --> F3[M]
    F --> F4[escala]

    G --> G1[gcc]
    G --> G2[g++]
    G --> G3[java]
    G --> G4[javac]
    G --> G5[python]

    H --> H1[name]
    H --> H2[flags]
    H --> H3[output]
```

## Dependencias de Ambiente

```mermaid
flowchart LR
    Runner[run_all] --> GCC[gcc]
    Runner --> GPP[g++]
    Runner --> JDK[javac]
    Runner --> JVM[java]
    Runner --> Python[python3 ou python]
    Python --> Matplotlib[matplotlib]

    GCC --> CBuild[C e C -O3]
    GPP --> CppBuild[C++ e C++ -O3]
    JDK --> JavaBuild[matriz_java.class]
    JVM --> JavaRun[execucao Java]
    Python --> PyRun[benchmark Python]
    Python --> PlotRun[plot_benchmarks.py]
    Python --> ValRun[validate_run.py]
```

## Estados de uma Execucao

```mermaid
stateDiagram-v2
    [*] --> Configurando
    Configurando --> Compilando: parametros e dependencias validos
    Configurando --> Falha: parametro/dependencia invalido
    Compilando --> Executando: build concluido
    Compilando --> Falha: erro de compilacao
    Executando --> ColetandoMetadados: CSVs gerados
    Executando --> Falha: erro em benchmark ou verificacao
    ColetandoMetadados --> GerandoGraficos: system_info e manifest gerados
    GerandoGraficos --> Validando: PNGs gerados
    GerandoGraficos --> Falha: erro no matplotlib ou CSV invalido
    Validando --> Concluida: validate_run.py aprovado
    Validando --> Falha: artefato ausente ou invalido
    Concluida --> [*]
    Falha --> [*]
```

## Integracao de Nova Linguagem ao Fluxo Principal

Use este roteiro quando um experimento for promovido para `src/`.

```mermaid
flowchart TD
    A[Novo benchmark em src/] --> B[Implementar contrato CLI comum]
    B --> C[Gerar CSV com cabecalho N,TCS,TAM,TDM]
    C --> D[Adicionar warm-up e M repeticoes]
    D --> E[Adicionar verificacao do resultado]
    E --> F[Atualizar run_all.sh]
    E --> G[Atualizar run_all.ps1]
    F --> H[Adicionar entrada no run_manifest.json]
    G --> H
    H --> I[Atualizar FILES em plot_benchmarks.py]
    I --> J[Atualizar EXPECTED_CSVS em validate_run.py]
    J --> K["Executar smoke test em out/<run_id>/"]
    K --> L[Documentar diferencas metodologicas relevantes]
```

## Pontos de Atencao Metodologica

- `TAM` mede alocacao e inicializacao juntas.
- `TCS` mede apenas a multiplicacao.
- `TDM` mede liberacao explicita quando a linguagem permite; Java e Python registram `0.0`.
- O warm-up nao entra na media final.
- `M` reduz ruido por media aritmetica simples.
- O algoritmo principal e cubico, com tres lacos aninhados.
- A matriz identidade como segundo operando torna a verificacao simples sem alterar a complexidade do calculo.
- Comparacoes entre linguagens devem considerar layout de memoria, otimizacoes do compilador, JIT do Java e overhead do interpretador Python.
