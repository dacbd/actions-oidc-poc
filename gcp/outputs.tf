output "Workload Identity Provider" {
  value = google_iam_workload_identity_pool_provider.github-actions.name
}