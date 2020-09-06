output "asg_id" {
  value = module.sample-app.asg_id
}

output "http_url" {
  value = "http://${module.discovery.hostname}/"
}
