param(
    [switch]$Batch,
    [string]$RunName = "",
    [int]$B = 0,
    [int]$Npts = 0,
    [int]$M = 0,
    [int]$Escala = -1,
    [switch]$WithRust,
    [switch]$WithJulia,
    [switch]$WithElixir,
    [switch]$WithAllExtras
)

if ($WithAllExtras) { $WithRust = $true; $WithJulia = $true; $WithElixir = $true }

chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Have([string]$Cmd) { return $null -ne (Get-Command $Cmd -ErrorAction SilentlyContinue) }
function Require-Command([string]$Cmd) {
    if (-not (Have $Cmd)) { throw "Dependencia ausente: $Cmd. Instale conforme docs/EXECUTION.md e tente novamente." }
}
function Require-PythonPackage([string]$Package) {
    python -c "import $Package" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Dependencia Python ausente ou quebrada: $Package. Instale com: python -m pip install -r requirements.txt" }
}
function New-Dir([string]$Path) { if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null } }
function Validate-Int([string]$Name, [int]$Value, [int]$Min, [int]$Max) {
    if ($Value -lt $Min -or $Value -gt $Max) { throw "Parametro invalido para ${Name}: $Value" }
}
function Validate-RunName([string]$Value) {
    if (-not [regex]::IsMatch($Value, '\A[A-Za-z0-9_.-]+\z') -or $Value.Contains("..")) {
        throw "Nome de execucao invalido: '$Value'. Use apenas A-Z, a-z, 0-9, _, . e -, sem '..' nem separadores de caminho."
    }
}
function First-Line([scriptblock]$Command) {
    try { $result = & $Command 2>&1 | Select-Object -First 1; if ($null -eq $result) { return "N/D" }; return $result.ToString() } catch { return "N/D" }
}
function AllLines([scriptblock]$Command) {
    try { $result = & $Command 2>&1 | ForEach-Object { $_.ToString() }; if ($null -eq $result -or $result.Count -eq 0) { return "N/D" }; return ($result -join "`n") } catch { return "N/D" }
}
function Get-JavaGC() {
    $knownGcFlags = @("UseG1GC", "UseParallelGC", "UseSerialGC", "UseShenandoahGC", "UseZGC", "UseEpsilonGC")
    try { $output = & java -XX:+PrintFlagsFinal -version 2>&1 | ForEach-Object { $_.ToString() } } catch { return "N/D" }
    foreach ($line in $output) {
        $parts = $line.Trim() -split '\s+'
        if ($parts.Count -ge 4 -and $parts[0] -eq "bool" -and $knownGcFlags -contains $parts[1] -and $parts[2] -eq "=" -and $parts[3] -eq "true") { return $parts[1] }
    }
    return "N/D"
}
function Assert-LastExitCode([string]$Description) {
    if ($LASTEXITCODE -ne 0) { throw "$Description falhou com codigo de saida $LASTEXITCODE." }
}

if (-not $Batch) {
    $RunName = Read-Host "Digite o nome da execucao (ENTER para timestamp)"
    $B = [int](Read-Host "Digite o tamanho maximo de matriz (B)")
    $Escala = [int](Read-Host "Escolha a escala [0]=Logaritmica, [1]=Linear")
    $Npts = [int](Read-Host "Digite o numero de pontos na escala (Npts)")
    $M = [int](Read-Host "Digite a quantidade de repeticoes para media (M)")
}
if ([string]::IsNullOrWhiteSpace($RunName)) { $RunName = Get-Date -Format "yyyyMMdd_HHmmss" }

Validate-RunName $RunName
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

# Preflight das extras solicitadas: falha antes de criar staging ou executar o nucleo.
if ($WithRust) { Require-Command "rustc" }
if ($WithJulia) { Require-Command "julia" }
if ($WithElixir) { Require-Command "elixir" }

$FinalDir = Join-Path "out" $RunName
$OutDir = Join-Path "out" ".running-$RunName"
$BuildWin = Join-Path "build" "windows"
$BuildJava = Join-Path "build" "java"
if (Test-Path -LiteralPath $FinalDir) { throw "Caminho final de execucao ja existe: $FinalDir. Use outro -RunName; o runner nunca reutiliza um destino final, mesmo vazio." }
if (Test-Path -LiteralPath $OutDir) { throw "Diretorio de trabalho temporario ja existe: $OutDir. Isso indica uma execucao anterior incompleta com o mesmo -RunName. Inspecione e remova-o manualmente antes de tentar novamente." }
New-Dir $OutDir; New-Dir $BuildWin; New-Dir $BuildJava

Write-Host "Resultados serao salvos em $FinalDir"
Write-Host "Diretorio de trabalho temporario (ate a validacao final): $OutDir"
Write-Host "Artefatos de compilacao em build/"
Write-Host "-----------------------------------"

$CExe = Join-Path $BuildWin "matriz_c.exe"
$CO3Exe = Join-Path $BuildWin "matriz_c_O3.exe"
$CppExe = Join-Path $BuildWin "matriz_cpp.exe"
$CppO3Exe = Join-Path $BuildWin "matriz_cpp_O3.exe"

Write-Host "Compilando C..."
gcc -std=c11 -Wall -Wextra src\matriz_c.c -o $CExe -lm; Assert-LastExitCode "Compilacao do C"
gcc -std=c11 -Wall -Wextra src\matriz_c.c -o $CO3Exe -lm -O3; Assert-LastExitCode "Compilacao do C -O3"
Write-Host "Compilando C++..."
g++ -std=c++17 -Wall -Wextra src\matriz_cpp.cpp -o $CppExe; Assert-LastExitCode "Compilacao do C++"
g++ -std=c++17 -Wall -Wextra src\matriz_cpp.cpp -o $CppO3Exe -O3; Assert-LastExitCode "Compilacao do C++ -O3"
Write-Host "Compilando Java..."
javac -d $BuildJava src\matriz_java.java; Assert-LastExitCode "Compilacao do Java"

Write-Host "Executando C..."; & $CExe $B $Npts $M $Escala (Join-Path $OutDir "resultado_c.csv"); Assert-LastExitCode "Execucao do C"
Write-Host "Executando C -O3..."; & $CO3Exe $B $Npts $M $Escala (Join-Path $OutDir "resultado_c_O3.csv"); Assert-LastExitCode "Execucao do C -O3"
Write-Host "Executando C++..."; & $CppExe $B $Npts $M $Escala (Join-Path $OutDir "resultado_cpp.csv"); Assert-LastExitCode "Execucao do C++"
Write-Host "Executando C++ -O3..."; & $CppO3Exe $B $Npts $M $Escala (Join-Path $OutDir "resultado_cpp_O3.csv"); Assert-LastExitCode "Execucao do C++ -O3"
Write-Host "Executando Java..."; java -cp $BuildJava matriz_java $B $Npts $M $Escala (Join-Path $OutDir "resultado_java.csv"); Assert-LastExitCode "Execucao do Java"
Write-Host "Executando Python..."; python src\matriz_python.py $B $Npts $M $Escala (Join-Path $OutDir "resultado_python.csv"); Assert-LastExitCode "Execucao do Python"

$RustVersion = ""; $JuliaVersion = ""; $ElixirVersion = ""
if ($WithRust) {
    $RustExe = Join-Path $BuildWin "matriz_rust.exe"
    Write-Host "Compilando Rust..."; rustc --edition=2021 -C opt-level=3 -D warnings src\matriz_rust.rs -o $RustExe; Assert-LastExitCode "Compilacao do Rust"
    Write-Host "Executando Rust..."; & $RustExe $B $Npts $M $Escala (Join-Path $OutDir "resultado_rust.csv"); Assert-LastExitCode "Execucao do Rust"
    $RustVersion = First-Line { rustc --version }
}
if ($WithJulia) {
    Write-Host "Executando Julia..."; julia src\matriz_Julia.jl $B $Npts $M $Escala (Join-Path $OutDir "resultado_julia.csv"); Assert-LastExitCode "Execucao do Julia"
    $JuliaVersion = First-Line { julia --version }
}
if ($WithElixir) {
    Write-Host "Executando Elixir..."; elixir src\matriz_multiplication.exs $B $Npts $M $Escala (Join-Path $OutDir "resultado_elixir.csv"); Assert-LastExitCode "Execucao do Elixir"
    $ElixirVersion = (elixir --version | Where-Object { $_ -match '^Elixir' } | Select-Object -First 1); if (-not $ElixirVersion) { $ElixirVersion = "N/D" }
}

Write-Host "Gerando system_info.md e system_info.json..."
$Os = Get-CimInstance Win32_OperatingSystem
$Cs = Get-CimInstance Win32_ComputerSystem
$Cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$RamGb = [math]::Round($Cs.TotalPhysicalMemory / 1GB, 2)
$GeneratedAt = (Get-Date).ToString("o")
$SysMd = Join-Path $OutDir "system_info.md"; $SysJson = Join-Path $OutDir "system_info.json"
$md = @("# Informações do Sistema", "", "_Gerado em: ${GeneratedAt}_", "", "## Windows", "- **Edição/Versão**: $($Os.Caption) $($Os.Version)", "- **Build**: $($Os.BuildNumber)", "", "### CPU", "- **Modelo**: $($Cpu.Name)", "- **Núcleos físicos**: $($Cpu.NumberOfCores)", "- **Threads lógicas**: $($Cpu.NumberOfLogicalProcessors)", "- **Clock máximo MHz**: $($Cpu.MaxClockSpeed)", "", "### Memória", "- **RAM total**: $RamGb GB")
$md | Set-Content -Encoding utf8 $SysMd
$sysInfo = [ordered]@{ generated_at = $GeneratedAt; windows = [ordered]@{ caption = $Os.Caption; version = $Os.Version; build = $Os.BuildNumber; cpu = [ordered]@{ model = $Cpu.Name; physical_cores = $Cpu.NumberOfCores; logical_processors = $Cpu.NumberOfLogicalProcessors; max_mhz = $Cpu.MaxClockSpeed }; memory = [ordered]@{ ram_gb = $RamGb } } }
$sysInfo | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 $SysJson

$ManifestTools = [ordered]@{ gcc = First-Line { gcc --version }; "g++" = First-Line { g++ --version }; java = AllLines { java -version }; java_gc = Get-JavaGC; javac = First-Line { javac -version }; python = First-Line { python --version } }
$ManifestLanguages = [System.Collections.Generic.List[object]]::new()
$ManifestLanguages.Add([ordered]@{ name = "C"; flags = "-std=c11 -Wall -Wextra"; output = "resultado_c.csv" })
$ManifestLanguages.Add([ordered]@{ name = "C"; flags = "-std=c11 -Wall -Wextra -O3"; output = "resultado_c_O3.csv" })
$ManifestLanguages.Add([ordered]@{ name = "C++"; flags = "-std=c++17 -Wall -Wextra"; output = "resultado_cpp.csv" })
$ManifestLanguages.Add([ordered]@{ name = "C++"; flags = "-std=c++17 -Wall -Wextra -O3"; output = "resultado_cpp_O3.csv" })
$ManifestLanguages.Add([ordered]@{ name = "Java"; flags = ""; output = "resultado_java.csv" })
$ManifestLanguages.Add([ordered]@{ name = "Python"; flags = ""; output = "resultado_python.csv" })
if ($WithRust) { $ManifestLanguages.Add([ordered]@{ name = "Rust"; flags = "--edition=2021 -C opt-level=3 -D warnings"; output = "resultado_rust.csv" }); $ManifestTools["rustc"] = $(if ($RustVersion) { $RustVersion } else { "N/D" }) }
if ($WithJulia) { $ManifestLanguages.Add([ordered]@{ name = "Julia"; flags = ""; output = "resultado_julia.csv" }); $ManifestTools["julia"] = $(if ($JuliaVersion) { $JuliaVersion } else { "N/D" }) }
if ($WithElixir) { $ManifestLanguages.Add([ordered]@{ name = "Elixir"; flags = ""; output = "resultado_elixir.csv" }); $ManifestTools["elixir"] = $(if ($ElixirVersion) { $ElixirVersion } else { "N/D" }) }
$Manifest = [ordered]@{ run_id = $RunName; generated_at = (Get-Date).ToUniversalTime().ToString("o"); commit_hash = First-Line { git rev-parse HEAD }; system = [ordered]@{ platform = "$($Os.Caption) $($Os.Version)"; machine = $env:PROCESSOR_ARCHITECTURE; python = First-Line { python --version } }; parameters = [ordered]@{ B = $B; Npts = $Npts; M = $M; escala = $Escala }; tools = $ManifestTools; languages = $ManifestLanguages }
$Manifest | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $OutDir "run_manifest.json")

Write-Host "Gerando graficos..."; python src\plot_benchmarks.py $OutDir; Assert-LastExitCode "Geracao dos graficos"
Write-Host "Validando execucao..."; python scripts\validate_run.py $OutDir; Assert-LastExitCode "Validacao da execucao"
Write-Host "Promovendo execucao para o diretorio final..."; Move-Item -LiteralPath $OutDir -Destination $FinalDir
Write-Host "-----------------------------------"
Write-Host "Finalizado. Arquivos em: $FinalDir"
