# Contribuindo com resultados

Uma das propostas centrais deste projeto é ser **colaborativo**: qualquer pessoa pode rodar os benchmarks em sua máquina e compartilhar os resultados.

---

## 1) Rodando os benchmarks

Siga as instruções de [EXECUTION.md](EXECUTION.md).  
No final, você terá arquivos `.csv` gerados em `out/<NOME_DA_EXECUCAO>/`.

---

## 2) Nomeando a execução

Escolha um nome descritivo para sua execução, incluindo:

- **máquina ou processador**
- **data**

Exemplos:

````bash
out/ryzen7\_5700u\_2025-09-03/
out/intel\_i5-1135G7\_win11\_2025-09-05/
````

---

## 3) Fazendo um pull request

1. Forke o repositório.  
2. Copie sua pasta `out/<NOME_DA_EXECUCAO>/` para dentro do repositório.  
3. Faça commit com mensagem clara
4. Abra um **Pull Request**.

```bash
git add out/ryzen7_5700u_2025-09-03
git commit -m "Adiciona resultados no Ryzen 7 5700U (Linux, 2025-09-03)"
git push
````

---

## 4) Diversidade de contribuições

- Não é necessário que os nomes sejam idênticos: cada pasta representa uma execução diferente.
- Quanto mais contribuições, maior a base comparativa.
- Resultados de máquinas variadas (desktops, notebooks, servidores) são todos bem-vindos.

---

## 5) Outras formas de contribuir

- Melhorar os códigos em cada linguagem.
- Adicionar novas linguagens ao benchmark.
- Melhorar os scripts de execução e visualização.
- Ampliar a análise teórica ou estatística dos resultados.

---

## 🙌 Agradecimentos

- Este projeto começou como uma atividade de **Cálculo Numérico** na **UNEMAT – Campus Alto Araguaia** em 2014 e segue agora como parte do Trabaldo de Conclusão de Curso **TCC** do discente **Marcos Adriano**.

- Agradecemos a cada um que quiser contribuir com esse repositório.
