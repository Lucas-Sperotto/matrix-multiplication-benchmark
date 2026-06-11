param(
    [switch]$Batch,
    [string]$RunName = "",
    [int]$B = 0,
    [int]$Npts = 0,
    [int]$M = 0,
    [int]$Escala = -1
)

chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Have([string]$Cmd) {
    return $null -ne (Get-Command $Cmd -ErrorAction SilentlyContinue)
}

function Require-Command([string]$Cmd) {
    if (-not (Have $Cmd)) {
        throw "Dependencia ausente: $Cmd. Instale conforme EXECUTION.md e tente novamente."
    }
}

function Require-PythonPackage([string]$Package) {
    python -c "import $Package" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Dependencia Python ausente ou quebrada: $Package. Instale com: python -m pip install -r requirements.txt"
    }
}

function New-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Validate-Int([string]$Name, [int]$Value, [int]$Min, [int]$Max) {
    if ($Value -lt $Min -or $Value -gt $Max) {
        throw "Parametro invalido para ${Name}: $Value"
    }
}

function First-Line([scriptblock]$Command) {
    try {
        $result = & $Command 2>&1 | Select-Object -First 1
        if ($null -eq $result) { return "N/D" }
        return $result.ToString()
    } catch {
        return "N/D"
    }
}

if (-not $Batch) {
    $RunName = Read-Host "Digite o nome da execucao (ENTER para timestamp)"
    $B = [int](Read-Host "Digite o tamanho maximo de matriz (B)")
    $Escala = [int](Read-Host "Escolha a escala [0]=Logaritmica, [1]=Linear")
    $Npts = [int](Read-Host "Digite o numero de pontos na escala (Npts)")
    $M = [int](Read-Host "Digite a quantidade de repeticoes para media (M)")
}

if ([string]::IsNullOrWhiteSpace($RunName)) {
    $RunName = Get-Date -Format "yyyyMMdd_HHmmss"
}

Validate-Int "B" $B 100 100000
Validate-Int "Npts" $Npts 2 10000
Validate-Int "M" $M 1 100000
Validate-Int "Escala" $Escala 0 1

Require-Command "gcc"
Require-Command "g++"
Require-Command "java"
Require-Command "javac"
Require-Command "python"
$MplCache = Join-Path ".cache" "matplotlib"
New-Dir $MplCache
$env:MPLCONFIGDIR = $MplCache
Require-PythonPackage "matplotlib"

$OutDir = Join-Path "out" $RunName
$BuildWin = Join-Path "build" "windows"
$BuildJava = Join-Path "build" "java"
New-Dir $OutDir
New-Dir $BuildWin
New-Dir $BuildJava

Write-Host "Resultados serao salvos em $OutDir"
Write-Host "Artefatos de compilacao em build/"
Write-Host "-----------------------------------"

$CExe = Join-Path $BuildWin "matriz_c.exe"
$CO3Exe = Join-Path $BuildWin "matriz_c_O3.exe"
$CppExe = Join-Path $BuildWin "matriz_cpp.exe"
$CppO3Exe = Join-Path $BuildWin "matriz_cpp_O3.exe"

Write-Host "Compilando C..."
gcc -std=c11 -Wall -Wextra src\matriz_c.c -o $CExe -lm
gcc -std=c11 -Wall -Wextra src\matriz_c.c -o $CO3Exe -lm -O3

Write-Host "Compilando C++..."
g++ -std=c++17 -Wall -Wextra src\matriz_cpp.cpp -o $CppExe
g++ -std=c++17 -Wall -Wextra src\matriz_cpp.cpp -o $CppO3Exe -O3

Write-Host "Compilando Java..."
javac -d $BuildJava src\matriz_java.java

Write-Host "Executando C..."
& $CExe $B $Npts $M $Escala (Join-Path $OutDir "resultado_c.csv")

Write-Host "Executando C -O3..."
& $CO3Exe $B $Npts $M $Escala (Join-Path $OutDir "resultado_c_O3.csv")

Write-Host "Executando C++..."
& $CppExe $B $Npts $M $Escala (Join-Path $OutDir "resultado_cpp.csv")

Write-Host "Executando C++ -O3..."
& $CppO3Exe $B $Npts $M $Escala (Join-Path $OutDir "resultado_cpp_O3.csv")

Write-Host "Executando Java..."
java -cp $BuildJava matriz_java $B $Npts $M $Escala (Join-Path $OutDir "resultado_java.csv")

Write-Host "Executando Python..."
python src\matriz_python.py $B $Npts $M $Escala (Join-Path $OutDir "resultado_python.csv")

Write-Host "Gerando system_info.md e system_info.json..."
$Os = Get-CimInstance Win32_OperatingSystem
$Cs = Get-CimInstance Win32_ComputerSystem
$Cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$RamGb = [math]::Round($Cs.TotalPhysicalMemory / 1GB, 2)
$GeneratedAt = (Get-Date).ToString("o")
$SysMd = Join-Path $OutDir "system_info.md"
$SysJson = Join-Path $OutDir "system_info.json"

$md = @(
    "# Informações do Sistema",
    "",
    "_Gerado em: ${GeneratedAt}_",
    "",
    "## Windows",
    "- **Edição/Versão**: $($Os.Caption) $($Os.Version)",
    "- **Build**: $($Os.BuildNumber)",
    "",
    "### CPU",
    "- **Modelo**: $($Cpu.Name)",
    "- **Núcleos físicos**: $($Cpu.NumberOfCores)",
    "- **Threads lógicas**: $($Cpu.NumberOfLogicalProcessors)",
    "- **Clock máximo MHz**: $($Cpu.MaxClockSpeed)",
    "",
    "### Memória",
    "- **RAM total**: $RamGb GB"
)
$md | Set-Content -Encoding utf8 $SysMd

$sysInfo = [ordered]@{
    generated_at = $GeneratedAt
    windows = [ordered]@{
        caption = $Os.Caption
        version = $Os.Version
        build = $Os.BuildNumber
        cpu = [ordered]@{
            model = $Cpu.Name
            physical_cores = $Cpu.NumberOfCores
            logical_processors = $Cpu.NumberOfLogicalProcessors
            max_mhz = $Cpu.MaxClockSpeed
        }
        memory = [ordered]@{
            ram_gb = $RamGb
        }
    }
}
$sysInfo | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 $SysJson

$Manifest = [ordered]@{
    run_id = $RunName
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    commit_hash = First-Line { git rev-parse HEAD }
    system = [ordered]@{
        platform = "$($Os.Caption) $($Os.Version)"
        machine = $env:PROCESSOR_ARCHITECTURE
        python = First-Line { python --version }
    }
    parameters = [ordered]@{
        B = $B
        Npts = $Npts
        M = $M
        escala = $Escala
    }
    tools = [ordered]@{
        gcc = First-Line { gcc --version }
        "g++" = First-Line { g++ --version }
        java = First-Line { java -version }
        javac = First-Line { javac -version }
        python = First-Line { python --version }
    }
    languages = @(
        [ordered]@{ name = "C"; flags = "-std=c11 -Wall -Wextra"; output = "resultado_c.csv" },
        [ordered]@{ name = "C"; flags = "-std=c11 -Wall -Wextra -O3"; output = "resultado_c_O3.csv" },
        [ordered]@{ name = "C++"; flags = "-std=c++17 -Wall -Wextra"; output = "resultado_cpp.csv" },
        [ordered]@{ name = "C++"; flags = "-std=c++17 -Wall -Wextra -O3"; output = "resultado_cpp_O3.csv" },
        [ordered]@{ name = "Java"; flags = ""; output = "resultado_java.csv" },
        [ordered]@{ name = "Python"; flags = ""; output = "resultado_python.csv" }
    )
}
$Manifest | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $OutDir "run_manifest.json")

Write-Host "Gerando graficos..."
python src\plot_benchmarks.py $OutDir

Write-Host "Validando execucao..."
python scripts\validate_run.py $OutDir

Write-Host "-----------------------------------"
Write-Host "Finalizado. Arquivos em: $OutDir"
