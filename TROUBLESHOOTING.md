# Troubleshooting

Registro dos principais problemas enfrentados durante o deploy na AWS e os passos para resolução.

---

## 1. API não responde via IP Público (Connection Refused)

* **Problema:** A aplicação compilou e iniciou sem erros no terminal, mas as requisições via navegador/Postman retornavam erro de conexão (Timeout/Connection Refused).
* **Causa:** O Security Group da instância EC2 na AWS bloqueia o tráfego externo por padrão. A porta 8080 não estava liberada no firewall.
* **Solução:** 1. No painel da AWS, acessei as configurações da EC2 e selecionei a aba **Security Groups**.
    2. Editei as **Inbound rules** (Regras de entrada).
    3. Adicionei uma nova regra do tipo **Custom TCP**, porta **8080**, definindo a origem como **0.0.0.0/0** (Anywhere).

---

## 2. API saindo do ar ao fechar o terminal SSH

* **Problema:** A aplicação funcionava normalmente, mas o processo era encerrado assim que eu fechava a janela do terminal ou a conexão SSH caía.
* **Causa:** Executar `java -jar` prende o processo ao terminal ativo (foreground). Quando o terminal é fechado, o sistema operacional mata todos os processos filhos atrelados a ele.
* **Solução:** Transformei a execução da API em um serviço de background gerenciado nativamente pelo Linux (`systemd`).
    1. Criei um arquivo de configuração em `/etc/systemd/system/userdevops.service` especificando o caminho do JDK e do artefato `.jar`, além da regra `Restart=always`.
    2. Habilitei e iniciei o serviço com os comandos:

  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable userdevops
  sudo systemctl start userdevops