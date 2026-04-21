variable "project"            {}
variable "vpc_id"             {}
variable "private_subnet_ids" {}
variable "db_secret_arn"      {}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = var.db_secret_arn
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "rds" {
  name   = "${var.project}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]   # only from within VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "main" {
  identifier             = "${var.project}-postgres"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = local.db_creds["dbname"]
  username               = local.db_creds["username"]
  password               = local.db_creds["password"]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = false
  deletion_protection    = true
  storage_encrypted      = true
  multi_az               = true
  iam_database_authentication_enabled = true
}

output "endpoint" { value = aws_db_instance.main.endpoint }
