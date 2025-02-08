output "vpc_id" {
  description = "ID der erstellten VPC"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  description = "IDs der öffentlichen Subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs der privaten Subnets"
  value       = aws_subnet.private[*].id
}

output "rds_endpoint" {
  description = "Endpoint der RDS MySQL Instanz"
  value       = aws_db_instance.mysql.endpoint
}
