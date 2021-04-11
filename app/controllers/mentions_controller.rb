class MentionsController < ApplicationController
  def index
    @users = User.order(username: :asc).username_matching_handle params[:username]
  end
end
