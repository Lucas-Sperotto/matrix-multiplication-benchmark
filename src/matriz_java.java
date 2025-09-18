
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
import java.util.Locale;

public class matriz_java {

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

    public static int[] logspace(int b, int Npts) {
        int a = 100; // valor inicial fixo
        if (Npts < 2)
            return new int[0]; // retorna array vazio se Npts < 2

        int[] arr = new int[Npts];

        double r = Math.pow((double) b / a, 1.0 / (Npts - 1)); // razão geométrica
        for (int i = 0; i < Npts; i++) {
            arr[i] = (int) Math.round(a * Math.pow(r, i)); // arredonda para inteiro
        }

        return arr;
    }

    public static int[] linear(int b, int Npts) {
        int a = 100; // valor inicial fixo
        if (Npts < 2)
            return new int[0]; // retorna array vazio se Npts < 2

        int[] arr = new int[Npts];

        double step = (b - a) / (Npts - 1);

        for (int i = 0; i < Npts; i++) {
            arr[i] = (int) (a + step * i + 0.5);
        }

        return arr;
    }

    public static void main(String[] args) {
        Locale.setDefault(Locale.US);

        int i, j;
        try {
            int M = 1; // valor padrão

            if (args.length <= 3) {
                System.out.println("Uso: java_matriz <B> <Npts> <M> <Escala>");
                System.out.println("Exemplo: java_matriz 4000 12 5 1");
                return;
            }

            // Converte os argumentos de String para inteiro
            int B = Integer.parseInt(args[0]); // valor máximo
            int Npts = Integer.parseInt(args[1]); // quantidade de pontos
            M = Integer.parseInt(args[2]); // número de repetições
            int escala = Integer.parseInt(args[3]);

            int[] Ns = (escala == 1) ? linear(B, Npts) : logspace(B, Npts);

            FileWriter writer = new FileWriter("resultado_java.csv");

            writer.write("N,TCS,TAM\n");

            // System.out.println(" B: " + B + "\n");
            // System.out.println(" Npts: " + Npts + "\n");
            // System.out.println(" M: " + M + "\n");

            for (int n = 0; n < Npts; n++) {

                int N = Ns[n];
                double timeAlloc = 0.0, timeCalc = 0.0;

                for (int m = 1; m <= M; m++) {

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
                    timeAlloc += (endAlloc - startAlloc) / 1e9;

                    // Tempo do cálculo
                    long startCalc = System.nanoTime();
                    multiply(mat1, mat2, res, N);
                    long endCalc = System.nanoTime();
                    timeCalc += (endCalc - startCalc) / 1e9;

                    // Java faz a coleta de lixo automaticamente, então não medimos o tempo de
                    // liberação manual.

                    // Verificação do resultado
                    for (i = 0; i < N; i++) {
                        for (j = 0; j < N; j++) {
                            if (res[i][j] != i + j)
                                System.out.println("Erro na multiplicação das matrizes para N = " + N + "!");
                        }
                    }
                    // System.out.println(N + ",");
                    // System.out.println(String.format("%.6e", timeCalc) + ",");
                    // System.out.println(String.format("%.6e", timeAlloc) + "\n");
                }
                // Salvando os resultados no arquivo
                writer.write(N + ",");
                writer.write(String.format("%.6e", (timeCalc / M)) + ",");
                writer.write(String.format("%.6e", (timeAlloc / M)) + "\n");

                System.out.println("Resultados para N = " + N + " salvos.");

            }

            writer.close();
            System.out.println("Todos os resultados foram salvos no arquivo resultado_java.csv.");
        } catch (IOException e) {
            System.out.println("Ocorreu um erro ao salvar os resultados.");
            e.printStackTrace();
        }
    }
}
