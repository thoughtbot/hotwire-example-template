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

## Loading with Turbo Frames

```diff
--- a/app/views/messages/index.html.erb
+++ b/app/views/messages/index.html.erb
 <h1>Messages</h1>

+<turbo-frame id="messages_page_<%= @page.page %>" class="grid gap-2" target="_top">
   <% if @page.prev %>
+    <turbo-frame id="messages_page_<%= @page.prev %>">
       <%= link_to pagy_url_for(@page, @page.prev), rel: "prev" do %>
         Previous page
       <% end %>
+    </turbo-frame>
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
+    <turbo-frame id="messages_page_<%= @page.next %>">
       <%= link_to pagy_url_for(@page, @page.next), rel: "next" do %>
         Next page
       <% end %>
+    </turbo-frame>
   <% end %>
+</turbo-frame>
```

### Replacing Frames with their content

```diff
--- a/app/views/messages/index.html.erb
+++ b/app/views/messages/index.html.erb
-    <turbo-frame id="messages_page_<%= @page.prev %>">
+    <turbo-frame id="messages_page_<%= @page.prev %>"
+                 data-controller="element" data-action="turbo:frame-render->element#replaceWithChildren">
       <%= link_to pagy_url_for(@page, @page.prev), rel: "prev" do %>
         Previous page
       <% end %>
     </turbo-frame>
```

```diff
--- a/app/views/messages/index.html.erb
+++ b/app/views/messages/index.html.erb
-    <turbo-frame id="messages_page_<%= @page.next %>">
+    <turbo-frame id="messages_page_<%= @page.next %>"
+                 data-controller="element" data-action="turbo:frame-render->element#replaceWithChildren">
       <%= link_to pagy_url_for(@page, @page.next), rel: "next" do %>
         Next page
       <% end %>
     </turbo-frame>
```

```javascript
// app/javascript/controllers/element_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  replaceWithChildren({ target }) {
    this.element.replaceWith(...target.children)
  }
}
```

There is ongoing exploration work ([hotwired/turbo#146][]) to declaratively add
this behavior directly to `<turbo-frame>` elements through the
`[rendering="replace"]` attribute.

[hotwired/turbo#146]: https://github.com/hotwired/turbo/pull/146

https://user-images.githubusercontent.com/2575027/152660510-68a9e849-81bc-41a5-a7e0-5d4ca1856556.mov

## Hiding pagination links

```diff
--- a/app/views/messages/index.html.erb
+++ b/app/views/messages/index.html.erb
-    <turbo-frame id="messages_page_<%= @page.prev %>"
+    <turbo-frame id="messages_page_<%= @page.prev %>" class="group"
                  data-controller="element" data-action="turbo:frame-render->element#replaceWithChildren">
-      <%= link_to pagy_url_for(@page, @page.prev), rel: "prev" do %>
+      <%= link_to pagy_url_for(@page, @page.prev), rel: "prev", class: "hidden group-first-of-type:block" do %>
         Previous page
       <% end %>
     </turbo-frame>
```

```diff
--- a/app/views/messages/index.html.erb
+++ b/app/views/messages/index.html.erb
-    <turbo-frame id="messages_page_<%= @page.next %>"
+    <turbo-frame id="messages_page_<%= @page.next %>" class="group"
                  data-controller="element" data-action="turbo:frame-render->element#replaceWithChildren">
-      <%= link_to pagy_url_for(@page, @page.next), rel: "next" do %>
+      <%= link_to pagy_url_for(@page, @page.next), rel: "next", class: "hidden group-last-of-type:block" do %>
         Next page
       <% end %>
     </turbo-frame>
```

https://user-images.githubusercontent.com/2575027/152660556-34c303d4-08af-4df5-8fcd-38c1b0655b83.mov
