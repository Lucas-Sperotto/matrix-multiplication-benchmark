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

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;

public class matriz_java {
    private static int parseInt(String text, String name, int minValue, int maxValue) {
        try {
            int value = Integer.parseInt(text);
            if (value < minValue || value > maxValue) {
                throw new NumberFormatException();
            }
            return value;
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Parametro invalido para " + name + ": " + text);
        }
    }

    private static int[] makePoints(int b, int npts, int escala) {
        int a = 100;
        int[] points = new int[npts];

        if (escala == 1) {
            double step = (double) (b - a) / (double) (npts - 1);
            for (int i = 0; i < npts; i++) {
                points[i] = (int) Math.round(a + step * i);
            }
        } else {
            double ratio = Math.pow((double) b / (double) a, 1.0 / (double) (npts - 1));
            for (int i = 0; i < npts; i++) {
                points[i] = (int) Math.round(a * Math.pow(ratio, i));
            }
        }

        return points;
    }

    private static void multiply(int[][] mat1, int[][] mat2, int[][] res, int n) {
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                int sum = 0;
                for (int k = 0; k < n; k++) {
                    sum += mat1[i][k] * mat2[k][j];
                }
                res[i][j] = sum;
            }
        }
    }

    private static boolean verifySample(int[][] res, int n) {
        int[] idxs = {0, n / 2, n - 1};

        for (int i : idxs) {
            for (int j : idxs) {
                if (res[i][j] != i + j) {
                    System.err.printf(Locale.US, "Erro na multiplicacao para N=%d em [%d,%d]%n", n, i, j);
                    return false;
                }
            }
        }

        return true;
    }

    private static double[] runOnce(int n) {
        long start = System.nanoTime();
        int[][] mat1 = new int[n][n];
        int[][] mat2 = new int[n][n];
        int[][] res = new int[n][n];

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                mat1[i][j] = i + j;
                mat2[i][j] = (i == j) ? 1 : 0;
            }
        }
        long end = System.nanoTime();
        double timeAlloc = (end - start) / 1e9;

        start = System.nanoTime();
        multiply(mat1, mat2, res, n);
        end = System.nanoTime();
        double timeCalc = (end - start) / 1e9;

        if (!verifySample(res, n)) {
            throw new IllegalStateException("Falha na verificacao do resultado.");
        }

        return new double[] {timeCalc, timeAlloc, 0.0};
    }

    public static void main(String[] args) {
        Locale.setDefault(Locale.US);

        if (args.length != 5) {
            System.err.println("Uso: java matriz_java <B> <Npts> <M> <Escala> <out_csv>");
            System.err.println("Exemplo: java matriz_java 4000 12 5 1 out/execucao/resultado_java.csv");
            System.exit(1);
        }

        try {
            int b = parseInt(args[0], "B", 100, 100000);
            int npts = parseInt(args[1], "Npts", 2, 10000);
            int mCount = parseInt(args[2], "M", 1, 100000);
            int escala = parseInt(args[3], "Escala", 0, 1);
            Path outCsv = Path.of(args[4]);
            Path parent = outCsv.getParent();
            if (parent != null) {
                Files.createDirectories(parent);
            }

            try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(outCsv))) {
                writer.println("N,TCS,TAM,TDM");

                for (int n : makePoints(b, npts, escala)) {
                    double timeCalc = 0.0;
                    double timeAlloc = 0.0;
                    double timeFree = 0.0;

                    for (int m = 0; m < mCount; m++) {
                        double[] times = runOnce(n);
                        timeCalc += times[0];
                        timeAlloc += times[1];
                        timeFree += times[2];
                    }

                    writer.printf(Locale.US, "%d,%.6e,%.6e,%.6e%n",
                            n,
                            timeCalc / mCount,
                            timeAlloc / mCount,
                            timeFree / mCount);
                    System.out.println("Resultados para N = " + n + " salvos.");
                }
            }

            System.out.println("Todos os resultados foram salvos em " + outCsv + ".");
        } catch (IOException | RuntimeException ex) {
            System.err.println(ex.getMessage());
            System.exit(1);
        }
    }
}
