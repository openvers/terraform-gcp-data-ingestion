"""GCP Cloud Function Example

A Google Cloud Platform (GCP) Cloud Function with a HTTP Trigger is a
serverless function that automatically executes in response to HTTP requests.
When a new HTTP request is received, the Cloud Function is triggered, allowing
you to perform custom logic or processing on the request data. This trigger mechanism
enables event-driven architecture and allows you to build scalable and event-based
solutions on GCP.

https://flask.palletsprojects.com/en/stable/patterns/fileuploads/
This example in particular will take JSON data from an HTTP request,
and store the exact same content with same file name in the Results GCS Bucket
referred to under ENV Variable OUTPUT_BUCKET.

"""

import logging
import os
import sys

import gcsfs
import google.cloud.logging
from flask import Flask, jsonify, request
from werkzeug.utils import secure_filename

# Environment Variables
OUTPUT_BUCKET = os.getenv("OUTPUT_BUCKET")
GOOGLE_PROJECT = (
    os.getenv("GOOGLE_PROJECT_ID").replace("/projects", "")
    if os.getenv("GOOGLE_PROJECT_ID")
    else None
)
GCP_TOKEN = os.getenv("GCP_TOKEN", "cloud")
ALLOWED_EXTENSIONS = {"json", "csv", "parquet", "avro"}

# Setup
client = google.cloud.logging.Client()
client.setup_logging()

app = Flask(__name__)


@app.route("/", methods=["POST"])
def run(event):
    try:
        logging.info("HTTP Request Received")
        if "files" not in request.files:
            return jsonify({"error": "No file part"}), 400

        fs = gcsfs.GCSFileSystem(project=GOOGLE_PROJECT, token=GCP_TOKEN)
        for file in request.files.getlist("files"):
            logging.info(
                f"HTTP Request: {secure_filename(file.filename)} | Initiating Data Ingestion"
            )
            with fs.open(
                os.path.join(f"gs://{OUTPUT_BUCKET}", secure_filename(file.filename)),
                "wb",
            ) as f:
                file.save(f)

        return "Data Ingestion Succesfull", 200

    except Exception as e:
        logging.error(f"Error: {e}")
        return "Data Ingestion Failed", 500


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080

    # This is used when running locally. Gunicorn is used to run the
    # application on Cloud Run. See entrypoint in Dockerfile.
    app.run(host="127.0.0.1", port=PORT, debug=True)
