variable "api_name" {
  type        = string
  default     = "task-api"
  description = "Tên của API Gateway"
}

variable "dynamodb_table_arn" {
  type        = string
  description = "ARN của bảng DynamoDB để Lambda tương tác"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Tên của bảng DynamoDB"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Danh sách các subnet ID mà Lambda sẽ chạy trong đó"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Danh sách Security Group IDs áp dụng cho Lambda"
}

variable "current_account" {
  type        = string
  description = "account id"
}
