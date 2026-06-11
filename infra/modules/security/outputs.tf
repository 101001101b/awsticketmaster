output "rabbitmq_sg_id" {
  value = aws_security_group.rabbitmq.id
}

output "postgres_sg_id" {
  value = aws_security_group.postgres.id
}

output "worker_sg_id" {
  value = aws_security_group.worker.id
}

output "loadgen_sg_id" {
  value = aws_security_group.loadgen.id
}
