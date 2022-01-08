class DocumentsController < ApplicationController
  def new
    @document = Document.new
  end

  def create
    @document = Document.new document_params

    if @document.save
      redirect_to document_url(@document)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @document = Document.find params[:id]
  end

  private

  def document_params
    params.require(:document).permit(
      :access,
      :passcode,
      :content,
    )
  end
end
