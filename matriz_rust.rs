/**********************************************************************
 * Projeto: Benchmark de Multiplicação de Matrizes
 * Descrição: Este código realiza a multiplicação de duas matrizes 
 *            de tamanho N x N, variando automaticamente o valor de N 
 *            e medindo o tempo de alocação de memória e do cálculo.
 *            O código salva os resultados em um arquivo de saída.
 *
 * Linguagem: Rust
 *
 * Autores: Lucas Kriesel Sperotto, Marcos Adriano Silva David
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

use std::fs::File;
use std::io::Write;
use std::time::Instant;

fn multiply(mat1: &Vec<Vec<i32>>, mat2: &Vec<Vec<i32>>, N: usize) -> Vec<Vec<i32>> {
    let mut res = vec![vec![0; N]; N];
    for i in 0..N {
        for j in 0..N {
            for k in 0..N {
                res[i][j] += mat1[i][k] * mat2[k][j];
            }
        }
    }
    res
}

fn main() {
    let mut file = File::create("resultado_rust.dat").expect("Erro ao criar arquivo");

    for &N in &[10, 100, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000] {  // Varie N automaticamente de 10 a 10000

        // Tempo de alocação de memória
        let start_alloc = Instant::now();
        let mat1: Vec<Vec<i32>> = (0..N).map(|i| (0..N).map(|j| (i + j) as i32).collect()).collect();
        let mat2: Vec<Vec<i32>> = (0..N).map(|i| (0..N).map(|j| if i == j { 1 } else { 0 }).collect()).collect();
        let time_alloc = start_alloc.elapsed();

        // Tempo do cálculo
        let start_calc = Instant::now();
        let _res = multiply(&mat1, &mat2, N);
        let time_calc = start_calc.elapsed();


        for i in 0..N {
            for j in 0..N {
                if res[i][j] != (i + j) as i32 {
                    println!("Erro na multiplicação das matrizes para N = {}!", N);
                }
            }
        }
        
        // Em Rust, a liberação de memória é automática ao sair do escopo, então não precisamos medir manualmente.

        // Salvando os resultados no arquivo
        writeln!(file, "N = {}", N).expect("Erro ao escrever no arquivo");
        writeln!(file, "Tempo de alocação de memória: {:.6} segundos", time_alloc.as_secs_f64()).expect("Erro ao escrever no arquivo");
        writeln!(file, "Tempo de cálculo: {:.6} segundos", time_calc.as_secs_f64()).expect("Erro ao escrever no arquivo");
        writeln!(file).expect("Erro ao escrever no arquivo");

        println!("Resultados para N = {} salvos.", N);
    }

    println!("Todos os resultados foram salvos no arquivo resultado_rust.dat.");
}
