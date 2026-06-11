variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "create_s3_bucket" {
  description = "Crear bucket S3"
  type        = bool
  default     = true
}
