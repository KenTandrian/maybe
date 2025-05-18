locals {
  queue_names = ["mf-high-priority", "mf-low-priority", "mf-medium-priority"]
}

resource "google_cloud_tasks_queue" "queues" {
  for_each = toset(local.queue_names)

  name     = each.value
  location = var.region
}
