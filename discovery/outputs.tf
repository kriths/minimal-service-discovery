output "hostname" {
  value = trimsuffix(local.record_name, ".")
}
