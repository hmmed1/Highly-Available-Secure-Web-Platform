resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  alarm_name          = "web-alb-less-than-2-healthy-targets"
  alarm_description   = "Alarm when fewer than two application instances are healthy"
  comparison_operator = "LessThanThreshold"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"

  statistic          = "Minimum"
  period             = 60
  evaluation_periods = 2
  threshold          = 2

  dimensions = {
    LoadBalancer = aws_lb.web_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.web_tg.arn_suffix
  }

  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "web-alb-5xx-errors"
  alarm_description   = "Alarm when the ALB reports excessive 5xx errors"
  comparison_operator = "GreaterThanThreshold"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  statistic          = "Sum"
  period             = 300
  evaluation_periods = 2
  threshold          = 10

  dimensions = {
    LoadBalancer = aws_lb.web_alb.arn_suffix
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  alarm_name          = "web-ec2-high-cpu"
  alarm_description   = "Alarm when average EC2 CPU usage is high"
  comparison_operator = "GreaterThanThreshold"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  statistic          = "Average"
  period             = 300
  evaluation_periods = 2
  threshold          = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "web-rds-high-cpu"
  alarm_description   = "Alarm when RDS CPU usage is high"
  comparison_operator = "GreaterThanThreshold"

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"

  statistic          = "Average"
  period             = 300
  evaluation_periods = 2
  threshold          = 80

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.web_db.identifier
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "web-rds-low-storage"
  alarm_description   = "Alarm when RDS free storage becomes too low"
  comparison_operator = "LessThanThreshold"

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"

  statistic          = "Minimum"
  period             = 300
  evaluation_periods = 2

  threshold = 2147483648

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.web_db.identifier
  }

  treat_missing_data = "notBreaching"
}
resource "aws_cloudwatch_dashboard" "web_platform" {
  dashboard_name = "HighlyAvailableWebPlatform"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB Request Count"
          view   = "timeSeries"
          region = "eu-west-3"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.web_alb.arn_suffix
            ]
          ]

          period = 300
          stat   = "Sum"
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Healthy Application Targets"
          view   = "timeSeries"
          region = "eu-west-3"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "LoadBalancer",
              aws_lb.web_alb.arn_suffix,
              "TargetGroup",
              aws_lb_target_group.web_tg.arn_suffix
            ]
          ]

          period = 60
          stat   = "Minimum"
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "EC2 CPU Utilization"
          view   = "timeSeries"
          region = "eu-west-3"

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              aws_autoscaling_group.web_asg.name
            ]
          ]

          period = 300
          stat   = "Average"
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "RDS CPU Utilization"
          view   = "timeSeries"
          region = "eu-west-3"

          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              aws_db_instance.web_db.identifier
            ]
          ]

          period = 300
          stat   = "Average"
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "RDS Free Storage"
          view   = "timeSeries"
          region = "eu-west-3"

          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              aws_db_instance.web_db.identifier
            ]
          ]

          period = 300
          stat   = "Minimum"
        }
      }
    ]
  })
}