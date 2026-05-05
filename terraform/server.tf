data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "spring_boot_server" {
  ami                         = data.aws_ami.ubuntu.id
  key_name                    = "LucasNot"
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  root_block_device {
      volume_size = 30
      volume_type = "gp3"
    }

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
                #!/bin/bash

                # Log de tudo para rastreio
                exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


                dd if=/dev/zero of=/swapfile bs=1M count=2048
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo '/swapfile none swap sw 0 0' >> /etc/fstab
                sleep 10

                # Instalação do Docker
                apt-get update -y
                apt-get install -y docker.io
                systemctl start docker
                systemctl enable docker

                # Arquivo do Prometheus na HOME
                mkdir -p /home/ubuntu
                cat << 'PROMETHEUS_EOF' > /home/ubuntu/prometheus.yml
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
                PROMETHEUS_EOF

                # Cria rede Docker customizada
                docker network create devops-network

                # Sobe a API
                docker run -d \
                  --network devops-network \
                  --name api-user-devops \
                  -p 8080:8080 \
                  --restart always \
                  lucasbschuck/user-devops-api:latest

                # Sobe o Prometheus
                docker run -d \
                  --network devops-network \
                  --name prometheus \
                  -v /home/ubuntu/prometheus.yml:/etc/prometheus/prometheus.yml \
                  -p 9090:9090 \
                  --restart always \
                  prom/prometheus:latest

                # Sobe o Grafana
                docker run -d \
                  --network devops-network \
                  --name grafana \
                  -p 3000:3000 \
                  --restart always \
                  grafana/grafana:latest

                #Sobe o Watchtower
                docker run -d \
                  --name watchtower \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  containrrr/watchtower \
                  --interval 30 \
                  --cleanup \
                  api-user-devops
                EOF

  tags = {
    Name = "spring-boot-api-server"
  }
}