variable "vpc_id" {
  description = "ID de la VPC (por defecto del lab)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC por defecto para reglas de SG"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}
