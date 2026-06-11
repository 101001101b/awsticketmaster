output "public_ip" {
  value = aws_instance.loadgen.public_ip
}

output "instance_id" {
  value = aws_instance.loadgen.id
}

output "private_ip" {
  value = aws_instance.loadgen.private_ip
}
