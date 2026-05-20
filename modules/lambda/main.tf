# --------------------------------------------------------------------------
# 1. API GATEWAY (HTTP API)
# --------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "http_api" {
  name          = var.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

data "archive_file" "lambda_zip" {
  for_each = local.functions

  type        = "zip"
  source_dir  = "${path.module}/functions/${each.key}"
  output_path = "${path.module}/build/${each.key}.zip"
}

# Base IAM Trust Policy cho Lambda
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# --------------------------------------------------------------------------
# 2. ĐỊNH NGHĨA CÁC FUNCTION (Mỗi function có IAM Role & Quyền DynamoDB riêng)
# --------------------------------------------------------------------------

locals {
  functions = {
    "GetTasksFunction" = {
      method = "GET"
      path   = "/tasks"
      actions = [
        "dynamodb:Scan",
        "dynamodb:Query"
      ]
    }
    "CreateTaskFunction" = {
      method = "POST"
      path   = "/tasks"
      actions = [
        "dynamodb:PutItem"
      ]
    }
    "UpdateTaskFunction" = {
      method = "PUT"
      path   = "/tasks/{id}" # API Gateway HTTP API dùng {id} thay vì :id
      actions = [
        "dynamodb:UpdateItem",
        "dynamodb:GetItem"
      ]
    }
    "DeleteTaskFunction" = {
      method = "DELETE"
      path   = "/tasks/{id}"
      actions = [
        "dynamodb:DeleteItem"
      ]
    }
  }
}

data "aws_iam_policy_document" "github_access_lambda" {
  for_each = local.functions

  statement {
    effect = "Allow"
    actions = [
      "iam:CreateRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/iam-role-${each.key}"
    ]
  }
}

resource "aws_iam_policy" "github_lambda_policy" {
  name        = "GithubActionsPolicy"
  description = "Quyền cho Github Actions"
  policy      = data.aws_iam_policy_document.github_access_lambda.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_to_github" {
  role       = "GithubActionsWorkflowRole"
  policy_arn = aws_iam_policy.github_lambda_policy.arn
}

# Tạo IAM Role riêng biệt cho từng Function
resource "aws_iam_role" "lambda_roles" {
  for_each           = local.functions
  name               = "iam-role-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Gắn policy ghi log CloudWatch cho từng Role
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  for_each   = local.functions
  role       = aws_iam_role.lambda_roles[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Gắn policy phân quyền DynamoDB riêng biệt theo đúng chức năng (Principle of Least Privilege)
resource "aws_iam_policy" "dynamodb_policies" {
  for_each = local.functions
  name     = "dynamodb-policy-${each.key}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = each.value.actions
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_attach" {
  for_each   = local.functions
  role       = aws_iam_role.lambda_roles[each.key].name
  policy_arn = aws_iam_policy.dynamodb_policies[each.key].arn
}

# Tạo các Lambda Function độc lập
resource "aws_lambda_function" "funcs" {
  for_each = local.functions

  function_name = each.key
  runtime        = "python3.12"
  handler        = "index.handler"

  role = aws_iam_role.lambda_roles[each.key].arn

  filename         = data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256

  environment {
    variables = {
      TASKS_TABLE = var.dynamodb_table_name
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }
}

# --------------------------------------------------------------------------
# 3. KẾT NỐI LAMBDA VỚI API GATEWAY ROUTE
# --------------------------------------------------------------------------

# Tạo Integration kết nối giữa API Gateway và Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  for_each           = local.functions
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.funcs[each.key].invoke_arn
  payload_format_version = "2.0"
}

# Tạo Route cho từng Method / Path
resource "aws_apigatewayv2_route" "routes" {
  for_each  = local.functions
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[each.key].id}"
}

# Cấp quyền cho API Gateway gọi đến Lambda (Permission)
resource "aws_lambda_permission" "api_gw_permission" {
  for_each      = local.functions
  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.funcs[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}