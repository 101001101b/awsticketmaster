output "private_ip" {
  value = aws_instance.postgres.private_ip
}

output "instance_id" {
  value = aws_instance.postgres.id
}
