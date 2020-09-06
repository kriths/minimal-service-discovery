variable "domain" {
  description = "Domain name for the deployment"
  type = string
}

variable "subdomain" {
  description = "Subdomain for deployment, empty for apex"
  type = string
  default = ""
}

variable "asg_arn" {
  description = "ARN of the auto scaling group"
  type = string
}

variable "asg_id" {
  description = "Name / ID of the auto scaling group"
  type = string
}
