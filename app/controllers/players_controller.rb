class PlayersController < ApplicationController
  def index
    @page, @players = pagy Player.all
  end
end
