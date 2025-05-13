class TasksController < ApplicationController
  # Cloud Tasks requests won't include CSRF tokens
  skip_before_action :verify_authenticity_token, raise: false
  skip_before_action :authenticate_user!

  def run
    request_body = JSON.parse(request.raw_post)
    job_class = request_body["job_class"]
    job_args = request_body["job_args"]
    deserialized_args = ActiveJob::Arguments.deserialize(job_args)

    # Dynamically constantize the job class and perform the job
    job_class.constantize.perform_now(*deserialized_args)

    head :ok
  rescue => e
    Rails.logger.error("Failed to process task: #{e.message}")
    head :internal_server_error
  end
end
