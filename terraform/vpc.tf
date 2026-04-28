# 1. O Terreno (VPC)
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "devops-portfolio-vpc"
  }
}

# 2. A Sala de Estar (Subnet Pública para o Spring Boot / EC2)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Importante: dá um IP público para a EC2 acessar a internet
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-subnet-ec2"
  }
}

# 3. O Cofre (Subnet Privada para o Banco de Dados / RDS)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Bancos de dados na AWS geralmente exigem zonas diferentes

  tags = {
    Name = "private-subnet-rds"
  }
}

# 4. A Porta da Rua (Internet Gateway)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "devops-portfolio-igw"
  }
}

# 5. O Mapa de Roteamento Público
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Representa "qualquer lugar na internet"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# 6. Conectando o Mapa à Subnet Pública
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. O Segundo Cofre (Subnet Privada 2 em outra Zona)
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24" # Note que o IP mudou para não dar conflito
  availability_zone = "us-east-1a"  # Colocamos no prédio 'a' (junto com a pública, mas isolada logicamente)

  tags = {
    Name = "private-subnet-rds-2"
  }
}

# 8. O Grupo de Subnets do Banco de Dados (Exigência da AWS)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "meu-grupo-de-subnets-db"

  # Aqui nós dizemos para a AWS: "Use essas duas subnets para o meu banco"
  subnet_ids = [
    aws_subnet.private_subnet.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "Meu DB Subnet Group"
  }
}