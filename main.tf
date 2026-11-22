data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "cloudwatch_role" {
  name = "${var.project_name}-EC2-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cloudwatch_profile" {
  name = "${var.project_name}-Instance-Profile"
  role = aws_iam_role.cloudwatch_role.name
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/project17/ec2/system"
  retention_in_days = 7
}

resource "aws_instance" "log_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  user_data_replace_on_change = true
  iam_instance_profile        = aws_iam_instance_profile.cloudwatch_profile.name

  user_data = templatefile("${path.module}/cloudwatch-agent.sh", {
    log_group = aws_cloudwatch_log_group.system_logs.name
  })

  tags = {
    Name    = "${var.project_name}-EC2"
    Project = "Project17"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_policy,
    aws_iam_role_policy_attachment.ssm_policy,
    aws_cloudwatch_log_group.system_logs
  ]
}
