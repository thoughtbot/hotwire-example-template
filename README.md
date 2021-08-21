# Hotwire: Modal form submissions

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-modal

## Our starting point

Our model:

```ruby
# app/models/message.rb

class Message < ApplicationRecord
  has_rich_text :content

  with_options presence: true do
    validates :content
    validates :recipient
    validates :sender
  end
end
```

Our controller:

```ruby
# app/controllers/messages_controller.rb

class MessagesController < ApplicationController
  def index
    @messages = Message.all
  end

  def new
    @message = Message.new
  end

  def create
    @message = Message.new message_params

    if @message.save
      redirect_to messages_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :recipient, :sender)
  end
end
```

Our view templates:

```erb
<%# app/views/messages/index.html.erb %>

<section>
  <h1>Messages</h1>

  <%= link_to "New message", new_message_path %>

  <% @messages.each do |message| %>
    <article>
      <header>
        <p>From: <%= message.sender %></p>
        <p>To: <%= message.recipient %></p>
      </header>

      <%= message.content %>
    </article>
  <% end %>
</section>
```

```erb
<%# app/views/messages/new.html.erb %>

<section>
  <h1>New message</h1>

  <%= link_to "Back", messages_path %>

  <%= form_with model: @message, class: "grid" do |form| %>
    <% if form.object.errors.any? %>
      <output role="alert">
        <h2><%= pluralize(form.object.errors.count, "error") %> prohibited this record from being saved:</h2>

        <ul>
          <% form.object.errors.each do |error| %>
            <li><%= error.full_message %></li>
          <% end %>
        </ul>
      </output>
    <% end %>

    <%= form.label :recipient %>
    <%= form.text_field :recipient %>

    <%= form.label :sender %>
    <%= form.text_field :sender %>

    <%= form.label :content %>
    <%= form.rich_text_area :content %>

    <button>Send</button>
  <% end %>
</section>
```
