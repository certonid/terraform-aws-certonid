variable "function_zip_file" {
  type        = string
  description = "Location for certonid serverless archive."

  validation {
    condition     = length(var.function_zip_file) > 0
    error_message = "The `function_zip_file` value must be provided."
  }
}

variable "function_name" {
  type        = string
  description = "AWS lambda function name."
  default     = "CertonidCertificateGenerator"
}

variable "function_handler" {
  type        = string
  description = "AWS lambda function handler."
  default     = "serverless"
}

variable "function_iam_role_name" {
  type        = string
  description = "AWS lambda function IAM role."
  default     = "certonid-lambda-role"
}

variable "function_iam_policy_name" {
  type        = string
  description = "AWS lambda function IAM policy."
  default     = "certonid-lambda-policy"
}

variable "symmetric_encryption_key" {
  type        = string
  description = "Key, which is used as CERTONID_SYMMETRIC_KEY for certonid."
  default     = ""
}

variable "is_kmsauth_enabled" {
  type        = bool
  description = "Add kmsauth for additional security."
  default     = false
}

variable "kmsauth_service_id" {
  type        = string
  description = "Kmsauth service ID."
  default     = "certonid"
}

variable "function_iam_kmsauth_policy_name" {
  type        = string
  description = "AWS kmsauth lambda function IAM policy."
  default     = "certonid-kmsauth-lambda-policy"
}

variable "is_group_for_clients_exists" {
  type        = bool
  description = "Is IAM group already created."
  default     = false
}

variable "clients_iam_group_name" {
  type        = string
  description = "AWS lambda clients IAM group."
  default     = "certonid-clients-role"
}

variable "clients_iam_policy_name" {
  type        = string
  description = "AWS lambda function IAM role."
  default     = "certonid-clients-policy"
}

variable "clients_names" {
  type        = set(string)
  description = "AWS clients, which attached to `clients_iam_group_name` IAM role to access certonid serverless function."
  default     = []
}
