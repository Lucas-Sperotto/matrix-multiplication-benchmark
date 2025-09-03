# Como executar os scripts (Linux/WSL e Windows)

Esta seção explica, passo a passo, como rodar **todos os benchmarks** (C, C++, Java e Python) usando os scripts do repositório:

* `run_all.sh` → Linux / WSL
* `run_all.ps1` → Windows (PowerShell)

A estrutura esperada do projeto é algo como:

```
.
├─ run_all.sh
├─ run_all.ps1
├─ src/
│  ├─ matriz_c.c
│  ├─ matriz_cpp.cpp
│  ├─ MatrixMultiplication.java
│  └─ matriz_python.py
└─ out/
```

Os resultados são salvos em `out/<NOME_DA_EXECUCAO>/` nos arquivos:

* `resultado_c.csv`
* `resultado_cpp.csv`
* `resultado_java.csv`
* `resultado_python.csv`

---

## 1) Executando no Linux / WSL (`run_all.sh`)

### Pré-requisitos

* **gcc** e **g++**
* **Java JDK** (para `javac`) e **JRE** (para `java`)
* **Python 3** com **pip**
* Pacote Python: **psutil**

### Instalação rápida (Ubuntu/Debian/WSL)

```bash
sudo apt update
sudo apt install -y build-essential openjdk-17-jdk python3 python3-pip
python3 -m pip install --user psutil
```

### Execução

> No terminal, dentro da **raiz do repositório**:

```bash
chmod +x ./run_all.sh        # apenas na primeira vez
./run_all.sh
```

O script vai:

1. Verificar/instalar dependências (quando aplicável no seu sistema).
2. Pedir um **nome para a execução** (ex.: `meu_pc_i7_2025-09-03`).
3. Compilar e rodar C, C++, Java e Python.
4. Mover os resultados para `out/<NOME_DA_EXECUCAO>/`.

---

## 2) Executando no Windows (PowerShell) — `run_all.ps1`

### Pré-requisitos

* **PowerShell** (padrão no Windows 10/11)
* **winget** (recomendado para instalar dependências)
* **MSYS2/MinGW-w64** (para `gcc` e `g++`) **ou** outro toolchain equivalente
* **Java JDK/JRE** (recomendado Temurin 17)
* **Python 3** + **pip**
* Pacote Python: **psutil**

#### Instalação sugerida

* **MSYS2/MinGW**: [https://www.msys2.org/](https://www.msys2.org/)
  Depois de instalar, abra o **MSYS2 MinGW x64** e rode:

  ```bash
  pacman -S --needed mingw-w64-x86_64-gcc
  ```

  Adicione `C:\msys64\mingw64\bin` ao **PATH** do Windows.
* **Java (Temurin 17)**:

  * Via winget (em PowerShell):

    ```powershell
    winget install -e --id EclipseAdoptium.Temurin.17.JDK
    winget install -e --id EclipseAdoptium.Temurin.17.JRE
    ```
* **Python 3**:

  ```powershell
  winget install -e --id Python.Python.3.12
  python -m pip install --user psutil
  ```

### Permissão para scripts

Se necessário, habilite a execução de scripts no PowerShell **como Administrador**:

```powershell
Set-ExecutionPolicy RemoteSigned
```

### Execução

> No **PowerShell**, dentro da **raiz do repositório**:

```powershell
.\run_all.ps1
```

O script vai:

1. Verificar dependências (tenta instalar via `winget` quando possível).
2. Pedir um **nome para a execução**.
3. Compilar e rodar C, C++, Java e Python.
4. Mover os resultados para `out\<NOME_DA_EXECUCAO>\`.

---

## 3) Personalizando os tamanhos de N

Os tamanhos de matriz `N` são definidos dentro dos códigos (ou do script). Para usar:

```
10, 100, 500, 1000, 1500, 2000, 2500, 3000
```

ajuste **uma** vez no local central (no script, se ele estiver parametrizando) ou diretamente em:

* `src/matriz_c.c`
* `src/matriz_cpp.cpp`
* `src/MatrixMultiplication.java`
* `src/matriz_python.py`

> Em C++ você pode usar:

```cpp
for (int N : std::initializer_list<int>{10,100,500,1000,1500,2000,2500,3000}) { /* ... */ }
```

> Em C, declare um array e itere por índice:

```c
int Ns[] = {10,100,500,1000,1500,2000,2500,3000};
int len = sizeof(Ns)/sizeof(Ns[0]);
for (int i = 0; i < len; ++i) { int N = Ns[i]; /* ... */ }
```

---

## 4) Saídas, logs e onde encontrar resultados

* Os executáveis/compilações rodam a partir da pasta raiz, **carregando os fontes de `src/`**.
* Cada linguagem gera um `resultado_*.dat`.
* Ao final, os arquivos são movidos para `out/<NOME_DA_EXECUCAO>/`.

Exemplo:

```
out/
└─ meu_pc_i7_2025-09-03/
   ├─ resultado_c.dat
   ├─ resultado_cpp.dat
   ├─ resultado_java.dat
   └─ resultado_python.dat
```

---

## 5) Solução de problemas (FAQ)

**“`./run_all.sh: arquivos necessários não encontrados`”**
→ Rode o script **a partir da raiz** do repositório (onde o script enxerga `src/`).
→ Confirme que os arquivos em `src/` têm exatamente os nomes esperados.

**`ModuleNotFoundError: No module named 'psutil'`**
→ Instale: `python3 -m pip install --user psutil` (Linux/WSL)
→ Ou: `python -m pip install --user psutil` (Windows)

**`javac: file not found` ou classpath errado**
→ Compile com `javac src/MatrixMultiplication.java`.
→ Execute com `java -cp src MatrixMultiplication`.
→ Garanta que o arquivo se chama **`MatrixMultiplication.java`** e que a **classe** é `MatrixMultiplication`.

**Permissão negada ao rodar `.sh`**

```bash
chmod +x ./run_all.sh
```

**`gcc`/`g++` não encontrados (Windows)**
→ Instale **MSYS2/MinGW-w64** e adicione `C:\msys64\mingw64\bin` ao PATH.
→ Feche e reabra o terminal após alterar o PATH.

**Resultados não aparecem em `out/`**
→ Verifique se cada executável realmente criou `resultado_*.dat`.
→ Rode cada linguagem manualmente para ver mensagens de erro.

---

## 6) Dicas de performance e repetição de testes

* Prefira compilar com **otimização** (`-O3`) para C/C++.
* Feche programas pesados e rode em condições semelhantes.
* Se quiser **múltiplas repetições por N** para tirar a média, implemente as repetições **dentro de cada código** (C/C++/Java/Python) e gere a média no próprio `resultado_*.dat`.
* Padronize `RUN_NAME` com informações da máquina/data (ex.: `ryzen7_5700U_2025-09-03`) para comparar execuções entre computadores.

---