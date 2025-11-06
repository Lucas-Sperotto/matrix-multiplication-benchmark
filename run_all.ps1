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
