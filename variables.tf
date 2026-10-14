## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "function_name" {
  type        = string
  description = "GCP Function Name"
}

variable "function_description" {
  type        = string
  description = "GCP Function Pipeline Description"
}

variable "function_bucket_name" {
  type        = string
  description = "GCS Function Source Bucket Name"
}

variable "google_kms_crypto_key_id" {
  type        = string
  description = "Google Cloud KMS Crypto Key ID"
}

variable "function_contents" {
  type = list(object({
    filepath = string,
    filename = string
  }))
  description = "Full File Paths to Function's Source Code to Zip into single Artifact"
}

variable "function_entrypoint" {
  type        = string
  description = "Function to Run from Source Code Once Triggered"
}

variable "function_service_account_email" {
  type        = string
  description = "Google Service Account to Bind IAM Role Access"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "function_memory" {
  type        = string
  description = "GCP Function memory size"
  default     = "256Mi"
}

variable "function_runtime" {
  type        = string
  description = "GCP Function Runtime Environment"
  default     = "python310"
}

variable "function_timeout" {
  type        = number
  description = "GCP Function Timeout Duration in Seconds"
  default     = 60
}

variable "function_environment_variables" {
  type        = map(any)
  description = "Additional GCP Cloud Function Environment Variables to include"
  default     = {}
}

variable "function_location" {
  type        = string
  description = "Google Cloud Function Region"
  default     = "us-east1"
}

variable "function_max_instance_count" {
  type        = number
  description = "Maximum number of instances for the function"
  default     = 1
}

variable "bearer_token_members" {
    type        = list(string)
    description = "List of user/service account emails"
    default     = []
}