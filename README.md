## Overview

This repository provides a modular, production-ready Terraform implementation for deploying a GCP data ingestion Cloud Function. It packages source code, uploads the function artifact to Google Cloud Storage, and provisions a Cloud Functions v2 HTTP endpoint that can ingest source data into a target GCS bucket. It includes:
- Cloud Functions v2 deployment for data ingestion workloads
- Source code packaging and upload to a GCS function artifact bucket

The modules are designed for flexibility and can be used for both development and production environments.

## Module Structure

- `modules/gcp_function/` – Cloud Functions v2 deployment, service configuration, IAM, runtime settings, and HTTP trigger output.
- `modules/gcp_function_zip/` – Function source archive creation and upload to a GCS artifact bucket.

## Usage

```hcl
module "data_ingestion" {
  source = "github.com/openvers/terraform-gcp-data-ingestion"

  function_name                  = "example-data-ingestion-function"
  function_description           = "Example GCP data ingestion Cloud Function"
  function_bucket_name           = "example-function-source-bucket"
  google_kms_crypto_key_id       = "projects/your-project/locations/us-east1/keyRings/example/cryptoKeys/example-key"
  function_entrypoint            = "run"

  function_contents = [
    {
      filename = "main.py"
      filepath = abspath("./source/main.py")
    },
    {
      filename = "requirements.txt"
      filepath = abspath("./source/requirements.txt")
    }
  ]

  function_environment_variables = {
    OUTPUT_BUCKET = "your-target-ingestion-bucket"
  }
}
```

## Testing

A test harness is provided in the `test/` directory. It includes:
- Service account and OIDC federation setup for authentication.
- Function source packaging and upload to the configured GCS artifact bucket.
- Cloud Function deployment configured with an ingestion output bucket environment variable.
- Output variables for integration with CI/CD pipelines.

### Prerequisites

Before running Terraform, configure a bootstrap Google Cloud service account that can create the service account and IAM resources managed by this module.

Set `GOOGLE_PROJECT` to the deployment project ID. Install the test dependencies (`python3 -m pip install pytest requests gcsfs`) and authenticate the gcloud CLI with `gcloud auth login`; CLI authentication is separate from Application Default Credentials.

For local tests, the CLI identity must be allowed to impersonate the generated service account exposed by `terraform -chdir=test output -raw service_account_email`. It needs `iam.serviceAccounts.getOpenIdToken` to mint the HTTP ID token and `iam.serviceAccounts.getAccessToken` to mint the storage access token. `roles/iam.serviceAccountTokenCreator` on that service account supplies both permissions; have an authorized administrator configure this grant if necessary.


```bash
#[TODO] Provide documentation to GCP IAM Configuration

cat << 'EOF' > ~/creds/gcp.secrets.envrc
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL="<service-account-email>"
export GOOGLE_PROJECT="<your-gcp-project-id>"
export GOOGLE_WORKLOAD_IDENTITY_PROVIDER="<identity-provider-uri>"
export GOOGLE_WORKLOAD_IDENTITY_PROVIDER_ID="<identity-provider-resource-id>"
export GOOGLE_WORKLOAD_IDENTITY_POOL_ID="<identity-pool-id>"

export GOOGLE_OAUTH_ACCESS_TOKEN="$(
  gcloud auth application-default print-access-token \
    --impersonate-service-account="$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL"
)"

export TF_API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')
EOF
```

### Local Deployment Testing

```bash
gcloud auth application-default login \
  --impersonate-service-account="$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL"

terraform login app.terraform.io

terraform -chdir=test init
terraform -chdir=test plan
terraform -chdir=test apply -auto-approve

export OUTPUT_BUCKET=$(terraform -chdir=test output -raw bronze_bucket_name)
export GCP_FUNCTION_API_ENDPOINT=$(terraform -chdir=test output -raw function_url)
export INVOKER_SERVICE_ACCOUNT_EMAIL=$(terraform -chdir=test output -raw service_account_email)

# Mint fresh credentials as the account granted access to the function and GCS.
export GOOGLE_ID_TOKEN="$(
  gcloud auth print-identity-token \
    --impersonate-service-account="$INVOKER_SERVICE_ACCOUNT_EMAIL" \
    --audiences="$GCP_FUNCTION_API_ENDPOINT" \
    --include-email
)"
export GOOGLE_OAUTH_ACCESS_TOKEN="$(
  gcloud auth print-access-token \
    --impersonate-service-account="$INVOKER_SERVICE_ACCOUNT_EMAIL"
)"

python3 -m pytest test/unit_test -m "local and env" -rs

direnv reload
terraform -chdir=test destroy -auto-approve
```

### Manual Dispatch Testing

```bash
# Try the Terraform Read/Plan job first once the workflow is available.
act -j terraform-dispatch-plan \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL \
  -s GOOGLE_OAUTH_ACCESS_TOKEN \
  -s GOOGLE_WORKLOAD_IDENTITY_PROVIDER \
  -s GOOGLE_WORKLOAD_IDENTITY_POOL_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show)

act -j terraform-dispatch-apply \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL \
  -s GOOGLE_OAUTH_ACCESS_TOKEN \
  -s GOOGLE_WORKLOAD_IDENTITY_PROVIDER \
  -s GOOGLE_WORKLOAD_IDENTITY_POOL_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show)

act -j terraform-dispatch-destroy \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL \
  -s GOOGLE_OAUTH_ACCESS_TOKEN \
  -s GOOGLE_WORKLOAD_IDENTITY_PROVIDER \
  -s GOOGLE_WORKLOAD_IDENTITY_POOL_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show)
```

### Integration Testing

Integration workflow support will be added with the GitHub workflow definitions. Once available, use `act` to validate the full integration lifecycle locally.

```bash
# Create an artifact location to upload/download between steps locally.
mkdir /tmp/artifacts

# Run the full integration test once the workflow is available.
act -j terraform-integration-destroy \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL \
  -s GOOGLE_OAUTH_ACCESS_TOKEN \
  -s GOOGLE_WORKLOAD_IDENTITY_PROVIDER \
  -s GOOGLE_WORKLOAD_IDENTITY_POOL_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show) \
  --artifact-server-path /tmp/artifacts
```

### Unit Tests

Unit workflow support will be added with the GitHub workflow definitions. Once available, use `act` to run Terraform formatting, validation, and unit-style checks locally.

```bash
act -j terraform-unit-tests \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_REGION \
  -s TF_API_TOKEN \
  --remote-name $(git remote show)
```

---

## License

See [LICENSE](./LICENSE) for details.
