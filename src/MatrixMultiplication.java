/**********************************************************************
 * Projeto: Benchmark de Multiplicação de Matrizes
 * Descrição: Este código realiza a multiplicação de duas matrizes 
 *            de tamanho N x N, variando automaticamente o valor de N 
 *            e medindo o tempo de alocação de memória e do cálculo.
 *            O código salva os resultados em um arquivo de saída.
 *
 * Linguagem: Java
 *
 * Autores: Lucas Kriesel Sperotto, Marcos Adriano SIlva David
 * Data: 05/09/2024
 *
 * Parâmetros:
 *  - N: tamanho da matriz (varia de 10 até 10.000)
 *
 * Saída: Arquivo de resultados contendo:
 *  - Tempo de alocação de memória
 *  - Tempo de cálculo (multiplicação das matrizes)
 *
 * Uso:
 *  - Compile e execute o código, e o arquivo de saída será gerado 
 *    contendo os resultados para diferentes valores de N.
 **********************************************************************/

import java.io.FileWriter;
import java.io.IOException;

public class MatrixMultiplication {

    public static void multiply(int[][] mat1, int[][] mat2, int[][] res, int N) {
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                res[i][j] = 0;
                for (int k = 0; k < N; k++) {
                    res[i][j] += mat1[i][k] * mat2[k][j];
                }
            }
        }
    }

    public static void main(String[] args) {
        int i, j;
        try {
            FileWriter writer = new FileWriter("resultado_java.dat");
            for (int N : new int[] { 10, 100, 1000, 2000, 3000, 4000 }) { // Varie
                                                                                                               // N
                                                                                                               // automaticamente
                                                                                                               // de 10
                                                                                                               // a
                                                                                                               // 10000

                // Tempo de alocação de memória
                long startAlloc = System.nanoTime();
                int[][] mat1 = new int[N][N];
                int[][] mat2 = new int[N][N];
                int[][] res = new int[N][N];

                // Inicializando as matrizes
                for (i = 0; i < N; i++) {
                    for (j = 0; j < N; j++) {
                        mat1[i][j] = i + j;
                        if (i == j)
                            mat2[i][j] = 1;
                        else {
                            mat2[i][j] = 0;
                        }
                    }
                }
                long endAlloc = System.nanoTime();
                double timeAlloc = (endAlloc - startAlloc) / 1e9;

                // Tempo do cálculo
                long startCalc = System.nanoTime();
                multiply(mat1, mat2, res, N);
                long endCalc = System.nanoTime();
                double timeCalc = (endCalc - startCalc) / 1e9;

                // Java faz a coleta de lixo automaticamente, então não medimos o tempo de
                // liberação manual.

                // Verificação do resultado
                for (i = 0; i < N; i++) {
                    for (j = 0; j < N; j++) {
                        if (res[i][j] != i + j)
                            System.out.println("Erro na multiplicação das matrizes para N = " + N + "!");
                    }
                }

                // Salvando os resultados no arquivo
                writer.write("N = " + N + "\n");
                writer.write("Tempo de alocação de memória: " + timeAlloc + " segundos\n");
                writer.write("Tempo de cálculo: " + timeCalc + " segundos\n\n");

                System.out.println("Resultados para N = " + N + " salvos.");

            }

            writer.close();
            System.out.println("Todos os resultados foram salvos no arquivo resultado_java.dat.");
        } catch (IOException e) {
            System.out.println("Ocorreu um erro ao salvar os resultados.");
            e.printStackTrace();
        }
    }
}
