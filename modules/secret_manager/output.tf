output "secret_id" {
  description = "GCP Secret Manager Secret ID"
  value       = google_secret_manager_secret.this.id
}

output "secret_name" {
  description = "GCP Secret Manager Secret Resource Name"
  value       = google_secret_manager_secret.this.name
}

output "secret_value" {
  description = "GCP Secret Manager Secret Value"
  value       = google_secret_manager_secret_version.this.secret_data
  sensitive   = true
}