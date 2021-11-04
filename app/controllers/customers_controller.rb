class CustomersController < ApplicationController
  def index
    @search = Search.new search_params
    @customers = @search.query(Customer.all)
  end

  private

  def search_params
    params.permit(:q)
  end
end
