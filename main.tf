data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ca_aws_kms_key" {
  count = length(var.symmetric_encryption_key) > 0 ? 0 : 1

  description              = "KMS key, which used by ${var.function_name} lambda to generate ssh certificates"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_kms_alias" "ca_aws_kms_alias" {
  count = length(var.symmetric_encryption_key) > 0 ? 0 : 1

  name          = "alias/certonid-ca-key"
  target_key_id = aws_kms_key.ca_aws_kms_key[0].key_id
}

resource "aws_kms_key" "kmsauth_aws_kms_key" {
  count = var.is_kmsauth_enabled ? 1 : 0

  description              = "KMS key, which used by kmsauth"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_kms_alias" "kmsauth_aws_kms_alias" {
  count = var.is_kmsauth_enabled ? 1 : 0

  name          = "alias/kmsauth-ca-key"
  target_key_id = aws_kms_key.kmsauth_aws_kms_key[0].key_id
}

resource "aws_iam_role" "iam_for_certonid_serverless" {
  name               = var.function_iam_role_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "iam_for_general_certonid_serverless" {
  name   = var.function_iam_general_policy_name
  role   = aws_iam_role.iam_for_certonid_serverless.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kms:GenerateRandom",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "iam_for_kms_certonid_serverless" {
  count = length(var.symmetric_encryption_key) > 0 ? 0 : 1

  name   = var.function_iam_kms_policy_name
  role   = aws_iam_role.iam_for_certonid_serverless.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowKMSDecryption",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey"
            ],
            "Resource": [
                "${aws_kms_key.ca_aws_kms_key[0].arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "iam_for_certonid_kmsauth_serverless" {
  count = var.is_kmsauth_enabled ? 1 : 0

  name   = var.function_iam_kmsauth_policy_name
  role   = aws_iam_role.iam_for_certonid_serverless.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowKMSDecryption",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey"
            ],
            "Resource": [
                "${aws_kms_key.kmsauth_aws_kms_key[0].arn}"
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

resource "aws_iam_group" "clients_aws_iam_group" {
  count = var.is_group_for_clients_exists ? 0 : 1

  name = var.clients_iam_group_name
  path = "/"
}

resource "aws_iam_group_policy" "clients_aws_iam_policy" {
  name   = var.clients_iam_policy_name
  group  = var.is_group_for_clients_exists ? var.clients_iam_group_name : aws_iam_group.clients_aws_iam_group[0].name
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

resource "aws_iam_group_policy" "clients_aws_iam_kmsauth_policy" {
  count = var.is_kmsauth_enabled ? 1 : 0

  name   = var.function_iam_kmsauth_policy_name
  group  = var.is_group_for_clients_exists ? var.clients_iam_group_name : aws_iam_group.clients_aws_iam_group[0].name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
          "iam:GetUser"
      ],
      "Resource": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      ]
    },
    {
      "Sid": "AllowKMSEncrypt",
      "Action": [
        "kms:Encrypt"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_kms_key.kmsauth_aws_kms_key[0].arn}"
      ],
      "Condition": {
        "StringEquals": {
          "kms:EncryptionContext:to": "${var.kmsauth_service_id}",
          "kms:EncryptionContext:user_type": "user",
          "kms:EncryptionContext:from": "$${aws:username}"
        },
        ${var.kmsauth_aws_additional_conditions}
      }
    }
  ]
}
EOF
}

resource "aws_iam_group_membership" "clients_aws_iam_group_membership" {
  count = var.is_group_for_clients_exists ? 0 : 1

  name  = "certonid-access-group-membership"
  users = var.clients_names
  group = aws_iam_group.clients_aws_iam_group[0].name
}
