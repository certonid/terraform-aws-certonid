output "ca_kms_arn" {
  value = length(var.symmetric_encryption_key) > 0 ? "" : aws_kms_key.ca_aws_kms_key[0].arn
}

output "kmsauth_kms_arn" {
  value = var.is_kmsauth_enabled ? aws_kms_key.kmsauth_aws_kms_key[0].arn : ""
}

output "function_iam_role_arn" {
  value = aws_iam_role.iam_for_certonid_serverless.arn
}

output "function_lambda_arn" {
  value = aws_lambda_function.certonid_serverless.arn
}

output "clients_iam_group_name" {
  value = var.is_group_for_clients_exists ? var.clients_iam_group_name : aws_iam_group.clients_aws_iam_group[0].name
}
