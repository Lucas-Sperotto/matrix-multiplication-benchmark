#!/bin/bash


# ----------------------------
# Verificação e instalação de requisitos
# ----------------------------

check_install() {
    PKG=$1
    CMD=$2
    if ! command -v "$CMD" &> /dev/null; then
        echo "[$PKG] não encontrado. Instalando..."
        sudo apt update
        sudo apt install -y "$PKG"
    else
        echo "[$PKG] já está instalado."
    fi
}

echo "🔍 Verificando dependências..."
check_install gcc gcc
check_install g++ g++
check_install default-jre java
check_install default-jdk javac
check_install python3 python3

# ----------------------------
# Verificação psutil (Python)
# ----------------------------
python3 -c "import psutil" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "📦 Instalando python3-psutil (sudo pode ser solicitado)..."
    sudo apt update
    sudo apt install -y python3-psutil
fi

echo "✅ Todas as dependências verificadas."
echo "-----------------------------------"


# ----------------------------
# Execução dos benchmarks
# ----------------------------

# Lista de valores de N
Ns=(10 100 500 1000 1500 2000 2500 3000)

# Pergunta o nome da execução
read -p "Digite o nome da execução: " RUN_NAME

# Cria pasta de saída
OUT_DIR="out/$RUN_NAME"
mkdir -p "$OUT_DIR"

echo "Resultados serão salvos em $OUT_DIR"
echo "-----------------------------------"

# Pergunta a quantidade de execuções para o calculo da media
read -p "Digite a quantidade de execuções para o calculo da media: " M

# 1. Compilar e executar C
echo "Compilando matriz_c.c..."
gcc src/matriz_c.c -o matriz_c -O3
if [ $? -eq 0 ]; then
    echo "Executando C..."
    ./matriz_c "$M"
    mv resultado_c.csv "$OUT_DIR/"
else
    echo "Erro na compilação de matriz_c.c"
fi

# 2. Compilar e executar C++
echo "Compilando matriz_cpp.cpp..."
g++ src/matriz_cpp.cpp -o matriz_cpp -O3
if [ $? -eq 0 ]; then
    echo "Executando C++..."
    ./matriz_cpp "$M"
    mv resultado_cpp.csv "$OUT_DIR/"
else
    echo "Erro na compilação de matriz_cpp.cpp"
fi

# 3. Compilar e executar Java
echo "Compilando MatrixMultiplication.java..."
javac src/MatrixMultiplication.java
if [ $? -eq 0 ]; then
    echo "Executando Java..."
    java -cp src MatrixMultiplication "$M"
    mv resultado_java.csv "$OUT_DIR/" 2>/dev/null || echo "Arquivo de saída Java não encontrado."
else
    echo "Erro na compilação de MatrixMultiplication.java"
fi

# 4. Executar Python
echo "Executando Python..."
python3 src/matriz_python.py "$M"
mv resultado_python.csv "$OUT_DIR/"

echo "-----------------------------------"
echo "Execução concluída! Resultados em: $OUT_DIR"

# ----------------------------
# Geração de gráficos
# ----------------------------
echo "Gerando gráficos..."
python3 src/plot_benchmarks.py "$OUT_DIR"