variable "regions" {
  type = set(string)
  description = "AWS lambda regions."
  default = []

  validation {
    condition     = length(var.regions) > 0
    error_message = "The `regions` value must have at least one region in list."
  }
}

variable "function_zip_file" {
  type        = string
  description = "Location for certonid serverless archive."
  default = ""

  validation {
    condition     = length(var.function_file) > 0
    error_message = "The `function_file` value must be provided."
  }
}

variable "function_name" {
  type = string
  description = "AWS lambda function name."
  default = "CertonidCertificateGenerator"
}

variable "function_iam_role" {
  type = string
  description = "AWS lambda function IAM role."
  default = "certonid-lambda-role"
}

variable "symmetric_encryption_key" {
  type = string
  description = "Key, which is used as CERTONID_SYMMETRIC_KEY for certonid."
  default = ""
}

variable "ca_key_kms_alias" {
  type = string
  description = "KMS alias key name, which is used by CA encrypted certificate."
  default = "certonid-ca-key"
}

variable "is_ca_kms_generated" {
  type = bool
  description = "Inform, that KMS key already generated."
  default = false
}

variable "ca_key_kms_generated_arn" {
  type = string
  description = "KMS arn, which is used to identify generated key."
}

variable "clients_iam_role" {
  type = string
  description = "AWS lambda clients IAM role."
  default = "certonid-clients-role"
}

variable "clients_names" {
  type = set(string)
  description = "AWS clients, which attached to `clients_iam_role` IAM role to access certonid serverless function."
  default = []
}
