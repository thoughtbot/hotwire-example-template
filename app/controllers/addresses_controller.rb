class AddressesController < ApplicationController
  def new
    @address = Address.new
  end

  def create
    @address = Address.new address_params

    if @address.save
      redirect_to address_url(@address)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @address = Address.find params[:id]
  end

  private

  def address_params
    params.require(:address).permit(
      :country,
      :line_1,
      :line_2,
      :city,
      :state,
      :postal_code,
    )
  end
end
