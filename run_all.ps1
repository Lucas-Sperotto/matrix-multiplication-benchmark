<<<<<<< HEAD
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
=======
# run_all.ps1 — versão simplificada e robusta

chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8


Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --------- Helpers ---------
function Have([string]$Cmd) { return $null -ne (Get-Command $Cmd -ErrorAction SilentlyContinue) }

function Ensure-PythonPackage([string]$pkg) {
    if (-not (Have "python")) { Write-Warning "Python não encontrado."; return }
    $code = "import pkgutil,sys;sys.exit(0 if pkgutil.find_loader('$pkg') else 1)"
    python -c $code | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "✅ '$pkg' ok"; return }
    Write-Host "Instalando '$pkg' com pip..."
    if (Have "pip") { pip install $pkg | Out-Null } else { python -m pip install $pkg | Out-Null }
}

function New-Dir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }

function Move-IfExists([string]$file, [string]$dstDir) {
    if (Test-Path $file) { Move-Item -Force $file (Join-Path $dstDir (Split-Path $file -Leaf)) }
}

# --------- Checagem rápida (não bloqueia) ---------
$haveGcc  = Have "gcc"
$haveGpp  = Have "g++"
$haveJava = Have "java"
$haveJavc = Have "javac"
$havePy   = Have "python"

if ($havePy) {
    Ensure-PythonPackage "pandas"
    Ensure-PythonPackage "matplotlib"
    Ensure-PythonPackage "psutil"
} else {
    Write-Warning "Python não encontrado; etapas Python/gráficos serão puladas."
}

# --------- Entradas ---------
$RUN_NAME = Read-Host "Digite o nome da execução (ENTER para timestamp)"
if ([string]::IsNullOrWhiteSpace($RUN_NAME)) { $RUN_NAME = (Get-Date -Format "yyyyMMdd_HHmmss") }

$OUT_DIR = Join-Path "out" $RUN_NAME
New-Dir $OUT_DIR

$B      = Read-Host "Tamanho máximo de Matriz (B)"
$ESCALA = Read-Host "Escala: [0]=Log, [1]=Linear"
$Npts   = Read-Host "Npts (nº de pontos)"
$M      = Read-Host "M (repetições para média)"

Write-Host "`nSaída: $OUT_DIR`n"


# --------- C (O3) ---------
try {
    if ($haveGcc -and (Test-Path "src\matriz_c.c")) {
        Write-Host "C (O3)…"
        gcc src\matriz_c.c -o matriz_c.exe -lm -O3
        .\matriz_c.exe $B $Npts $M $ESCALA "-O3"
        Move-IfExists "resultado_c_O3.csv" $OUT_DIR
    } else { Write-Warning "GCC ausente ou src\matriz_c.c não encontrado. Pulando C (O3)." }
} catch { Write-Warning "C (O3): $($_.Exception.Message)" }

# --------- C (normal) ---------
try {
    if ($haveGcc -and (Test-Path "src\matriz_c.c")) {
        Write-Host "C…"
        gcc src\matriz_c.c -o matriz_c.exe -lm
        .\matriz_c.exe $B $Npts $M $ESCALA
        Move-IfExists "resultado_c.csv" $OUT_DIR
    } else { Write-Warning "GCC ausente ou src\matriz_c.c não encontrado. Pulando C." }
} catch { Write-Warning "C: $($_.Exception.Message)" }

# --------- C++ (O3) ---------
try {
    if ($haveGpp -and (Test-Path "src\matriz_cpp.cpp")) {
        Write-Host "C++ (O3)…"
        g++ src\matriz_cpp.cpp -o matriz_cpp.exe -O3
        .\matriz_cpp.exe $B $Npts $M $ESCALA "-O3"
        Move-IfExists "resultado_cpp_O3.csv" $OUT_DIR
    } else { Write-Warning "G++ ausente ou src\matriz_cpp.cpp não encontrado. Pulando C++ (O3)." }
} catch { Write-Warning "C++ (O3): $($_.Exception.Message)" }

# --------- C++ (normal) ---------
try {
    if ($haveGpp -and (Test-Path "src\matriz_cpp.cpp")) {
        Write-Host "C++…"
        g++ src\matriz_cpp.cpp -o matriz_cpp.exe
        .\matriz_cpp.exe $B $Npts $M $ESCALA
        Move-IfExists "resultado_cpp.csv" $OUT_DIR
    } else { Write-Warning "G++ ausente ou src\matriz_cpp.cpp não encontrado. Pulando C++." }
} catch { Write-Warning "C++: $($_.Exception.Message)" }

# --------- Java ---------
try {
    if ($haveJava -and $haveJavc -and (Test-Path "src\matriz_java.java")) {
        Write-Host "Java…"
        javac src\matriz_java.java
        # Classe sem package:
        java -cp src matriz_java $B $Npts $M $ESCALA
        Move-IfExists "resultado_java.csv" $OUT_DIR
    } else { Write-Warning "Java/javac ausentes ou src\matriz_java.java não encontrado. Pulando Java." }
} catch { Write-Warning "Java: $($_.Exception.Message)" }

# --------- Python ---------
try {
    if ($havePy -and (Test-Path "src\matriz_python.py")) {
        Write-Host "Python…"
        python src\matriz_python.py $B $Npts $M $ESCALA
        Move-IfExists "resultado_python.csv" $OUT_DIR
    } else { Write-Warning "Python ausente ou src\matriz_python.py não encontrado. Pulando Python." }
} catch { Write-Warning "Python: $($_.Exception.Message)" }

# --------- system_info.md ---------
try {
    Write-Host "Gerando system_info.md…"
    $os  = Get-CimInstance Win32_OperatingSystem
    $cs  = Get-CimInstance Win32_ComputerSystem
    $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1)
    $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $wsl = ""
    try { $wsl = (wsl.exe --status 2>$null | Out-String).Trim() } catch { $wsl = "" }

    $md = @()
    $md += "# Informações do Sistema"
    $md += ""
    $md += "_Gerado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_"
    $md += ""
    $md += "## Windows"
    $md += "- **Edição/Versão**: $($os.Caption) $($os.Version)"
    $md += "- **Build**: $($os.BuildNumber)"
    $md += ""
    $md += "### CPU (host)"
    $md += "- **Modelo**: $($cpu.Name)"
    $md += "- **Núcleos (físicos)**: $($cpu.NumberOfCores)"
    $md += "- **Lógicos (threads)**: $($cpu.NumberOfLogicalProcessors)"
    $md += "- **Clock Máx (MHz)**: $($cpu.MaxClockSpeed)"
    $md += ""
    $md += "### Memória (host)"
    $md += "- **RAM total**: $ram GB"
    if ($wsl) {
        $md += ""
        $md += "### WSL --status"
        $md += '```'
        $md += $wsl
        $md += '```'
    }
    $tmp = Join-Path $PWD "system_info.md"
    $md | Set-Content -Encoding utf8 $tmp
    Move-IfExists $tmp $OUT_DIR
} catch { Write-Warning "system_info.md: $($_.Exception.Message)" }

# --------- plot_benchmarks.py ---------
try {
    if ($havePy -and (Test-Path "src\plot_benchmarks.py")) {
        Write-Host "Gerando gráficos…"
        python src\plot_benchmarks.py $OUT_DIR
    } else { Write-Warning "plot_benchmarks.py não encontrado ou Python ausente. Pulando gráficos." }
} catch { Write-Warning "plot_benchmarks: $($_.Exception.Message)" }

Write-Host "`n✅ Finalizado. Arquivos em: $OUT_DIR"
>>>>>>> 26fad68dcaa09e715badd063663827340ce535bb
