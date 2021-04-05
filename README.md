# Hotwire: Typeahead searching

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-typeahead-search

Let's build a collapsible search-as-you-type text box that expands to
show its results in-line while searching, supports keyboard navigation
and selection, and only submits requests to our server when there is a
search term.

We’ll start with an out-of-the-box Rails installation that utilizes
Turbo Drive, Turbo Frames, and Stimulus to then progressively enhance
concepts and tools that are built directly into browsers. Plus, it’ll
degrade gracefully when JavaScript is unavailable!

The code samples contained within omit the majority of the application's
setup. While reading, know that the application's baseline code was
generated via `rails new`. The rest of the source code from this article
can be found [on GitHub][].

[on GitHub]: https://github.com/thoughtbot/hotwire-example-template/commits/hotwire-example-typeahead-search

Our haystack
---

We'll be searching through a collection of Active Record-backed
`Message` models, with each row containing a [TEXT][] column named
`body`. Let's use Rails' `scaffold` [generator][] to create application
scaffolding for the `Message` routes, controllers, and model:

```sh
bin/rails generate scaffold Message body:text
```

For simplicity's sake, our application will rely on SQL's [ILIKE][]-powered
pattern matching. Once implemented, the experience could be improved by more
powerful search tools (e.g. PostgresSQL's [full-text searching][] capabilities).

[TEXT]: https://www.postgresql.org/docs/12/datatype-character.html
[generator]: https://guides.rubyonrails.org/command_line.html#bin-rails-generate
[ILIKE]: https://www.postgresql.org/docs/12/functions-matching.html#FUNCTIONS-LIKE
[full-text searching]: https://www.postgresql.org/docs/12/textsearch.html

Searching for our needle
---

First, we'll declare the `searches#index` route to handle our search
query requests:

```diff
--- a/config/routes.rb
+++ b/config/routes.rb
 Rails.application.routes.draw do
   resources :messages
+  resources :searches, only: :index
   # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
 end
```

Next, add a `<header>` element to our layout. While we're at it, we'll
also wrap the `<%= yield %>` in a `<main>` element so that it's the
`<header>` element's sibling:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
@@ -15,6 +15,21 @@
   <body>
+    <header>
+    </header>
+
-    <%= yield %>
+    <main><%= yield %></main>
   </body>
 </html>
```

Within the `<header>`, we'll nest a `<form>` element that submits
requests to the `searches#index` route:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
@@ -15,6 +15,21 @@
   <body>
     <header>
+      <form action="<%= searches_path %>">
+      </form>
     </header>

     <main><%= yield %></main>
   </body>
 </html>
```

When declared without a `[method]` attribute, `<form>` elements default
to `[method="get"]`. Since querying is an [idempotent][] and [safe][]
action, the `<form>` element will make [GET][] HTTP requests when
submitted.

Within the `<form>`, we'll declare an `<input type="search">` to capture
the query and a `<button>` to submit the request:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
       <form action="<%= searches_path %>">
+        <label for="search_query">Query</label>
+        <input id="search_query" name="query" type="search">
+
+        <button>
+          Search
+        </button>
       </form>
```

[idempotent]: https://developer.mozilla.org/en-US/docs/Glossary/Idempotent
[safe]: https://developer.mozilla.org/en-US/docs/Glossary/Safe/HTTP
[GET]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET

Within the `searches#index` controller action, we'll transform the
`?query=` parameter into an argument for our `Message.containing` Active
Record [scope][].

```ruby
class SearchesController < ApplicationController
  def index
    @messages = Message.containing(params[:query])
  end
end
```

The `Message.containing` scope interpolates the `query` argument's text
into an [ILIKE][] statement with leading and trailing `%` wildcard
operators:

```diff
--- a/app/models/message.rb
+++ b/app/models/message.rb
 class Message < ApplicationRecord
+  scope :containing, -> (query) { where <<~SQL, "%" + query + "%" }
+    body ILIKE :query
+  SQL
 end
```

Within the corresponding `app/views/searches/index.html.erb` template,
we'll render an `<a>` element for each result. We'll pass each
`Message#body` to [highlight][] so that the portions of the text that
match the search term are wrapped with [`<mark>`][mark] elements.

```erb
<h1>Results</h1>

<ul>
  <% @messages.each do |message| %>
    <li>
      <%= link_to highlight(message.body, params[:query]), message_path(message) %>
    </li>
  <% end %>
</ul>
```

[scope]: https://edgeapi.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-scope
[Message.none]: https://edgeapi.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-none
[set_page_and_extract_portion_from]: https://github.com/basecamp/geared_pagination/tree/v1.1.0#example
[highlight]: https://edgeapi.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-highlight
[mark]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/mark
