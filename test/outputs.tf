output "service_account_email" {
  description = "GCP Service Account created within project"
  value       = module.service_account_auth.service_account_email
}

output "bronze_bucket_name" {
  description = "The bronze bucket name."
  value       = module.data_lake.bronze_bucket_name
}

output "bronze_bucket_url" {
  description = "The bronze bucket URL."
  value       = module.data_lake.bronze_bucket_url
}

output "bronze_bucket_location" {
  description = "The bronze bucket location."
  value       = module.data_lake.bronze_bucket_location
}

output "function_name" {
  description = "GCP Cloud Function Name"
  value       = module.gcp_cloud_function.function_name
}

output "function_url" {
  description = "GCP Cloud Function URL"
  value       = module.gcp_cloud_function.function_url
}

output "gcs_function_bucket_name" {
  description = "GCS Bucket Name for Source Code Zip Blob"
  value       = module.gcp_cloud_function.gcs_function_bucket_name
}

output "gcs_function_object_name" {
  description = "GCS Object Name for Source Code Zip Blob"
  value       = module.gcp_cloud_function.gcs_function_object_name
}

output "gcs_function_object_url" {
  description = "GCS Function URL for Source Code Zip Blob"
  value       = module.gcp_cloud_function.gcs_function_object_url
}
