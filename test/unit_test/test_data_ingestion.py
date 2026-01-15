"""
Unit Test: HTTP-triggered GCP Function File Upload

This unit test verifies the functionality of GCP Function triggered
by HTTP requests. The function is expected to receive a
file upload (in the HTTP request body) and a filename (as a query parameter),
and write the file to an Google Cloud Store bucket specified by the
OUTPUT_BUCKET environment variables.

The test sends a sample JSON payload to the function's API endpoint and then
checks that the file has been correctly written to the storage bucket. This ensures the
function's API integration and Blob Storage write logic are functioning as intended.

Environment Variables Required:
 - OUTPUT_BUCKET: Name of the Google Cloud Storage bucket where files will be written.
 - FUNCTION_URL: The HTTP endpoint for the Azure Function.

Local Testing Steps:
```
cd test
direnv allow

terraform init && \
terraform apply -auto-approve

direnv reload

# Ensure you have installed dependencies: pip install pytest requests gcsfs
python3 -m pytest -m 'local and env'

terraform destroy -auto-approve
```
"""

import io
import json
import os
import uuid

import gcsfs
import pytest
import requests

# Environment Variables
OUTPUT_BUCKET = os.getenv("OUTPUT_BUCKET")
GOOGLE_PROJECT = os.getenv("GOOGLE_PROJECT")
GCP_FUNCTION_API_ENDPOINT = os.getenv("GCP_FUNCTION_API_ENDPOINT")
GCP_FUNCTION_API_OAUTH_KEY = os.getenv("GCP_FUNCTION_API_OAUTH_KEY")
GOOGLE_OAUTH_ACCESS_TOKEN_IMPERSONATION = os.getenv(
    "GOOGLE_OAUTH_ACCESS_TOKEN_IMPERSONATION"
)

assert OUTPUT_BUCKET is not None
assert GOOGLE_PROJECT is not None
assert GCP_FUNCTION_API_ENDPOINT is not None
assert GCP_FUNCTION_API_OAUTH_KEY is not None
assert GOOGLE_OAUTH_ACCESS_TOKEN_IMPERSONATION is not None


@pytest.mark.local
@pytest.mark.env
def test_gcp_env_http_function_file_upload(payload=None):
    """
    Test uploading a file to the GCP Function via HTTP POST and verifying it's written to Blob Storage.
    Uses storage account key from environment for access.

    Args:
        payload (dict, optional): The JSON payload to upload. If None, a random payload is generated.
    """
    logging.info("Pytest | Test HTTP Function File Upload with Environment Credentials")
    if payload is None:
        payload = {"test_value": str(uuid.uuid4())}

    filename = f"test-env-{str(uuid.uuid4())}.json"

    # Send HTTP POST to Azure Function
    response = requests.post(
        url=GCP_FUNCTION_API_ENDPOINT,
        headers={"Authorization": f"Bearer {GCP_FUNCTION_API_OAUTH_KEY}"},
        files=[("files", (filename, io.BytesIO(json.dumps(payload).encode("utf-8"))))],
    )

    assert response.status_code == 200, f"Function HTTP call failed: {response.text}"

    # Verify the file was written to Blob Storage
    fs = gcsfs.GCSFileSystem(
        project=GOOGLE_PROJECT, token=GOOGLE_OAUTH_ACCESS_TOKEN_IMPERSONATION
    )
    with fs.open(
        os.path.join(f"gs://{OUTPUT_BUCKET}", filename),
        "r",
    ) as f:
        rs = json.load(f)
        assert rs["test_value"] == payload["test_value"]
