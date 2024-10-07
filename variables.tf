variable "subscription_id" {
  default     = ""
  description = "The Subscription ID which should be used. This can also be sourced from the ARM_SUBSCRIPTION_ID Environment Variable."
  type        = string
}

variable "client_id" {
  default     = ""
  description = "The Client ID which should be used. This can also be sourced from the ARM_CLIENT_ID Environment Variable."
  type        = string
}

variable "client_secret" {
  default     = ""
  description = "When authenticating as a Service Principal using a Client Secret, the Client Secret which should be used. This can also be sourced from the ARM_CLIENT_SECRET Environment Variable."
  type        = string
}

variable "tenant_id" {
  default     = ""
  description = "The Tenant ID which should be used. This can also be sourced from the ARM_TENANT_ID Environment Variable."
  type        = string
}

variable "env" {
  default     = ""
  description = "Environment to apply Terraform"
  type        = string
}
