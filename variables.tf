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
