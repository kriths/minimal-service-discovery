data "aws_ami" "amzn2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")
  vars = {
    script_code = filebase64("${path.module}/index.php")
  }
}

resource "aws_subnet" "servers" {
  vpc_id = var.vpc_id
  map_public_ip_on_launch = true
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "servers" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_instance" "single" {
  ami = data.aws_ami.amzn2.id
  instance_type = "t3.nano"
  subnet_id = aws_subnet.servers.id
  security_groups = [ aws_security_group.servers.id ]

  user_data = data.template_file.user_data.rendered
}
