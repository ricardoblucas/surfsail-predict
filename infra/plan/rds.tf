resource "random_string" "db_suffix" {
  length = 4
  special = false
  upper = false
}

resource "random_string" "root_username" {
  length = 12
  special = false
  upper = true
}

resource "random_password" "root_password" {
  length = 12
  special = false
  upper = true
}


resource "aws_db_instance" "postgresql" {

  # Engine options
  engine                              = "postgres"
  engine_version                      = "14"

  # Settings
  db_name                                = "postgresql${var.env}"
  identifier                          = "postgresql-${var.env}"

  # Credentials Settings
  username                            = "u${random_string.root_username.result}"
  password                            = "p${random_password.root_password.result}"

  # DB instance size
  instance_class                      = "db.t3.micro"

  # Storage
  storage_type                        = "gp2"
  allocated_storage                   = 100
  max_allocated_storage               = 200

  # Availability & durability
  multi_az                            = true
  
  # Connectivity
  db_subnet_group_name                = aws_db_subnet_group.sg.id
  
  publicly_accessible                 = false
  vpc_security_group_ids              = [aws_security_group.sg.id]
  port                                = var.rds_port

  # Database authentication
  iam_database_authentication_enabled = true 

  # Additional configuration
#   parameter_group_name                = "default.postgres12"

  # Backup
  backup_retention_period             = 14
  backup_window                       = "03:00-04:00"
  final_snapshot_identifier           = "postgresql-final-snapshot-${random_string.db_suffix.result}" 
  delete_automated_backups            = true
  skip_final_snapshot                 = false

  # Encryption
  storage_encrypted                   = true
  
  # Maintenance
  auto_minor_version_upgrade          = true
  maintenance_window                  = "Sat:00:00-Sat:02:00"

  # Deletion protection
  deletion_protection                 = false

  tags = {
    Environment = var.env
  }
}

# RDS DB SECURITY GROUP
resource "aws_security_group" "sg" {
  name        = "postgresql-${var.env}"
  description = "Allow EKS inbound/outbound traffic"
  vpc_id      = aws_vpc.main.id


  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.private["private-rds-1"].cidr_block]  
  }

  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.private["private-rds-2"].cidr_block]  
  }
  
  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.public["public-rds-1"].cidr_block]  
  }

  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.public["public-rds-2"].cidr_block]  
  }


  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.private["private-rds-1"].cidr_block]  
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.private["private-rds-2"].cidr_block]  
  }

  egress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.public["public-rds-1"].cidr_block]  
  }

  egress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.public["public-rds-2"].cidr_block]  
  }

  tags = {
    Name        = "postgresql-${var.env}"
    Environment = var.env
  }
}

# RDS DB SUBNET GROUP
resource "aws_db_subnet_group" "sg" {
  name       = "postgresql-${var.env}"
  subnet_ids = [aws_subnet.private["private-rds-1"].id, aws_subnet.private["private-rds-2"].id]

  tags = {
    Environment = var.env
    Name        = "postgresql-${var.env}"
  }
}
