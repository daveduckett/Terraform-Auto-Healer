/// EC2 Section

# Create the EC2 role
resource "aws_iam_role" "auto_healer_role" {
  name = "AutoHealer-EC2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "auto-healer-role"
  }
}

# attach the needed SSM policy to the role
resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.auto_healer_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# attach the policy for logging to the role
resource "aws_iam_role_policy_attachment" "attach_ssm_logging_policy" {
  role       = aws_iam_role.auto_healer_role.name
  policy_arn = aws_iam_policy.ssm_logging.arn
}

# attach the instance profile to the role
resource "aws_iam_instance_profile" "auto_healer_instance_profile" {
  name = "AutoHealer-Instance-Profile"
  role = aws_iam_role.auto_healer_role.name
}

/// Event Bridge Section 

# Create the Event Bridge role
resource "aws_iam_role" "eventbridge_ssm_role" {
  name = "EventBridge-SSM-Automation-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { 
        Service = [
                "events.amazonaws.com",
                "ssm.amazonaws.com"
            ]
        }
    }]
  })
}

# Attach the policy that allows rebooting EC2
resource "aws_iam_role_policy_attachment" "ssm_automation_attach" {
  role       = aws_iam_role.eventbridge_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

// SSM Section
resource "aws_iam_policy" "ssm_logging" {
  name        = "SSMForensicsLogging"
  description = "Allows EC2 to write forensics logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        # It's best practice to point this to your specific Log Group ARN
        Resource = "${aws_cloudwatch_log_group.diagnosis_reports.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_pass_role" {
  name = "EventBridgePassRole"
  role = aws_iam_role.eventbridge_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Existing PassRole Statement
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*" 
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ssm.amazonaws.com"
          }
        }
      },
      {
        # NEW Reboot Statement
        Effect   = "Allow"
        Action   = "ec2:RebootInstances"
        Resource = "*" # You can narrow this to your specific EC2 ARNs later
      }
    ]
  })
}