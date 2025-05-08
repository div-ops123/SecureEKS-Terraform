output "rds_endpoint" {
  value = aws_db_instance.rds_db.endpoint
}
output "db_name" {
  value = var.db_name
}