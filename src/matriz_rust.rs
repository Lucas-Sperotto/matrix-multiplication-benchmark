/**********************************************************************
 * Projeto: Benchmark de Multiplicação de Matrizes
 * Descrição: Multiplicação de duas matrizes N x N em Rust puro (apenas
 *            biblioteca padrão), medindo tempo de alocação/inicialização
 *            (TAM), cálculo (TCS) e liberação explícita de memória (TDM).
 *
 * Linguagem: Rust
 *
 * Autores: Lucas Kriesel Sperotto, Thassio Artur Grisolia Vaz e Silva
 * Data: 26/08/2026
 *
 * Parâmetros (CLI): B Npts M Escala out_csv
 *  - B: tamanho máximo da matriz; N varia de 100 até B
 *  - Npts: número de pontos na escala (2 a 10000)
 *  - M: repetições medidas para calcular a média (1 a 100000)
 *  - Escala: 0=logarítmica, 1=linear
 *  - out_csv: caminho do arquivo CSV de saída
 *
 * Contrato completo em docs/EXTRA_LANGUAGES.md.
 **********************************************************************/

use std::env;
use std::fs::{self, File};
use std::hint::black_box;
use std::io::{BufWriter, Write};
use std::path::Path;
use std::process::ExitCode;
use std::time::Instant;

const MIN_B: i64 = 100;
const MAX_B: i64 = 100_000;
const MIN_NPTS: i64 = 2;
const MAX_NPTS: i64 = 10_000;
const MIN_M: i64 = 1;
const MAX_M: i64 = 100_000;
const MIN_ESCALA: i64 = 0;
const MAX_ESCALA: i64 = 1;
const BASE_A: f64 = 100.0;

struct Times {
    calc: f64,
    alloc: f64,
    free: f64,
}

fn parse_int(text: &str, name: &str, min_value: i64, max_value: i64) -> Result<i64, String> {
    match text.parse::<i64>() {
        Ok(value) if value >= min_value && value <= max_value => Ok(value),
        _ => Err(format!("Parametro invalido para {name}: {text}")),
    }
}

fn make_points(b: i64, npts: i64, escala: i64) -> Vec<usize> {
    // Mesma regra de arredondamento usada em matriz_c.c/matriz_cpp.cpp/matriz_java.java
    // e corrigida em matriz_python.py: metade-para-cima via floor(x + 0.5). Todas as
    // referencias precisam concordar aqui para que a serie de N seja identica entre
    // linguagens (regressao em tests/test_point_generation.py).
    let mut points = Vec::with_capacity(npts as usize);
    if escala == 1 {
        let step = (b as f64 - BASE_A) / (npts as f64 - 1.0);
        for i in 0..npts {
            points.push((BASE_A + step * i as f64 + 0.5).floor() as usize);
        }
    } else {
        let ratio = (b as f64 / BASE_A).powf(1.0 / (npts as f64 - 1.0));
        for i in 0..npts {
            points.push((BASE_A * ratio.powf(i as f64) + 0.5).floor() as usize);
        }
    }
    points
}

/// Aloca um buffer plano de N*N elementos zerados sem risco de aborto por
/// falta de memoria: `try_reserve_exact` retorna `Err` em vez de abortar o
/// processo quando a alocacao falha ou o tamanho em bytes estoura `usize`.
/// Uso: apenas para `res`, que precisa nascer zerado (contrato) e so e
/// reescrito depois, na janela de TCS, por `multiply`.
fn allocate_zeroed(len: usize) -> Result<Vec<i32>, String> {
    let mut buffer: Vec<i32> = Vec::new();
    buffer
        .try_reserve_exact(len)
        .map_err(|err| format!("Falha de alocacao para {len} elementos: {err}"))?;
    buffer.resize(len, 0);
    Ok(buffer)
}

/// Aloca e inicializa um buffer plano de N*N elementos em uma unica
/// passagem, sem zerar antes: `mat1`/`mat2` tem todo elemento sobrescrito
/// de qualquer forma, entao zerar primeiro (como `allocate_zeroed` faz)
/// duplicaria o trabalho de escrita dentro da janela de TAM (achado M2 da
/// revisao de codigo). `try_reserve_exact` mantem a alocacao falivel.
fn allocate_with(
    len: usize,
    n: usize,
    mut value_at: impl FnMut(usize, usize) -> i32,
) -> Result<Vec<i32>, String> {
    let mut buffer: Vec<i32> = Vec::new();
    buffer
        .try_reserve_exact(len)
        .map_err(|err| format!("Falha de alocacao para {len} elementos: {err}"))?;
    for i in 0..n {
        for j in 0..n {
            buffer.push(value_at(i, j));
        }
    }
    Ok(buffer)
}

fn multiply(mat1: &[i32], mat2: &[i32], res: &mut [i32], n: usize) {
    // SAFETY: mat1, mat2 e res sao sempre buffers de exatamente n*n
    // elementos (alocados com essa mesma contagem em run_once), e i, j, k
    // percorrem 0..n, logo i*n+k, k*n+j e i*n+j nunca excedem n*n-1. O
    // bounds-check do Rust nesse laco custa ~40% de TCS sem equivalente em
    // C/C++ (achado M1 da revisao de codigo, medido empiricamente); os
    // acessos abaixo sao comprovadamente seguros por construcao.
    for i in 0..n {
        for j in 0..n {
            let mut sum: i32 = 0;
            for k in 0..n {
                unsafe {
                    sum = sum.wrapping_add(
                        mat1.get_unchecked(i * n + k)
                            .wrapping_mul(*mat2.get_unchecked(k * n + j)),
                    );
                }
            }
            unsafe {
                *res.get_unchecked_mut(i * n + j) = sum;
            }
        }
    }
}

fn verify_sample(res: &[i32], n: usize) -> Result<(), String> {
    let idxs = [0usize, n / 2, n - 1];
    for &i in &idxs {
        for &j in &idxs {
            let expected = (i + j) as i32;
            let actual = res[i * n + j];
            if actual != expected {
                return Err(format!("Erro na multiplicacao para N={n} em [{i},{j}]"));
            }
        }
    }
    Ok(())
}

fn run_once(n: usize) -> Result<Times, String> {
    let n2 = n
        .checked_mul(n)
        .ok_or_else(|| format!("N muito grande: overflow ao calcular N*N para N={n}"))?;

    let start_alloc = Instant::now();
    let mat1 = allocate_with(n2, n, |i, j| (i + j) as i32)?;
    let mat2 = allocate_with(n2, n, |i, j| if i == j { 1 } else { 0 })?;
    let mut res = allocate_zeroed(n2)?;
    let alloc_time = start_alloc.elapsed().as_secs_f64();

    let start_calc = Instant::now();
    multiply(&mat1, &mat2, &mut res, n);
    let calc_time = start_calc.elapsed().as_secs_f64();
    // Barreira de otimizacao, fora da janela cronometrada: verify_sample so le
    // 9 das N*N posicoes de `res`. Sem isso, um otimizador suficientemente
    // agressivo em -O3 poderia provar que apenas essas 9 posicoes sao
    // observaveis e eliminar parte do calculo O(N^3), inflando artificialmente
    // o desempenho medido. black_box so precisa ocorrer em algum ponto apos a
    // chamada para ter efeito em tempo de compilacao; nao precisa estar dentro
    // da regiao medida em tempo de execucao (achado N1 da revisao de codigo).
    let res = black_box(res);

    verify_sample(&res, n)?;

    let start_free = Instant::now();
    drop(mat1);
    drop(mat2);
    drop(res);
    let free_time = start_free.elapsed().as_secs_f64();

    Ok(Times {
        calc: calc_time,
        alloc: alloc_time,
        free: free_time,
    })
}

fn run(args: &[String]) -> Result<(), String> {
    if args.len() != 6 {
        return Err(format!(
            "Uso: {prog} <B> <Npts> <M> <Escala> <out_csv>\nExemplo: {prog} 4000 12 5 1 out/execucao/resultado_rust.csv",
            prog = args[0]
        ));
    }

    let b = parse_int(&args[1], "B", MIN_B, MAX_B)?;
    let npts = parse_int(&args[2], "Npts", MIN_NPTS, MAX_NPTS)?;
    let m_count = parse_int(&args[3], "M", MIN_M, MAX_M)?;
    let escala = parse_int(&args[4], "Escala", MIN_ESCALA, MAX_ESCALA)?;
    let out_csv = &args[5];

    let out_path = Path::new(out_csv);
    if let Some(parent) = out_path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent).map_err(|err| {
                format!(
                    "Erro ao criar diretorio de saida: {} ({err})",
                    parent.display()
                )
            })?;
        }
    }

    let file = File::create(out_path)
        .map_err(|err| format!("Erro ao abrir arquivo de saida: {out_csv} ({err})"))?;
    let mut writer = BufWriter::new(file);
    writeln!(writer, "N,TCS,TAM,TDM")
        .map_err(|err| format!("Erro ao escrever no arquivo de saida: {err}"))?;

    for n in make_points(b, npts, escala) {
        run_once(n)?; // warm-up descartado

        let mut sum_calc = 0.0_f64;
        let mut sum_alloc = 0.0_f64;
        let mut sum_free = 0.0_f64;
        for _ in 0..m_count {
            let times = run_once(n)?;
            sum_calc += times.calc;
            sum_alloc += times.alloc;
            sum_free += times.free;
        }

        let m = m_count as f64;
        writeln!(
            writer,
            "{n},{:.6e},{:.6e},{:.6e}",
            sum_calc / m,
            sum_alloc / m,
            sum_free / m
        )
        .map_err(|err| format!("Erro ao escrever no arquivo de saida: {err}"))?;
        println!("Resultados para N = {n} salvos.");
    }

    writer
        .flush()
        .map_err(|err| format!("Erro ao finalizar arquivo de saida: {err}"))?;
    println!("Todos os resultados foram salvos em {out_csv}.");
    Ok(())
}

fn main() -> ExitCode {
    let args: Vec<String> = env::args().collect();
    match run(&args) {
        Ok(()) => ExitCode::SUCCESS,
        Err(message) => {
            eprintln!("{message}");
            ExitCode::FAILURE
        }
    }
}

// Compilado apenas por `rustc --test` (nunca pelo build de producao usado
// pelo runner, que nao passa --test); reusa a funcao multiply() real para
// provar que ela implementa multiplicacao de matrizes, nao apenas copia
// (B=identidade no benchmark principal nao distingue os dois casos).
#[cfg(test)]
mod tests {
    use super::multiply;

    #[test]
    fn multiply_non_identity_2x2() {
        // A = [[1,2],[3,4]], B = [[5,6],[7,8]] (row-major, flat i*n+j).
        let mat1: Vec<i32> = vec![1, 2, 3, 4];
        let mat2: Vec<i32> = vec![5, 6, 7, 8];
        let mut res: Vec<i32> = vec![0; 4];
        multiply(&mat1, &mat2, &mut res, 2);
        assert_eq!(res, vec![19, 22, 43, 50]);
    }
}
