data "aws_iam_role" "github_role" {
  name = "GithubActionsWorkflowRole"
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
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:DescribeVpcs",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:DescribeSubnets",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_minimal" {
  role       = data.aws_iam_role.github_role.name
  policy_arn = aws_iam_policy.vpc_minimal_policy.arn
}