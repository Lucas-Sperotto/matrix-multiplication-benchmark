/**********************************************************************
 * Teste de corretude (nao de desempenho) para src/matriz_java.java.
 *
 * Reusa a multiply() de producao (visibilidade de pacote, nao private,
 * ver src/matriz_java.java) com um caso conhecido nao identidade, fora
 * da janela de benchmark. Mesmo pacote default de matriz_java, para
 * poder chamar o metodo sem torna-lo publico.
 *
 * Compilar e executar junto de matriz_java.class:
 *   javac -d build/java src/matriz_java.java tests/TestMatrizJava.java
 *   java -cp build/java TestMatrizJava
 **********************************************************************/
public class TestMatrizJava {
    public static void main(String[] args) {
        // A = [[1,2],[3,4]], B = [[5,6],[7,8]]
        int[][] mat1 = {{1, 2}, {3, 4}};
        int[][] mat2 = {{5, 6}, {7, 8}};
        int[][] res = new int[2][2];
        int[][] expected = {{19, 22}, {43, 50}};

        matriz_java.multiply(mat1, mat2, res, 2);

        for (int i = 0; i < 2; i++) {
            for (int j = 0; j < 2; j++) {
                if (res[i][j] != expected[i][j]) {
                    System.err.printf("FALHA: res[%d][%d]=%d, esperado=%d%n", i, j, res[i][j], expected[i][j]);
                    System.exit(1);
                }
            }
        }

        System.out.println("OK: matriz_java multiply() caso nao identidade 2x2");
    }
}
