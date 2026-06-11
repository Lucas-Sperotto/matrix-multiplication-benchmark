# Diagramas de Execucao e Arquitetura

Este documento descreve os fluxos da branch `tcc-bcc-marcos` do benchmark de
multiplicacao de matrizes.

Os diagramas usam Mermaid. No GitHub, eles sao renderizados automaticamente em
arquivos Markdown.

## Escopo da Branch

- Orquestradores: `run_all.sh` e `run_all.ps1`
- Benchmarks principais: C, C++, Java e Python em `src/`
- Gerador de graficos: `src/plot_benchmarks.py`
- Coleta de sistema Linux/WSL: `src/gen_sysinfo_md.sh`
- Saidas por execucao: `out/<run_id>/`
- Variantes/experimentos tambem estao em `src/`: Rust, Julia, Elixir, BLAS e `teste.py`

Nesta branch, os benchmarks principais ainda escrevem os CSVs na raiz do
repositorio. Depois disso, `run_all.sh` ou `run_all.ps1` move os arquivos para
`out/<run_id>/`.

## Visao Geral

```mermaid
flowchart LR
    Usuario[Usuario] --> Runner[run_all.sh ou run_all.ps1]

    Runner --> Deps[Verificacao de dependencias]
    Runner --> Inputs[Coleta interativa: run_name, B, escala, Npts, M]
    Runner --> Build[Compilacao]
    Runner --> Exec[Execucao dos benchmarks]
    Runner --> Move[Movimentacao dos CSVs]
    Runner --> SysInfo[Coleta de system_info.md]
    Runner --> Plot[Geracao dos graficos]

    Build --> CBin[matriz_c ou matriz_c.exe na raiz]
    Build --> CppBin[matriz_cpp ou matriz_cpp.exe na raiz]
    Build --> JavaClass[src/matriz_java.class]

    Exec --> RootCsvs[(resultado_*.csv na raiz)]
    RootCsvs --> Move
    Move --> OutDir["out/<run_id>/"]
    SysInfo --> OutDir
    Plot --> OutDir
```

## Componentes e Responsabilidades

| Componente | Responsabilidade |
| --- | --- |
| `run_all.sh` | Fluxo Linux/WSL: verifica ou instala dependencias, compila, executa, move CSVs, coleta `system_info.md` e gera graficos. |
| `run_all.ps1` | Fluxo Windows PowerShell: verifica dependencias, compila, executa, move CSVs e gera graficos. |
| `src/matriz_c.c` | Benchmark C; escolhe `resultado_c.csv` ou `resultado_c_O3.csv` pela quantidade de argumentos. |
| `src/matriz_cpp.cpp` | Benchmark C++; escolhe `resultado_cpp.csv` ou `resultado_cpp_O3.csv` pela quantidade de argumentos. |
| `src/matriz_java.java` | Benchmark Java; gera `resultado_java.csv` com colunas `N,TCS,TAM`. |
| `src/matriz_python.py` | Benchmark Python puro; gera `resultado_python.csv` com colunas `N,TCS,TAM`. |
| `src/gen_sysinfo_md.sh` | Gera `system_info.md` em Linux/WSL, com dados do host Windows quando possivel. |
| `src/plot_benchmarks.py` | Le CSVs, normaliza algumas diferencas de coluna e salva graficos PNG. |

## Sequencia Ponta a Ponta

```mermaid
sequenceDiagram
    actor U as Usuario
    participant R as run_all
    participant C as C/C++
    participant J as Java
    participant P as Python
    participant S as gen_sysinfo_md.sh
    participant G as plot_benchmarks.py
    participant O as out/run_id

    U->>R: Executa script e responde perguntas
    R->>R: Verifica dependencias do sistema e pacotes Python
    R->>R: Cria out/run_id/
    R->>C: Compila e executa C -O3
    C-->>R: resultado_c_O3.csv na raiz
    R->>O: Move resultado_c_O3.csv
    R->>C: Compila e executa C
    C-->>R: resultado_c.csv na raiz
    R->>O: Move resultado_c.csv
    R->>C: Compila e executa C++ -O3
    C-->>R: resultado_cpp_O3.csv na raiz
    R->>O: Move resultado_cpp_O3.csv
    R->>C: Compila e executa C++
    C-->>R: resultado_cpp.csv na raiz
    R->>O: Move resultado_cpp.csv
    R->>J: Compila e executa Java
    J-->>R: resultado_java.csv na raiz
    R->>O: Move resultado_java.csv
    R->>P: Executa matriz_python.py
    P-->>R: resultado_python.csv na raiz
    R->>O: Move resultado_python.csv
    R->>S: Linux/WSL gera system_info.md
    S-->>R: system_info.md na raiz
    R->>O: Move system_info.md
    R->>G: Gera graficos a partir de out/run_id/
    G-->>O: grafico_*.png
    R-->>U: Exibe caminho da execucao
```

## Fluxo Linux/WSL

```mermaid
flowchart TD
    A[Inicio: ./run_all.sh] --> B[Verifica gcc, g++, java, javac e python3]
    B --> C[Verifica pandas, matplotlib e psutil]
    C --> D{Dependencia ausente?}
    D -- Sim --> E[Tenta instalar com apt ou pip]
    D -- Nao --> F[Prossegue]
    E --> F
    F --> G[Solicita RUN_NAME]
    G --> H[Cria out/RUN_NAME/]
    H --> I[Solicita B, escala, Npts e M]
    I --> J[Compila C com -O3]
    J --> K[Executa C -O3 com argumento extra -O3]
    K --> L[Move resultado_c_O3.csv]
    L --> M[Compila e executa C sem -O3]
    M --> N[Move resultado_c.csv]
    N --> O[Compila e executa C++ -O3]
    O --> P[Move resultado_cpp_O3.csv]
    P --> Q[Compila e executa C++ sem -O3]
    Q --> R[Move resultado_cpp.csv]
    R --> S[Compila e executa Java]
    S --> T[Move resultado_java.csv]
    T --> U[Executa Python]
    U --> V[Move resultado_python.csv]
    V --> W[Executa src/gen_sysinfo_md.sh]
    W --> X[Move system_info.md]
    X --> Y[Executa src/plot_benchmarks.py]
    Y --> Z[Fim]
```

## Fluxo Windows PowerShell

```mermaid
flowchart TD
    A["Inicio: .\run_all.ps1"] --> B[Verifica gcc, g++, java, javac e Python]
    B --> C[Verifica pandas, matplotlib e psutil]
    C --> D{Dependencia critica ausente?}
    D -- Sim --> E[Avisa o usuario]
    D -- Nao --> F[Prossegue]
    E --> F
    F --> G[Solicita RUN_NAME]
    G --> H[Cria out/RUN_NAME/]
    H --> I[Solicita B, escala, Npts e M]
    I --> J[Compila C -O3 para matriz_c.exe]
    J --> K[Executa C -O3]
    K --> L[Move resultado_c_O3.csv]
    L --> M[Compila e executa C sem -O3]
    M --> N[Move resultado_c.csv]
    N --> O[Compila e executa C++ -O3]
    O --> P[Move resultado_cpp_O3.csv]
    P --> Q[Compila e executa C++ sem -O3]
    Q --> R[Move resultado_cpp.csv]
    R --> S[Compila e executa Java]
    S --> T[Move resultado_java.csv]
    T --> U[Executa Python]
    U --> V[Move resultado_python.csv]
    V --> W{system_info.md existe na raiz?}
    W -- Sim --> X[Move system_info.md]
    W -- Nao --> Y[Segue sem relatorio de sistema]
    X --> Z[Executa src/plot_benchmarks.py]
    Y --> Z
    Z --> AA[Fim]
```

## Contrato dos Benchmarks Principais

Os executaveis principais recebem:

```text
B Npts M escala
```

C e C++ recebem um quinto argumento opcional usado pelos scripts para selecionar
o nome de saida da versao `-O3`:

```text
B Npts M escala "-O3"
```

| Argumento | Significado |
| --- | --- |
| `B` | Maior valor de `N` a ser gerado. |
| `Npts` | Quantidade de pontos entre `100` e `B`. |
| `M` | Quantidade de repeticoes para calcular a media. |
| `escala` | `0` para logaritmica, `1` para linear. |
| quinto argumento | Apenas C/C++; quando presente, muda o arquivo para `*_O3.csv`. |

## Formatos de CSV na Branch

```mermaid
flowchart LR
    C[C e C++] --> CTLM["N,TCS,TAM,TLM"]
    Java[Java] --> JTAM["N,TCS,TAM"]
    Python[Python] --> PTAM["N,TCS,TAM"]
    CTLM --> Plot[plot_benchmarks.py]
    JTAM --> Plot
    PTAM --> Plot
    Plot --> TDM["Normaliza TLM para TDM quando TDM nao existe"]
    Plot --> Graficos[grafico_*.png]
```

Observacoes:

- `TCS`: tempo de calculo da multiplicacao.
- `TAM`: tempo de alocacao e inicializacao.
- `TLM`: tempo de liberacao de memoria em C/C++; equivale ao conceito atual de `TDM`.
- Java e Python nao registram coluna de liberacao/desalocacao nessa branch.
- O plotador so plota uma metrica quando a coluna existe ou foi normalizada.

## Ciclo Interno de um Benchmark

```mermaid
flowchart TD
    A[main] --> B[Abre CSV de saida na raiz]
    B --> C[Le B, Npts, M e escala]
    C --> D{escala == 1?}
    D -->|Sim| E[Gera pontos lineares]
    D -->|Nao| F[Gera pontos logaritmicos]
    E --> G[Percorre lista de N]
    F --> G
    G --> H{Ainda ha N?}
    H -- Nao --> Z[Fecha arquivo e termina]
    H -- Sim --> I[Zera acumuladores de tempo]
    I --> J{m menor ou igual a M?}
    J -- Sim --> K[Aloca e inicializa matrizes]
    K --> L[Multiplica mat1 x mat2]
    L --> M[Verifica resultado completo]
    M --> N[Libera memoria quando aplicavel]
    N --> O[Acumula tempos]
    O --> J
    J -- Nao --> P[Calcula media dos tempos]
    P --> Q[Grava linha no CSV]
    Q --> H
```

## Detalhe da Repeticao Cronometrada

```mermaid
flowchart TD
    A[Repeticao m] --> B[Inicio TAM]
    B --> C[Aloca mat1, mat2 e res]
    C --> D[Inicializa mat1 com i + j]
    D --> E[Inicializa mat2 como identidade]
    E --> F[Fim TAM]
    F --> G[Inicio TCS]
    G --> H[Executa tres lacos de multiplicacao]
    H --> I[Fim TCS]
    I --> J[Verifica todas as celulas do resultado]
    J --> K{Resultado valido?}
    K -- Nao --> L[Imprime erro]
    K -- Sim --> M[Continua]
    L --> M
    M --> N[Inicio TLM/TDM quando aplicavel]
    N --> O[Libera memoria manual em C/C++]
    O --> P[Fim TLM/TDM]
    P --> Q[Retorna ao loop de repeticoes]
```

## Geracao dos Pontos de N

```mermaid
flowchart TD
    A[Entrada B, Npts, escala] --> B{escala == 1?}
    B -->|Linear| C["step = (B - 100) / (Npts - 1)"]
    C --> D["N_i = round(100 + step * i)"]
    B -->|Logaritmica| E["ratio = (B / 100)^(1 / (Npts - 1))"]
    E --> F["N_i = round(100 * ratio^i)"]
    D --> G[Lista de N]
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
    E -- Sim --> G["res[i,j] = 0"]
    G --> H[k = 0]
    H --> I{k menor que N?}
    I -- Sim --> J["res[i,j] += mat1[i,k] * mat2[k,j]"]
    J --> K[k++]
    K --> I
    I -- Nao --> L[j++]
    L --> E
```

## Fluxo de Dados e Artefatos

```mermaid
flowchart LR
    subgraph Entrada[Entrada interativa]
        RunName[RUN_NAME]
        Params[B, escala, Npts, M]
    end

    subgraph Raiz[Raiz do repositorio]
        Exe[matriz_c, matriz_cpp ou .exe]
        Class[src/matriz_java.class]
        TmpCsv[resultado_*.csv temporarios]
        TmpSys[system_info.md temporario]
    end

    subgraph Out["out/<run_id>/"]
        Csvs[resultado_c.csv<br/>resultado_c_O3.csv<br/>resultado_cpp.csv<br/>resultado_cpp_O3.csv<br/>resultado_java.csv<br/>resultado_python.csv]
        Sys[system_info.md quando gerado]
        Graphs[grafico_*.png]
    end

    Params --> Exe
    Params --> Class
    Exe --> TmpCsv
    Class --> TmpCsv
    TmpCsv --> Csvs
    TmpSys --> Sys
    Csvs --> Graphs
    RunName --> Out
```

## Geracao de Graficos

```mermaid
flowchart TD
    A[plot_benchmarks.py out_dir] --> B[Mapeia arquivos CSV conhecidos]
    B --> C[Le CSVs existentes com pandas]
    C --> D[Normaliza nomes das colunas]
    D --> E{Existe TDM?}
    E -- Sim --> F[Usa TDM]
    E -- Nao --> G{Existe TLM?}
    G -- Sim --> H[Copia TLM para TDM]
    G -- Nao --> I[Serie nao possui desalocacao]
    F --> J[Detecta coluna N]
    H --> J
    I --> J
    J --> K[Para cada metrica: TCS, TAM, TDM]
    K --> L[Grafico todas as linguagens]
    K --> M[Grafico C vs C++ preferindo O3]
    K --> N[Grafico C e C++ com e sem O3]
    K --> O[Grafico todas exceto Python]
    L --> P[Salva PNG em out_dir]
    M --> P
    N --> P
    O --> P
```

## Coleta de Informacoes de Sistema

```mermaid
flowchart TD
    A[src/gen_sysinfo_md.sh] --> B[Detecta Linux ou WSL]
    B --> C[Coleta kernel, distro e lscpu]
    C --> D[Coleta memoria via /proc/meminfo]
    D --> E{WSL com powershell.exe?}
    E -- Sim --> F[Coleta CPU, RAM, Windows e wsl --status do host]
    E -- Nao --> G[Usa apenas dados Linux/WSL]
    F --> H[Escreve system_info.md]
    G --> H
```

## Estados de uma Execucao

```mermaid
stateDiagram-v2
    [*] --> VerificandoDependencias
    VerificandoDependencias --> ColetandoParametros
    ColetandoParametros --> Compilando
    Compilando --> Executando
    Executando --> MovendoCSVs
    MovendoCSVs --> ColetandoSistema
    ColetandoSistema --> GerandoGraficos
    GerandoGraficos --> Concluida
    VerificandoDependencias --> Falha: dependencia critica ausente
    Compilando --> Falha: erro de compilacao
    Executando --> Falha: erro no benchmark
    MovendoCSVs --> Falha: CSV ausente
    GerandoGraficos --> Falha: erro no pandas ou matplotlib
    Concluida --> [*]
    Falha --> [*]
```

## Integracao de Nova Linguagem

```mermaid
flowchart TD
    A[Novo benchmark em src/] --> B[Receber B, Npts, M e escala]
    B --> C[Gerar pontos de N com escala linear ou logaritmica]
    C --> D[Medir TCS e TAM]
    D --> E[Registrar desalocacao como TDM ou TLM, se existir]
    E --> F["Salvar CSV com nome resultado_<linguagem>.csv"]
    F --> G[Atualizar run_all.sh]
    F --> H[Atualizar run_all.ps1]
    G --> I[Atualizar mapa files em plot_benchmarks.py]
    H --> I
    I --> J[Executar um teste pequeno]
    J --> K["Conferir graficos em out/<run_id>/"]
```

## Pontos de Atencao Metodologica

- Nao ha rodada de warm-up separada nessa branch; todas as `M` repeticoes entram na media.
- C e C++ usam `clock()` e matrizes como ponteiros para ponteiros, nao buffers planos.
- Java usa `int[][]`, que tambem e um array de arrays.
- Python usa listas de listas e depende de `psutil`, embora o uso de memoria esteja comentado na saida.
- A verificacao do resultado percorre a matriz inteira, o que adiciona trabalho fora do `TCS`.
- O segundo operando e a matriz identidade, entao o resultado esperado e `i + j`.
- `run_all.sh` tenta instalar dependencias automaticamente com `sudo apt`, o que pode pedir senha.
- Nao ha validador automatico nesta branch; a verificacao final e a existencia dos CSVs e PNGs em `out/<run_id>/`.
