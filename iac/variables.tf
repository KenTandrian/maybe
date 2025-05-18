variable "app_name" {
  description = "The name of the application."
  type        = string
  default     = "Maybe Finance"
}

variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  description = "The region in which to provision resources."
  type        = string
  default     = "asia-southeast1"
}

variable "service_name" {
  description = "The name of the service."
  type        = string
  default     = "maybe-finance"
}
