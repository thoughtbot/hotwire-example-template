class BoardsController < ApplicationController
  def show
    @board = Board.find params[:id]
  end

  def index
    @boards = Board.all

    redirect_to board_url(@boards.first)
  end
end
