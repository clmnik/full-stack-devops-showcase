resource "aws_s3_bucket" "vault_storage" {
  bucket = "my-vault-storage-bucket-${random_string.rand_id.result}"
  tags = {
    Name = "vault-s3-storage"
  }
}

resource "aws_s3_bucket_versioning" "vault_storage_versioning" {
  bucket = aws_s3_bucket.vault_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_string" "rand_id" {
  length  = 8
  special = false
  upper   = false
}

data "aws_iam_policy_document" "vault_ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vault_ec2_role" {
  name               = "vault-ec2-prod-role"
  assume_role_policy = data.aws_iam_policy_document.vault_ec2_assume_role.json
  tags = {
    Name = "vault-ec2-prod-role"
  }
}

data "aws_kms_key" "external_vault_key" {
  key_id = var.vault_kms_key_arn
}

data "aws_iam_policy_document" "vault_ec2_inline_doc" {
  statement {
    sid       = "S3Access"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.vault_storage.arn,
      "${aws_s3_bucket.vault_storage.arn}/*"
    ]
  }
  statement {
    sid       = "KMSAccess"
    actions   = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [data.aws_kms_key.external_vault_key.arn]
  }
}

resource "aws_iam_policy" "vault_ec2_policy" {
  name   = "vault-ec2-prod-policy"
  policy = data.aws_iam_policy_document.vault_ec2_inline_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_vault_ec2_policy" {
  policy_arn = aws_iam_policy.vault_ec2_policy.arn
  role       = aws_iam_role.vault_ec2_role.name
}

resource "aws_iam_instance_profile" "vault_ec2_profile" {
  name = "vault-ec2-prod-profile"
  role = aws_iam_role.vault_ec2_role.name
}

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
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.vault_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.vault_ec2_profile.name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y unzip
    curl -sLo /tmp/vault.zip https://releases.hashicorp.com/vault/1.13.1/vault_1.13.1_linux_amd64.zip
    unzip /tmp/vault.zip -d /usr/local/bin
    chmod +x /usr/local/bin/vault
    mkdir -p /etc/vault.d
    cat <<CONFIG >/etc/vault.d/config.hcl
    ui = true
    listener "tcp" {
      address = "0.0.0.0:8200"
      tls_disable = "true"
    }
    storage "s3" {
      bucket = "${aws_s3_bucket.vault_storage.bucket}"
      region = "${var.aws_region}"
    }
    seal "awskms" {
      region     = "${var.aws_region}"
      kms_key_id = "${data.aws_kms_key.external_vault_key.arn}"
    }
    api_addr = "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8200"
    CONFIG
    cat <<SERVICE >/etc/systemd/system/vault.service
    [Unit]
    Description=HashiCorp Vault (Production)
    After=network-online.target
    Wants=network-online.target
    [Service]
    ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/config.hcl
    ExecReload=/bin/kill --signal HUP $MAINPID
    KillMode=process
    Restart=on-failure
    LimitNOFILE=65536
    AmbientCapabilities=CAP_IPC_LOCK
    CapabilityBoundingSet=CAP_IPC_LOCK
    [Install]
    WantedBy=multi-user.target
    SERVICE
    systemctl daemon-reload
    systemctl enable vault
    systemctl start vault
  EOF
  tags = {
    Name = "vault-ec2-prod"
  }
}

output "vault_public_ip" {
  description = "Vault Public IP"
  value       = aws_instance.vault_ec2.public_ip
}

output "vault_private_ip" {
  description = "Vault Private IP"
  value       = aws_instance.vault_ec2.private_ip
}
