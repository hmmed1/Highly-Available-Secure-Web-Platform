


data "aws_caller_identity" "current" {}




resource "aws_iam_policy" "developer_policy" {
  name        = "HighlyAvailableWebPlatform-DeveloperPolicy"
  description = "Read-only infrastructure access for application developers"

  policy = file("${path.module}/iam/developer-policy.json")

  tags = {
    Project = "Highly-Available-Secure-Web-Platform"
    Role    = "Developer"
  }
}


resource "aws_iam_role" "developer_role" {
  name = "HighlyAvailableWebPlatform-DeveloperRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "Highly-Available-Secure-Web-Platform"
    Role    = "Developer"
  }
}


resource "aws_iam_role_policy_attachment" "developer_policy_attachment" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.developer_policy.arn
}

resource "aws_iam_role" "sysadmin_role" {
  name = "HighlyAvailableWebPlatform-SysadminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "Highly-Available-Secure-Web-Platform"
    Role    = "Sysadmin"
  }
}
resource "aws_iam_role_policy_attachment" "sysadmin_admin_policy" {
  role       = aws_iam_role.sysadmin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}