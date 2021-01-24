output "lambda_arn" {
  value       = module.lambda.arn
  description = "ARN of the given lambda."
}

output "cloudwatch_logs_arn" {
  value       = module.lambda.cloudwatch_logs_arn
  description = "ARN of Lambda cloudwatch logs"
}

output "cloudwatch_logs_name" {
  value       = module.lambda.cloudwatch_logs_name
  description = "Cloudwatch logs name"

}

output "invoke_arn" {

  value       = module.lambda.invoke_arn
  description = "Cloudwatch invoke_arn"

}

output "deployment_invoke_url" {
  description = "Deployment invoke url"
  value       = aws_api_gateway_deployment.deployment.invoke_url
}