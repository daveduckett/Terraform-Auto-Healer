resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  count               = 5
  alarm_name          = "high-cpu-auto-healer-${count.index}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60" # 1 minute
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"

  # This is the "Link" to the specific servers
  dimensions = {
    InstanceId = aws_instance.auto_healer_server[count.index].id
  }

  # This sends the alarm state change to EventBridge and your SNS Topic
  alarm_actions = [aws_sns_topic.auto_healer_alerts.arn]
}

# Create log stream for forensic data
resource "aws_cloudwatch_log_group" "diagnosis_reports" {
  name              = "/aws/ssm/auto-healer-forensics"
  retention_in_days = 3
}


# Create a Unified Dashboard to review these patients
resource "aws_cloudwatch_dashboard" "healer_dashboard" {
  dashboard_name = "Auto-Healer-Fleet-Status"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            for i in range(length(aws_instance.auto_healer_server)) : [
              "AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.auto_healer_server[i].id,
              { "label" : "Patient-${i}" }
            ]
          ]
          period = 60
          stat   = "Average"
          region = "us-east-1"
          title  = "Fleet CPU Utilization (%)"
        }
      }
    ]
  })
}