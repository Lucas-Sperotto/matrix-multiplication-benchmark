# Diagramas de Execucao e Arquitetura

Este documento descreve os fluxos do benchmark publicavel de multiplicacao de matrizes:
C, C++, Java e Python formam o nucleo; Rust, Julia e Elixir entram opcionalmente por flags de `run_all.sh` ou `run_all.ps1`.

Os diagramas usam Mermaid. No GitHub, eles sao renderizados automaticamente em arquivos Markdown.

## Escopo do Fluxo Publicavel

- Codigo-fonte principal: `src/`
- Orquestradores: `run_all.sh` e `run_all.ps1`
- Scripts auxiliares: `scripts/`
- Testes de contrato e corretude: `tests/`
- Saida padrao de cada execucao: `out/<run_id>/`
- Experimentos que permanecem em `experiments/`, como BLAS, ainda nao fazem parte do fluxo publicavel.

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

    Csvs --> Staging["out/.running-<run_id>/"]
    SysInfo --> Staging
    Manifest --> Staging
    Pngs --> Staging
    Status -- Aprovada --> Promote[Promocao]
    Staging --> Promote
    Promote --> OutDir["out/<run_id>/"]
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
| `src/matriz_rust.rs` | Benchmark Rust opcional, compilado quando `--with-rust`/`-WithRust` e usado. |
| `src/matriz_Julia.jl` | Benchmark Julia opcional, executado quando `--with-julia`/`-WithJulia` e usado. |
| `src/matriz_multiplication.exs` | Benchmark Elixir opcional, executado quando `--with-elixir`/`-WithElixir` e usado. |
| `src/plot_benchmarks.py` | Le CSVs de uma execucao e gera graficos PNG para TCS, TAM e TDM. |
| `scripts/gen_sysinfo_md.sh` | Gera `system_info.md` e `system_info.json` em Linux/WSL. |
| `scripts/validate_run.py` | Valida CSVs, metadados JSON/MD e existencia dos graficos. |
| `tests/` | Reune regressões de contrato e testes pequenos de corretude nao identidade. |

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
    participant O as out/.running-run_id/ (staging)

    U->>R: Informa parametros ou usa modo interativo
    R->>R: Normaliza run_name e valida B, Npts, M, escala
    R->>R: Confere gcc, g++, Java, Python e matplotlib
    R->>O: Confere colisoes e cria staging
    R->>B: Compila C, C -O3, C++, C++ -O3 e Java

    loop Para cada variante central
        R->>C: Executa com B Npts M escala out_csv
        C->>C: Warm-up por N
        C->>C: M repeticoes cronometradas por N
        C->>O: Grava resultado_*.csv
    end

    opt Flags de linguagens extras
        R->>R: Confere rustc, julia e/ou elixir no ponto de uso
        R->>B: Compila Rust, se solicitado
        R->>C: Executa cada extra solicitada
        C->>O: Grava o respectivo resultado_*.csv
    end

    R->>S: Coleta informacoes de sistema
    S->>O: Grava system_info.md e system_info.json
    R->>O: Grava run_manifest.json
    R->>P: Gera graficos a partir dos CSVs
    P->>O: Grava grafico_*.png
    R->>V: Valida out/.running-run_id/
    V->>O: Le CSVs, JSONs, MD e PNGs
    V-->>R: Sucesso ou erro
    alt Sucesso
        R->>O: Promove (rename) para out/run_id/
        R-->>U: Caminho final: out/run_id/
    else Erro depois da criacao do staging
        R-->>U: Aborta; out/.running-run_id/ preservado, out/run_id/ nunca criado
    end
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
    I --> I1{"out/<run_id>/ ja existe, mesmo vazio, ou out/.running-<run_id>/ ja existe?"}
    I1 -- Sim --> I2[Aborta: nao sobrescreve execucao completa nem staging incompleto]
    I1 -- Nao --> J["Cria out/.running-<run_id>/ (staging), build/linux/ e build/java/"]
    J --> K[Compila C e C -O3]
    K --> L[Compila C++ e C++ -O3]
    L --> M[Compila Java]
    M --> N[Executa 6 benchmarks centrais]
    N --> N1{Ha flags de extras?}
    N1 -- Sim --> N2[Checa toolchains no ponto de uso e compila/executa extras]
    N1 -- Nao --> O[Coleta system_info.md e system_info.json]
    N2 --> O
    O --> P["Gera run_manifest.json (inclui java_gc)"]
    P --> Q[Gera graficos PNG]
    Q --> R[Valida execucao]
    R -- Falha --> R1["Aborta; se ja criado, staging e preservado para diagnostico; destino final nunca e criado"]
    R -- Sucesso --> T["Promove: mv out/.running-<run_id>/ para out/<run_id>/"]
    T --> S["Finaliza com caminho de out/<run_id>/"]
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
    I --> I1{"out/<run_id>/ ja existe, mesmo vazio, ou out/.running-<run_id>/ ja existe?"}
    I1 -- Sim --> I2[Aborta: nao sobrescreve execucao completa nem staging incompleto]
    I1 -- Nao --> J["Cria out/.running-<run_id>/ (staging), build/windows/ e build/java/"]
    J --> K[Compila C e C -O3 para .exe]
    K --> L[Compila C++ e C++ -O3 para .exe]
    L --> M[Compila Java]
    M --> N[Executa C, C -O3, C++, C++ -O3, Java e Python]
    N --> N1{Ha switches de extras?}
    N1 -- Sim --> N2[Checa toolchains no ponto de uso e compila/executa extras]
    N1 -- Nao --> O[Gera system_info.md e system_info.json via PowerShell]
    N2 --> O
    O --> P["Gera run_manifest.json (inclui java_gc)"]
    P --> Q[Executa plot_benchmarks.py]
    Q --> R[Executa validate_run.py]
    R -- Falha --> R1["Aborta; se ja criado, staging e preservado para diagnostico; destino final nunca e criado"]
    R -- Sucesso --> T["Promove: Move-Item out/.running-<run_id>/ para out/<run_id>/"]
    T --> S["Finaliza com caminho de out/<run_id>/"]
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
| `TDM` | Tempo medio de desalocacao; em Java, Python, Julia e Elixir e `0.0` |

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
    C --> D[Aloca entradas e, quando aplicavel, res]
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
        Csv[resultado_c.csv<br/>resultado_c_O3.csv<br/>resultado_cpp.csv<br/>resultado_cpp_O3.csv<br/>resultado_java.csv<br/>resultado_python.csv<br/>+ resultado_rust/julia/elixir.csv se solicitados]
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
    B -- Sim --> C[Le run_manifest.json e Npts esperado]
    C --> D{"Os 6 CSVs centrais estao declarados no manifesto?"}
    D -- Nao --> X
    D -- Sim --> E{"Algum CSV opcional presente e nao declarado?"}
    E -- Sim --> X
    E -- Nao --> F[Valida cada CSV declarado: cabecalho, linhas numericas, N nao decrescente, tempos finitos e nao negativos, contagem igual a Npts]
    F --> G{"Series de N identicas entre todos os CSVs?"}
    G -- Nao --> X
    G -- Sim --> H[Confere system_info.md nao vazio]
    H --> I[Valida system_info.json com generated_at]
    I --> J{Existe ao menos um grafico_*.png?}
    J -- Nao --> X
    J -- Sim --> K[Validacao concluida com sucesso]
```

O manifesto é a fonte autoritativa para os seis CSVs centrais e os três opcionais reconhecidos: qualquer um deles presente no diretório mas ausente do manifesto invalida a execução, e uma saída declarada mas ausente também invalida. CSVs de nomes arbitrários ainda não são rejeitados pelo validador.

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
    B -.-> B7["resultado_rust.csv (com --with-rust)"]
    B -.-> B8["resultado_julia.csv (com --with-julia)"]
    B -.-> B9["resultado_elixir.csv (com --with-elixir)"]

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
    G -.-> G6["rustc (com --with-rust)"]
    G -.-> G7["julia (com --with-julia)"]
    G -.-> G8["elixir (com --with-elixir)"]

    H --> H1[name]
    H --> H2[flags]
    H --> H3[output]
    H -.-> H4["entrada Rust/Julia/Elixir somente se a flag foi usada e a execucao teve sucesso"]
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
    Configurando --> EmStaging: parametros e dependencias centrais validos, cria out/.running-<run_id>/
    Configurando --> Falha: parametro/dependencia central invalido, ou out/<run_id>/ ou out/.running-<run_id>/ ja existem
    EmStaging --> Compilando
    Compilando --> Executando: build concluido
    Compilando --> FalhaEmStaging: erro de compilacao
    Executando --> ColetandoMetadados: CSVs gerados
    Executando --> FalhaEmStaging: toolchain extra ausente, erro em benchmark ou verificacao
    ColetandoMetadados --> GerandoGraficos: system_info e manifest gerados (inclui java_gc)
    GerandoGraficos --> Validando: PNGs gerados
    GerandoGraficos --> FalhaEmStaging: erro no matplotlib ou CSV invalido
    Validando --> Promovendo: validate_run.py aprovado
    Validando --> FalhaEmStaging: artefato ausente ou invalido
    Promovendo --> Concluida: mv/Move-Item out/.running-<run_id>/ para out/<run_id>/
    Concluida --> [*]
    FalhaEmStaging --> [*]: out/.running-<run_id>/ preservado para diagnostico; out/<run_id>/ nunca criado
    Falha --> [*]
```

## Integracao de Nova Linguagem ao Fluxo Principal

Use este roteiro quando um experimento for promovido para `src/`. Rust, Julia e Elixir seguem este fluxo: sao **opcionais por flag**, nao obrigatorias -- nao entram em `EXPECTED_CSVS` (que permanece só com os 6 nomes centrais), so no manifesto quando a flag correspondente e usada e a execucao tem sucesso.

```mermaid
flowchart TD
    A[Novo benchmark em src/] --> B[Implementar contrato CLI comum]
    B --> C[Gerar CSV com cabecalho N,TCS,TAM,TDM]
    C --> D[Adicionar warm-up e M repeticoes]
    D --> E[Adicionar verificacao do resultado]
    E --> F["Adicionar flag opcional em run_all.sh (--with-X)"]
    E --> G["Adicionar flag opcional em run_all.ps1 (-WithX)"]
    F --> H["Se a flag for usada: detectar toolchain, compilar/executar, abortar tudo se falhar"]
    G --> H
    H --> I["Adicionar entrada em run_manifest.json (languages/tools) somente se a execucao teve sucesso"]
    I --> J["Manter plot_benchmarks.py e validate_run.py compativeis com a serie opcional"]
    J --> K["Executar smoke test com e sem a flag em out/<run_id>/"]
    K --> L[Documentar diferencas metodologicas relevantes]
```

## Pontos de Atencao Metodologica

Resumo rapido; o desenho experimental completo (variaveis, controles, JIT, GC, layout de memoria por linguagem, limitacoes e ameacas a validade) esta em [METHODOLOGY.md](METHODOLOGY.md):

- `TAM` e a janela de alocacao/inicializacao, incluindo `res`, em C, C++, Java, Python, Rust e Julia. Elixir e a unica excecao: por imutabilidade, `res` so existe ao final da construcao.
- `TCS` e a janela de calculo; em Elixir inclui tambem a construcao imutavel de `res` (excecao estrutural, nao de implementacao).
- `TDM` mede uma liberacao provocada em C/C++/Rust; Java, Python, Julia e Elixir registram `0.0` porque o protocolo nao mede a liberacao automatica, nao porque ela seja instantanea.
- O warm-up nao entra na media final.
- `M` reduz ruido por media aritmetica simples; tempos individuais por repeticao nao sao preservados.
- O algoritmo principal e algoritmicamente equivalente, O(N^3), com ordem logica `i,j,k`; representacao e operacoes internas variam por linguagem.
- A matriz identidade como segundo operando torna a verificacao simples sem alterar a complexidade do calculo.
- Comparacoes entre linguagens devem considerar layout de memoria, largura dos inteiros, otimizacoes do compilador, JIT de Java/Julia/BEAM, GC e imutabilidade.
