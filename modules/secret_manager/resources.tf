terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      configuration_aliases = [
        google.auth_session,
      ]
    }
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string representing a Bearer Token.
##
## Parameters:
## - `length`: Length of the random string.
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `lower`: Whether to include lowercase letters in the random string.
## - `numeric`: Whether to include numeric characters into the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  length  = 40
  special = false
  upper   = true
  lower   = true
  numeric = true
}

data "google_client_openid_userinfo" "this" {
  provider = google.auth_session
}

local {
  secret_value   = coalesce(var.secret_value, random_string.this.result)
  secret_members = distinct(concat(var.secret_members, [data.google_client_openid_userinfo.this.email]))
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SECRET MANAGER SECRET RESOURCE
##
## This resource will create a Secret in GCP Secret Manager
##
## Parameters:
## `secret_id`: The ID of the Secret Artifact.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_secret_manager_secret" "this" {
  provider = google.auth_session

  secret_id = var.secret_id
  replication {
    auto {}
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SECRET MANAGER SECRET VERSION RESOURCE
##
## This resource will store a value into a Secret in GCP Secret Manager
##
## Parameters:
## `secret`: The ID of the Secret Artifact.
## `secret_data`: The value of the secret.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_secret_manager_secret_version" "this" {
  provider = google.auth_session

  secret      = google_secret_manager_secret.this.id
  secret_data = local.secret_value
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SECRET MANAGER SECRET IAM MEMBER RESOURCE
##
## This resource will allow access to IAM Members
##
## Parameters:
## `project`: Google Project ID
## `secret_id`: The ID of the Secret Artifact.
## `role`: IAM Role to attach secet and member.
## `member`: User Email.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_secret_manager_secret_iam_member" "this" {
  for_each = toset(local.secret_members)
  
  project   = google_secret_manager_secret.this.project
  secret_id = google_secret_manager_secret.this.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "user:${each.value}"
}
