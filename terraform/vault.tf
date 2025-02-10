resource "aws_security_group" "vault_sg" {
  name        = "vault-sg"
  description = "Security group for Vault"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow Vault UI/API"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault-sg"
  }
}


resource "aws_instance" "vault_ec2" {
  # anstelle von "ami = "ami-08c40ec9ead489470"" ...
  ami                    = data.aws_ami.amazon_linux2.id

  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.vault_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y unzip

    # Download Vault
    curl -sLo /tmp/vault.zip https://releases.hashicorp.com/vault/1.13.1/vault_1.13.1_linux_amd64.zip
    unzip /tmp/vault.zip -d /usr/local/bin
    chmod +x /usr/local/bin/vault

    cat <<SERVICE > /etc/systemd/system/vault.service
    [Unit]
    Description=HashiCorp Vault
    After=network-online.target
    Wants=network-online.target

    [Service]
    ExecStart=/usr/local/bin/vault server -dev -dev-listen-address=0.0.0.0:8200 -log-level=info
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl enable vault.service
    systemctl start vault.service
  EOF

  tags = {
    Name = "vault-ec2"
  }
}


output "vault_public_ip" {
  description = "Vault instance public IP"
  value       = aws_instance.vault_ec2.public_ip
}

output "vault_private_ip" {
  description = "Vault instance private IP"
  value       = aws_instance.vault_ec2.private_ip
}
