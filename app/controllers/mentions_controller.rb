class MentionsController < ApplicationController
  def index
    @users = User.all.order(username: :asc)
  end
end
