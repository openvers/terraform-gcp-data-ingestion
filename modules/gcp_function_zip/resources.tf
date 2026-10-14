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
## FUNCTION BUCKET MODULE
##
## GCS Bucket to store GCP function source code.
##
## Parameters:
## - `bucket_name`: GCS bucket name
## ---------------------------------------------------------------------------------------------------------------------
module "function_bucket" {
  source = "github.com/openvers/terraform-gcp-data-lake.git//modules/gcs_bucket?ref=c625ba002ca48a3294f82a09212afc46e38d136e"

  bucket_name              = var.function_bucket_name
  google_kms_crypto_key_id = var.google_kms_crypto_key_id

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## ARCHIVE FILE DATA SOURCE
##
## Zip the latest changes to the function source code prior to deployment.
##
## Parameters:
## - `type`: Archive file type
## - `output_file_mode`: Unix permission
## - `output_path`: Archive output path
## - `content`: Dynamic source code file paths to compressed in archive
## - `filename`: Dynamic source code file names to be mapped in compressed archive
## ---------------------------------------------------------------------------------------------------------------------
data "archive_file" "this" {
  type             = "zip"
  output_file_mode = "0666"
  output_path      = "./source/${var.function_name}.zip"

  dynamic "source" {
    for_each = var.function_contents
    content {
      content  = file(source.value.filepath) # Path to File
      filename = source.value.filename       # Name of file in zip file
    }
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE STORAGE BUCKET OBJECT RESOURCE
##
## Upload the pipeline source code to trigger on every new blob upload on the trigger bucket.
##
## Parameters:
## - `name`: Blob name for function source code artifact
## - `bucket`: GCS Bucket name where function source code will reside
## - `source`: File path to function source code zip archive
## ---------------------------------------------------------------------------------------------------------------------
resource "google_storage_bucket_object" "this" {
  provider = google.auth_session

  name   = "${var.function_name}.zip"
  bucket = module.function_bucket.bucket_name
  source = data.archive_file.this.output_path
}
