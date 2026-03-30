# 1. Create the SNS Topic
resource "aws_sns_topic" "auto_healer_alerts" {
  name = "auto-healer-alerts"
}

# 2. Create the Subscription (Your Email)
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.auto_healer_alerts.arn
  protocol  = "email"
  endpoint  = "duck7090@gmail.com" # Change this to your actual email!
}