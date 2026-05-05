# User DevOps - Portfolio Completo de DevOps

## Visão Geral

Este é um projeto de portfólio que demonstra uma aplicação completa de **DevOps**, cobrindo desde o desenvolvimento de uma API REST com Spring Boot até o deploy automatizado na AWS com monitoramento em tempo real. O objetivo é apresentar um ecossistema funcional que integra **CI/CD, Infraestrutura como Código (IaC), Containers, Cloud AWS e Observabilidade**.

A aplicação consiste em uma API de gerenciamento de usuários que permite criar, consultar, atualizar e deletar registros em um banco de dados PostgreSQL, tudo provisionado automaticamente na AWS via Terraform e com deploy contínuo via GitHub Actions.

---

## Sumário

- [Arquitetura](#arquitetura)
- [Aplicação Spring Boot](#aplicação-spring-boot)
- [Infraestrutura AWS](#infraestrutura-aws)
- [Monitoramento](#monitoramento)
- [CI/CD](#cicd)
- [Segurança](#segurança)
- [Como Executar](#como-executar)
- [Endpoints da API](#endpoints-da-api)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)

---

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                         │
└─────────────────────────────────────────────────────────────────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
   ┌──────────┐            ┌──────────┐            ┌──────────┐
   │  :8080   │            │  :9090   │            │  :3000   │
   │    API   │            │Prometheus│            │ Grafana  │
   └────┬─────┘            └────┬─────┘            └────┬─────┘
        │                       │                       │
        └───────────────────────┬───────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │    EC2 Instance       │
                    │   Ubuntu 22.04        │
                    │   Docker Engine       │
                    │   + Swap 2GB          │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │    VPC 10.0.0.0/16     │
                    │  ┌─────────────────┐  │
                    │  │ Public Subnet   │  │
                    │  │ 10.0.1.0/24     │  │
                    │  │ EC2 + Docker    │  │
                    │  └─────────────────┘  │
                    │  ┌─────────────────┐  │
                    │  │ Private Subnet  │  │
                    │  │ 10.0.2.0/24     │  │
                    │  │ 10.0.3.0/24     │  │
                    │  │ RDS PostgreSQL  │  │
                    │  └─────────────────┘  │
                    └───────────────────────┘
```

### Componentes Principais

| Componente | Função |
|------------|--------|
| **API Spring Boot** | Backend RESTful com CRUD de usuários |
| **PostgreSQL RDS** | Banco de dados relacional privado |
| **Prometheus** | Coleta de métricas da aplicação |
| **Grafana** | Dashboards e visualização de métricas |
| **Watchtower** | Atualização automática de containers |
| **Docker Network** | Comunicação interna entre containers |

---

## Aplicação Spring Boot

### Visão Geral

A aplicação é uma API REST desenvolvida em **Java 17** com **Spring Boot 3.3.4**, seguindo uma arquitetura em camadas com separação de responsabilidades.

### Estrutura de Pacotes

```
lucasbschuck.userdevops/
├── UserDevopsApplication.java      # Classe principal
├── controllers/
│   └── UserDevopsController.java   # REST Controller
├── application/
│   ├── CreateUser.java             # Caso de uso: Criar usuário
│   ├── DeleteUser.java             # Caso de uso: Deletar usuário
│   ├── FindUserByEmail.java        # Caso de uso: Buscar usuário
│   └── UpdateUser.java             # Caso de uso: Atualizar usuário
├── model/
│   └── User.java                   # Entidade JPA
└── repository/
    └── UserRepository.java         # Acesso ao banco de dados
```

### Entidade User

A entidade principal da aplicação representa um usuário no sistema:

- **id**: UUID gerado automaticamente pelo Hibernate
- **name**: Nome do usuário
- **email**: E-mail único e obrigatório (usado como chave de busca)

### Casos de Uso (Application Layer)

A camada de aplicação encapsula a lógica de negócio em classes dedicadas:

- **CreateUser**: Recebe nome e e-mail, persiste no banco via Repository
- **FindUserByEmail**: Busca usuário por e-mail, retorna Optional
- **UpdateUser**: Atualiza nome do usuário baseado no e-mail
- **DeleteUser**: Remove usuário do banco por e-mail

### Configuração de Dependências (pom.xml)

O projeto utiliza as seguintes tecnologias:

| Dependência | Função |
|-------------|--------|
| `spring-boot-starter-web` | API REST com Tomcat embutido |
| `spring-boot-starter-data-jpa` | Persistência com Hibernate |
| `spring-boot-starter-validation` | Validação de dados |
| `spring-boot-starter-actuator` | Endpoints de saúde e métricas |
| `micrometer-registry-prometheus` | Exportação de métricas no formato Prometheus |
| `spring-cloud-aws-starter-parameter-store` | Integração com AWS SSM Parameter Store |
| `postgresql` | Driver do banco de dados PostgreSQL |
| `h2` | Banco em memória para testes |
| `lombok` | Redução de boilerplate |
| `spring-boot-devtools` | Hot reload em desenvolvimento |

### application.yaml

```yaml
spring:
  application:
    name: user-devops
  config:
    import: "aws-parameterstore:/devops-portfolio/db/"
  jpa:
    database-platform: org.hibernate.dialect.PostgreSQLDialect
management:
    endpoints:
      web:
        exposure:
          include: health,info,prometheus
    endpoint:
      prometheus:
        enabled: true
    metrics:
      tags:
        application: ${spring.application.name}
```

A aplicação carrega as credenciais do banco de dados automaticamente do **AWS Systems Manager Parameter Store**, eliminando a necessidade de hardcodear senhas.

### Dockerfile

```dockerfile
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /build/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Utiliza **multi-stage build** para reduzir o tamanho da imagem final, compilando em uma imagem Maven e executando apenas o JRE Alpine.

---

## Infraestrutura AWS

### Visão Geral

Toda a infraestrutura é provisionada via **Terraform** com backend S3 para state compartilhado e DynamoDB para state locking, permitindo colaboração em equipe.

### Recursos Criados

#### 1. VPC (Virtual Private Cloud)

- **CIDR**: 10.0.0.0/16
- **DNS Support**: Habilitado
- **DNS Hostnames**: Habilitado

#### 2. Subnets

| Subnet | CIDR | Tipo | AZ | Função |
|--------|------|------|-----|--------|
| public-subnet-ec2 | 10.0.1.0/24 | Pública | us-east-1a | Hospeda EC2 |
| private-subnet-rds | 10.0.2.0/24 | Privada | us-east-1b | Hospeda RDS |
| private-subnet-rds-2 | 10.0.3.0/24 | Privada | us-east-1a | Hospeda RDS (HA) |

#### 3. Internet Gateway

Conecta a VPC à internet, permitindo acesso aos serviços públicos.

#### 4. Route Table Pública

Roteia tráfego de saída (0.0.0.0/0) para o Internet Gateway, aplicada apenas à subnet pública.

#### 5. Security Groups

**EC2 Security Group** (`ec2_sg`):
- Porta 22 (SSH): Acesso restrito por IP via variável
- Porta 8080 (API): Acesso público
- Porta 3000 (Grafana): Acesso público
- Porta 9090 (Prometheus): Acesso público
- Egress: Todo tráfego de saída liberado

**RDS Security Group** (`rds_sg`):
- Porta 5432 (PostgreSQL): Acesso permitido APENAS do Security Group da EC2
- Egress: Todo tráfego de saída liberado

#### 6. EC2 Instance

- **AMI**: Ubuntu 22.04 LTS (busca automática pela mais recente)
- **Tipo**: t3.micro (Free Tier elegível)
- **Volume**: 30GB gp3
- **Swap**: 2GB configurado via user_data
- **IAM Profile**: Permite leitura de parâmetros SSM

**User Data (Script de Inicialização)**:
1. Configura swap de 2GB para evitar OOM
2. Instala Docker e inicia o serviço
3. Cria arquivo de configuração do Prometheus
4. Cria rede Docker customizada `devops-network`
5. Sobe containers: API, Prometheus, Grafana, Watchtower

#### 7. RDS PostgreSQL

- **Engine**: PostgreSQL 16.3
- **Classe**: db.t3.micro
- **Storage**: 20GB
- **Database**: userdb
- **Username**: lucas
- **Password**: Gerada automaticamente pelo Terraform (16 caracteres com símbolos)
- **Acesso Público**: `false` (apenas via VPC)
- **Subnet Group**: Spans em duas AZs para alta disponibilidade

#### 8. IAM Role para EC2

- **Role**: `ec2-ssm-role`
- **Policy**: Permite `ssm:GetParameter`, `ssm:GetParameters`, `ssm:GetParametersByPath`
- **Instance Profile**: Associado à EC2 para leitura de credenciais do banco

#### 9. SSM Parameter Store

Parâmetros criados automaticamente pelo Terraform:

| Parâmetro | Tipo | Valor |
|-----------|------|-------|
| `/devops-portfolio/db/spring.datasource.url` | String | URL JDBC do RDS |
| `/devops-portfolio/db/spring.datasource.username` | String | lucas |
| `/devops-portfolio/db/spring.datasource.password` | SecureString | Senha gerada aleatoriamente |
| `/devops-portfolio/db/spring.jpa.hibernate.ddl-auto` | String | update |

#### 10. Backend S3 para Terraform State

- **Bucket**: `user-devops-tf-state-public-demo`
- **Chave**: `global/s3/terraform.tfstate`
- **Encryption**: Habilitado
- **DynamoDB Table**: `user-devops-tf-locks` para state locking

---

## Monitoramento

### Prometheus

O Prometheus coleta métricas da aplicação Spring Boot via endpoint `/actuator/prometheus`.

**Configuração**:
```yaml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'spring-boot-api'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['api-user-devops:8080']
        labels:
          application: 'Minha-API-DevOps'
          instance: 'Servidor-EC2'
```

O Prometheus acessa a API pelo **nome do container Docker** (`api-user-devops`) dentro da rede `devops-network`, sem necessidade de IPs estáticos.

### Grafana

Dashboard para visualização das métricas coletadas pelo Prometheus.

**Configuração de DataSource**:
- **URL**: `http://prometheus:9090` (comunicação interna Docker)
- **Tipo**: Prometheus

**Acesso**:
- URL: `http://<EC2_IP>:3000`
- Login padrão: `admin/admin`

### Métricas Disponíveis

- `http_server_requests_seconds_count` - Total de requisições HTTP
- `http_server_requests_seconds_sum` - Soma dos tempos de resposta
- `http_server_requests_seconds_max` - Tempo máximo de resposta
- `jvm_memory_used_bytes` - Memória JVM utilizada
- `process_cpu_usage` - Uso de CPU do processo
- `system_cpu_usage` - Uso de CPU do sistema
- `logback_events_total` - Eventos de log
- `hikaricp_connections_active` - Conexões ativas com o banco

### Watchtower

Container que verifica a cada 30 segundos se há nova versão da imagem `lucasbschuck/user-devops-api:latest`. Se houver, ele baixa e reinicia o container automaticamente, permitindo deploy contínuo sem downtime manual.

---

## CI/CD

### Pipeline GitHub Actions

O pipeline é acionado automaticamente em **push para a branch main** e possui dois jobs sequenciais:

#### Job 1: Build e Push (build-and-push)

1. **Checkout**: Baixa o código do repositório
2. **Setup Java 17**: Configura JDK Temurin com cache Maven
3. **Login Docker Hub**: Autenticação com secrets
4. **Build e Push**: Compila a aplicação e envia imagem `lucasbschuck/user-devops-api:latest`

#### Job 2: Deploy AWS (deploy-aws)

Depende do job anterior (`needs: build-and-push`)

1. **Checkout**: Baixa o código novamente
2. **AWS Credentials**: Configura credenciais via secrets
3. **Setup Terraform**: Instala Terraform v1.0+
4. **Terraform Init**: Inicializa backend S3
5. **Terraform Plan**: Gera plano de execução
6. **Terraform Apply**: Aplica mudanças na infraestrutura
7. **Get Outputs**: Exporta endpoints para arquivo JSON
8. **SSM Parameters**: Confirma que parâmetros estão configurados

### Secrets Necessários

| Secret | Origem |
|--------|--------|
| `DOCKER_USERNAME` | Usuário do Docker Hub |
| `DOCKER_PASSWORD` | Token de acesso do Docker Hub |
| `AWS_ACCESS_KEY_ID` | Chave de acesso AWS IAM |
| `AWS_SECRET_ACCESS_KEY` | Chave secreta AWS IAM |

---

## Segurança

### Práticas Implementadas

1. **Zero Hardcoded Secrets**: Todas as credenciais são injetadas via SSM Parameter Store ou variáveis de ambiente
2. **Senhas Aleatórias**: Senha do banco gerada automaticamente pelo Terraform com 16 caracteres e símbolos
3. **Banco Privado**: RDS acessível apenas via VPC, sem exposição pública
4. **SSH Restrito**: Acesso SSH limitado a IPs configurados em `var.ssh_allowed_ips`
5. **State Criptografado**: Backend S3 com encryption habilitado
6. **State Locking**: DynamoDB previne corrupção do state em execuções concorrentes
7. **IAM Least Privilege**: EC2 possui apenas permissão de leitura SSM
8. **Segurança para Repositório Público**: Nenhum dado sensível nos arquivos do projeto

### Variáveis de Configuração

```hcl
variable "ssh_allowed_ips" {
  description = "Lista de IPs permitidos para acesso SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # ⚠️ Substitua no terraform.tfvars
}

variable "s3_bucket_name" {
  description = "Nome único para bucket S3"
  type        = string
}
```

Crie um arquivo `terraform.tfvars` local (não commitado) com seus valores:
```hcl
ssh_allowed_ips = ["SEU_IP_AQUI/32"]
s3_bucket_name  = "nome-unico-do-seu-bucket"
```

---

## Como Executar

### Pré-requisitos

- Conta AWS com acesso programático
- Docker Hub account
- GitHub repository configurado com os 4 secrets
- AWS CLI instalado e configurado localmente
- Terraform >= 1.0 instalado

### Passo a Passo

#### 1. Clone o Repositório

```bash
git clone https://github.com/seu-usuario/user-devops.git
cd user-devops
```

#### 2. Configure as Variáveis

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com seus valores
```

#### 3. Crie Recursos de Backend (Primeira vez apenas)

```bash
aws s3 mb s3://user-devops-tf-state-public-demo --region us-east-1

aws dynamodb create-table \
    --table-name user-devops-tf-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

#### 4. Execute o Terraform

```bash
terraform init
terraform apply -auto-approve
```

#### 5. Acesse os Endpoints

Após o apply, o Terraform exibirá os endpoints:

```
api_endpoint        = "http://<IP>:8080"
prometheus_endpoint = "http://<IP>:9090"
grafana_endpoint    = "http://<IP>:3000"
rds_endpoint        = <sensível>
```

#### 6. Configure o Grafana

1. Acesse `http://<IP>:3000`
2. Login: `admin/admin`
3. Adicione DataSource Prometheus com URL: `http://prometheus:9090`
4. Crie dashboards com as métricas disponíveis

#### 7. Deploy Contínuo (Opcional)

Para ativar CI/CD:
1. Configure os 4 secrets no GitHub
2. Push para `main` dispara o pipeline automaticamente
3. Watchtower atualiza o container em ~30 segundos

---

## Endpoints da API

### Base URL
```
http://<EC2_IP>:8080
```

### CRUD de Usuários

#### Criar Usuário
```http
POST /user
Content-Type: application/json

{
  "name": "Lucas Schuck",
  "email": "lucas@exemplo.com"
}
```
**Resposta**: `200 OK` - `User created successfully`

#### Buscar Usuário
```http
GET /user?email=lucas@exemplo.com
```
**Resposta**: `200 OK` - Objeto User ou `404 Not Found`

#### Atualizar Usuário
```http
PUT /user
Content-Type: application/json

{
  "name": "Lucas B. Schuck",
  "email": "lucas@exemplo.com"
}
```
**Resposta**: `200 OK` - `User updated successfully` ou `404 Not Found`

#### Deletar Usuário
```http
DELETE /user?email=lucas@exemplo.com
```
**Resposta**: `200 OK` - `User deleted successfully`

### Health Checks

```http
GET /actuator/health
GET /actuator/info
GET /actuator/prometheus
```

---

## Tecnologias Utilizadas

### Backend
| Tecnologia | Versão | Função |
|------------|--------|--------|
| Java | 17 | Linguagem principal |
| Spring Boot | 3.3.4 | Framework web |
| Spring Data JPA | 3.3.4 | Persistência |
| Spring Validation | 3.3.4 | Validação de dados |
| Spring Actuator | 3.3.4 | Métricas e health |
| Spring Cloud AWS | 3.1.1 | Integração SSM |
| PostgreSQL | 16.3 | Banco de dados |
| Hibernate | 6.x | ORM |
| Lombok | - | Redução de boilerplate |
| Maven | 3.9.6 | Build tool |

### DevOps & Infra
| Tecnologia | Função |
|------------|--------|
| Terraform | Infraestrutura como Código |
| AWS EC2 | Servidor de aplicação |
| AWS RDS | Banco de dados gerenciado |
| AWS VPC | Rede virtual isolada |
| AWS S3 | Backend de state Terraform |
| AWS DynamoDB | State locking |
| AWS SSM | Gerenciamento de secrets |
| AWS IAM | Controle de acesso |
| Docker | Containerização |
| Docker Hub | Registry de imagens |
| GitHub Actions | CI/CD |

### Monitoramento
| Tecnologia | Função |
|------------|--------|
| Prometheus | Coleta de métricas |
| Grafana | Visualização de dashboards |
| Micrometer | Instrumentação de métricas |
| Watchtower | Atualização automática de containers |

---

## Estrutura do Projeto

```
user-devops/
├── .github/
│   └── workflows/
│       └── workflow.yml           # Pipeline CI/CD
├── src/
│   ├── main/
│   │   ├── java/lucasbschuck/userdevops/
│   │   │   ├── application/       # Casos de uso
│   │   │   ├── controllers/       # REST Controllers
│   │   │   ├── model/             # Entidades JPA
│   │   │   └── repository/        # Interfaces Spring Data
│   │   └── resources/
│   │       └── application.yaml   # Configuração Spring
│   └── test/                      # Testes unitários
├── terraform/
│   ├── main.tf                    # Provider + Backend S3
│   ├── vpc.tf                     # VPC, Subnets, IGW, Routes
│   ├── security.tf                # Security Groups
│   ├── server.tf                  # EC2 + User Data (Docker)
│   ├── database.tf                # RDS + SSM Parameters
│   ├── iam.tf                     # Roles e Policies
│   ├── outputs.tf                 # Outputs Terraform
│   ├── variables.tf               # Variáveis configuráveis
│   ├── state.tf                   # Bucket e DynamoDB demo
│   └── terraform.tfvars.example   # Exemplo de variáveis
├── Dockerfile                     # Multi-stage build
├── docker-compose.yml             # Desenvolvimento local
├── pom.xml                        # Dependências Maven
└── README.md                      # Este documento
```

---

## Licença

Este projeto é de código aberto e está licenciado sob a [MIT License](LICENSE).

---

## Autor

**Lucas B. Schuck**

- GitHub: [@lucasbschuck](https://github.com/lucasbschuck)
- LinkedIn: [lucasbschuck](https://linkedin.com/in/lucasbschuck)

---

## Agradecimentos

Este projeto foi desenvolvido como portfólio para demonstrar competências em:
- Desenvolvimento de APIs RESTful
- Arquitetura em camadas
- Infraestrutura como Código
- Containers e Orquestração
- Cloud Computing (AWS)
- CI/CD e Automação
- Observabilidade e Monitoramento
