class TasksController < ApplicationController
  def new
    @task = Task.new
  end

  def create
    @task = Task.create! task_params

    redirect_to tasks_url
  end

  def index
    @tasks = Task.all
  end

  def edit
    @task = Task.find params[:id]
  end

  def update
    @task = Task.find params[:id]

    @task.update! task_params

    respond_to do |format|
      format.html { redirect_to tasks_url }
      format.turbo_stream
    end
  end

  private

  def task_params
    params.require(:task).permit(:details, :done)
  end
end
