variable "min_count" {
  description = "Minimum count of instances"
  type = number
}

variable "max_count" {
  description = "Maximum count of instances"
  type = number
}

variable "domain" {
  description = "Domain name for the deployment"
  type = string
}

variable "subdomain" {
  description = "Subdomain for deployment, empty for apex"
  type = string
}
