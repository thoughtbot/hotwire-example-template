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

## Loading the Tooltip Asynchronously

Fortunately, optimizing these requests is really easy. All we need to do is add a `loading` attribute and have it set to `"lazy"` to [lazy-load][] the tooltips.

This means the request to the tooltip endpoint will be made only when the `<turbo-frame>` becomes visible in the viewport. This is because `loading="lazy"` is using the [Intersection Observer API][] [under the hood][].

```diff
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
+                 loading="lazy"
     >
       <!-- The tooltip will be added here. -->
     </turbo-frame>
   </p>
 </div>
```

If you go back to `http://localhost:3000/users` you'll notice that a network request is only made once you hover over the link.

![Hovering over each link loads the tooltip asynchronously](https://images.thoughtbot.com/blog-vellum-image-uploads/rVXa8PJ9Sq2u3G3WXTEZ_hw-2.gif)

Right now we're hiding each frame with the `hidden` class and then revealing it with the `peer-hover:block` class. Both of these classes are provided to us by [Tailwind][] and are a nice abstraction of the [general sibling combinator][]. Even though a `<turbo-frame>` may be in the viewport, the fact that it's not visible prevents the network request from being made. It's only when the `<turbo-frame>` is revealed via CSS that the request is made.

![The Tailwind classes used to abstract the general sibling combinator and reveal the tooltip](https://images.thoughtbot.com/blog-vellum-image-uploads/n8yQbPEhSrClaUTcZ1ve_hw-3.png)

In order to test this, try removing the `hidden` class from the `<turbo-frame>`. You'll notice the tooltips are still lazy-loaded, except this time they are loaded once they come into the viewport.

```diff
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
-                 class="hidden absolute translate-y-[-150%] z-10
+                 class="absolute translate-y-[-150%] z-10
                         peer-hover:block peer-focus:block hover:block focus-within:block"
                  loading="lazy"
     >
       <!-- The tooltip will be added here. -->
     </turbo-frame>
   </p>
 </div>
```

![Displaying the frame will load the tooltip once it's in the viewport.](https://images.thoughtbot.com/blog-vellum-image-uploads/dQLMVeagQjuj15wOIuAd_hw-4.gif)

[lazy-load]: https://turbo.hotwired.dev/reference/frames#lazy-loaded-frame
[Tailwind]: https://tailwindcss.com/
[general sibling combinator]: https://developer.mozilla.org/en-US/docs/Web/CSS/General_sibling_combinator
[Intersection Observer API]: https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API
[under the hood]: https://github.com/hotwired/turbo/blob/8bce5f17cd697716600d3b34836365ebcdc04b3f/src/observers/appearance_observer.ts
[aria-describedby]: https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-describedby
[ARIA WAI specification for tooltips]: https://www.w3.org/TR/wai-aria-practices-1.1/#tooltip

## Takeaways

There are two main takeaways from this simple demonstration that extend beyond Hotwire and Tailwind.

### Lazy-load content when you can

There's a cost to each network request, and not all user's will be viewing your application on the latest hardware or on a stable internet connection. Consider lazy-loading content that's not critical to the initial page load, especially if that content is not in the viewport.

Turbo makes this easy with its `loading` attribute, but this is not a Turbo specific concept.

#### CSS can be leveraged to drive interactions

In our example we're able to reveal the tooltip by hovering over the tooltip's sibling. This may seem like the result of some magical property provided by Tailwind via the [peer class][], but in reality it's just the result of the [general sibling combinator][] (which has been around since Internet Explorer 7) in combination with [user action pseudo-classes][]. This is an incredibly powerful yet under utilized feature of CSS, and is often unnecessarily replicated with JavaScript.

Tailwind has exposed some of the most powerful features that CSS has to offer, but remember that they're just abstractions around existing CSS specifications.

[peer class]: https://tailwindcss.com/docs/hover-focus-and-other-states#styling-based-on-sibling-state
[general sibling combinator]: https://developer.mozilla.org/en-US/docs/Web/CSS/General_sibling_combinator
[user action pseudo-classes]: https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-classes#user_action_pseudo-classes
