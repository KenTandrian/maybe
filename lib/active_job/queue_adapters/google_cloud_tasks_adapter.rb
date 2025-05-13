require "google/cloud/tasks"

module ActiveJob
  module QueueAdapters
    class GoogleCloudTasksAdapter
      include Rails.application.routes.url_helpers

      QUEUE_NAME_MAPPING = {
        high_priority: "mf-high-priority",
        medium_priority: "mf-medium-priority",
        low_priority: "mf-low-priority"
      }.freeze

      def client
        @client ||= Google::Cloud::Tasks.cloud_tasks
      end

      def enqueue(job)
        enqueue_at(job, nil)
      end

      def enqueue_at(job, timestamp)
        client = Google::Cloud::Tasks.cloud_tasks
        project_id = ENV.fetch("GOOGLE_CLOUD_PROJECT")
        invoker_email = ENV.fetch("GOOGLE_CLOUD_TASKS_SA_EMAIL")

        queue_path = client.queue_path(
          project: project_id,
          location: "asia-southeast1",
          queue: QUEUE_NAME_MAPPING[job.queue_name.to_sym] || "mf-low-priority"
        )

        task = {
          http_request: {
            http_method: :POST,
            url: tasks_url(queue_name: job.queue_name),
            headers: { "Content-Type" => "application/json" },
            body: JSON.dump({
              job_class: job.class.name,
              job_args: ActiveJob::Arguments.serialize(job.arguments)
            }),
            oidc_token: {
              service_account_email: invoker_email
            }
          }
        }

        task[:schedule_time] = timestamp.to_datetime.rfc3339 if timestamp

        client.create_task(parent: queue_path, task: task)
      end

      def enqueue_after_transaction_commit?
        true
      end
    end
  end
end
