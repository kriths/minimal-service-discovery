variable "vpc_id" {
  description = "VPC to launch instances in"
  type = string
}

variable "min_count" {
  description = "Minimum count of instances"
  type = number
}

variable "max_count" {
  description = "Maximum count of instances"
  type = number
}
