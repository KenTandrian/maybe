resource "google_apphub_application" "maybe-finance" {
  application_id = var.service_name
  description    = "${var.app_name} application"
  display_name   = var.app_name
  location       = var.region

  attributes {
    criticality { type = "MISSION_CRITICAL" }
    environment { type = "PRODUCTION" }
  }

  scope {
    type = "REGIONAL"
  }
}

data "google_cloud_run_service" "maybe-finance" {
  name     = var.service_name
  location = var.region
}

data "google_apphub_discovered_service" "maybe-finance" {
  location    = var.region
  service_uri = "//run.googleapis.com/projects/${var.project_id}/locations/${var.region}/services/${data.google_cloud_run_service.maybe-finance.name}"
}

resource "google_apphub_service" "maybe-finance" {
  application_id     = google_apphub_application.maybe-finance.application_id
  discovered_service = data.google_apphub_discovered_service.maybe-finance.name
  display_name       = "Cloud Run - ${var.app_name}"
  location           = var.region
  service_id         = "gcr-${var.service_name}"

  attributes {
    criticality { type = "MISSION_CRITICAL" }
    environment { type = "PRODUCTION" }
  }
}
