# Fetch current AWS Region (e.g., us-east-1)
data "aws_region" "current" {}

# Fetch current AWS Account ID
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_event_rule" "reboot_rule" {
  name        = "reboot-on-high-cpu"
  description = "Trigger SSM Automation when CPU alarm fires"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [{ "prefix" : "high-cpu-auto-healer-" }]
      state = {
        value = ["ALARM"]
      }
    }
  })
}


resource "aws_cloudwatch_event_target" "ssm_forensics" {
  rule      = aws_cloudwatch_event_rule.reboot_rule.name
  target_id = "ForensicsThenReboot"
  
  # Ensure it says 'automation-definition' and NOT 'document'
  arn       = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:automation-definition/${aws_ssm_document.auto_forensics.name}"
  
  role_arn  = aws_iam_role.eventbridge_ssm_role.arn

  # ADD THIS BLOCK
  dead_letter_config {
    arn = aws_sqs_queue.eventbridge_dlq.arn
  }

  input_transformer {
    input_paths = {
      instance_id = "$.detail.configuration.metrics[0].metricStat.metric.dimensions.InstanceId"
    }
    # The keys in this JSON MUST match the 'parameters' block in your ssm.tf
    input_template = <<EOF
{
  "InstanceId": ["<instance_id>"],
  "AutomationAssumeRole": ["${aws_iam_role.eventbridge_ssm_role.arn}"]
}
EOF
  }
}

// Adding DLQ SQS
resource "aws_sqs_queue" "eventbridge_dlq" {
  name = "auto-healer-eventbridge-dlq"
}

# We need a policy to allow EventBridge to write to this queue
resource "aws_sqs_queue_policy" "dlq_policy" {
  queue_url = aws_sqs_queue.eventbridge_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.eventbridge_dlq.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.reboot_rule.arn
          }
        }
      }
    ]
  })
}