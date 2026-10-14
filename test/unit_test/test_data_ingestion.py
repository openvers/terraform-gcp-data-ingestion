"""Integration Test: HTTP-triggered GCP Function File Upload

Uploads a JSON file as multipart form data to a GCP Function and verifies
the payload written to Google Cloud Storage. HTTP invocation uses an
audience-specific ID token; storage access uses a short-lived OAuth token.

Environment Variables Required:
 - OUTPUT_BUCKET: Name of the Google Cloud Storage bucket where files will be written.
 - GOOGLE_PROJECT: Google Cloud project ID used for storage access.
 - GCP_FUNCTION_API_ENDPOINT: The HTTP endpoint for the GCP Function.
 - GOOGLE_ID_TOKEN: Audience-specific ID token for HTTP invocation.
 - GOOGLE_OAUTH_ACCESS_TOKEN: OAuth access token for Google Cloud Storage.

Local Testing Steps (from the repository root):
```
python3 -m pytest test/unit_test -m "local and env" -rs
```

See README.md's Local Deployment Testing section for deployment, token
generation, environment setup, and teardown. Missing configuration skips
the test rather than failing collection.
"""

import io
import json
import logging
import os
import uuid

import gcsfs
import pytest
import requests
from google.oauth2.credentials import Credentials

def _required_env(name):
    value = os.getenv(name)
    if not value:
        pytest.skip(f"Required environment variable is not set: {name}")
    return value


def _oauth_filesystem_kwargs():
    return {
        "project": _required_env("GOOGLE_PROJECT"),
        "token": Credentials(token=_required_env("GOOGLE_OAUTH_ACCESS_TOKEN")),
    }


def _upload_file(endpoint, id_token, filename, payload):
    response = requests.post(
        url=endpoint,
        headers={"Authorization": f"Bearer {id_token}"},
        files=[("files", (filename, io.BytesIO(json.dumps(payload).encode("utf-8"))))],
    )
    assert response.status_code == 200, f"Function HTTP call failed: {response.text}"


def _read_blob(fs, path):
    with fs.open(path, "rb") as file:
        return json.loads(file.read())


def _verify_function_file_upload(payload, **filesystem_kwargs):
    endpoint = _required_env("GCP_FUNCTION_API_ENDPOINT")
    id_token = _required_env("GOOGLE_ID_TOKEN")
    bucket_name = _required_env("OUTPUT_BUCKET")
    filename = f"test-env-{uuid.uuid4()}.json"

    _upload_file(endpoint, id_token, filename, payload)

    fs = gcsfs.GCSFileSystem(**filesystem_kwargs)
    result = _read_blob(fs, f"gs://{bucket_name}/{filename}")
    assert result["test_value"] == payload["test_value"]


@pytest.mark.local
@pytest.mark.env
def test_gcp_env_http_function_file_upload(payload=None):
    logging.info("Pytest | Test HTTP Function File Upload with Environment Credentials")
    payload = payload or {"test_value": str(uuid.uuid4())}

    _verify_function_file_upload(payload, **_oauth_filesystem_kwargs())
