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

## Presenting a `<form>` modally

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
   <body>
     <%= yield %>
+
+    <dialog class="group" role="dialog" aria-modal="true"
+            data-controller="dialog" data-action="turbo:frame-load->dialog#showModal">
+      <turbo-frame id="dialog"></turbo-frame>
+    </dialog>
   </body>
 </html>
```

```diff
--- a/app/views/messages/index.html.erb
+++ b/app/views/messages/index.html.erb
 <section>
   <h1>Messages</h1>

-  <%= link_to "New message", new_message_path %>
+  <%= link_to "New message", new_message_path, class: "sm:hidden" %>

   <% @messages.each do |message| %>
     <article>
```

```diff
--- a/app/views/messages/index.html.erb
+++ b/app/views/messages/index.html.erb
 <section>
   <h1>Messages</h1>

   <%= link_to "New message", new_message_path, class: "sm:hidden" %>

+  <form action="<%= new_message_path %>" class="hidden sm:block" data-turbo-frame="dialog">
+    <button name="turbo_frame" value="dialog" aria-expanded="false">New message</button>
+  </form>
+
   <% @messages.each do |message| %>
     <article>
```

```diff
--- a/app/views/messages/new.html.erb
+++ b/app/views/messages/new.html.erb
-<section>
+<turbo-frame id="<%= params[:turbo_frame] || dom_id(@message) %>" role="section" target="_top">
   <h1>New message</h1>

   <%= link_to "Back", messages_path %>
@@ -27,4 +27,4 @@

     <button>Send</button>
   <% end %>
-</section>
+</turbo-frame>
```

```diff
--- a/app/views/messages/new.html.erb
+++ b/app/views/messages/new.html.erb
 <turbo-frame id="<%= params[:turbo_frame] || dom_id(@message) %>" role="section" target="_top">
   <h1>New message</h1>

-  <%= link_to "Back", messages_path %>
+  <%= link_to "Back", messages_path, class: "group-open:hidden" %>
+
+  <form method="dialog" class="hidden group-open:block">
+    <button>Back</button>
+  </form>
```

```javascript
// app/javascript/controllers/dialog_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  showModal() {
    if (this.element.open) return
    else this.element.showModal()
  }
}
```

### Polyfilling support for `<dialog>`

While [support has landed in WebKit][dialog-webkit], [Firefox support][] is
still in the works. In the meantime, behavior can be polyfilled with the
[dialog-polyfill][] package.

[Firefox support]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog#browser_compatibility
[dialog-webkit]: https://webkit.org/blog/12209/introducing-the-dialog-element/
[dialog-polyfill]: https://github.com/GoogleChrome/dialog-polyfill

```diff
--- a/app/javascript/controllers/dialog_controller.js
+++ b/app/javascript/controllers/dialog_controller.js
 import { Controller } from "@hotwired/stimulus"
+import dialogPolyfill from "https://cdn.skypack.dev/dialog-polyfill"

 export default class extends Controller {
+  initialize() {
+    dialogPolyfill.registerDialog(this.element)
+  }
+
   showModal() {
```

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
     <%= csp_meta_tag %>

     <script src="https://cdn.tailwindcss.com"></script>
+    <link rel="stylesheet" href="https://cdn.skypack.dev/dialog-polyfill/dist/dialog-polyfill.css">
     <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
     <%= javascript_importmap_tags %>
   </head>
```

## Submitting the `<form>` modally

```diff
--- a/app/views/messages/new.html.erb
+++ b/app/views/messages/new.html.erb
   <%= form_with model: @message, class: "grid" do |form| %>
+    <%= hidden_field_tag "turbo_frame", params[:turbo_frame] %>

     <% if form.object.errors.any? %>
```

```diff
--- a/app/controllers/messages_controller.rb
+++ b/app/controllers/messages_controller.rb
     @message = Message.new message_params

     if @message.save
-      redirect_to messages_url
+      redirect_to messages_url, turbo_frame: "_top"
     else
       render :new, status: :unprocessable_entity
     end
```
