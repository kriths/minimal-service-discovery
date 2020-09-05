resource "aws_lambda_function" "launch_handler" {
  function_name = "asg_launch_handler"
  runtime = "python3.8"
  handler = "lambda.on_launch"
  memory_size = 128
  timeout = 5 * 60

  filename = var.lambda_deployment.output_path
  source_code_hash =var.lambda_deployment.output_base64sha256

  role = var.role_arn

  environment {
    variables = var.lambda_environment
  }
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

resource "aws_lambda_permission" "launch_sns" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.launch_handler.function_name
  principal = "sns.amazonaws.com"
  source_arn = aws_sns_topic.launch_events.arn
}
