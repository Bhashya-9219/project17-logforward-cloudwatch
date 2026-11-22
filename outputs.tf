output "instance_id" {
  value = aws_instance.log_server.id
}

output "public_ip" {
  value = aws_instance.log_server.public_ip
}

output "log_group" {
  value = aws_cloudwatch_log_group.system_logs.name
}
