terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "sim-parables"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ci-cd-gcp-workspace"
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT DATA SOURCE
##
## GCP Project Configurations/Details Data Source.
## ---------------------------------------------------------------------------------------------------------------------
data "google_project" "this" {
  provider = google.tokengen
}

locals {
  suffix = "test-${random_string.this.result}"
  principal_roles = [
    {
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.POOL_ID}/subject/repo:${var.GITHUB_REPOSITORY}:ref:${var.GITHUB_REF}",
      role      = "roles/iam.workloadIdentityUser"
    },
    {
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.POOL_ID}/subject/repo:${var.GITHUB_REPOSITORY}:environment:${var.GITHUB_ENV}",
      role      = "roles/iam.workloadIdentityUser"
    },
  ]
}


## ---------------------------------------------------------------------------------------------------------------------
## GCP PROVIDER
##
## Configures the GCP provider with OIDC Connect via ENV Variables.
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias = "tokengen"
}

##---------------------------------------------------------------------------------------------------------------------
## GCP SERVICE ACCOUNT MODULE
##
## This module provisions a GCP service account along with associated roles and security groups.
##
## Parameters:
## - `IMPERSONATE_SERVICE_ACCOUNT_EMAIL`: Existing GCP service account email to impersonate for new SA creation.
## - `new_service_account_name`: New service account name.
##---------------------------------------------------------------------------------------------------------------------
module "service_account_auth" {
  source = "github.com/openvers/terraform-gcp-service-account.git?ref=5645d79241069640d425010dbf0cf11785a03da7"

  IMPERSONATE_SERVICE_ACCOUNT_EMAIL = var.IMPERSONATE_SERVICE_ACCOUNT_EMAIL
  new_service_account_name          = "tf-service-account-${local.suffix}"
  roles_list = [
    "roles/storage.admin",
    "roles/cloudkms.admin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudfunctions.admin",
    "roles/logging.logWriter",
    "roles/artifactregistry.writer",
    "roles/run.builder"
  ]

  providers = {
    google.tokengen = google.tokengen
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GCP PROVIDER
##
## Authenticated session with newly created service account.
##
## Parameters:
## - `access_token`: Access token from service_account_auth module
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias        = "auth_session"
  access_token = module.service_account_auth.access_token
  project      = data.google_project.this.project_id
}

##---------------------------------------------------------------------------------------------------------------------
## GCP WORKLOAD IDENTITY FEDERTAION PRINICPALS MODULE
##
## This module creates Service Account grants to a specific Google Workload Identity Federation (WIF) Pool
## to allow OpenID Connect authorization within Github Actions.
##
## Parameters:
## - `project_number`: GCP project number (not ID).
## - `pool_id`: Exiting Google WIF pool ID.
## - `prinicpal_roles`: List of objects defining WIF prinicpals and impersonating roles.
## - `service_account_id`: New service account ID.
##---------------------------------------------------------------------------------------------------------------------
module "workload_identity_federation_principals" {
  source = "github.com/openvers/terraform-gcp-service-account.git//modules/workflow_identity_federation_principal?ref=5645d79241069640d425010dbf0cf11785a03da7"

  project_number     = data.google_project.this.number
  pool_id            = var.POOL_ID
  provider_id        = var.PROVIDER_ID
  principal_roles    = local.principal_roles
  service_account_id = module.service_account_auth.service_account_id

  providers = {
    google.auth_session = google.auth_session
  }
}


##---------------------------------------------------------------------------------------------------------------------
## GCP DATA LAKE MODULE
##
## This module creates a Google Cloud Data Lake with Bronze, Silver, and Gold buckets, and a KMS key ring.
##
## Parameters:
## - `bronze_bucket_name`: Name of the Bronze bucket.
## - `silver_bucket_name`: Name of the Silver bucket.
## - `gold_bucket_name`: Name of the Gold bucket.
## - `kms_key_ring_name`: Name of the KMS key ring.
## - `kms_key_name`: Name of the KMS key.
##---------------------------------------------------------------------------------------------------------------------
module "data_lake" {
  source     = "github.com/openvers/terraform-gcp-data-lake.git?ref=6a1fb77f16aa1616fb0428c4914f4e822083c3fd"
  depends_on = [module.service_account_auth]

  bronze_bucket_name = "test-bronze-bucket-${local.suffix}"
  silver_bucket_name = "test-silver-bucket-${local.suffix}"
  gold_bucket_name   = "test-gold-bucket-${local.suffix}"
  kms_key_ring_name  = "test-key-ring-${local.suffix}"
  kms_key_name       = "test-data-lake-key-${local.suffix}"

  providers = {
    google.auth_session = google.auth_session
  }
}

##---------------------------------------------------------------------------------------------------------------------
## GCP CLOUD FUNCTION MODULE
##
## This module provisions a GCP Cloud Function with Blob Trigger capabilities to run stored procedure on newly created
## blobs landing in the trigger bucket.
##
## Parameters:
## - `function_name`: GCP Cloud Function name
## - `function_service_account_email`: Recently providioned service account email
## - `function_service_account_member`: Recently providioned service account member ID
## - `function_entrypoint`: Function name to run from source code on blob trigger
## - `target_bucket_name`: GCS Bucket to create and configure the Cloud Function to trigger on
## - `function_contents`: Dynamic mapping of Function source code files to archive
##
## Providers:
## - `google.tokengen`: Alias for the GCP provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "gcp_cloud_function" {
  source = "../"
  depends_on = [
    module.service_account_auth,
    module.data_lake
  ]

  function_name                  = "example-cloud-function-${local.suffix}"
  function_description           = "Example GCP Data Ingestion Cloud Function"
  function_bucket_name           = "example-cloud-function-source-${local.suffix}"
  google_kms_crypto_key_id       = module.data_lake.google_kms_crypto_key_id
  function_service_account_email = module.service_account_auth.service_account_email
  function_entrypoint            = "run"
  function_contents = [
    {
      filename = "main.py",
      filepath = abspath("./source/main.py")
    },
    {
      filename = "requirements.txt",
      filepath = abspath("./source/requirements.txt")
    }
  ]

  function_environment_variables = {
    OUTPUT_BUCKET = module.data_lake.bronze_bucket_name
  }

  providers = {
    google.auth_session = google.auth_session
  }
}
