locals {
  data_source = "database.json"
}

resource "google_cloud_scheduler_job" "job" {
  project = var.project_id

  name     = "spanner-backup-job"
  schedule = "0 * * * *"
  region   = var.region

  http_target {
    uri         = google_cloudfunctions2_function.function.service_config[0].uri # Trigger the cloud function.
    http_method = "POST"
    body        = base64encode(file("${path.root}/${local.data_source}"))
    oidc_token {
      service_account_email = google_service_account.service_account.email # Use the created service account.
    }
  }
}
