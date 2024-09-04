#include <iostream>
#include <fstream>
#include <ctime>

using namespace std;

void multiply(int** mat1, int** mat2, int** res, int N) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            res[i][j] = 0;
            for (int k = 0; k < N; k++) {
                res[i][j] += mat1[i][k] * mat2[k][j];
            }
        }
    }
}

int main() {
    ofstream file("resultado_cpp.dat");
    if (!file.is_open()) {
        cout << "Erro ao abrir o arquivo!" << endl;
        return 1;
    }

    for (int N = 10; N <= 10000; N *= 10) {  // Varie N automaticamente de 10 a 10000

        // Tempo de alocação de memória
        clock_t start_alloc = clock();
        int** mat1 = new int*[N];
        int** mat2 = new int*[N];
        int** res = new int*[N];

        for (int i = 0; i < N; i++) {
            mat1[i] = new int[N];
            mat2[i] = new int[N];
            res[i] = new int[N];
        }
        clock_t end_alloc = clock();
        double time_alloc = double(end_alloc - start_alloc) / CLOCKS_PER_SEC;

        // Inicializando as matrizes
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                mat1[i][j] = i + j;
                mat2[i][j] = i - j;
            }
        }

        // Tempo do cálculo
        clock_t start_calc = clock();
        multiply(mat1, mat2, res, N);
        clock_t end_calc = clock();
        double time_calc = double(end_calc - start_calc) / CLOCKS_PER_SEC;

        // Tempo de liberação de memória
        clock_t start_free = clock();
        for (int i = 0; i < N; i++) {
            delete[] mat1[i];
            delete[] mat2[i];
            delete[] res[i];
        }
        delete[] mat1;
        delete[] mat2;
        delete[] res;
        clock_t end_free = clock();
        double time_free = double(end_free - start_free) / CLOCKS_PER_SEC;

        // Salvando os resultados no arquivo
        file << "N = " << N << endl;
        file << "Tempo de alocação de memória: " << time_alloc << " segundos" << endl;
        file << "Tempo de cálculo: " << time_calc << " segundos" << endl;
        file << "Tempo de liberação de memória: " << time_free << " segundos" << endl << endl;

        cout << "Resultados para N = " << N << " salvos." << endl;
    }

    file.close();
    cout << "Todos os resultados foram salvos no arquivo resultado_cpp.dat." << endl;

    return 0;
}
