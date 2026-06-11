data "aws_region" "current" {}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["${var.project_name}/autoscaling", "Backlog", { stat = "Sum" }],
            [".", "WorkerCount", { stat = "Average" }],
            [".", "BacklogPerWorker", { stat = "Average" }],
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Autoscaling Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ECS Workers CPU/Memory"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.rabbitmq_instance_id],
            ["...", "InstanceId", var.postgres_instance_id],
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EC2 CPU (RabbitMQ + Postgres)"
        }
      },
      {
        type = "log"
        properties = {
          query  = "SOURCE '${var.log_group_name}' | fields @timestamp, @message | sort @timestamp desc | limit 50"
          region = data.aws_region.current.name
          title  = "Worker Logs (recent)"
        }
      },
    ]
  })
}
