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
        try {
            FileWriter writer = new FileWriter("resultado_java.dat");

            for (int N : new int[]{10, 100, 1000, 10000}) {  // Varie N automaticamente de 10 a 10000

                // Tempo de alocação de memória
                long startAlloc = System.nanoTime();
                int[][] mat1 = new int[N][N];
                int[][] mat2 = new int[N][N];
                int[][] res = new int[N][N];
                
                // Inicializando as matrizes
                for (int i = 0; i < N; i++) {
                    for (int j = 0; j < N; j++) {
                        mat1[i][j] = i + j;
                        mat2[i][j] = i - j;
                    }
                }
                long endAlloc = System.nanoTime();
                double timeAlloc = (endAlloc - startAlloc) / 1e9;

                // Tempo do cálculo
                long startCalc = System.nanoTime();
                multiply(mat1, mat2, res, N);
                long endCalc = System.nanoTime();
                double timeCalc = (endCalc - startCalc) / 1e9;

                // Java faz a coleta de lixo automaticamente, então não medimos o tempo de liberação manual.

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
