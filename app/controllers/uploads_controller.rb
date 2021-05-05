class UploadsController < ApplicationController
  def new
    @upload = Upload.new
  end

  def create
    @upload = Upload.create! upload_params

    redirect_to @upload
  end

  private

  def upload_params
    params.require(:upload).permit(:file)
  end
end
