variable "aws_region" {
  description = "AWS Region"
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR Block for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR Blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR Blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "db_username" {
  description = "Datenbank-Benutzer"
  default     = "appuser"
}

variable "db_password" {
  description = "Datenbank-Passwort"
  default     = "apppassword"
}

variable "db_name" {
  description = "Name der Datenbank"
  default     = "appdb"
}

variable "db_instance_class" {
  description = "RDS Instanztyp"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Speicherplatz in GB"
  default     = 20
}
