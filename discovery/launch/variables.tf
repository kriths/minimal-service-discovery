variable "lambda_deployment" {
  description = "Deployment ZIP file"
}

variable "lambda_environment" {
  description = "Environment variables for lambda"
  type = map(string)
}

variable "role_arn" {
  description = "Lambda execution role arn"
  type = string
}

variable "asg_id" {
  description = "Name / ID of the auto scaling group"
  type = string
}
