output "api_endpoint" {
  value       = aws_apigatewayv2_stage.default.invoke_url
  description = "URL Endpoint của API để gọi từ Postman/Client"
}