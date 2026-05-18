data "aws_iam_role" "github_role" {
  name = "GithubActionsWorkflowRole"
}


# Lấy thông tin tài khoản AWS hiện tại một cách tự động
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "github_actions_iam_policy" {
  name = "github-actions-iam-permissions"
  role = data.aws_iam_role.github_role.id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "iam:GetRole"
        # Terraform tự điền Account ID ở đây khi chạy 
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GithubActionsWorkflowRole"
      }
    ]
  })
}

resource "aws_iam_policy" "vpc_minimal_policy" {
  name        = "github-actions-vpc-minimal"
  description = "Quyen toi thieu de tao VPC tu dong"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:DescribeVpcs",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:DescribeSubnets",
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${data.aws_iam_role.github_role.name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_minimal" {
  role       = data.aws_iam_role.github_role.name
  policy_arn = aws_iam_policy.vpc_minimal_policy.arn
}
