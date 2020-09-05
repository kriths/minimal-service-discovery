data "archive_file" "deployment" {
  source_file = "${path.module}/lambda.py"
  output_path = ".build/lambda-deployment.zip"
  type = "zip"
}

resource "aws_lambda_function" "launch_handler" {
  function_name = "asg_launch_handler"
  runtime = "python3.8"
  handler = "lambda.on_launch"
  memory_size = 128
  timeout = 5 * 60

  filename = data.archive_file.deployment.output_path
  source_code_hash = data.archive_file.deployment.output_base64sha256

  role = aws_iam_role.lambda.arn

  environment {
    variables = {
      HOSTED_ZONE = data.aws_route53_zone.zone.id
      DOMAIN = var.domain
      SUBDOMAIN = var.subdomain
      ASG_ID = var.asg_id
    }
  }
}

resource "aws_lambda_permission" "launch_sns" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.launch_handler.function_name
  principal = "sns.amazonaws.com"
  source_arn = aws_sns_topic.launch_events.arn
}
