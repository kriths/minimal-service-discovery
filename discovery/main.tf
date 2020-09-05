data "aws_route53_zone" "zone" {
  name = var.domain
}

locals {
  prefix = var.subdomain == "" ? "" : "${var.subdomain}."  # Skip preceding dot for apex
  record_name = "${local.prefix}${var.domain}."
}

resource "aws_sns_topic" "launch_events" {
  name_prefix = "asg_launch_"
}

resource "aws_autoscaling_notification" "launch" {
  group_names = [ var.asg_id ]
  notifications = [ "autoscaling:EC2_INSTANCE_LAUNCH" ]
  topic_arn = aws_sns_topic.launch_events.arn
}

resource "aws_sns_topic_subscription" "launch_lambda" {
  topic_arn = aws_sns_topic.launch_events.arn
  protocol = "lambda"
  endpoint = aws_lambda_function.launch_handler.arn
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
