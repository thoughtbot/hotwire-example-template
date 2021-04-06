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

## Enhancing our search

Currently, submitting our search `<form>` navigates our application,
resulting in a full-page transition. We can improve upon that experience
by navigating _part_ of our page instead.

[Turbo Frames][] are a predefined portion of a page that can be updated
upon request. Any requests from inside a frame from links or forms are
captured, and the frame's contents are automatically updated after
receiving a response. Frames are rendered as `<turbo-frame>` [Custom
Elements][], and have their own set of [attributes and properties][].
They can be navigated by descendant `<a>` and `<form>` elements _or_ by
`<a>` and `<form>` elements elsewhere in the document.

Let's render our search results _into_ a `<turbo-frame>` element. We'll
add the element as a sibling to our header's `<form>` element, making
sure to give it an `[id]` attribute:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
         <button type="submit">
           Search
         </button>
       </form>
+
+      <turbo-frame id="search_results"></turbo-frame>
     </header>
   </body>
```

To navigate it, we'll _target_ it with our search `<form>` by declaring
the [data-turbo-frame="search_results"][] attribute:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
@@ -17,7 +17,7 @@
-      <form action="<%= searches_path %>">
+      <form action="<%= searches_path %>" data-turbo-frame="search_results">
         <label for="search_query">Query</label>
         <input id="search_query" name="query" type="search">

         <button>
           Search
         </button>
       </form>

       <turbo-frame id="search_results"></turbo-frame>
```

Whenever our `<form>` element submits, Turbo will navigate the
`<turbo-frame id="search_results">` based on the `<form>` element's
[action][] attribute. For example, when a user fills in the `<input
type="search">` element with "needle" and submits the `<form>`, Turbo
will set the `<turbo-frame>` element's [src][] attribute and navigate to
`/searches?query=needle`. The request's [Accept][] HTTP Headers will be
similar to what the browser would submit had it navigated the entire
page.

In response, our server will handle the request like any other HTML
request, with one additional constraint: we'll need to make sure that
our response HTML [contains a `<turbo-frame>` element with an `[id]`
attribute that matches the frame in the requesting page][matching-id].

To meet that requirement, we'll wrap the contents of the
`searches#index` template in a matching `<turbo-frame
id="search_results">` element:

```diff
--- a/app/views/searches/index.html.erb
+++ b/app/views/searches/index.html.erb
+<turbo-frame id="search_results">
   <h1>Results</h1>

   <ul>
     <% @messages.each do |message| %>
       <li>
         <%= link_to highlight(message.body, params[:query]), message_path(message) %>
       </li>
     <% end %>
   </ul>
+</turbo-frame>
```

To ensure sure that the request's `<turbo-frame>` element `[id]` is
consistent with to the response's, we'll encode the identifier into the
`?turbo_frame=` query parameter as part of the `<form>` element's
`[action]` attribute:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
@@ -17,7 +17,7 @@
-      <form action="<%= searches_path %>" data-turbo-frame="search_results">
+      <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results">
         <label for="search_query">Query</label>
         <input id="search_query" name="query" type="search">

         <button>
           Search
         </button>
       </form>

       <turbo-frame id="search_results"></turbo-frame>
```

Then we'll encode the value into the rendered `<turbo-frame>` element's
`[id]` with a default value when the `param` is missing:

```diff
--- a/app/views/searches/index.html.erb
+++ b/app/views/searches/index.html.erb
-<turbo-frame id="search_results">
+<turbo-frame id="<%= params.fetch(:turbo_frame, "search_results") %>">
```

When an end-user clicks on a `<a>` element in the results, we'll want to
navigate the _page_, not the `<turbo-frame>` element that contains the
`<a>`. To ensure that, we have two options: annotate each `<a>` with the
[`data-turbo-frame="_top"`][] attribute, or annotate the `application`
layout template's `<turbo-frame>` element with the [`target="_top"`][]
attribute.

For the sake of simplicity, let's annotate the custom `<turbo-frame>`
element with the custom `[target]` attribute instead of annotating the
standards-based `<a>` element with a `data`-prefixed custom attribute:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
-      <turbo-frame id="search_results"></turbo-frame>
+      <turbo-frame id="search_results" target="_top"></turbo-frame>
```

[Turbo Frames]: https://turbo.hotwire.dev/handbook/frames
[Custom Elements]: https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_custom_elements
[attributes and properties]: https://turbo.hotwire.dev/reference/frames
[data-turbo-frame="search_results"]: https://turbo.hotwire.dev/handbook/frames#targeting-navigation-into-or-out-of-a-frame
[action]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#attr-action
[src]: https://turbo.hotwire.dev/reference/frames#html-attributes
[Accept]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept
[matching-id]: https://turbo.hotwire.dev/reference/frames#basic-frame
[`data-turbo-frame="_top"`]: https://turbo.hotwired.dev/reference/frames#frame-with-overwritten-navigation-targets
[`target="_top"`]: https://turbo.hotwired.dev/reference/frames#frame-that-drives-navigation-to-replace-whole-page

## Hiding the results when inactive

Now that we're overlaying our results on top of the rest of the page,
we'll only want to do so when the end-user is actively searching. We'll
also want to avoid needless requests to the server with empty query
text.

Lucky for us, browsers provide a built-in mechanism to prevent bad
`<form>` submissions and to surface a field's correctness: [Constraint
Validations][]!

In our case, there are two ways that a search can be invalid:

1. The query `<input>` element is completely blank.
2. The query `<input>` element has a value, but that value is comprised
   of entirely empty text characters.

To consider those states invalid, render the `<input>` with [required][]
and [pattern][] attributes:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
       <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results">
         <label for="search_query">Query</label>
-        <input id="search_query" name="query" type="search">
+        <input id="search_query" name="query" type="search" pattern=".*\w+.*" required>
```

By default, browsers will communicate a field's invalidity by
rendering a field-local tooltip message. While it's important to
minimize the number of invalid HTTP requests sent to our server, a
type-ahead search box works best when users can incrementally make
changes to the query string. In our case, a validation message could
disruptive or distract a user mid-search.

To have more control over the validation experience, we'll need to write
some JavaScript. Let's create
`app/javascript/controllers/form_controller.js` to serve as a [Stimulus
Controller][]:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
}
```

Next, we'll need to listen for browsers' built-in [invalid][] events to
fire. When they do, we'll route them to the `form` controller as a
[Stimulus Action][] named `hideValidationMessage`:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
     <header>
-      <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results">
+      <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results"
+        data-controller="form" data-action="invalid->form#hideValidationMessage:capture">
         <label for="search_query">Query</label>
```

One quirk of [invalid][] events is that they _do not_ [bubble up][]
through the [DOM][]. To account for that, our `form` controller will
need to act on them during the capture phase. Stimulus supports the
[`:capture` suffix][capture] as a directive to hint to our action
routing that the controller's action should be invoked during the
capture phase of the underlying event listener.

Once we're able to act upon the [invalid][] event, we'll want the
`form#hideValidationMessage` action to [prevent the default behavior][]
to stop the browser from rendering the validation message.

```diff
--- a/app/javascript/controllers/form_controller.js
+++ b/app/javascript/controllers/form_controller.js
 import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
+  hideValidationMessage(event) {
+    event.stopPropagation()
+    event.preventDefault()
+  }
 }
```

When an ancestor `<form>` element contains fields that are invalid, it
will match the [:invalid][] pseudo-selector. By rendering the search
results `<turbo-frame>` element as a [direct sibling][] to the `<form>`
element, we can incorporate the `:invalid` state into the sibling
element's style, and hide it.

```diff
--- a/app/assets/stylesheets/application.css
+++ b/app/assets/stylesheets/application.css
*= require_tree .
*= require_self
*/
+
+.empty\:hidden:empty                                { display: none; }
+.peer:invalid ~ .peer-invalid\:hidden               { display: none; }

--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
    <header>
-      <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results"
+      <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results" class="peer"
        data-controller="form" data-action="invalid->form#hideValidationMessage:capture">
        <label for="search_query">Query</label>

--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
-      <turbo-frame id="search_results" target="_top"></turbo-frame>
+      <turbo-frame id="search_results" target="_top" class="empty:hidden peer-invalid:hidden"></turbo-frame>
    </header>
```

[Constraint Validations]: https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/HTML5/Constraint_validation
[required]: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/required
[pattern]: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/pattern
[invalid]: https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/invalid_event
[capture]: https://stimulus.hotwire.dev/reference/actions#options
[Stimulus Controller]: https://stimulus.hotwire.dev/handbook/hello-stimulus#controllers-bring-html-to-life
[Stimulus Action]: https://stimulus.hotwire.dev/handbook/building-something-real#connecting-the-action
[bubble up]: https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Building_blocks/Events#Bubbling_and_capturing_explained
[DOM]: https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model
[prevent the default behavior]: https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Building_blocks/Events#preventing_default_behavior
[:invalid]: https://developer.mozilla.org/en-US/docs/Web/CSS/:invalid
[Tailwind CSS]: https://tailwindcss.com/
[variant]: https://tailwindcss.com/docs/hover-focus-and-other-states
[direct sibling]: https://developer.mozilla.org/en-US/docs/Web/CSS/General_sibling_combinator

## Navigating the results

Now that our search results are rendered onto the page, we'll want to
navigate through them with our keyboard's direction keys. The Web
Accessibility Initiative - Accessible Rich Internet Applications (<abbr
title="Web Accessibility Initiative - Accessible Rich Internet
Applications">[WAI-ARIA][]</abbr>) Authoring Practices outline a pattern
for this type of behavior: [role="combobox"][].

We'll depend on the [@github/combobox-nav][] package to progressively
enhance our search results by outsourcing keyboard navigation and
selection management.

Wiring-up the controller
---

Since we're overriding the way that browsers prompt users with a list of
choices when filling out a text box, we'll start by signalling to
browsers that our `<input type="search">` can skip autocompletion by
declaring [autocomplete="off"][]:

[@github/combobox-nav]: https://github.com/github/combobox-nav
[WAI-ARIA]: https://www.w3.org/TR/wai-aria-practices/
[role="combobox"]: https://www.w3.org/TR/wai-aria-1.2/#combobox
[autocomplete="off"]: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete#values

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
   <body>
     <header>
       <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results" class="peer"
         data-controller="form" data-action="invalid->form#hideValidationMessage:capture">
         <label for="search_query">Query</label>
-        <input id="search_query" name="query" type="search" pattern=".*\w+.*" required>
+        <input id="search_query" name="query" type="search" pattern=".*\w+.*" required autocomplete="off">
```

Next, we'll create a `combobox` [Stimulus Controller][] and import the
`@github/combobox-nav` package through [Skypack][]:

[Stimulus Controller]: https://stimulus.hotwired.dev/handbook/hello-stimulus#controllers-bring-html-to-life
[Skypack]: https://www.skypack.dev

```javascript
import { Controller } from "@hotwired/stimulus"
import Combobox from "https://cdn.skypack.dev/@github/combobox-nav"

export default class extends Controller {
}
```

Our controller needs an element within the browser's document to attach
its behavior to, so we'll declare `[data-controller="combobox"]` on an
element. In this case, it's crucial that the element is an ancestor of
_both_ our `<input type="search">` and our `<turbo-frame
id="search_results">` elements. Since the `<input type="search">`
element's ancestor `<form>` is the `<turbo-frame id="search_results">`
element's sibling, their `<header>` ancestor will do the trick:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
   <body>
-    <header>
+    <header data-controller="combobox">
       <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results" class="peer"
         data-controller="form" data-action="invalid->form#hideValidationMessage:capture">
         <label for="search_query">Query</label>
```

In order to construct and attach a `Combobox` instance, we'll need two
elements: a `[role="combobox"]` element and a `[role="listbox"]` element
with. [Stimulus Targets][] afford controllers with direct references to
elements with the matching attributes. We'll create targets to access
the input and the list:

[Stimulus Targets]: https://stimulus.hotwired.dev/reference/targets

```diff
--- a/app/javascript/controllers/combobox_controller.js
+++ b/app/javascript/controllers/combobox_controller.js
 import { Controller } from "@hotwired/stimulus"
 import Combobox from "https://cdn.skypack.dev/@github/combobox-nav"

 export default class extends Controller {
+  static get targets() { return [ "input", "list" ] }
 }
```

We'll annotate elements in our templates to coincide with each target
declaration. First, we'll declare `[data-combobox-target="input"]` on
our `<input type="search">`:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
   <body>
     <header data-controller="combobox">
       <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results" class="peer"
         data-controller="form" data-action="invalid->form#hideValidationMessage:capture">
         <label for="search_query">Query</label>
-        <input id="search_query" name="query" type="search" pattern=".*\w+.*" required autocomplete="off">
+        <input id="search_query" name="query" type="search" pattern=".*\w+.*" required autocomplete="off"
+          data-combobox-target="input">
```

According to the `@github/combobox-nav` [documentation][], there are two
requirements for the list:

> * Each option needs to have `role="option"` and a unique `id`
> * The list should have `role="listbox"`

To meet those requirements, we'll declare `[role="listbox"]` and
`[data-combobox-target="list"]` on the `searches/index` template's
`<ul>` element. For each of the `<ul>` element's descendant `<a>`
elements will declare the `[role="option"]` attribute, and make sure
each has a unique `[id]` attribute:

[documentation]: https://github.com/github/combobox-nav/tree/main#usage

```diff
--- a/app/views/searches/index.html.erb
+++ b/app/views/searches/index.html.erb
 <turbo-frame id="<%= params.fetch(:turbo_frame, "search_results") %>">
   <h1>Results</h1>

-  <ul>
+  <ul role="listbox" data-combobox-target="list">
     <% @messages.each do |message| %>
       <li>
-        <%= link_to highlight(message.body, params[:query]), message_path(message) %>
+        <%= link_to highlight(message.body, params[:query]), message_path(message),
+              id: dom_id(message, :search_result), role: "option" %>
       </li>
     <% end %>
   </ul>
```

Now that our controller has direct access to the necessary element, and
those elements meet the markup requirements for `@github/combobox-nav`,
we can wire-up our [Stimulus Actions][] to start and stop keyboard event
interception.

[Stimulus Actions]: https://stimulus.hotwired.dev/reference/actions

We'll want our controller to start intercepting keyboard events
whenever:

1. The `<input type="search">` element gains focus
2. The `[role="listbox"]` element is present and contains search results
   to navigate

To cover the first case, we'll declare a `start()` action:

```diff
--- a/app/javascript/controllers/combobox_controller.js
+++ b/app/javascript/controllers/combobox_controller.js
 export default class extends Controller {
   static get targets() { return [ "input", "list" ] }
+
+  start() {
+    this.combobox?.destroy()
+
+    this.combobox = new Combobox(this.inputTarget, this.listTarget)
+    this.combobox.start()
+  }
 }
```

The action makes use of the [optional chaining operator][] to safely
destroy any previously instantiated `Combobox` instances so that each
`start()` action operates without stale references.

In order to route [focus][] events to our controller's `start()` action,
we'll need to declare a `focus->combobox#start` descriptor on the
`<input type="search">` element:

[optional chaining operator]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Optional_chaining
[focus]: https://developer.mozilla.org/en-US/docs/Web/API/Element/focus_event

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
@@ -10,11 +10,12 @@
   </head>

   <body>
     <header data-controller="combobox">
       <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results" class="peer"
         data-controller="form" data-action="invalid->form#hideValidationMessage:capture">
         <label for="search_query">Query</label>
         <input id="search_query" name="query" type="search" pattern=".*\w+.*" required autocomplete="off"
-          data-combobox-target="input">
+          data-combobox-target="input" data-action="focus->combobox#start">
```

To cover the second case, we'll implement a `listTargetConnected()`
callback to fire whenever our `[data-combobox-target="list"]` element is
connected to the document:

```diff
--- a/app/javascript/controllers/combobox_controller.js
+++ b/app/javascript/controllers/combobox_controller.js
 export default class extends Controller {
   static get targets() { return [ "input", "list" ] }
+
+  listTargetConnected() {
+    this.start()
+  }
+
   start() {
```

We'll stop intercepting keyboard events whenever the `<input
type="search">` element loses focus. To do so, we'll add a `stop()`
action to our controller:

```diff
--- a/app/javascript/controllers/combobox_controller.js
+++ b/app/javascript/controllers/combobox_controller.js

     this.combobox = new Combobox(this.inputTarget, this.listTarget)
     this.combobox.start()
   }
+
+  stop() {
+    this.combobox?.stop()
+  }
 }
```

Next, we'll declare a `focusout->combobox#stop` descriptor on our
`<input type="search">` element so that our controller's `stop()` is
invoked whenever a [focusout][] event fires:

[focusout]: https://developer.mozilla.org/en-US/docs/Web/API/Element/focusout_event

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
         <label for="search_query">Query</label>
         <input id="search_query" name="query" type="search" pattern=".*\w+.*" required autocomplete="off"
-          data-combobox-target="input" data-action="focus->combobox#start">
+          data-combobox-target="input" data-action="focus->combobox#start focusout->combobox#stop">
```

Finally, whenever the controlled element is [disconnected][] from the
document, we'll destroy the `Combobox` instance:

[disconnected]: https://stimulus.hotwired.dev/reference/lifecycle-callbacks#disconnection

```diff
--- a/app/javascript/controllers/combobox_controller.js
+++ b/app/javascript/controllers/combobox_controller.js
   static get targets() { return [ "input", "list" ] }

+  disconnect() {
+    this.combobox?.destroy()
+  }
+
   listTargetConnected() {
     this.start()
   }
```

Visually indicating selection
---

Navigating a `[role="combobox"]` element moves a _selection_ cursor,
instead of the document's focus. Whenever <kbd>↑</kbd> or <kbd>↓</kbd>
keys are pressed, the `Combobox` instance will set
`[aria-selected="true"]` on the current `[role="option"]` element and
`[aria-selected="false"]` on all other `[role="option"]` elements.

To add a visual cue that the selection has changed, we'll declare an
`aria-selected:outline-black` class inspired by Tailwind CSS:

```diff
--- a/app/assets/stylesheets/application.css
+++ b/app/assets/stylesheets/application.css
 .empty\:hidden:empty                                { display: none; }
 .peer:invalid ~ .peer-invalid\:hidden               { display: none; }
+.aria-selected\:outline-black[aria-selected="true"] { outline: 2px dotted black; }
```

Next, we'll add that class to our `<a>` search result elements:

```diff
--- a/app/views/searches/index.html.erb
+++ b/app/views/searches/index.html.erb
@@ -1,10 +1,11 @@
     <% @messages.each do |message| %>
       <li>
         <%= link_to highlight(message.body, params[:query]), message_path(message),
-              id: dom_id(message, :search_result), role: "option" %>
+              id: dom_id(message, :search_result), role: "option", class: "aria-selected:outline-black" %>
       </li>
     <% end %>
```

## Searching while typing

Whenever the end-user enters text into `<input type="search">` element,
an [input][] event fill fire fore each keystroke and bubble up.. When
the `<input>` element's text changes, we'll refresh the search results
by submitting the corresponding `<form>` element. Since the `<form>`
element targets the `<turbo-frame id="search_results">`, the frame will
navigate automatically whenever the form submits.

To submit the `<form>` after each keystroke, we'll declare an action
descriptor to route all `input` events to the `form#submit` action:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
@@ -17,11 +17,11 @@
   <body>
     <header>
       <form action="<%= searches_path(turbo_frame: "search_results") %>" data-turbo-frame="search_results" class="peer"
-        data-controller="form" data-action="invalid->form#hideValidationMessage:capture">
+        data-controller="form" data-action="invalid->form#hideValidationMessage:capture input->form#submit">
         <label for="search_query">Query</label>
         <input id="search_query" name="query" type="search" pattern=".*\w+.*" required>

         <button>
           Search
         </button>
       </form>
```

We'll declare `[data-form-target="submit"]` on the `<form>` element's
`<button>`, so that the `form` controller instance can access it as a
[Target][]:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
@@ -17,11 +17,11 @@
-        <button>
+        <button data-form-target="submit">
           Search
         </button>
```

We'll declare the `submit` target within the `form` controller, then
implement the `submit()` action to reference the new target and submit
the `<form>` by clicking the `<button>` on the end-user's behalf:

```diff
--- a/app/javascript/controllers/form_controller.js
+++ b/app/javascript/controllers/form_controller.js
 import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
+  static get targets() { return [ "submit" ] }
+
+  submit() {
+    this.submitTarget.click()
+  }
+
   hideValidationMessage(event) {
     event.stopPropagation()
     event.preventDefault()
   }
 }
```

Since we'll be automatically submitting the form on each keystroke, we
have an opportunity to hide the submit button. We'll use JavaScript to
set the [hidden][] attribute on the element. By deferring the `[hidden]`
attribute to JavaScript, we can ensure that the element is visible
whenever end-users are browsing without JavaScript enabled.

```diff
--- a/app/javascript/controllers/form_controller.js
+++ b/app/javascript/controllers/form_controller.js
 import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
   static get targets() { return [ "submit" ] }
+
+  connect() {
+    this.submitTarget.hidden = true
+  }

   submit() {
```

Finally, submitting the `<form>` on _every_ keystroke results in a
cascade of sequential HTTP requests. In that scenario, the majority of
the intermediate responses could be ignored. To limit the number of
concurrent requests, we'll add limitations to ensure that a submission
occurs _at most_ once every 200 milliseconds. We'll add a client-side
dependency on [Lodash.debounce][] through [Skypack][]. Once that
function is available, we'll re-bind the `form#submit` action to the
debounced version:

```diff
--- a/app/javascript/controllers/form_controller.js
+++ b/app/javascript/controllers/form_controller.js
 import { Controller } from "@hotwired/stimulus"
+import debounce from "https://cdn.skypack.dev/lodash.debounce"

 export default class extends Controller {
   static get targets() { return [ "submit" ] }
+
+  initialize() {
+    this.submit = debounce(this.submit.bind(this), 200)
+  }

   connect() {
     this.submitTarget.hidden = true
   }
```

[input]: https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/input_event
[Target]: https://stimulus.hotwire.dev/handbook/building-something-real#defining-the-target
[hidden]: https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/hidden
[Lodash.debounce]: https://lodash.com/docs/4.17.15#debounce
[Skypack]: https://www.skypack.dev/about

Wrapping up
---

We started with an out-of-the-box Rails application generated by `rails
new`, then implemented a collapsible search-as-you-type experience. The
`<input type="search">` element's container expands to show its results
in-line while searching, supports keyboard navigation and selection, and
only submits requests to the server when a search term is present.

We never encode our search request or response into JSON, and our client
communicates with our server without any calls to [XMLHttpRequest][] or
[fetch][] from within our application code.

On top of all that, we've implemented the experience with [semantically
meaningful][] elements like [`<form>`][mdn-form], [`<input
type="search">`][mdn-input-search], and [`<mark>`][mdn-mark]!

[semantically meaningful]: https://developer.mozilla.org/en-US/docs/Glossary/semantics
[XMLHttpRequest]: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
[fetch]: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API
[mdn-form]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form
[mdn-input-search]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/search
[mdn-mark]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/mark
