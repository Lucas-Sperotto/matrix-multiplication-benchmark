#!/bin/bash


# ----------------------------
# Verificação e instalação de requisitos
# ----------------------------

check_install() {
    PKG=$1
    CMD=$2
    if ! command -v "$CMD" &> /dev/null; then
        echo "❌ [$PKG] não encontrado. Instalando..."
        sudo apt update
        sudo apt install -y "$PKG"
    else
        echo "✅ [$PKG] já está instalado."
    fi
}

check_python_package() {
    PKG=$1
    python3 -c "import $PKG" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Pacote Python '$PKG' não encontrado. Tentando instalar com apt..."
        if apt-cache search "python3-$PKG" | grep -q "python3-$PKG"; then
            sudo apt-get install -y "python3-$PKG"
        else
            echo "⚠️  Pacote python3-$PKG não encontrado no apt. Instalando com pip..."
            pip3 install --user "$PKG"
        fi
    else
        echo "✅ Pacote Python '$PKG' já está instalado."
    fi
}

echo "🔍 Verificando dependências..."
check_install gcc gcc
check_install g++ g++
check_install default-jre java
check_install default-jdk javac
check_install python3 python3
check_python_package pandas
check_python_package matplotlib
check_python_package psutil



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
read -p "Digite o tamanho maximo de Matriz: " B
read -p "Digite o numero de pontos na escala Log:" Npts
read -p "Digite a quantidade de execuções para o calculo da media: " M




# 1. Compilar e executar C
echo "Compilando matriz_c.c..."
gcc src/matriz_c.c -o matriz_c -lm -O3
if [ $? -eq 0 ]; then
    echo "Executando C..."
    ./matriz_c "$B" "$Npts" "$M"
    mv resultado_c.csv "$OUT_DIR/"
else
    echo "Erro na compilação de matriz_c.c"
fi

# 2. Compilar e executar C++
echo "Compilando matriz_cpp.cpp..."
g++ src/matriz_cpp.cpp -o matriz_cpp -O3
if [ $? -eq 0 ]; then
    echo "Executando C++..."
    ./matriz_cpp "$B" "$Npts" "$M"
    mv resultado_cpp.csv "$OUT_DIR/"
else
    echo "Erro na compilação de matriz_cpp.cpp"
fi

# 3. Compilar e executar Java
echo "Compilando matriz_java.java..."
javac src/matriz_java.java
if [ $? -eq 0 ]; then
    echo "Executando Java..."
    java -cp src matriz_java "$B" "$Npts" "$M"
    mv resultado_java.csv "$OUT_DIR/" 2>/dev/null || echo "Arquivo de saída Java não encontrado."
else
    echo "Erro na compilação de matriz_java.java"
fi

# 4. Executar Python
echo "Executando Python..."
python3 src/matriz_python.py "$B" "$Npts" "$M"
mv resultado_python.csv "$OUT_DIR/"

echo "-----------------------------------"
echo "Execução concluída! Resultados em: $OUT_DIR"

# 5. Capturando informações de hardware
echo "Capturando informações de hardware"
./gen_sysinfo_md.sh
mv system_info.md "$OUT_DIR/"

# ----------------------------
# Geração de gráficos
# ----------------------------
echo "Gerando gráficos..."
python3 src/plot_benchmarks.py "$OUT_DIR"