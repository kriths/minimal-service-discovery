data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")
  vars = {
    script_code = filebase64("${path.module}/index.php")
  }
}

resource "aws_instance" "single" {
  ami = "ami-0c115dbd34c69a004"  # Latest Amazon Linux 2
  instance_type = "t3.nano"

  user_data = data.template_file.user_data.rendered
}
