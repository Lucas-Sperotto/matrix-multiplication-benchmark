<# 
  run_all.ps1  —  Windows/PowerShell
  Espelha o fluxo do run_all.sh (Linux): dependências, C/C++ (-O3 e normal), Java, Python,
  captura de system_info.md e geração de gráficos.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ----------------------------
# Utilidades
# ----------------------------
function Have($cmd) {
  $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Need-Tool($display, $cmd, $wingetId) {
  if (Have $cmd) {
    Write-Host "✅ [$display] já está instalado ($cmd encontrado)."
    return $true
  } else {
    Write-Host "❌ [$display] não encontrado."
    if (Have "winget") {
      $ans = Read-Host "Deseja instalar $display via winget agora? (s/N)"
      if ($ans -match '^(s|S|y|Y)') {
        try {
          winget install -e --id $wingetId --accept-source-agreements --accept-package-agreements
          if (Have $cmd) {
            Write-Host "✅ $display instalado."
            return $true
          } else {
            Write-Warning "⚠️  $display ainda não aparece no PATH nesta sessão. Abra um novo terminal ou adicione manualmente ao PATH."
            return $false
          }
        } catch {
          Write-Warning "⚠️  Falha ao instalar $display via winget: $($_.Exception.Message)"
          return $false
        }
      } else {
        Write-Warning "⚠️  Pulei a instalação de $display. Certifique-se de instalá-lo."
        return $false
      }
    } else {
      Write-Warning "⚠️  winget não disponível. Instale $display manualmente."
      return $false
    }
  }
}

function Ensure-PythonPackage($pkg) {
  try {
    python - <<PY
import importlib, sys
sys.exit(0 if importlib.util.find_spec("$pkg") else 1)
PY
    if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ Pacote Python '$pkg' já está instalado."
      return
    }
  } catch {}

  Write-Host "❌ Pacote Python '$pkg' não encontrado. Instalando com pip..."
  try {
    pip install $pkg
    Write-Host "✅ '$pkg' instalado."
  } catch {
    Write-Warning "⚠️  Falha ao instalar '$pkg': $($_.Exception.Message)"
  }
}

function New-Dir($path) {
  if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null }
}

# ----------------------------
# Checagem de dependências
# ----------------------------
Write-Host "🔍 Verificando dependências..."

# Observação: para gcc/g++, recomendo MSYS2 ou Mingw-w64.
$okGcc = Need-Tool "GCC (C)" "gcc" "MSYS2.MSYS2"
$okGpp = Need-Tool "G++ (C++)" "g++" "MSYS2.MSYS2"

# Java JRE/JDK — você pode usar Temurin:
$okJava = Need-Tool "Java Runtime" "java" "EclipseAdoptium.Temurin.21.JRE"   # ajuste se quiser JRE 17
$okJavac = Need-Tool "Java JDK (javac)" "javac" "EclipseAdoptium.Temurin.21.JDK"

# Python + pip
$okPy = Need-Tool "Python 3" "python" "Python.Python.3.12"
$okPip = Have "pip"

if (-not $okPip -and $okPy) {
  try {
    python -m ensurepip --upgrade
    $okPip = Have "pip"
  } catch {
    Write-Warning "⚠️  Não consegui configurar pip automaticamente."
  }
}

if ($okPy -and $okPip) {
  Ensure-PythonPackage "pandas"
  Ensure-PythonPackage "matplotlib"
  Ensure-PythonPackage "psutil"
} else {
  Write-Warning "⚠️  Python/pip indisponíveis — a etapa Python e os gráficos podem falhar."
}

Write-Host "✅ Verificação concluída."
Write-Host "-----------------------------------"

# ----------------------------
# Entradas do usuário
# ----------------------------
$RUN_NAME = Read-Host "Digite o nome da execução"
$OUT_DIR  = Join-Path "out" $RUN_NAME
New-Dir $OUT_DIR
Write-Host "Resultados serão salvos em $OUT_DIR"
Write-Host "-----------------------------------"

# Mantendo o mesmo diálogo do run_all.sh (:contentReference[oaicite:2]{index=2})
$B      = Read-Host "Digite o tamanho máximo de Matriz (B)"
$ESCALA = Read-Host "Escolha o tipo de escala gráfica: [0] = Logarítmica, [1] = Linear"
$Npts   = Read-Host "Digite o número de pontos na escala (Npts)"
$M      = Read-Host "Digite a quantidade de execuções para o cálculo da média (M)"

# ----------------------------
# Compilar/Executar C Otimizado e Normal
# ----------------------------
try {
  Write-Host "Compilando src\matriz_c.c (com -O3)..."
  gcc src\matriz_c.c -o matriz_c.exe -lm -O3
  Write-Host "Executando C -O3..."
  .\matriz_c.exe $B $Npts $M $ESCALA "-O3"
  if (Test-Path "resultado_c_O3.csv") { Move-Item -Force "resultado_c_O3.csv" (Join-Path $OUT_DIR "resultado_c_O3.csv") }
} catch {
  Write-Warning "⚠️  Erro na compilação/execução otimizada de C: $($_.Exception.Message)"
}

try {
  Write-Host "Compilando src\matriz_c.c (sem -O3)..."
  gcc src\matriz_c.c -o matriz_c.exe -lm
  Write-Host "Executando C..."
  .\matriz_c.exe $B $Npts $M $ESCALA
  if (Test-Path "resultado_c.csv") { Move-Item -Force "resultado_c.csv" (Join-Path $OUT_DIR "resultado_c.csv") }
} catch {
  Write-Warning "⚠️  Erro na compilação/execução normal de C: $($_.Exception.Message)"
}

# ----------------------------
# Compilar/Executar C++ Otimizado e Normal
# ----------------------------
try {
  Write-Host "Compilando src\matriz_cpp.cpp (com -O3)..."
  g++ src\matriz_cpp.cpp -o matriz_cpp.exe -O3
  Write-Host "Executando C++ -O3..."
  .\matriz_cpp.exe $B $Npts $M $ESCALA "-O3"
  if (Test-Path "resultado_cpp_O3.csv") { Move-Item -Force "resultado_cpp_O3.csv" (Join-Path $OUT_DIR "resultado_cpp_O3.csv") }
} catch {
  Write-Warning "⚠️  Erro na compilação/execução otimizada de C++: $($_.Exception.Message)"
}

try {
  Write-Host "Compilando src\matriz_cpp.cpp (sem -O3)..."
  g++ src\matriz_cpp.cpp -o matriz_cpp.exe
  Write-Host "Executando C++..."
  .\matriz_cpp.exe $B $Npts $M $ESCALA
  if (Test-Path "resultado_cpp.csv") { Move-Item -Force "resultado_cpp.csv" (Join-Path $OUT_DIR "resultado_cpp.csv") }
} catch {
  Write-Warning "⚠️  Erro na compilação/execução normal de C++: $($_.Exception.Message)"
}

# ----------------------------
# Compilar/Executar Java
# ----------------------------
try {
  Write-Host "Compilando Java (src\matriz_java.java)..."
  javac src\matriz_java.java
  Write-Host "Executando Java..."
  # se a classe não tem package, o -cp src funciona:
  java -cp src matriz_java $B $Npts $M $ESCALA
  if (Test-Path "resultado_java.csv") { Move-Item -Force "resultado_java.csv" (Join-Path $OUT_DIR "resultado_java.csv") }
} catch {
  Write-Warning "⚠️  Erro na compilação/execução Java: $($_.Exception.Message)"
}

# ----------------------------
# Executar Python
# ----------------------------
try {
  Write-Host "Executando Python..."
  python src\matriz_python.py $B $Npts $M $ESCALA
  if (Test-Path "resultado_python.csv") { Move-Item -Force "resultado_python.csv" (Join-Path $OUT_DIR "resultado_python.csv") }
} catch {
  Write-Warning "⚠️  Erro na execução Python: $($_.Exception.Message)"
}

Write-Host "-----------------------------------"
Write-Host "Execuções concluídas. Salvando em: $OUT_DIR"

# ----------------------------
# Captura de informações do sistema (system_info.md)
# Porta da lógica do gen_sysinfo_md.sh (:contentReference[oaicite:3]{index=3})
# ----------------------------
function Write-SystemInfoMarkdown {
  param([string]$OutFile = "system_info.md")

  $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $os  = (Get-CimInstance Win32_OperatingSystem)
  $cs  = (Get-CimInstance Win32_ComputerSystem)
  $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1)
  $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)

  $wslStatus = ""
  try {
    $wslStatus = wsl.exe --status 2>$null
  } catch {}

  $lines = @(
    "# Informações do Sistema"
    ""
    "_Gerado em: $now_"
    ""
    "## Windows"
    "- **Edição/Versão**: $($os.Caption) $($os.Version)"
    "- **Build**: $($os.BuildNumber)"
    ""
    "### CPU (host)"
    "- **Modelo**: $($cpu.Name)"
    "- **Núcleos (físicos)**: $($cpu.NumberOfCores)"
    "- **Lógicos (threads)**: $($cpu.NumberOfLogicalProcessors)"
    "- **Clock Máx (MHz)**: $($cpu.MaxClockSpeed)"
    ""
    "### Memória (host)"
    "- **RAM física total**: $ramGB GB"
  )

  if ($wslStatus) {
    $lines += @(
      ""
      "### Status do WSL"
      '```'
      ($wslStatus | Out-String).TrimEnd()
      '```'
    )
  }

  $lines | Set-Content -Encoding UTF8 $OutFile
  Write-Host "Arquivo gerado: $OutFile"
}

try {
  Write-Host "Capturando informações de sistema..."
  $sysInfoPath = Join-Path $PWD "system_info.md"
  Write-SystemInfoMarkdown -OutFile $sysInfoPath
  Move-Item -Force $sysInfoPath (Join-Path $OUT_DIR "system_info.md")
} catch {
  Write-Warning "⚠️  Falha ao gerar system_info.md: $($_.Exception.Message)"
}

# ----------------------------
# Geração de gráficos
# ----------------------------
try {
  Write-Host "Gerando gráficos..."
  python src\plot_benchmarks.py $OUT_DIR
} catch {
  Write-Warning "⚠️  Falha ao gerar gráficos: $($_.Exception.Message)"
}

Write-Host "✅ Finalizado. Resultados em: $OUT_DIR"
