output "instance_public_ips" {
  description = "Public IP addresses of the auto-healer fleet"
  value       = {
    for i, instance in aws_instance.auto_healer_server : 
    instance.tags["Name"] => instance.public_ip
  }
}

output "forensics_log_group" {
  description = "The CloudWatch Log Group where forensics are sent"
  value       = aws_cloudwatch_log_group.diagnosis_reports.name
}

output "dashboard_url" {
  description = "Quick link to the CloudWatch Dashboard (Standard URL format)"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.healer_dashboard.dashboard_name}"
}