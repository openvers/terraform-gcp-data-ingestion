output "gcs_function_bucket_name" {
  description = "GCS Bucket Name for Source Code Zip Blob"
  value       = module.function_bucket.bucket_name
}

output "gcs_function_object_name" {
  description = "GCS Object Name for Source Code Zip Blob"
  value       = google_storage_bucket_object.this.name
}

output "gcs_function_object_url" {
  description = "GCS Function URL for Source Code Zip Blob"
  value       = "https://storage.googleapis.com/${module.function_bucket.bucket_name}/${google_storage_bucket_object.this.name}"
}
