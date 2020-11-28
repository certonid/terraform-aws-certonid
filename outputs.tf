output "ca_kms_arn" {
  value = aws_kms_alias.ca_aws_kms_alias.arn
}

output "function_arn" {
  value = aws_lambda_function.certonid_serverless.arn
}

output "clients_iam_group_name" {
  value = aws_iam_group.group_for_clients.name
}
