class BuildingsController < ApplicationController
  def new
    @building = Building.new
  end

  def create
    @building = Building.new building_params

    if @building.save
      redirect_to building_url(@building)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @building = Building.find params[:id]
  end

  private

  def building_params
    params.require(:building).permit(
      :building_type,
      :management_phone_number,
      :building_type_description,
      :line_1,
      :line_2,
      :city,
      :state,
      :postal_code,
    )
  end
end
