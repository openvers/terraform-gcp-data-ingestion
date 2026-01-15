## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "function_name" {
  type        = string
  description = "GCP Function Name for Source Code Zip Blob"
}

variable "function_contents" {
  type = list(object({
    filepath = string,
    filename = string
  }))
  description = "Full File Paths to Function's Source Code to Zip into single Artifact"
}

variable "function_bucket_name" {
  type        = string
  description = "GCS Function Source Bucket Name"
}

variable "google_kms_crypto_key_id" {
  type        = string
  description = "Google Cloud KMS Crypto Key ID"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------
