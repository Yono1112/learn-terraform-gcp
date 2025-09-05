variable "project_id" {
  description = "Your GCP Project ID"
  type        = string
  default     = "keishou-app"
}

variable "region" {
  description = "The region to host the resources"
  type        = string
  default     = "asia-northeast1"
}

variable "db_password" {
  description = "The password for the Cloud SQL database user"
  type        = string
  sensitive   = true // この設定で、planやapplyの結果にパスワードが表示されなくなる
}