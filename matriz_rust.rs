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

    for &N in &[10, 100, 1000, 10000] {  // Varie N automaticamente de 10 a 10000

        // Tempo de alocação de memória
        let start_alloc = Instant::now();
        let mat1: Vec<Vec<i32>> = (0..N).map(|i| (0..N).map(|j| (i + j) as i32).collect()).collect();
        let mat2: Vec<Vec<i32>> = (0..N).map(|i| (0..N).map(|j| (i as i32) - (j as i32)).collect()).collect();
        let time_alloc = start_alloc.elapsed();

        // Tempo do cálculo
        let start_calc = Instant::now();
        let _res = multiply(&mat1, &mat2, N);
        let time_calc = start_calc.elapsed();

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
