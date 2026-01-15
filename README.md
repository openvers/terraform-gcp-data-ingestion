# Terraform GCP Data Lake Module

## Overview

This repository provides a modular, production-ready Terraform implementation for provisioning a secure, scalable GCP Data Lake. It includes:
- Medallion architecture GCS buckets (Bronze, Silver, Gold)
- Service Account impersonation for secure authentication
- IAM policies for access control
- Secure access patterns and lifecycle management

The modules are designed for flexibility and can be used for both development and production environments.

## Module Structure

- `modules/gcs_bucket/` – GCS bucket creation, versioning, encryption, lifecycle, and access control.

## Usage

```hcl
module "data_lake" {
  source = "github.com/openvers/terraform-gcp-data-lake"

  impersonate_service_account = "your-service-account-email"
  project_id                  = "your-gcp-project-id"
  bronze_bucket_name          = "my-bronze-bucket"
  silver_bucket_name          = "my-silver-bucket"
  gold_bucket_name            = "my-gold-bucket"
}
```

## Testing

A test harness is provided in the `test/` directory. It includes:
- Service account and OIDC federation setup for authentication.
- Automated creation of a sample file and upload to the bronze bucket using Terraform's `local_file` and `google_storage_bucket_object` resources.
- Output variables for integration with CI/CD pipelines.

### Local Deployment Testing

To test the deployment locally, you will need to authenticate with GCP first.

```sh
gcloud auth application-default login

terraform -chdir ./test init
terraform -chdir ./test plan
terraform -chdir ./test apply -auto-approve
terraform -chdir ./test destroy -auto-approve
```

## License

See LICENSE for details.
