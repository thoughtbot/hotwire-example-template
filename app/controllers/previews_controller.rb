class PreviewsController < ApplicationController
  def create
    @preview = Article.new(article_params)

    redirect_to new_article_url(article: @preview.attributes)
  end

  private

  def article_params
    params.require(:article).permit(:content)
  end
end
