resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "fullstack-devops-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "fullstack-devops-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  db_name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false

  tags = {
    Name = "fullstack-devops-mysql"
  }
}
