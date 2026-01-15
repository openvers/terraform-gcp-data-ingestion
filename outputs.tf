output "function_name" {
  description = "GCP Cloud Function Name"
  value       = module.gcp_function.function_name
}

output "function_url" {
  description = "GCP Cloud Function URL"
  value       = module.gcp_function.function_url
}

output "gcs_function_bucket_name" {
  description = "GCS Bucket Name for Source Code Zip Blob"
  value       = module.gcp_function.gcs_function_bucket_name
}

output "gcs_function_object_name" {
  description = "GCS Object Name for Source Code Zip Blob"
  value       = module.gcp_function.gcs_function_object_name
}

output "gcs_function_object_url" {
  description = "GCS Function URL for Source Code Zip Blob"
  value       = module.gcp_function.gcs_function_object_url
}
