class TasksController < ApplicationController
  skip_before_action :verify_authenticity_token # Cloud Tasks requests won't include CSRF tokens

  def run
    job_class = params[:job_class]
    job_args = params[:job_args]

    # Dynamically constantize the job class and perform the job
    job_class.constantize.perform_now(*job_args)

    head :ok
  rescue => e
    Rails.logger.error("Failed to process task: #{e.message}")
    head :internal_server_error
  end
end
