output "rabbitmq_private_ip" {
  value       = module.rabbitmq.private_ip
  description = "IP privada de RabbitMQ"
}

output "postgres_private_ip" {
  value       = module.postgres.private_ip
  description = "IP privada de PostgreSQL"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "URL del repositorio ECR"
}

output "s3_bucket_id" {
  value       = module.storage.bucket_id
  description = "Bucket S3 de resultados"
}

output "ecs_cluster_name" {
  value       = module.workers.cluster_name
  description = "Nombre del cluster ECS"
}

output "ecs_service_name" {
  value       = module.workers.service_name
  description = "Nombre del servicio ECS"
}

output "cloudwatch_dashboard_url" {
  value       = module.observability.dashboard_url
  description = "URL del dashboard CloudWatch"
}
