# Hotwire: Asynchronously loaded tooltips

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-tooltip-fetch

Let's build a common yet often overlooked feature: Tooltips. The goal here is to load and display a tooltip rendering a user's avatar and name when hovering over a link.

The code samples contained within omit the majority of the application’s setup. While reading, know that the application’s baseline code was generated with Rails 7 via `rails new`. The rest of the source code from this article can be found [on GitHub][].

[on GitHub]: https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-tooltip-fetch

## Setup

Our setup creates a `/users/:id/tooltip?turbo_frame=tooltip_user_:id` endpoint that will return the markup in `app/views/tooltips/show.html.erb`. We wrap the content in a [frame][] with a unique ID so that Turbo will return this particular frame's content when a request with a matching ID is made to this endpoint.

We're deliberately prefixing the ID with `tooltip_user_` because we will be adding other elements that have an ID generated with the [dom_id][] method. Adding the prefix helps keep the ID unique.

We pass `"_top"` to the `target` attribute to ensure any links clicked within the tooltip will [replace the whole page][], and not just the content within this `<turbo-frame>`.

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :users do
    resource :tooltip, only: :show
  end
end
```

```ruby
# app/controllers/tooltips_controller.rb
class TooltipsController < ApplicationController
  def show
    @user = User.find params[:user_id]
  end
end
```

```html
<!-- app/views/tooltips/show.html.erb -->
<turbo-frame id="<%= params.fetch :turbo_frame, dom_id(@user) %>" target="_top">
  <div class="relative">
    <div class="flex gap-2 items-center p-1 bg-black rounded-md text-white">
      <%= render partial: "users/user", object: @user, formats: :svg %>
      <strong>Name:</strong>
      <%= link_to @user.name, @user, class: "text-white" %>
    </div>
    <div class="h-2 w-2 bg-black rotate-45 -top-1 -left-2 ml-[50%] relative"></div>
  </div>
</turbo-frame>
```

[frame]: https://turbo.hotwired.dev/reference/frames
[dom_id]: https://api.rubyonrails.org/classes/ActionView/RecordIdentifier.html#method-i-dom_id
[replace the whole page]: https://turbo.hotwired.dev/reference/frames#frame-targeting-the-whole-page-by-default

## Loading the Tooltip

Now that we've created our tooltip endpoint and partial we just need to load them onto the page. This can be achieved with a `<turbo-frame>`.

```html
<!-- app/views/users/_user.html.erb -->
<div id="<%= dom_id user %>" class="scaffold_record">
  <p>
    <strong>Name:</strong>
    <%= user.name %>
  </p>

  <p class="relative">
    <%= link_to "Show this user", user, class: "peer", aria: { describedby: dom_id(user, :tooltip) } %>
    <!--
      Right now we're hiding each frame and its children
      with the `hidden` class. We're revealing each frame
      and its children with the `peer-hover:block` class.
     -->
    <turbo-frame id="<%= dom_id user, :tooltip %>" target="_top" role="tooltip"
                 src="<%= user_tooltip_path(user, turbo_frame: dom_id(user, :tooltip)) %>"
                 class="hidden absolute translate-y-[-150%] z-10
                        peer-hover:block peer-focus:block hover:block focus-within:block"
    >
      <!-- The tooltip will be added here. -->
    </turbo-frame>
  </p>
</div>
```

Again, we give each `<turbo-frame>` a unique ID by passing in `:tooltip` as the second argument to `dom_id`. We're doing this because we're already calling `dom_id` in this partial as well as in `app/views/tooltips/show.html.erb`.

We set the `src` of the `<turbo-frame>` to the tooltip endpoint we created in the setup. This means that when the page loads, each of these frames will fire off a network request to the tooltip endpoint and render the content of the tooltip in the `<turbo-frame>`.

Just like before, we pass `"_top"` to the `target` attribute to ensure that any links clicked within the tooltip will replace the whole page and not just content of the `<turbo-frame>` that was clicked.

Note that we assign the link an [aria-describedby][] attribute and give the turbo-frame a `role` of `"tooltip"` to comply with the [ARIA WAI specification for tooltips], which is currently a work in progress.

If you navigate to <http://localhost:3000/users> you may not notice anything special since the tooltips show up when you hover over each link. However a separate network request is made to the tooltip endpoint for each user regardless of whether or not you hover over their link.

![Multiple network requests as seen in the dev tools.](https://images.thoughtbot.com/blog-vellum-image-uploads/SS91GhEdQhm83wPXQ7fl_hw-1.png)
