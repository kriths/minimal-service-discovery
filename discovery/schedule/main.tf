resource "aws_lambda_function" "schedule_handler" {
  function_name = "asg_schedule_handler"
  runtime = "python3.8"
  handler = "lambda.on_schedule"
  memory_size = 128
  timeout = 5 * 60

  filename = var.lambda_deployment.output_path
  source_code_hash = var.lambda_deployment.output_base64sha256

  role = var.role_arn

  environment {
    variables = var.lambda_environment
  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "schedule_lambda" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn = aws_lambda_function.schedule_handler.arn
}

resource "aws_lambda_permission" "schedule_cw" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.schedule_handler.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.schedule.arn
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/aws/lambda/${aws_lambda_function.schedule_handler.function_name}"
  retention_in_days = 1
}
