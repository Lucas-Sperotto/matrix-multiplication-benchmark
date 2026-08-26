/**********************************************************************
 * Teste de corretude (nao de desempenho) para src/matriz_cpp.cpp.
 * Mesmo racional de tests/test_matriz_c.c: reusa a multiply() de
 * producao com um caso conhecido nao identidade, fora da janela de
 * benchmark, sem duplicar nem alterar o codigo de producao.
 *
 * Compilar e executar separadamente do build do runner:
 *   g++ -std=c++17 -Wall -Wextra -Wno-unused-function \
 *       tests/test_matriz_cpp.cpp -o build/test_matriz_cpp
 *   ./build/test_matriz_cpp
 **********************************************************************/

#include <iostream>
#include <vector>

#define main matriz_cpp_main
#include "../src/matriz_cpp.cpp"
#undef main

int main()
{
    // A = [[1,2],[3,4]], B = [[5,6],[7,8]] (row-major, flat i*n+j).
    std::vector<int> mat1 = {1, 2, 3, 4};
    std::vector<int> mat2 = {5, 6, 7, 8};
    std::vector<int> res(4, 0);
    std::vector<int> expected = {19, 22, 43, 50};

    multiply(mat1, mat2, res, 2);

    if (res != expected)
    {
        std::cerr << "FALHA: multiply() nao produziu o resultado esperado\n";
        return 1;
    }

    std::cout << "OK: matriz_cpp multiply() caso nao identidade 2x2\n";
    return 0;
}
