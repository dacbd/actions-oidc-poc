output "Workload_Identity_Provider" {
  value = google_iam_workload_identity_pool_provider.github-actions.name
}