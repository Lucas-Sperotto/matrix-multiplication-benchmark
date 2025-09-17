# run_all.ps1
# Replica o comportamento de run_all.sh no Windows/PowerShell
# - Verifica/instala dependências (gcc, g++, Java (JRE/JDK), Python, psutil)
# - Compila e executa C, C++, Java e Python
# - Salva resultados em out/<RUN_NAME>
# Obs.: Para instalação automática é necessário winget. Caso não haja, o script orienta manualmente.

$ErrorActionPreference = "Stop"

function Test-Command {
    param([Parameter(Mandatory=$true)][string]$Name)
    $old = $ErrorActionPreference
    try {
        $ErrorActionPreference = "SilentlyContinue"
        $null = Get-Command $Name
        return $true
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $old
    }
}

function Try-Install {
    param(
        [string]$DisplayName,
        [scriptblock]$Test,
        [string]$WingetId,
        [string]$ManualHint
    )
    if (-not (& $Test)) {
        Write-Host "[$DisplayName] não encontrado."
        if (Test-Command -Name "winget") {
            Write-Host "Tentando instalar $DisplayName via winget..."
            try {
                winget install -e --id $WingetId --accept-source-agreements --accept-package-agreements | Out-Null
            } catch {
                Write-Host "Falha ao instalar $DisplayName via winget. $ManualHint"
            }
        } else {
            Write-Host "winget não está disponível. $ManualHint"
        }
        if (-not (& $Test)) {
            Write-Host "⚠️ Ainda não encontrei $DisplayName no PATH. Talvez seja necessário reiniciar o terminal ou ajustar o PATH."
        } else {
            Write-Host "[$DisplayName] instalado/encontrado."
        }
    } else {
        Write-Host "[$DisplayName] já está instalado."
    }
}

Write-Host "🔍 Verificando dependências..."

# gcc
Try-Install `
  -DisplayName "gcc" `
  -Test { Test-Command -Name "gcc" } `
  -WingetId "MSYS2.MSYS2" `
  -ManualHint "Instale o MinGW-w64/MSYS2 (ex.: https://www.msys2.org/), e garanta que 'gcc' e 'g++' estejam no PATH (pacotes mingw64)."

# g++
if (-not (Test-Command -Name "g++")) {
    Write-Host "[g++] não encontrado. Ao instalar MSYS2/MinGW, garanta também o g++ (mingw-w64)."
}

# Java Runtime (java)
Try-Install `
  -DisplayName "Java Runtime (java)" `
  -Test { Test-Command -Name "java" } `
  -WingetId "EclipseAdoptium.Temurin.17.JRE" `
  -ManualHint "Instale um JRE (ex.: Temurin JRE 17) e garanta que 'java' esteja no PATH."

# Java Development Kit (javac)
Try-Install `
  -DisplayName "Java Development Kit (javac)" `
  -Test { Test-Command -Name "javac" } `
  -WingetId "EclipseAdoptium.Temurin.17.JDK" `
  -ManualHint "Instale um JDK (ex.: Temurin JDK 17) e garanta que 'javac' esteja no PATH."

# Python
Try-Install `
  -DisplayName "Python" `
  -Test { Test-Command -Name "python" -or Test-Command -Name "python3" } `
  -WingetId "Python.Python.3.12" `
  -ManualHint "Instale Python 3 (ex.: via Microsoft Store/winget) e garanta que 'python' esteja no PATH."

# Alias python3 -> python (se existir apenas 'python')
if (-not (Test-Command -Name "python3") -and (Test-Command -Name "python")) {
    Set-Alias -Name python3 -Value python -Scope Script -ErrorAction SilentlyContinue
}

Write-Host "Verificando psutil no Python..."
$psutilCheck = & python3 - << 'PY'
try:
    import psutil  # noqa: F401
    print("OK")
except Exception:
    print("MISSING")
PY

if ($psutilCheck.Trim() -ne "OK") {
    Write-Host "📦 Instalando psutil (pode solicitar confirmação do pip)..."
    try {
        & python3 -m pip install --user psutil
    } catch {
        Write-Host "Falha ao instalar psutil via pip. Tente manualmente: python -m pip install --user psutil"
    }
}

Write-Host "✅ Todas as dependências verificadas."
Write-Host "-----------------------------------"

# ----------------------------
# Execução dos benchmarks
# ----------------------------

# Lista de N — igual ao .sh
$Ns = @(10, 100, 500, 1000, 1500, 2000, 2500, 3000)

# Pergunta o nome da execução
$RUN_NAME = Read-Host "Digite o nome da execução"
$OUT_DIR = Join-Path "out" $RUN_NAME
New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null

Write-Host "Resultados serão salvos em $OUT_DIR"
Write-Host "-----------------------------------"

# 1. Compilar e executar C
Write-Host "Compilando matriz_c.c..."
$compileC = $true
try {
    & gcc "src/matriz_c.c" -o "matriz_c.exe" -O3
} catch {
    $compileC = $false
    Write-Host "Erro na compilação de matriz_c.c"
}
if ($compileC) {
    Write-Host "Executando C..."
    try {
        & .\matriz_c.exe
        if (Test-Path "resultado_c.csv") {
            Move-Item -Force "resultado_c.csv" (Join-Path $OUT_DIR "resultado_c.csv")
        } else {
            Write-Host "Arquivo de saída C não encontrado."
        }
    } catch {
        Write-Host "Falha ao executar matriz_c.exe: $($_.Exception.Message)"
    }
}

# 2. Compilar e executar C++
Write-Host "Compilando matriz_cpp.cpp..."
$compileCPP = $true
try {
    & g++ "src/matriz_cpp.cpp" -o "matriz_cpp.exe" -O3
} catch {
    $compileCPP = $false
    Write-Host "Erro na compilação de matriz_cpp.cpp"
}
if ($compileCPP) {
    Write-Host "Executando C++..."
    try {
        & .\matriz_cpp.exe
        if (Test-Path "resultado_cpp.csv") {
            Move-Item -Force "resultado_cpp.csv" (Join-Path $OUT_DIR "resultado_cpp.csv")
        } else {
            Write-Host "Arquivo de saída C++ não encontrado."
        }
    } catch {
        Write-Host "Falha ao executar matriz_cpp.exe: $($_.Exception.Message)"
    }
}

# 3. Compilar e executar Java
Write-Host "Compilando MatrixMultiplication.java..."
$compileJava = $true
try {
    & javac "src/MatrixMultiplication.java"
} catch {
    $compileJava = $false
    Write-Host "Erro na compilação de MatrixMultiplication.java"
}
if ($compileJava) {
    Write-Host "Executando Java..."
    try {
        & java -cp "src" MatrixMultiplication
        if (Test-Path "resultado_java.csv") {
            Move-Item -Force "resultado_java.csv" (Join-Path $OUT_DIR "resultado_java.csv")
        } else {
            Write-Host "Arquivo de saída Java não encontrado."
        }
    } catch {
        Write-Host "Falha ao executar Java: $($_.Exception.Message)"
    }
}

# 4. Executar Python
Write-Host "Executando Python..."
try {
    & python3 "src/matriz_python.py"
    if (Test-Path "resultado_python.csv") {
        Move-Item -Force "resultado_python.csv" (Join-Path $OUT_DIR "resultado_python.csv")
    } else {
        Write-Host "Arquivo de saída Python não encontrado."
    }
} catch {
    Write-Host "Falha ao executar Python: $($_.Exception.Message)"
}

Write-Host "-----------------------------------"
Write-Host "Execução concluída! Resultados em: $OUT_DIR"
