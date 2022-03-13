provider "google" {
  project = var.gcp_project_id
  region = "us-west1"
}

resource "google_iam_workload_identity_pool" "pool" {
  provider                  = google-beta
  workload_identity_pool_id = "gh-actions-pool"
}
# https://github.com/google-github-actions/auth#setup
# https://cloud.google.com/iam/docs/workload-identity-federation?_ga=2.178799844.-1125913399.1642444018#mapping
resource "google_iam_workload_identity_pool_provider" "github-actions" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  attribute_mapping                  = {
    "google.subject" = "assertion.sub"
    "attribute.actor" = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri        = "https://token.actions.githubusercontent.com"
  }
}


# DVC Bucket
resource "google_storage_bucket" "dvc" {
  name = "${var.gcp_project_id}_dvc-objects"
  location = "us-west1"
}

# DVC Access SA
resource "google_service_account" "dos" {
  account_id = "dvc-object-storage"
}
resource "google_service_account_iam_policy" "dos-policy" {
  service_account_id = google_service_account.dos.name
  policy_data =  data.google_iam_policy.dos.policy_data
}
data "google_iam_policy" "dos" {
  binding {
    role = google_project_iam_custom_role.dos.name
    members = [ "serviceAccount:${google_service_account.dos.email}" ]
  }
  binding {
    role = "roles/iam.workloadIdentityUser"
    members = ["principalSet:${google_iam_workload_identity_pool.pool.workload_identity_pool_id}/attribute.repository/${var.my_repo}"]
  }
}
resource "google_project_iam_custom_role" "dos" {
  role_id = "dvc_object_storage"
  title = ""
  description = ""
  permissions = [
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
  ]
}