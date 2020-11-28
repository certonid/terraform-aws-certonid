resource "aws_kms_key" "ca_aws_kms_key" {
  count = var.is_ca_kms_generated ? 0 : 1

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_kms_alias" "ca_aws_kms_alias" {
  count = var.is_ca_kms_generated ? 0 : 1

  name          = "alias/${var.ca_key_kms_alias}"
  target_key_id = aws_kms_key.ca_aws_kms_key.key_id
}

resource "aws_iam_role" "iam_for_certonid_serverless" {
  name = var.function_iam_role

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        },
        {
            "Sid": "AllowKMSDecryption",
            "Effect": "Allow",
            "Action": [
                "kms:GenerateRandom",
                "kms:Decrypt",
                "kms:DescribeKey"
            ],
            "Resource": [
                "${var.is_ca_kms_generated ? var.ca_key_kms_generated_arn : aws_kms_alias.ca_aws_kms_alias.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_lambda_function" "certonid_serverless" {
  function_name = var.function_name
  description   = "Certonid serverless function for ${var.function_name}"
  filename      = var.function_zip_file
  role          = aws_iam_role.iam_for_certonid_serverless.arn
  handler       = var.function_handler

  source_code_hash = filebase64sha256(var.function_zip_file)

  runtime                        = "go1.x"
  memory_size                    = 128
  timeout                        = 10
  reserved_concurrent_executions = 5

  environment {
    variables = {
      CERTONID_SYMMETRIC_KEY = var.symmetric_encryption_key
    }
  }
}

resource "aws_iam_group" "group_for_clients" {
  name = var.clients_iam_group
  path = "/"
}

resource "aws_iam_group_policy" "group_for_clients" {
  name  = var.clients_iam_group
  group = aws_iam_group.group_for_clients.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "${aws_lambda_function.certonid_serverless.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_user_group_membership" "group_for_clients" {
  for_each = var.clients_names
  user     = each.key

  groups = [
    aws_iam_group.group_for_clients.name
  ]
}
