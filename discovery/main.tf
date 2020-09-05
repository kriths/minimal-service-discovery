data "aws_route53_zone" "zone" {
  name = var.domain
}

data "archive_file" "deployment" {
  source_file = "${path.module}/lambda.py"
  output_path = ".build/lambda-deployment.zip"
  type = "zip"
}

locals {
  prefix = var.subdomain == "" ? "" : "${var.subdomain}."  # Skip preceding dot for apex
  record_name = "${local.prefix}${var.domain}."
  lambda_environment = {
    HOSTED_ZONE = data.aws_route53_zone.zone.id
    DOMAIN = var.domain
    SUBDOMAIN = var.subdomain
    ASG_ID = var.asg_id
  }
}

module "launch" {
  source = "./launch"

  asg_id = var.asg_id
  role_arn = aws_iam_role.lambda.arn
  lambda_deployment = data.archive_file.deployment
  lambda_environment = local.lambda_environment
}

module "schedule" {
  source = "./schedule"

  role_arn = aws_iam_role.lambda.arn
  lambda_deployment = data.archive_file.deployment
  lambda_environment = local.lambda_environment
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
