# Hotwire Example Template

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-pagination

## Our starting point

Our model:

```ruby
# app/models/message.rb

class Message < ApplicationRecord
  has_rich_text :content

  scope :most_recent_first, -> { order created_at: :desc }
end
```

Our controller:

```ruby
# app/controllers/messages_controller.rb

class MessagesController < ApplicationController
  def index
    @page, @messages = pagy Message.where(query_params).most_recent_first
  end

  private

  def query_params
    params.permit(:author)
  end
end
```

Our [pagy][] initialization:

[pagy]: https://github.com/ddnexus/pagy

```ruby
# config/initializers/pagy.rb

ActiveSupport.on_load :action_controller_base do
  include Pagy::Backend
end

ActiveSupport.on_load :action_view do
  include Pagy::UrlHelpers
end
```

Our view template:

```erb
<%# app/views/messages/index.html.erb %>

<h1>Messages</h1>

<% if @page.prev %>
  <%= link_to pagy_url_for(@page, @page.prev), rel: "prev" do %>
    Previous page
  <% end %>
<% end %>

<% @messages.each do |message| %>
  <article class="border border-solid">
    <%= message.content %>

    <p>
      Posted by: <%= link_to message.author, messages_path(author: message.author) %>
    </p>
  </article>
<% end %>

<% if @page.next %>
  <%= link_to pagy_url_for(@page, @page.next), rel: "next" do %>
    Next page
  <% end %>
<% end %>
```

https://user-images.githubusercontent.com/2575027/152660466-a41560a9-a6b6-4438-9ae5-8d9b67a2b3b4.mov
