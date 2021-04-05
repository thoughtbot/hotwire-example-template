class PreviewsController < ApplicationController
  def create
    @preview = Article.new(article_params)

    respond_to do |format|
      format.html { redirect_to new_article_url(article: @preview.attributes) }
      format.turbo_stream
    end
  end

  private

  def article_params
    params.require(:article).permit(:content)
  end
end
