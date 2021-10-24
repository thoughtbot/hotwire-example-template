class MessagesController < ApplicationController
  def index
    @page, @messages = pagy Message.where(query_params).most_recent_first
  end

  private

  def query_params
    params.permit(:author)
  end
end
