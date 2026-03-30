resource "aws_ssm_document" "auto_forensics" {
  name          = "AutoHealer-Forensics-and-Reboot"
  document_type = "Automation" # <--- Must be Automation

  content = jsonencode({
    schemaVersion = "0.3" # <--- Automation requires 0.3
    description   = "Collects forensics then reboots the instance."
    parameters = {
      InstanceId = {
        type = "String"
        description = "EC2 Instance to heal"
      }
      AutomationAssumeRole = {
        type = "String"
        description = "Role for the automation to assume"
      }
    }
    assumeRole = "{{ AutomationAssumeRole }}"
    mainSteps = [
      {
        name   = "runForensics"
        action = "aws:runCommand" # <--- Automation calling a command step
        inputs = {
          DocumentName = "AWS-RunShellScript"
          InstanceIds  = ["{{ InstanceId }}"]
          Parameters = {
            commands = [
                "#!/bin/bash",
                "INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)",
                "LOG_GROUP='/aws/ssm/auto-healer-forensics'",
                "LOG_STREAM=\"$INSTANCE_ID-$(date +%s)\"",
                "aws logs create-log-stream --log-group-name $LOG_GROUP --log-stream-name $LOG_STREAM --region us-east-1",
                "echo '--- TOP CPU PROCESSES ---' > /tmp/forensics.txt",
                "ps aux --sort=-%cpu | head -n 10 >> /tmp/forensics.txt",
                # 1. Capture the content and escape it for JSON using Python
                "MESSAGE_JSON=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' < /tmp/forensics.txt)",

                # 2. Ship it to CloudWatch using the proper JSON array format
                "TIMESTAMP=$(date +%s%3N)",
                "aws logs put-log-events --log-group-name $LOG_GROUP --log-stream-name $LOG_STREAM --log-events \"[{\\\"timestamp\\\": $TIMESTAMP, \\\"message\\\": $MESSAGE_JSON}]\" --region us-east-1"            ]
          }
        }
      },
      {
        name   = "rebootInstance"
        action = "aws:executeAwsApi"
        inputs = {
          Service = "ec2"
          Api     = "RebootInstances"
          InstanceIds = ["{{ InstanceId }}"]
        }
      }
    ]
  })
}