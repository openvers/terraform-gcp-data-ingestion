terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      configuration_aliases = [
        google.auth_session,
      ]
    }
  }
}

##---------------------------------------------------------------------------------------------------------------------
## GCP CLOUD FUNCTION MODULE
##
## GCP Cloud Function with HTTP Trigger to execute a source data ingestion into GCS bucket.
##
## Parameters:
## - `function_name`: GCP Cloud Function name
## - `function_service_account_email`: Recently providioned service account email
## - `function_service_account_member`: Recently providioned service account member ID
## - `function_entrypoint`: Function name to run from source code on blob trigger
## - `function_bucket_name`: GCS Bucket to create and configure the Cloud Function to trigger on
## - `function_contents`: Dynamic mapping of Function source code files to archive
##---------------------------------------------------------------------------------------------------------------------
module "gcp_function" {
  source = "./modules/gcp_function"

  function_name                  = var.function_name
  function_description           = var.function_description
  function_location              = var.function_location
  function_service_account_email = var.function_service_account_email
  function_entrypoint            = var.function_entrypoint
  function_bucket_name           = var.function_bucket_name
  google_kms_crypto_key_id       = var.google_kms_crypto_key_id
  function_contents              = var.function_contents
  function_environment_variables = var.function_environment_variables

  providers = {
    google.auth_session = google.auth_session
  }
}
