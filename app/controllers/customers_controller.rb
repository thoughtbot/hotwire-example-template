class CustomersController < ApplicationController
  def index
    @search = Search.new search_params
    @customers = @search.query(Customer.all)
  end

  private

  def search_params
    params.permit(:q, :deactivated, :first_purchase_on_minimum, :first_purchase_on_maximum)
  end
end
