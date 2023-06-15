variable "project_id" {
  type        = string
  description = "project id on gcp"
}

variable "region" {
  type        = string
  description = "location of gcp instance"
}

variable "service_account_name" {
  type        = string
  description = "service account name"
}

variable "service_account_roles" {
  type        = list(string)
  description = "list of roles for service account binding"
}

variable "bucket_name" {
  type        = string
  description = "storage bucket name"
}
