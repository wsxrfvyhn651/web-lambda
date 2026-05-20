module "dynamo_system" {
  source     = "./modules/dynamodb"
  table_name = "Task"
}

module "my_task_api" {
  source              = "./modules/lambda"
  api_name            = "task-management-api"
  dynamodb_table_arn  = module.dynamo_system.table_arn
  dynamodb_table_name = module.dynamo_system.table_name

  subnet_ids         = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  security_group_ids = [aws_security_group.lambda_sg.id]
}

output "endpoint_url" {
  value = module.my_task_api.api_endpoint
}