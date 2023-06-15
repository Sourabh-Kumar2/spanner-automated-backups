locals {
  src                  = "${path.root}/function/src"
  build                = "${path.root}/function/build/bkp.zip"
  bucket_storage_class = "NEARLINE" # Keep the storage class to "NEARLINE" as the data will be accessed rarely to build the cloud function.
}

# Install the dependencies before zipping it.
resource "null_resource" "dep" {
  triggers = {
    run = uuid() # Always make the new build.
  }
  provisioner "local-exec" {
    command     = "yarn install"
    working_dir = local.src
  }
}

# Archive the function source with it's all dependencies.
data "archive_file" "build" {
  type        = "zip"
  source_dir  = local.src
  output_path = local.build
  depends_on  = [null_resource.dep]
}

# Create a cloud storage bucket to upload the zip file.
resource "google_storage_bucket" "bucket" {
  project                     = var.project_id
  location                    = var.region
  name                        = var.bucket_name
  storage_class               = local.bucket_storage_class
  uniform_bucket_level_access = true
}

# Upload the object to bucket
resource "google_storage_bucket_object" "archive" {
  name   = "backup-function-${data.archive_file.build.output_sha}.zip" # Use archive hash to upload if the content is updated.
  bucket = google_storage_bucket.bucket.name
  source = local.build
}

# Create cloud function
resource "google_cloudfunctions2_function" "function" {
  name     = "spanner-bkp"
  location = var.region
  project  = var.project_id
  build_config {
    runtime     = "nodejs18"
    entry_point = "backup" # Keep the same name as used in index.js file with exports.<*>
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.archive.name
      }
    }
    environment_variables = {
      PROJECT_ID = var.project_id
    }
  }
  service_config {
    timeout_seconds  = 3600 # 1 hour, as the backup takes time to complete
    available_memory = "256M"
    available_cpu    = "1"
  }
}
