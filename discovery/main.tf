data "aws_route53_zone" "zone" {
  name = var.domain
}

locals {
  prefix = var.subdomain == "" ? "" : "${var.subdomain}."  # Skip preceding dot for apex
  record_name = "${local.prefix}${var.domain}."
}

# Ensure any records that have been created during execution are removed on destroy
resource "null_resource" "delete_dns_record" {
  triggers = {
    hosted_zone_id = data.aws_route53_zone.zone.id
    record_name = local.record_name
  }

  provisioner "local-exec" {
    when = destroy
    command = <<EOF
changes=$(aws route53 list-resource-record-sets --hosted-zone-id ${self.triggers.hosted_zone_id} \
  --query "ResourceRecordSets[?Name == '${self.triggers.record_name}']" |\
  jq '.[] | {"Action":"DELETE", "ResourceRecordSet": .} | {"Changes": [.]}')
[ -n "$changes" ] || exit 0
aws route53 change-resource-record-sets --hosted-zone-id ${self.triggers.hosted_zone_id} --change-batch "$changes"
EOF
    on_failure = continue
  }
}
