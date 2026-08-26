#!/usr/bin/env bash

# Diagnostico somente leitura dos toolchains usados pelas linguagens extras.
# Essenciais: rustc; erl e elixir; julia. Os demais comandos sao auxiliares.

set -u

missing_required=()

report_tool() {
    local label="$1"
    local required="$2"
    local executable="$3"
    shift 3

    local path
    local output
    local status

    if ! path="$(command -v -- "$executable" 2>/dev/null)"; then
        printf '[AUSENTE] %s\n' "$label"
        if [[ "$required" == "required" ]]; then
            missing_required+=("$label")
        fi
        return
    fi

    output="$("$executable" "$@" 2>&1)"
    status=$?
    if (( status != 0 )); then
        printf '[ERRO] %s (%s)\n' "$label" "$path"
        if [[ -n "$output" ]]; then
            while IFS= read -r line; do
                printf '       %s\n' "$line"
            done <<< "$output"
        fi
        if [[ "$required" == "required" ]]; then
            missing_required+=("$label")
        fi
        return
    fi

    printf '[OK] %s (%s)\n' "$label" "$path"
    if [[ -n "$output" ]]; then
        while IFS= read -r line; do
            printf '     %s\n' "$line"
        done <<< "$output"
    else
        printf '     versao nao informada pelo comando\n'
    fi
}

printf 'Rust\n'
report_tool rustup optional rustup --version
report_tool rustc required rustc --version
report_tool cargo optional cargo --version
report_tool rustfmt optional rustfmt --version
report_tool clippy optional cargo-clippy --version

printf '\nErlang/Elixir\n'
report_tool erl required erl -version
report_tool elixir required elixir --version
report_tool mix optional mix --version

printf '\nJulia\n'
report_tool julia required julia --version
report_tool juliaup optional juliaup --version

if (( ${#missing_required[@]} > 0 )); then
    printf '\nERRO: runtimes/compiladores essenciais ausentes ou com erro:' >&2
    printf ' %s' "${missing_required[@]}" >&2
    printf '\n' >&2
    exit 1
fi

printf '\nTodos os runtimes/compiladores essenciais estao disponiveis.\n'
