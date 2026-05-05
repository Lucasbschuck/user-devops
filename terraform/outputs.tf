# Outputs para facilitar acesso aos recursos

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.spring_boot_server.public_ip
}

output "ec2_public_dns" {
  description = "DNS público da instância EC2"
  value       = aws_instance.spring_boot_server.public_dns
}

output "api_endpoint" {
  description = "URL completa para acessar a API"
  value       = "http://${aws_instance.spring_boot_server.public_ip}:8080"
}

output "prometheus_endpoint" {
  description = "URL para acessar o Prometheus"
  value       = "http://${aws_instance.spring_boot_server.public_ip}:9090"
}

output "grafana_endpoint" {
  description = "URL para acessar o Grafana"
  value       = "http://${aws_instance.spring_boot_server.public_ip}:3000"
}

output "rds_endpoint" {
  description = "Endpoint do banco de dados RDS"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "ssm_parameters" {
  description = "Parâmetros SSM criados"
  value = {
    db_url      = aws_ssm_parameter.db_url_param.name
    db_user     = aws_ssm_parameter.db_user_param.name
    db_password = aws_ssm_parameter.db_password_param.name
    db_ddl_auto = aws_ssm_parameter.db_ddl_auto_param.name
  }
}
