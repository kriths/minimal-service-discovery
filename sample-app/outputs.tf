output "asg_arn" {
  value = aws_autoscaling_group.servers.arn
}

output "asg_id" {
  value = aws_autoscaling_group.servers.id
}
