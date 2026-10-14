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

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT DATA SOURCE
##
## GCP Project Configurations/Details Data Source.
## ---------------------------------------------------------------------------------------------------------------------
data "google_project" "this" {
  provider = google.auth_session
}

data "google_client_openid_userinfo" "this" {
  provider = google.auth_session
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE CLOUD FUNCTIONS FUNCTION ZIP MODULE
##
## Module to create a zip file containing the function code and dependencies.
## Parameters:
##   function_name: Name of the function.
##   function_contents: Contents of the function.
##   function_bucket_name: Name of the bucket where the function will be stored.
## ---------------------------------------------------------------------------------------------------------------------
module "gcp_function_zip" {
  source = "./modules/gcp_function_zip"

  function_name            = var.function_name
  function_contents        = var.function_contents
  function_bucket_name     = var.function_bucket_name
  google_kms_crypto_key_id = var.google_kms_crypto_key_id

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE CLOUD FUNCTIONS FUNCTION RESOURCE
##
## GCP Cloud Function with HTTP Trigger to execute a source data ingestion into GCS bucket.
##
## Parameters:
## - `name`: GCP Function name
## - `description`: GCP Function description defining its purpose
## - `runtime`: GCP Function runtime enviornment/ code runtime
## - `location`: GCP Function location
## - `available_memory`: Size of GCP Function memory to allocate
## - `bucket`: GCS Bucket where the GCP Function source code resides
## - `object`: Blob path to GCP Function source code artifact
## - `service_account`: Service Account Email to run functions as/ mirror roles
## - `timeout`: Length of time to run function before timing out
## - `entry_point`: Function to enter in source code once triggered
## - `environment_variables`: Mapping of ENV Variables to pass to Function runtime
## ---------------------------------------------------------------------------------------------------------------------
resource "google_cloudfunctions2_function" "this" {
  provider = google.auth_session

  name        = var.function_name
  description = var.function_description
  location    = var.function_location

  build_config {
    runtime               = var.function_runtime
    entry_point           = var.function_entrypoint
    environment_variables = var.function_environment_variables
    service_account       = data.google_client_openid_userinfo.this.id

    source {
      storage_source {
        bucket = module.gcp_function_zip.gcs_function_bucket_name
        object = module.gcp_function_zip.gcs_function_object_name
      }
    }
  }

  service_config {
    max_instance_count    = var.function_max_instance_count
    available_memory      = var.function_memory
    timeout_seconds       = var.function_timeout
    environment_variables = var.function_environment_variables
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE CLOUD FUNCTIONS FUNCTION IAM MEMBER RESOURCE
##
## Provide IAM Member access to the Service Account to allow the Service Account to invoke Cloud Function Trigger when
## new blob hits the trigger bucket.
##
## Parameters:
## - `project`: GCP Project ID
## - `location`: GCP Region
## - `cloud_function`: GCP Function Name
## - `role`: IAM role name to allow cloud functions invoker to service account
## - `member`: Service account email binded to GCP Function
## ---------------------------------------------------------------------------------------------------------------------
resource "google_cloudfunctions2_function_iam_member" "this" {
  provider   = google.auth_session
  depends_on = [google_cloudfunctions2_function.this]

  project        = data.google_project.this.project_id
  location       = google_cloudfunctions2_function.this.location
  cloud_function = google_cloudfunctions2_function.this.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.function_service_account_email}"
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE CLOUD RUN SERVICE IAM MEMBER RESOURCE
##
## Provide IAM Member access with Cloud Run Service to the Service Account for 
## Gen2 HTTP invocation is authorized by the underlying Cloud Run service.
##
## Parameters:
## - `project`: GCP Project ID
## - `location`: GCP Region
## - `service`: GCP Function Service Name
## - `role`: IAM role name to allow cloud functions invoker to service account
## - `member`: Service account email binded to GCP Function
## ---------------------------------------------------------------------------------------------------------------------
resource "google_cloud_run_service_iam_member" "this" {
  provider = google.auth_session
  depends_on = [google_cloudfunctions2_function.this]

  project  = google_cloudfunctions2_function.this.project
  location = google_cloudfunctions2_function.this.location
  service  = basename(google_cloudfunctions2_function.this.service_config[0].service)
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.function_service_account_email}"
}
