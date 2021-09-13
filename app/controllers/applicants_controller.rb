class ApplicantsController < ApplicationController
  def new
    @applicant = Applicant.new applicant_params
  end

  def create
    @applicant = Applicant.new applicant_params

    if @applicant.save
      redirect_to applicant_url(@applicant)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @applicant = Applicant.find params[:id]
  end

  def edit
    @applicant = Applicant.find params[:id]
    @applicant.assign_attributes applicant_params
  end

  def update
    @applicant = Applicant.find params[:id]

    if @applicant.update applicant_params
      redirect_to applicant_url(@applicant)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def applicant_params
    params.fetch(:applicant, {}).permit(
      :name,
      references_attributes: [ :name, :email_address, :id, :_destroy ],
    )
  end
end
