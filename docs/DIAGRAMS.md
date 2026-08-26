# Diagramas de Execucao e Arquitetura

Este documento descreve os fluxos do benchmark publicavel de multiplicacao de matrizes.
C, C++, Java e Python formam o nucleo. Rust, Julia e Elixir entram opcionalmente por flags de `run_all.sh` ou `run_all.ps1`.

Os diagramas usam Mermaid e foram escritos com sintaxe conservadora para renderizacao direta no GitHub.

## Escopo do Fluxo Publicavel

- Codigo-fonte principal: `src/`
- Orquestradores: `run_all.sh` e `run_all.ps1`
- Scripts auxiliares: `scripts/`
- Testes de contrato e corretude: `tests/`
- Staging de uma execucao: `out/.running-<run_id>/`
- Saida final de uma execucao aprovada: `out/<run_id>/`
- Experimentos em `experiments/`, como BLAS, nao fazem parte do fluxo publicavel.

## Visao Geral

```mermaid
flowchart LR
    Usuario["Usuario"] --> Runner["run_all.sh ou run_all.ps1"]

    Runner --> Parametros["Entrada: run_name, B, Npts, M, escala"]
    Runner --> Deps["Preflight de dependencias"]
    Runner --> Build["Compilacao"]
    Runner --> Exec["Execucao dos benchmarks"]
    Runner --> Meta["Coleta de metadados"]
    Runner --> Plot["Geracao de graficos"]
    Runner --> Val["Validacao"]

    Build --> CBin["C e C -O3"]
    Build --> CppBin["C++ e C++ -O3"]
    Build --> JavaClass["Java"]
    Build -. opcional .-> RustBin["Rust"]

    Exec --> Csvs["resultado_*.csv"]
    Meta --> SysInfo["system_info.md e system_info.json"]
    Meta --> Manifest["run_manifest.json"]
    Plot --> Pngs["grafico_*.png"]

    Csvs --> Staging["out/.running-run_id/"]
    SysInfo --> Staging
    Manifest --> Staging
    Pngs --> Staging
    Staging --> Val
    Val -- aprovada --> Promote["Promocao atomica ou Move-Item"]
    Val -- falha --> Preserve["Staging preservado para diagnostico"]
    Promote --> OutDir["out/run_id/"]
```

## Componentes e Responsabilidades

| Componente | Responsabilidade |
| --- | --- |
| `run_all.sh` | Orquestra Linux/WSL: valida parametros e `run_name`, faz preflight de dependencias, compila, executa, coleta sistema, gera manifesto, plota, valida e promove a execucao. |
| `run_all.ps1` | Orquestra Windows PowerShell com o mesmo contrato e verificacao explicita de codigos de saida de programas nativos. |
| `src/matriz_c.c` | Benchmark C, usado nas variantes normal e `-O3`. |
| `src/matriz_cpp.cpp` | Benchmark C++, usado nas variantes normal e `-O3`. |
| `src/matriz_java.java` | Benchmark Java com `int[][]`. |
| `src/matriz_python.py` | Benchmark Python puro. |
| `src/matriz_rust.rs` | Benchmark Rust opcional, compilado quando solicitado. |
| `src/matriz_Julia.jl` | Benchmark Julia opcional, executado quando solicitado. |
| `src/matriz_multiplication.exs` | Benchmark Elixir opcional, executado quando solicitado. |
| `src/plot_benchmarks.py` | Le os CSVs disponiveis e gera graficos PNG para TCS, TAM e TDM. |
| `scripts/gen_sysinfo_md.sh` | Gera `system_info.md` e `system_info.json` em Linux/WSL. |
| `scripts/validate_run.py` | Valida CSVs, manifesto, metadados e existencia dos graficos. |
| `tests/` | Reune regressões de contrato e testes pequenos de corretude nao identidade. |

## Sequencia Ponta a Ponta

```mermaid
sequenceDiagram
    actor U as Usuario
    participant R as Runner
    participant B as Build
    participant C as Benchmarks
    participant S as Sistema
    participant P as Plot
    participant V as Validador
    participant O as Staging

    U->>R: Informa parametros ou usa modo interativo
    R->>R: Normaliza e valida run_name
    R->>R: Valida B, Npts, M e escala
    R->>R: Confere dependencias centrais e matplotlib
    opt Linguagens extras solicitadas
        R->>R: Confere rustc, julia e ou elixir no preflight
    end
    R->>R: Confere colisao de run_id
    R->>O: Cria out/.running-run_id/
    R->>B: Compila C, C -O3, C++, C++ -O3 e Java

    loop Para cada variante central
        R->>C: Executa com B Npts M escala out_csv
        C->>C: Warm-up por N
        C->>C: M repeticoes medidas por N
        C->>O: Grava resultado CSV
    end

    opt Linguagens extras solicitadas
        R->>B: Compila Rust quando solicitado
        R->>C: Executa cada extra solicitada
        C->>O: Grava o CSV da extra
    end

    R->>S: Coleta informacoes do sistema
    S->>O: Grava system_info
    R->>O: Grava run_manifest.json
    R->>P: Gera graficos
    P->>O: Grava grafico PNG
    R->>V: Valida o staging
    V->>O: Le CSVs, JSON, Markdown e PNG
    V-->>R: Sucesso ou erro

    alt Sucesso
        R->>O: Promove staging para out/run_id/
        R-->>U: Informa o caminho final
    else Erro depois da criacao do staging
        R-->>U: Aborta e preserva o staging para diagnostico
    end
```

## Fluxo do Orquestrador Linux/WSL

```mermaid
flowchart TD
    A["Inicio: ./run_all.sh"] --> B{"Modo batch?"}
    B -- nao --> C["Solicita run_name, B, escala, Npts e M"]
    B -- sim --> D["Le argumentos CLI"]
    C --> E["Define run_name por timestamp se vazio"]
    D --> E
    E --> F{"Parametros obrigatorios presentes?"}
    F -- nao --> F1["Mostra uso e encerra"]
    F -- sim --> G["Valida run_name e intervalos numericos"]
    G --> H["Checa gcc, g++, javac, java e python3"]
    H --> I["Checa matplotlib"]
    I --> X{"Alguma extra foi solicitada?"}
    X -- sim --> X1["Preflight de rustc, julia e ou elixir solicitados"]
    X -- nao --> I1{"Destino final ou staging ja existem?"}
    X1 --> I1
    I1 -- sim --> I2["Aborta sem criar novo staging"]
    I1 -- nao --> J["Cria staging e diretorios de build"]
    J --> K["Compila C e C -O3"]
    K --> L["Compila C++ e C++ -O3"]
    L --> M["Compila Java"]
    M --> N["Executa 6 variantes centrais"]
    N --> N1{"Ha extras solicitadas?"}
    N1 -- sim --> N2["Compila Rust quando preciso e executa extras"]
    N1 -- nao --> O["Coleta system_info"]
    N2 --> O
    O --> P["Gera run_manifest.json"]
    P --> Q["Gera graficos PNG"]
    Q --> R["Executa validate_run.py"]
    R -- falha --> R1["Aborta e preserva staging para diagnostico"]
    R -- sucesso --> T["Move staging para out/run_id/"]
    T --> S["Finaliza com caminho da execucao"]
```

## Fluxo do Orquestrador Windows PowerShell

```mermaid
flowchart TD
    A["Inicio: run_all.ps1"] --> B["Configura UTF-8, StrictMode e Stop"]
    B --> C{"Parametro Batch foi usado?"}
    C -- nao --> D["Solicita run_name, B, escala, Npts e M"]
    C -- sim --> E["Usa parametros informados"]
    D --> F["Define run_name por timestamp se vazio"]
    E --> F
    F --> G["Valida run_name, B, Npts, M e Escala"]
    G --> H["Checa gcc, g++, java, javac e python"]
    H --> I["Checa matplotlib"]
    I --> X{"Alguma extra foi solicitada?"}
    X -- sim --> X1["Preflight de rustc, julia e ou elixir solicitados"]
    X -- nao --> I1{"Destino final ou staging ja existem?"}
    X1 --> I1
    I1 -- sim --> I2["Aborta sem criar novo staging"]
    I1 -- nao --> J["Cria staging e diretorios de build"]
    J --> K["Compila C e C -O3 para EXE"]
    K --> L["Compila C++ e C++ -O3 para EXE"]
    L --> M["Compila Java"]
    M --> N["Executa 6 variantes centrais"]
    N --> N1{"Ha extras solicitadas?"}
    N1 -- sim --> N2["Compila Rust quando preciso e executa extras"]
    N1 -- nao --> O["Gera system_info via PowerShell"]
    N2 --> O
    O --> P["Gera run_manifest.json"]
    P --> Q["Executa plot_benchmarks.py"]
    Q --> R["Executa validate_run.py"]
    R -- falha --> R1["Aborta e preserva staging para diagnostico"]
    R -- sucesso --> T["Move-Item do staging para out/run_id/"]
    T --> S["Finaliza com caminho da execucao"]
```

## Contrato dos Benchmarks

Todos os benchmarks principais recebem os mesmos argumentos:

```text
B Npts M escala out_csv
```

| Argumento | Significado | Regra |
| --- | --- | --- |
| `B` | Maior valor de `N` | Inteiro entre `100` e `100000` |
| `Npts` | Quantidade de pontos | Inteiro entre `2` e `10000` |
| `M` | Repeticoes medidas | Inteiro entre `1` e `100000` |
| `escala` | Geracao de `N` | `0` logaritmica, `1` linear |
| `out_csv` | Caminho do CSV | O benchmark cria os diretorios pais quando necessario e sobrescreve o arquivo. Nos runners, o caminho aponta para o staging. |

Cabecalho comum:

```csv
N,TCS,TAM,TDM
```

| Coluna | Significado |
| --- | --- |
| `N` | Dimensao da matriz quadrada `N x N` |
| `TCS` | Tempo medio da multiplicacao |
| `TAM` | Tempo medio de alocacao e inicializacao |
| `TDM` | Tempo medio de desalocacao explicita. Em Java, Python, Julia e Elixir e `0.0`. |

## Ciclo Interno de um Benchmark

```mermaid
flowchart TD
    A["main"] --> B["Valida CLI e converte B, Npts, M e escala"]
    B --> C["Gera lista de N"]
    C --> D["Cria diretorios pais e abre out_csv"]
    D --> E["Escreve N,TCS,TAM,TDM"]
    E --> F{"Ainda ha N?"}
    F -- nao --> Z["Fecha CSV e encerra"]
    F -- sim --> G["Seleciona N atual"]
    G --> H["Executa um warm-up descartado"]
    H --> I["Zera acumuladores"]
    I --> J{"Ainda faltam repeticoes medidas?"}
    J -- sim --> K["Executa run_once"]
    K --> L["Acumula TAM, TCS e TDM"]
    L --> J
    J -- nao --> M["Calcula medias dividindo por M"]
    M --> N["Grava uma linha no CSV"]
    N --> F
```

## Detalhe de `run_once`

```mermaid
flowchart TD
    A["run_once N"] --> B["Checa tamanho e alocacao"]
    B --> C["Inicio TAM"]
    C --> D["Aloca entradas e resultado quando aplicavel"]
    D --> E["Inicializa A com i + j"]
    E --> F["Inicializa B como identidade"]
    F --> G["Fim TAM"]
    G --> H["Inicio TCS"]
    H --> I["Multiplica A por B"]
    I --> J["Fim TCS"]
    J --> K["Verifica amostras do resultado"]
    K --> L{"Resultado valido?"}
    L -- nao --> X["Erro e encerramento"]
    L -- sim --> M["Inicio TDM quando aplicavel"]
    M --> N["Libera memoria explicita quando aplicavel"]
    N --> O["Fim TDM"]
    O --> P["Retorna tempos"]
```

Observacoes:

- C e C++ usam buffers contiguos.
- Rust usa `Vec<i32>` plano e acessos `get_unchecked` documentados.
- Java usa `int[][]`.
- Python usa listas de listas.
- Julia usa `Matrix{Int32}` em layout column-major.
- Elixir usa tupla plana imutavel e constroi o resultado dentro de TCS.
- A validacao amostral do benchmark usa a identidade como segundo operando.
- Os testes de corretude em `tests/` usam tambem uma matriz nao identidade 2x2.

## Geracao dos Pontos de N

```mermaid
flowchart TD
    A["make_points B, Npts, escala"] --> B{"escala igual a 1?"}
    B -- sim --> C["x = 100 + (B - 100) * i / (Npts - 1)"]
    B -- nao --> D["x = 100 * (B / 100) elevado a i / (Npts - 1)"]
    C --> E["N = floor(x + 0.5)"]
    D --> E
    E --> F["Mantem exatamente Npts valores, inclusive repetidos"]
```

A regra de arredondamento e metade-para-cima para valores positivos, implementada de forma equivalente a `floor(x + 0.5)`. O caso linear `B=101`, `Npts=3` deve produzir `[100, 101, 101]`.

## Algoritmo de Multiplicacao

```mermaid
flowchart TD
    A["Inicio multiply"] --> B["i = 0"]
    B --> C{"i menor que N?"}
    C -- nao --> Z["Fim"]
    C -- sim --> D["j = 0"]
    D --> E{"j menor que N?"}
    E -- nao --> F["Incrementa i"]
    F --> C
    E -- sim --> G["sum = 0"]
    G --> H["k = 0"]
    H --> I{"k menor que N?"}
    I -- sim --> J["sum recebe sum mais A i,k vezes B k,j"]
    J --> K["Incrementa k"]
    K --> I
    I -- nao --> L["C i,j recebe sum"]
    L --> M["Incrementa j"]
    M --> E
```

A ordem logica dos lacos e `i, j, k` em todas as implementacoes do contrato comum.

## Fluxo de Dados e Artefatos

```mermaid
flowchart LR
    Params["Parametros B, Npts, M, escala"] --> Runner["Runner"]
    Sources["src/matriz_*"] --> Runner
    Runner --> Build["build/"]
    Runner --> Staging["out/.running-run_id/"]
    Build --> Exec["Benchmarks"]
    Exec --> Csv["resultado_*.csv"]
    Csv --> Staging
    Runner --> Sys["system_info"]
    Sys --> Staging
    Runner --> Manifest["run_manifest.json"]
    Manifest --> Staging
    Staging --> Plot["plot_benchmarks.py"]
    Plot --> Graphs["grafico_*.png"]
    Graphs --> Staging
    Staging --> Validate["validate_run.py"]
    Validate -- sucesso --> Final["out/run_id/"]
```

## Geracao dos Graficos

```mermaid
flowchart TD
    A["plot_benchmarks.py out_dir"] --> B["Prepara MPLCONFIGDIR"]
    B --> C["Carrega matplotlib com backend Agg"]
    C --> D["Mapeia CSVs conhecidos"]
    D --> E["Aplica exclusoes solicitadas"]
    E --> F["Le CSVs existentes"]
    F --> G{"Ha dados validos?"}
    G -- nao --> X["Erro"]
    G -- sim --> H["Para cada metrica TCS, TAM e TDM"]
    H --> I["Grafico com todas as series disponiveis"]
    H --> J["Grafico C vs C++ preferindo -O3"]
    H --> K["Grafico C e C++ com e sem -O3"]
    H --> L["Grafico C vs C++ sem -O3"]
    H --> M["Grafico sem Python"]
    I --> N["Salva PNG"]
    J --> N
    K --> N
    L --> N
    M --> N
```

## Validacao da Execucao

```mermaid
flowchart TD
    A["validate_run.py out/run_id"] --> B{"Diretorio existe?"}
    B -- nao --> X["Erro"]
    B -- sim --> C["Le run_manifest.json"]
    C --> D["Le Npts esperado"]
    D --> E{"Os 6 CSVs centrais estao declarados?"}
    E -- nao --> X
    E -- sim --> F{"CSV opcional conhecido esta presente sem declaracao?"}
    F -- sim --> X
    F -- nao --> G["Valida cada CSV declarado"]
    G --> H["Confere cabecalho, linhas, numeros, tempos e quantidade Npts"]
    H --> I{"Series de N sao identicas?"}
    I -- nao --> X
    I -- sim --> J["Confere system_info.md e system_info.json"]
    J --> K{"Existe ao menos um grafico PNG?"}
    K -- nao --> X
    K -- sim --> L["Validacao concluida com sucesso"]
```

O manifesto e a fonte autoritativa para os seis CSVs centrais e para Rust, Julia e Elixir quando solicitados. Um CSV opcional conhecido presente sem declaracao invalida a execucao.

## Estrutura do Diretorio de Saida

```mermaid
flowchart TD
    A["out/run_id/"] --> B["CSVs centrais"]
    A --> C["CSVs opcionais quando solicitados"]
    A --> D["Metadados"]
    A --> E["Graficos"]

    B --> B1["resultado_c.csv"]
    B --> B2["resultado_c_O3.csv"]
    B --> B3["resultado_cpp.csv"]
    B --> B4["resultado_cpp_O3.csv"]
    B --> B5["resultado_java.csv"]
    B --> B6["resultado_python.csv"]

    C -.-> C1["resultado_rust.csv"]
    C -.-> C2["resultado_julia.csv"]
    C -.-> C3["resultado_elixir.csv"]

    D --> D1["system_info.md"]
    D --> D2["system_info.json"]
    D --> D3["run_manifest.json"]

    E --> E1["grafico_TCS_*.png"]
    E --> E2["grafico_TAM_*.png"]
    E --> E3["grafico_TDM_*.png"]
```

## Manifest da Execucao

```mermaid
flowchart TD
    A["run_manifest.json"] --> B["run_id"]
    A --> C["generated_at UTC"]
    A --> D["commit_hash"]
    A --> E["system"]
    A --> F["parameters"]
    A --> G["tools"]
    A --> H["languages"]

    E --> E1["platform"]
    E --> E2["machine"]
    E --> E3["python"]

    F --> F1["B"]
    F --> F2["Npts"]
    F --> F3["M"]
    F --> F4["escala"]

    G --> G1["gcc"]
    G --> G2["g++"]
    G --> G3["java"]
    G --> G4["java_gc"]
    G --> G5["javac"]
    G --> G6["python"]
    G -. opcional .-> G7["rustc"]
    G -. opcional .-> G8["julia"]
    G -. opcional .-> G9["elixir"]

    H --> H1["name"]
    H --> H2["flags"]
    H --> H3["output"]
```

As ferramentas extras e as respectivas linguagens entram no manifesto somente quando foram solicitadas e executadas com sucesso.

## Dependencias de Ambiente

```mermaid
flowchart LR
    Runner["run_all"] --> GCC["gcc"]
    Runner --> GPP["g++"]
    Runner --> JDK["javac"]
    Runner --> JVM["java"]
    Runner --> Python["python"]
    Python --> Matplotlib["matplotlib"]

    Runner -. quando solicitado .-> Rustc["rustc"]
    Runner -. quando solicitado .-> Julia["julia"]
    Runner -. quando solicitado .-> Elixir["elixir"]

    GCC --> CBuild["C e C -O3"]
    GPP --> CppBuild["C++ e C++ -O3"]
    JDK --> JavaBuild["matriz_java.class"]
    JVM --> JavaRun["execucao Java"]
    Python --> PyRun["benchmark Python"]
    Python --> PlotRun["plot_benchmarks.py"]
    Python --> ValRun["validate_run.py"]
    Rustc --> RustRun["benchmark Rust"]
    Julia --> JuliaRun["benchmark Julia"]
    Elixir --> ElixirRun["benchmark Elixir"]
```

## Estados de uma Execucao

```mermaid
stateDiagram-v2
    [*] --> Configurando
    Configurando --> FalhaAntesStaging: parametro ou run_name invalido
    Configurando --> FalhaAntesStaging: dependencia central ausente
    Configurando --> FalhaAntesStaging: toolchain extra solicitada ausente
    Configurando --> FalhaAntesStaging: destino final ou staging ja existe
    Configurando --> EmStaging: preflight aprovado e staging criado

    EmStaging --> Compilando
    Compilando --> Executando: build concluido
    Compilando --> FalhaEmStaging: erro de compilacao

    Executando --> ColetandoMetadados: benchmarks concluidos
    Executando --> FalhaEmStaging: benchmark ou verificacao falhou

    ColetandoMetadados --> GerandoGraficos: metadados concluidos
    ColetandoMetadados --> FalhaEmStaging: erro de metadados

    GerandoGraficos --> Validando: PNGs gerados
    GerandoGraficos --> FalhaEmStaging: erro de graficos

    Validando --> Promovendo: validacao aprovada
    Validando --> FalhaEmStaging: validacao rejeitada

    Promovendo --> Concluida: staging promovido para out/run_id/
    Concluida --> [*]
    FalhaEmStaging --> [*]: staging preservado para diagnostico
    FalhaAntesStaging --> [*]
```

## Integracao de Nova Linguagem ao Fluxo Principal

Use este roteiro quando uma nova linguagem for promovida para `src/`. Rust, Julia e Elixir seguem esse modelo como linguagens opcionais por flag.

```mermaid
flowchart TD
    A["Novo benchmark em src/"] --> B["Implementa CLI B Npts M escala out_csv"]
    B --> C["Gera CSV N,TCS,TAM,TDM"]
    C --> D["Adiciona warm-up e M repeticoes medidas"]
    D --> E["Adiciona verificacao do resultado"]
    E --> F["Adiciona teste nao identidade"]
    F --> G["Adiciona flag opcional ao runner Linux"]
    F --> H["Adiciona flag opcional ao runner Windows"]
    G --> I["Preflight da toolchain antes do staging"]
    H --> I
    I --> J["Compila e ou executa somente quando solicitado"]
    J --> K["Registra tools e languages no manifesto apos sucesso"]
    K --> L["Mantem plot e validador compativeis"]
    L --> M["Executa harness e smoke tests com e sem a flag"]
    M --> N["Documenta diferencas metodologicas"]
```

## Pontos de Atencao Metodologica

Resumo rapido. O desenho experimental completo esta em [METHODOLOGY.md](METHODOLOGY.md) e as ameacas a validade estao em [THREATS_TO_VALIDITY.md](THREATS_TO_VALIDITY.md).

- `TAM` cobre alocacao e inicializacao de A, B e do resultado quando a representacao permite pre-alocacao.
- Elixir e a excecao estrutural: o resultado imutavel e construido durante `TCS`.
- `TCS` mede a multiplicacao manual O(N^3), com ordem logica `i, j, k`.
- `TDM` mede liberacao explicita em C, C++ e Rust. Java, Python, Julia e Elixir registram `0.0`.
- O warm-up e descartado e nao entra na media de `M` repeticoes.
- A matriz identidade simplifica a verificacao amostral do benchmark, mas nao substitui os testes nao identidade.
- C e C++ possuem variantes com e sem `-O3`, enquanto Rust e integrado com `opt-level=3`.
- Comparacoes devem considerar layout de memoria, largura dos inteiros, JIT, GC, bounds-checks, imutabilidade e otimizacoes do compilador.
