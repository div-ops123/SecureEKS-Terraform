output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets_ids" {
  value = aws_subnet.public[*].id  # Returns a list of ALL public subnet IDs
}

output "private_subnets_ids" {
  value = aws_subnet.private[*].id # Returns a list of ALL private subnet IDs
}