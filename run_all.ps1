# Requires -Version 5.1
# Script: run_all.ps1
# Versao adaptada do script bash para Windows/PowerShell

# ----------------------------
# Funcoes de verificacao
# ----------------------------

function Check-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string]$DisplayName = $null
    )

    if (-not $DisplayName) { $DisplayName = $Command }

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "[$DisplayName] ja esta instalado."
        return $true
    }
    else {
        Write-Host "[$DisplayName] nao encontrado no PATH."
        return $false
    }
}

function Check-PythonPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Package
    )

    # Tenta python e python3
    $pythonCmd = $null
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonCmd = "python"
    }
    elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonCmd = "python3"
    }

    if (-not $pythonCmd) {
        Write-Host "Python nao encontrado. Instale o Python 3 e tente novamente."
        return
    }

    & $pythonCmd -c "import $Package" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Pacote Python '$Package' nao encontrado."
        Write-Host "   Instale com:  $pythonCmd -m pip install $Package"
    }
    else {
        Write-Host "Pacote Python '$Package' ja esta instalado."
    }
}

# ----------------------------
# Verificacao de dependencias
# ----------------------------

Write-Host "Verificando dependencias..."

$okGcc   = Check-Command -Command "gcc"   -DisplayName "gcc"
$okGpp   = Check-Command -Command "g++"   -DisplayName "g++"
$okJava  = Check-Command -Command "java"  -DisplayName "Java (JRE)"
$okJavac = Check-Command -Command "javac" -DisplayName "Java (JDK)"

# Descobre se existe python ou python3
$okPython = $false
if (Check-Command -Command "python" -DisplayName "Python") {
    $okPython = $true
}
elseif (Check-Command -Command "python3" -DisplayName "Python3") {
    $okPython = $true
}

if ($okPython) {
    Check-PythonPackage -Package "pandas"
    Check-PythonPackage -Package "matplotlib"
    Check-PythonPackage -Package "psutil"
}
else {
    Write-Host "Python nao encontrado, nao foi possivel checar pacotes."
}

Write-Host "Verificacao de dependencias concluida."
Write-Host "--------------------------------------"

# Se algo critico faltar, voce pode abortar aqui se quiser:
if (-not ($okGcc -and $okGpp -and $okJava -and $okJavac -and $okPython)) {
    Write-Host "Existem dependencias ausentes. Instale-as e execute novamente."
    # Se quiser forcar saida, descomente:
    # exit 1
}

# ----------------------------
# Perguntas ao usuario
# ----------------------------

# Lista de N (mantida por compatibilidade, se quiser usar no futuro)
$Ns = @(10, 100, 500, 1000, 1500, 2000, 2500, 3000)

$RUN_NAME = Read-Host "Digite o nome da execucao"
$OUT_DIR  = Join-Path "out" $RUN_NAME

# Cria pasta de saida
New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null

Write-Host "Resultados serao salvos em $OUT_DIR"
Write-Host "-----------------------------------"

$B      = Read-Host "Digite o tamanho maximo de Matriz (B)"
$ESCALA = Read-Host "Escolha o tipo de escala grafica: [0] = Logaritmica, [1] = Linear"
if ([string]::IsNullOrWhiteSpace($ESCALA)) {
    Write-Host "Nenhuma escala informada, assumindo ESCALA = 1 (Linear)."
    $ESCALA = "1"
}
$Npts   = Read-Host "Digite o numero de pontos na escala"
$M      = Read-Host "Digite a quantidade de execucoes para o calculo da media"

# Detecta comando python (python ou python3) para uso posterior
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
}
elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonCmd = "python3"
}
else {
    Write-Host "Nenhum comando Python encontrado (python/python3)."
    exit 1
}

# ----------------------------
# 1. Compilar e executar C Otimizado
# ----------------------------
Write-Host "Compilando matriz_c.c (otimizado)..."
gcc src/matriz_c.c -o matriz_c.exe -lm -O3
if ($LASTEXITCODE -eq 0) {
    Write-Host "Executando C -O3..."
    .\matriz_c.exe $B $Npts $M $ESCALA "-O3"
    if (Test-Path "resultado_c_O3.csv") {
        Move-Item -Path "resultado_c_O3.csv" -Destination $OUT_DIR -Force
    }
    else {
        Write-Host "resultado_c_O3.csv nao encontrado."
    }
}
else {
    Write-Host "Erro na compilacao de matriz_c.c (O3)"
}

# ----------------------------
# 1.1 Compilar e executar C sem otimizacao extra
# ----------------------------
Write-Host "Compilando matriz_c.c..."
gcc src/matriz_c.c -o matriz_c.exe -lm
if ($LASTEXITCODE -eq 0) {
    Write-Host "Executando C..."
    .\matriz_c.exe $B $Npts $M $ESCALA
    if (Test-Path "resultado_c.csv") {
        Move-Item -Path "resultado_c.csv" -Destination $OUT_DIR -Force
    }
    else {
        Write-Host "resultado_c.csv nao encontrado."
    }
}
else {
    Write-Host "Erro na compilacao de matriz_c.c"
}

# ----------------------------
# 2. Compilar e executar C++ Otimizado
# ----------------------------
Write-Host "Compilando matriz_cpp.cpp (otimizado)..."
g++ src/matriz_cpp.cpp -o matriz_cpp.exe -O3
if ($LASTEXITCODE -eq 0) {
    Write-Host "Executando C++ -O3..."
    .\matriz_cpp.exe $B $Npts $M $ESCALA "-O3"
    if (Test-Path "resultado_cpp_O3.csv") {
        Move-Item -Path "resultado_cpp_O3.csv" -Destination $OUT_DIR -Force
    }
    else {
        Write-Host "resultado_cpp_O3.csv nao encontrado."
    }
}
else {
    Write-Host "Erro na compilacao de matriz_cpp.cpp (O3)"
}

# ----------------------------
# 2.1 Compilar e executar C++ sem otimizacao extra
# ----------------------------
Write-Host "Compilando matriz_cpp.cpp..."
g++ src/matriz_cpp.cpp -o matriz_cpp.exe
if ($LASTEXITCODE -eq 0) {
    Write-Host "Executando C++..."
    .\matriz_cpp.exe $B $Npts $M $ESCALA
    if (Test-Path "resultado_cpp.csv") {
        Move-Item -Path "resultado_cpp.csv" -Destination $OUT_DIR -Force
    }
    else {
        Write-Host "resultado_cpp.csv nao encontrado."
    }
}
else {
    Write-Host "Erro na compilacao de matriz_cpp.cpp"
}

# ----------------------------
# 3. Compilar e executar Java
# ----------------------------
Write-Host "Compilando matriz_java.java..."
javac src\matriz_java.java
if ($LASTEXITCODE -eq 0) {
    Write-Host "Executando Java..."
    # -cp src: indica o diretorio onde esta a classe compilada
    java -cp src matriz_java $B $Npts $M $ESCALA
    if (Test-Path "resultado_java.csv") {
        Move-Item -Path "resultado_java.csv" -Destination $OUT_DIR -Force
    }
    else {
        Write-Host "Arquivo de saida Java (resultado_java.csv) nao encontrado."
    }
}
else {
    Write-Host "Erro na compilacao de matriz_java.java"
}

# ----------------------------
# 4. Executar Python
# ----------------------------
Write-Host "Executando Python..."
& $pythonCmd "src/matriz_python.py" $B $Npts $M $ESCALA
if (Test-Path "resultado_python.csv") {
    Move-Item -Path "resultado_python.csv" -Destination $OUT_DIR -Force
}
else {
    Write-Host "resultado_python.csv nao encontrado."
}

Write-Host "-----------------------------------"
Write-Host "Execucao concluida! Resultados em: $OUT_DIR"

# ----------------------------
# 5. Capturando informacoes de hardware
# ----------------------------
Write-Host "Capturando informacoes de hardware..."

# No script original em bash:
# ./src/gen_sysinfo_md.sh
# Aqui voce pode criar uma versao PowerShell equivalente
# ou chamar bash se tiver Git Bash instalado.
#
# Exemplo (se tiver bash do Git no PATH):
# bash src/gen_sysinfo_md.sh

if (Test-Path "system_info.md") {
    Move-Item -Path "system_info.md" -Destination $OUT_DIR -Force
}

# ----------------------------
# 6. Geracao de graficos
# ----------------------------
Write-Host "Gerando graficos..."
& $pythonCmd "src/plot_benchmarks.py" $OUT_DIR

Write-Host "Tudo pronto!"
