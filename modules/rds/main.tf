# Defines which subnet to place the RDS
resource "aws_db_subnet_group" "rds" {
  name       = "${var.cluster_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.common_tags, { Name = "${var.cluster_name}-rds" })
}

resource "aws_db_instance" "rds_db" {
  identifier             = "${var.cluster_name}-rds"
  engine                 = "postgres"
  engine_version         = "14.15"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [var.rds_security_group_id]
  skip_final_snapshot    = true

  tags                   = merge(var.common_tags, { Name = "${var.cluster_name}-rds" })
}