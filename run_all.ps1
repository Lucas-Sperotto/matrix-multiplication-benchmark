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

if ($WithAllExtras) {
    $WithRust = $true
    $WithJulia = $true
    $WithElixir = $true
}

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
        throw "Dependencia ausente: $Cmd. Instale conforme docs/EXECUTION.md e tente novamente."
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

# Como First-Line, mas preserva todas as linhas (unidas por \n) em vez de
# só a primeira. Usado para `java -version`, cuja 2a/3a linha normalmente
# identifica a VM/vendor (ex.: "OpenJDK 64-Bit Server VM..."), relevante
# para proveniencia experimental.
function AllLines([scriptblock]$Command) {
    try {
        $result = & $Command 2>&1 | ForEach-Object { $_.ToString() }
        if ($null -eq $result -or $result.Count -eq 0) { return "N/D" }
        return ($result -join "`n")
    } catch {
        return "N/D"
    }
}

# Sondagem best-effort do coletor de lixo efetivamente configurado, sem
# fixar nem alterar nenhum parametro de GC usado pelo benchmark (a JVM roda
# com as flags padrao do ambiente em todo o restante do script).
# -XX:+PrintFlagsFinal e um flag de diagnostico HotSpot; pode nao existir ou
# se comportar diferente em outras JVMs (OpenJ9, GraalVM native), por isso
# qualquer falha cai em "N/D" sem abortar a execucao. Lista fechada de
# flags (nao um casamento generico "Use...GC"): varias outras flags
# "Use...GC" existem (ex.: UseMaximumCompactionOnSystemGC) e tambem podem
# estar "= true" sem indicar qual coletor esta em uso.
function Get-JavaGC() {
    $knownGcFlags = @("UseG1GC", "UseParallelGC", "UseSerialGC", "UseShenandoahGC", "UseZGC", "UseEpsilonGC")
    try {
        $output = & java -XX:+PrintFlagsFinal -version 2>&1 | ForEach-Object { $_.ToString() }
    } catch {
        return "N/D"
    }
    foreach ($line in $output) {
        $parts = $line.Trim() -split '\s+'
        if ($parts.Count -ge 4 -and $parts[0] -eq "bool" -and $knownGcFlags -contains $parts[1] -and $parts[2] -eq "=" -and $parts[3] -eq "true") {
            return $parts[1]
        }
    }
    return "N/D"
}

# PowerShell nao trata automaticamente um codigo de saida != 0 de um
# executavel nativo como erro terminante, mesmo com $ErrorActionPreference
# = "Stop". Toda compilacao, benchmark e validacao nativa e conferida
# explicitamente para impedir que um binario antigo ou uma saida invalida
# sejam tratados como sucesso.
function Assert-LastExitCode([string]$Description) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Description falhou com codigo de saida $LASTEXITCODE."
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

# $FinalDir e' o destino publicavel; $OutDir passa a ser um diretorio de
# trabalho temporario sob o mesmo out/, promovido (movido) para $FinalDir
# somente apos toda a execucao E scripts\validate_run.py terem sucesso.
# Isso evita que uma execucao abortada no meio apareça como um out/<run_id>
# completo e indistinguivel de uma execucao valida. Move-Item dentro de
# out/ fica no mesmo volume/drive na esmagadora maioria dos casos (ver
# Tarefa 6 do docs/FINAL_STABILIZATION_PLAN.md para as alternativas
# consideradas).
$FinalDir = Join-Path "out" $RunName
$OutDir = Join-Path "out" ".running-$RunName"
$BuildWin = Join-Path "build" "windows"
$BuildJava = Join-Path "build" "java"
# O destino final precisa ser inteiramente inexistente. Permitir um diretorio
# vazio faria Move-Item colocar o staging dentro dele, em vez de promove-lo
# para o caminho final esperado.
if (Test-Path -LiteralPath $FinalDir) {
    throw "Caminho final de execucao ja existe: $FinalDir. Use outro -RunName; o runner nunca reutiliza um destino final, mesmo vazio."
}
if (Test-Path -LiteralPath $OutDir) {
    throw "Diretorio de trabalho temporario ja existe: $OutDir. Isso indica uma execucao anterior incompleta com o mesmo -RunName (nunca foi promovida a $FinalDir). Inspecione o conteudo para diagnostico e remova-o manualmente antes de tentar novamente."
}
New-Dir $OutDir
New-Dir $BuildWin
New-Dir $BuildJava

Write-Host "Resultados serao salvos em $FinalDir"
Write-Host "Diretorio de trabalho temporario (ate a validacao final): $OutDir"
Write-Host "Artefatos de compilacao em build/"
Write-Host "-----------------------------------"

$CExe = Join-Path $BuildWin "matriz_c.exe"
$CO3Exe = Join-Path $BuildWin "matriz_c_O3.exe"
$CppExe = Join-Path $BuildWin "matriz_cpp.exe"
$CppO3Exe = Join-Path $BuildWin "matriz_cpp_O3.exe"

Write-Host "Compilando C..."
gcc -std=c11 -Wall -Wextra src\matriz_c.c -o $CExe -lm
Assert-LastExitCode "Compilacao do C"
gcc -std=c11 -Wall -Wextra src\matriz_c.c -o $CO3Exe -lm -O3
Assert-LastExitCode "Compilacao do C -O3"

Write-Host "Compilando C++..."
g++ -std=c++17 -Wall -Wextra src\matriz_cpp.cpp -o $CppExe
Assert-LastExitCode "Compilacao do C++"
g++ -std=c++17 -Wall -Wextra src\matriz_cpp.cpp -o $CppO3Exe -O3
Assert-LastExitCode "Compilacao do C++ -O3"

Write-Host "Compilando Java..."
javac -d $BuildJava src\matriz_java.java
Assert-LastExitCode "Compilacao do Java"

Write-Host "Executando C..."
& $CExe $B $Npts $M $Escala (Join-Path $OutDir "resultado_c.csv")
Assert-LastExitCode "Execucao do C"

Write-Host "Executando C -O3..."
& $CO3Exe $B $Npts $M $Escala (Join-Path $OutDir "resultado_c_O3.csv")
Assert-LastExitCode "Execucao do C -O3"

Write-Host "Executando C++..."
& $CppExe $B $Npts $M $Escala (Join-Path $OutDir "resultado_cpp.csv")
Assert-LastExitCode "Execucao do C++"

Write-Host "Executando C++ -O3..."
& $CppO3Exe $B $Npts $M $Escala (Join-Path $OutDir "resultado_cpp_O3.csv")
Assert-LastExitCode "Execucao do C++ -O3"

Write-Host "Executando Java..."
java -cp $BuildJava matriz_java $B $Npts $M $Escala (Join-Path $OutDir "resultado_java.csv")
Assert-LastExitCode "Execucao do Java"

Write-Host "Executando Python..."
python src\matriz_python.py $B $Npts $M $Escala (Join-Path $OutDir "resultado_python.csv")
Assert-LastExitCode "Execucao do Python"

$RustVersion = ""
$JuliaVersion = ""
$ElixirVersion = ""

if ($WithRust) {
    Require-Command "rustc"
    $RustExe = Join-Path $BuildWin "matriz_rust.exe"
    Write-Host "Compilando Rust..."
    rustc --edition=2021 -C opt-level=3 -D warnings src\matriz_rust.rs -o $RustExe
    Assert-LastExitCode "Compilacao do Rust"
    Write-Host "Executando Rust..."
    & $RustExe $B $Npts $M $Escala (Join-Path $OutDir "resultado_rust.csv")
    Assert-LastExitCode "Execucao do Rust"
    $RustVersion = First-Line { rustc --version }
}

if ($WithJulia) {
    Require-Command "julia"
    Write-Host "Executando Julia..."
    julia src\matriz_Julia.jl $B $Npts $M $Escala (Join-Path $OutDir "resultado_julia.csv")
    Assert-LastExitCode "Execucao do Julia"
    $JuliaVersion = First-Line { julia --version }
}

if ($WithElixir) {
    Require-Command "elixir"
    Write-Host "Executando Elixir..."
    elixir src\matriz_multiplication.exs $B $Npts $M $Escala (Join-Path $OutDir "resultado_elixir.csv")
    Assert-LastExitCode "Execucao do Elixir"
    $ElixirVersion = (elixir --version | Where-Object { $_ -match '^Elixir' } | Select-Object -First 1)
    if (-not $ElixirVersion) { $ElixirVersion = "N/D" }
}

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

$ManifestTools = [ordered]@{
    gcc = First-Line { gcc --version }
    "g++" = First-Line { g++ --version }
    java = AllLines { java -version }
    java_gc = Get-JavaGC
    javac = First-Line { javac -version }
    python = First-Line { python --version }
}
$ManifestLanguages = [System.Collections.Generic.List[object]]::new()
$ManifestLanguages.Add([ordered]@{ name = "C"; flags = "-std=c11 -Wall -Wextra"; output = "resultado_c.csv" })
$ManifestLanguages.Add([ordered]@{ name = "C"; flags = "-std=c11 -Wall -Wextra -O3"; output = "resultado_c_O3.csv" })
$ManifestLanguages.Add([ordered]@{ name = "C++"; flags = "-std=c++17 -Wall -Wextra"; output = "resultado_cpp.csv" })
$ManifestLanguages.Add([ordered]@{ name = "C++"; flags = "-std=c++17 -Wall -Wextra -O3"; output = "resultado_cpp_O3.csv" })
$ManifestLanguages.Add([ordered]@{ name = "Java"; flags = ""; output = "resultado_java.csv" })
$ManifestLanguages.Add([ordered]@{ name = "Python"; flags = ""; output = "resultado_python.csv" })

# So entram no manifesto as linguagens solicitadas e executadas com sucesso.
# A versao e metadado: se a sondagem nao produzir texto, usa N/D sem omitir
# uma linguagem que comprovadamente terminou a execucao.
if ($WithRust) {
    $ManifestLanguages.Add([ordered]@{ name = "Rust"; flags = "--edition=2021 -C opt-level=3 -D warnings"; output = "resultado_rust.csv" })
    $ManifestTools["rustc"] = $(if ($RustVersion) { $RustVersion } else { "N/D" })
}
if ($WithJulia) {
    $ManifestLanguages.Add([ordered]@{ name = "Julia"; flags = ""; output = "resultado_julia.csv" })
    $ManifestTools["julia"] = $(if ($JuliaVersion) { $JuliaVersion } else { "N/D" })
}
if ($WithElixir) {
    $ManifestLanguages.Add([ordered]@{ name = "Elixir"; flags = ""; output = "resultado_elixir.csv" })
    $ManifestTools["elixir"] = $(if ($ElixirVersion) { $ElixirVersion } else { "N/D" })
}

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
    tools = $ManifestTools
    languages = $ManifestLanguages
}
$Manifest | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $OutDir "run_manifest.json")

Write-Host "Gerando graficos..."
python src\plot_benchmarks.py $OutDir
Assert-LastExitCode "Geracao dos graficos"

Write-Host "Validando execucao..."
python scripts\validate_run.py $OutDir
Assert-LastExitCode "Validacao da execucao"

# Promocao: so alcancada se tudo acima teve sucesso ($ErrorActionPreference
# = "Stop" mais Assert-LastExitCode abortam o script em qualquer falha
# anterior, inclusive uma falha de validate_run.py).
Write-Host "Promovendo execucao para o diretorio final..."
Move-Item -LiteralPath $OutDir -Destination $FinalDir

Write-Host "-----------------------------------"
Write-Host "Finalizado. Arquivos em: $FinalDir"
