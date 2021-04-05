class SearchesController < ApplicationController
  def index
    @messages = Message.containing(params[:query])
  end
end
