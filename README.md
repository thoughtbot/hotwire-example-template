# Hotwire: Turbo Frame-powered Inline Editing

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-inline-edit

When reading a branch's source code, read the changes commit-by-commit either on
the branch comparison page (for example,
[main...hotwire-example-inline-edit][]), the branch's commits page (for
example, [hotwire-example-inline-edit][]), or the branch's `README.md` file
(for example, [hotwire-example-inline-edit][README]).

[main...hotwire-example-inline-edit]: https://github.com/thoughtbot/hotwire-example-template/compare/hotwire-example-inline-edit
[hotwire-example-inline-edit]: https://github.com/thoughtbot/hotwire-example-template/commits/hotwire-example-inline-edit
[README]: https://github.com/thoughtbot/hotwire-example-template/blob/hotwire-example-inline-edit/README.md

## Our starting point

`Article` records are categorized by `Category` records.

```ruby
# app/models/article.rb

class Article < ApplicationRecord
  has_many :categorizations
  has_many :categories, through: :categorizations

  has_rich_text :content

  with_options presence: true do
    validates :byline
    validates :content
    validates :name
  end
end

# app/models/category.rb

class Category < ApplicationRecord
  has_many :categorizations
  has_many :articles, through: :categorizations
end

# app/models/categorization.rb

class Categorization < ApplicationRecord
  belongs_to :article
  belongs_to :category
end
```

Records are served by a bog-standard `ArticlesController`. We'll be spending
most of our time in the templates for the `show` and `edit` actions.

```ruby
# app/controllers/articles_controller.rb

class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    @article = Article.find params[:id]
  end

  def edit
    @article = Article.find params[:id]
  end

  def update
    @article = Article.find params[:id]

    if @article.update article_params
      redirect_to article_url(@article)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def article_params
    params.require(:article).permit(
      :byline,
      :content,
      :name,
      :published_on,
      category_ids: []
    )
  end
end
```

The `app/views/articles/show.html.erb` template renders and formats the
`Article` record's values:

```erb
<%# app/views/articles/show.html.erb %>

<section class="grid gap-2 max-w-prose m-auto">
  <%= link_to "Edit Article", edit_article_path(@article) %>

  <h1><%= @article.name %></h1>

  <span>By: <%= @article.byline %></span>

  <% if @article.published_on.nil? %>
    <span>(Unpublished)</span>
  <% else %>
    <%= localize @article.published_on, format: :long %>
  <% end %>

  <strong>Categories</strong>

  <span>
    <% @article.categories.each do |category| %>
      <span><%= category.name %></span>
    <% end %>
  </span>

  <%= @article.content %>
</section>
```

<img src="https://images.thoughtbot.com/blog-vellum-image-uploads/spw8TIeuTFbCkdumaUUO_article-show.png"
     alt="An Article page with name, byline, published on date, categories, and content"
     height="720">

The `app/views/articles/edit.html.erb` renders a collection of form fields to
change the `Article` record's values. The template's `<form>` element submits a
`PATCH /articles/:id` request when submitted:

```erb
<%# app/views/articles/edit.html.erb %>

<%= form_with model: @article, class: "grid gap-2 max-w-prose m-auto" do |form| %>
  <%= link_to "Back", article_path(@article) %>

  <%= form.label :name %>
  <%= form.text_field :name %>

  <%= form.label :byline %>
  <%= form.text_field :byline %>

  <%= form.label :published_on %>
  <%= form.date_field :published_on %>

  <fieldset>
    <legend>
      <%= @article.class.human_attribute_name(:category_ids) %>
    </legend>

    <%= form.collection_check_boxes :category_ids, Category.all, :id, :name do |builder| %>
      <%= builder.check_box %>
      <%= builder.label %>
    <% end %>
  </fieldset>

  <%= form.label :content %>
  <%= form.rich_text_area :content %>

  <%= form.button %>
<% end %>
```

<img src="https://images.thoughtbot.com/blog-vellum-image-uploads/MniJocQJeKY5nHwCXocw_article-edit.png"
     alt="A fields to edit an Article's name, byline, published on date, categories, and content"
     height="720">
