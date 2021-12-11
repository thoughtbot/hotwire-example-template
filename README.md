# Hotwire: Strategies for managing stateful pages

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-restore-page-state

Let's explore ways to achieve client-side interactivity with server-generated
HTML over the Wire.

The code samples contained within omit the majority of the application’s setup.
While reading, know that the application’s baseline code was generated via rails
new. The rest of the [source code][] from this article can be found on GitHub,
and is best read [commit-by-commit][].

The code samples assume reader familiarity with:

* the structure and conventions of a [Ruby on Rails][] application
* transmitting <abbr title="Create, Read, Update, and Destroy">CRUD</abbr>
  operations over <abbr title="Hyper Text Transfer Protocol">HTTP</abbr>
* handling events with Stimulus controllers and actions
* loading content asynchronously with Turbo Frames

The code samples demonstrate:

* responding to Form Submissions with Turbo Stream content
* progressively enhancing client-side applications to maintain end-user state
* navigating Turbo Frames through Form Submissions and <abbr title="Hyper Text
  Transfer Protocol">HTTP</abbr> redirects

[Ruby on Rails]: https://guides.rubyonrails.org
[source code]: https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-restore-page-state
[commit-by-commit]: https://github.com/thoughtbot/hotwire-example-template/compare/hotwire-example-restore-page-state

Our starting point
---

We'll start with a minimal set of templates and controller actions that manage a
collection of `Task` records. A `Task` has two attributes: `details` and `done`.
The `TasksController` actions are minimal implementations that aim to
conventionally read from and write to a database of `Task` records:

```ruby
class TasksController < ApplicationController
  def new
    @task = Task.new
  end

  def create
    @task = Task.create! task_params

    redirect_to tasks_url
  end

  def index
    @tasks = Task.all
  end

  def edit
    @task = Task.find params[:id]
  end

  def update
    @task = Task.find params[:id]

    @task.update! task_params

    redirect_to tasks_url
  end

  private

  def task_params
    params.require(:task).permit(:details, :done)
  end
end
```

There is one primary end-user facing templates of note: `tasks/index.html.erb`.
The `tasks/index.html.erb` template splits the collection of `Task` records into
two groups split across two sections: those that are "to do", and those that are
"done".

Each section's heading maintains a counter of the records within, and each list
renders a shared `tasks/task` template partial that displays information about
the `Task` within a `<form>` element that updates its "done"-ness:

```erb
<%# app/views/tasks/index.html.erb %>

<section>
  <h1>To-do (<%= @tasks.to_do.size %>)</h1>

  <ol>
    <%= render collection: @tasks.to_do, partial: "tasks/task" %>
  </ol>

  <details>
    <summary>Add task</summary>
    <turbo-frame id="new_task" src="<%= new_task_path %>" loading="lazy"></turbo-frame>
  </details>
</section>

<section>
  <h1>Done (<%= @tasks.done.size %>)</h1>

  <ol>
    <%= render collection: @tasks.done, partial: "tasks/task" %>
  </ol>
</section>
```

Each `tasks/task` partial renders a `<turbo-frame>` that nests a `<form>`
element to update whether or not the `Task` record is "done", and an `<a>`
element to navigate to the `Task` record's edit route:

```erb
<%# app/views/tasks/_task.html.erb %>

<li>
  <turbo-frame id="<%= dom_id task %>">
    <%= form_with model: task, namespace: task.id, data: { turbo_frame: "_top" } do |form| %>
      <%= form.button :done, value: !task.done do %>
        <% if task.done %>
          To do
        <% else %>
          Done
        <% end %>
      <% end %>
      <%= form.label :done, task.details %>

      <%= link_to "Edit", edit_task_path(task) %>
    <% end %>
  </turbo-frame>
</li>
```

There are two notable arguments to the call to [`form_with`][]:

1.  the `namespace: task.id` option ensures that the fields within the`<form>`
    elements render with `[id]` and `[for]` attribute pairs that are unique
    across the document by generating their values from `Task` record identifiers

2.  the `data: { turbo_frame: "_top" }` option ensures that when the `<form>`
    element is submitted, Turbo [will drive the entire page][_top] in spite of
    the `<form>` element's nesting within its ancestor `<turbo-frame>` element.

[`form_with`]: https://edgeapi.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with
[_top]: https://turbo.hotwired.dev/handbook/frames#targeting-navigation-into-or-out-of-a-frame

Linking to the `Task` record's edit page from within the `<turbo-frame>` element
powers inline editing:

https://user-images.githubusercontent.com/2575027/148577872-6430e3cd-8abf-4f6c-9bf3-26364f0087cd.mov

In addition to rendering all `Task` records, the `tasks/index` template provides
end-user access to two other templates to create and edit `Task` records:
`tasks/new.html.erb` and `tasks/edit.html.erb` (respectively).

The `tasks/index` template, declares a `<turbo-frame loading="lazy">` element
within a `<details>` element.

The `<turbo-frame>` element will lazily load a `<form>` element for creating new
`Task` records. Since the `<details>` element is collapsed by default,
the `<turbo-frame>` won't start to load until it appears in the viewport.

The `<form>` is loaded through a request to the `TasksController#new` action,
which renders the `tasks/new` template:

```erb
<%# app/views/tasks/new.html.erb %>

<turbo-frame id="new_task">
  <%= form_with model: @task, data: { turbo_frame: "_top" } do |form| %>
    <%= render partial: "tasks/form", object: form %>
  <% end %>
</turbo-frame>
```

Passing `data: { turbo_frame: "_top" }` as an option to the [`form_with`][] call
results in rendering a `<form>` element with a `[data-turbo-frame="_top"]`
attribute. When the `<form>` element is submitted, Turbo [will drive the entire
page][_top], despite the fact that the `<form>` is nested within the
`<turbo-frame id="new_task">`.

[_top]: https://turbo.hotwired.dev/handbook/frames#targeting-navigation-into-or-out-of-a-frame

Similarly, the `TasksController#edit` action (linked to from within each
`tasks/task` partial) renders the `tasks/edit` template:

```erb
<%# app/views/tasks/edit.html.erb %>

<turbo-frame id="<%= dom_id @task %>">
  <%= form_with model: @task, namespace: @task.id do |form| %>
    <%= render partial: "tasks/form", object: form %>

    <%= link_to "Cancel", tasks_path %>
  <% end %>
</turbo-frame>
```

Both the `tasks/new` and `tasks/edit` templates share a `tasks/_form.html.erb`
partial:

```erb
<%# app/views/tasks/_form.html.erb %>

<%= form.label :details, class: "sr-only" %>
<%= form.text_field :details, required: true, pattern: /.*\w+.*/ %>
<%= form.button %>
```

Finally, we'll render the `<section>` elements as parts of a two-column grid:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
     <%= javascript_importmap_tags %>
   </head>

-  <body>
+  <body class="grid grid-cols-2">
     <%= yield %>
   </body>
 </html>
```

When end-users mark a `Task` as "to do" or "done", the entire page navigates,
and their in-page state (scroll depth, unsaved changes, etc.) is lost:

https://user-images.githubusercontent.com/2575027/148577879-0569f6f6-a6f5-45e9-a5eb-547fa96712a3.mov

What do we gain?
---

With the exception of _how_ the `<form>` element itself is lazily-loaded onto
the page, the rest of the code that reads from and writes to our collection of
`Task` records aims to be Conventional Rails. What lacks in flare, it
makes-up for in maintainability, stability, and predictability.

At what cost?
---

Assessing our approach from that vantage point, let's consider some of the
drawbacks, namely the user experience challenges:

1. Each submission (either creating or updating a `Task`) initiates a
   full-page navigation, which discards the entire document
2. If a user scrolls down the page to act upon a `Task`, the subsequent
   submission scrolls their browser back to the top of the page
3. If a user expands the "Add task" [disclosure][] then marks a `Task`
   as "done", the page load will cause the disclosure to re-collapse
4. If a user starts to fill out the details of a new `Task`, then marks
   a `Task` as "done", the unsaved `Task` is lost

[disclosure]: https://w3c.github.io/aria-practices/#disclosure

## Responding to Form Submissions with Turbo Streams

Navigating with a full-page HTTP redirect after a Form Submission means that any
end-user browser state will be lost. That state might include:

* how far they've scrolled within the page
* any text they've typed into a form
* which elements they've collapsed or expanded
* which element has focus

Responding to the submission with a Turbo Stream response provides an
opportunity to avoid those problems entirely. As an alternative to full-page
navigations, Turbo Stream responses encode operations that are executed within
the context of document in its current state.

We can configure our `TasksController` to render Turbo Stream responses by
calling [`respond_to`][] and calling `format.turbo_stream` within the block:

[`respond_to`]: https://edgeapi.rubyonrails.org/classes/ActionController/MimeResponds.html#method-i-respond_to

```diff
diff --git a/app/controllers/tasks_controller.rb b/app/controllers/tasks_controller.rb
index d5f0cf7..2b30b1e 100644
--- a/app/controllers/tasks_controller.rb
+++ b/app/controllers/tasks_controller.rb
@@ -18,7 +18,10 @@ class TasksController < ApplicationController

     @task.update! task_params

-    redirect_to tasks_url
+    respond_to do |format|
+      format.html { redirect_to tasks_url }
+      format.turbo_stream
+    end
   end
```

Once the controller opts-into Turbo Stream support, it needs to declare a
template for the controller action to render. In this case, we'll declare a
`tasks/update.turbo_stream.erb` file that corresponds to the
`TasksController#update` action:

```erb
<%# app/views/tasks/update.turbo_stream.erb %>

<%= turbo_stream.remove dom_id(@task, :li) %>

<%= turbo_stream.append @task.done ? "done_tasks" : "to_do_tasks" do %>
  <%= render partial: "tasks/task", object: @task %>
<% end %>
```

The template generates two `<turbo-stream>` elements:

1.  a `<turbo-stream>` with [action="remove"][] and a [target][] referencing an
    element with an `[id]` generated by `dom_id(@task, :li)`
2.  a `<turbo-stream>` with [action="append"][] and `[target="done_tasks"]`
    or `[target="to_do_tasks"]`, depending on the `Task` record's
    state

The `<turbo-stream action="remove">` element doesn't have any descendant
content, whereas the `<turbo-stream action="append">` element renders a
`tasks/task` partial as its content.

Since these Turbo Streams operations target elements within the current
document, we'll need to change our templates to render elements with
corresponding `[id]` attributes.

First, we'll update the `tasks/task` partial so that it renders the `<li>`
element with an `[id]` attribute generated by `dom_id(task, :li)`:

```diff
--- a/app/views/tasks/_task.html.erb
+++ b/app/views/tasks/_task.html.erb
-<li>
+<li id="<%= dom_id task, :li %>">
   <turbo-frame id="<%= dom_id task %>">
     <%= form_with model: task, namespace: task.id, data: { turbo_frame: "_top" } do |form| %>
       <%= form.button :done, value: !task.done do %>
```

Next, we'll change the `tasks/index` template, marking the "to do"
section's `<ol>` element with `[id="to_do_tasks"]`:

```diff
--- a/app/views/tasks/index.html.erb
+++ b/app/views/tasks/index.html.erb
 <section>
   <h1>To-do (<%= @tasks.to_do.size %>)</h1>

-  <ol>
+  <ol id="to_do_tasks">
     <%= render collection: @tasks.to_do, partial: "tasks/task" %>
   </ol>
```

Next, we'll make a similar change for the "done" section's `<ol>` element:

```diff
--- a/app/views/tasks/index.html.erb
+++ b/app/views/tasks/index.html.erb
 <section>
   <h1>Done (<%= @tasks.done.size %>)</h1>

-  <ol>
+  <ol id="done_tasks">
     <%= render collection: @tasks.done, partial: "tasks/task" %>
   </ol>
 </section>
```

Once we've ensured that there are elements that correspond to the `[target]`
attributes rendered in our Turbo Stream response, Turbo handles the rest.
When marking a `Task` as "done" or "to do", our application
changes that `Task` record's checkbox to reflect that state, _and_ it
re-arranges our two lists to reflect the new state of the world.

[target]: https://turbo.hotwired.dev/handbook/streams#stream-messages-and-actions
[action="remove"]: https://turbo.hotwired.dev/reference/streams#remove
[action="append"]: https://turbo.hotwired.dev/reference/streams#append

Unfortunately, these changes don't account for _all_ the new information. After
executing the Turbo Stream operations, two parts of our document have fallen out
of synchronization with the server: the counters in the "To-do" and "Done"
section headings.

To account for those changes, we can render additional `<turbo-stream>` elements
that [update][] their content:

[update]: https://turbo.hotwired.dev/reference/streams#update

```diff
--- a/app/views/tasks/update.turbo_stream.erb
+++ b/app/views/tasks/update.turbo_stream.erb
 <%= turbo_stream.remove dom_id(@task, :li) %>

 <%= turbo_stream.append @task.done ? "done_tasks" : "to_do_tasks" do %>
   <%= render partial: "tasks/task", object: @task %>
 <% end %>
+
+<%= turbo_stream.update "to_do_size", Task.to_do.size %>
+<%= turbo_stream.update "done_size", Task.done.size %>
```

Like our initial set of `<turbo-stream>` elements, these new operations target
elements in the document that have corresponding `[id]` attributes. To ensure
that parity, we'll wrap the "To-do" counter in a `<span>` elements:

```diff
--- a/app/views/tasks/index.html.erb
+++ b/app/views/tasks/index.html.erb
-  <h1>To-do (<%= @tasks.to_do.size %>)</h1>
+  <h1>To-do (<%= tag.span @tasks.to_do.size, id: "to_do_size" %>)</h1>
```

Then we'll make a similar change to the "Done" counter:

```diff
--- a/app/views/tasks/index.html.erb
+++ b/app/views/tasks/index.html.erb
<section>
-  <h1>Done (<%= @tasks.done.size %>)</h1>
+  <h1>Done (<%= tag.span @tasks.done.size, id: "done_size" %>)</h1>
```

What have we gained?
---

In total, these changes enable our application to transmit and respond to Form
Submissions by making in-place, minimally intrusive changes to the browser's
current document, without discarding stateful changes to the document:

https://user-images.githubusercontent.com/2575027/148579509-7c272283-61a8-4c62-8ab4-5d0de6eeec90.mov

Since the Turbo Stream operations are so tightly scoped and minimally intrusive,
there are several notable gains:

1.  The response status code is [200 OK][] not a [Redirection][], so our browser
    doesn't navigate the URL or fetch an entire document from the server
2.  We retain the rest of our page's state (like scroll depth, partially
    filled-out fields, expanded disclosures, element focus, etc.)

[200 OK]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/200
[Redirection]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#redirection_messages

At what cost?
---

Given our challenges and circumstances, the decision to utilize Turbo Streams in
response to Form Submissions grants us flexibility and control over the changes
we make to requesting documents.

Turbo Streams are an _immensely_ powerful and precise way to change to the
current document, and enable techniques that are otherwise costly, awkward, or
outright impossible. It's good to know that we have Turbo Streams in our back
pocket, for situations that demand their power and precision.

In spite of that power, there are trade-offs to be made.

When refreshing the contents of a single element on the page, a single
`<turbo-stream>` operation is an extremely cost-effective solution. When the
number of elements that require change grows, so do the costs.

In this example's case, there are several requirements:

1.  the current version of the `Task` must be removed
2.  the section that contains the current version must update its heading's
    counter to reflect the _subtraction_
3.  the new version must be added to the correct list
4.  the section that contains the current version must update its heading's
    counter to reflect the _addition_

Reaching for tools like Turbo Streams means we're foregoing standardized HTTP
mechanisms like `Content-Type: text/html` or [Redirection][] response.

Our application is now burdened with the responsibility reproducing common HTTP
request-response mechanisms (for example, changing the browser's URL, resetting
`<form>` element fields, or refreshing content across the page).

In this example's case, as the list of requirements grew, the number of required
operations grew linearly. Given a different set of requirements, the _number_ of
operations might remain the same, but the _scope_ of the elements affected by
those operations might grow. Regardless of the number or scope of operations,
our application is responsible for executing them all.

When we deviate from HTTP Standards, we're on our.

## Preserving state across Turbo Drive Visits

Most applications have pages or experiences that tip the scales in favor of
Turbo Stream, and make the trade-offs involved with appear to be a fair bargain.

For the rest of the pages, progressively enhanced HTTP redirects have a lot to
offer. Let's revert our changes to their original state, abandoning our usage of
Turbo Streams and returning to redirects and full-page navigations.

One of the central pillars of [Turbo Drive's value proposition][Turbo Drive]
value proposition is its ability to persist the current document's `<html>`
element and retain the current JavaScript process' references to the
`window` and `document` instances.

When navigating from one page to another, Turbo Drive updates the page's content
by replacing the current `<body>` element with a new `<body>` element extracted
from the response's HTML.

Turbo Drive-enabled applications can leverage that permanence by declaring
long-lived [Stimulus Controllers][] on the `<html>` document.

Where does our application fit on a continuum between possible with Turbo Drive
and the interactivity that's possible with Turbo Streams? Where is our threshold
of comfortability?

What tools do we have at our disposal to [Progressively Enhance][] the browser's
built-in behavior?

[Turbo Drive]: https://turbo.hotwired.dev/handbook/introduction#turbo-drive%3A-navigate-within-a-persistent-process
[Stimulus Controllers]: https://stimulus.hotwired.dev/handbook/hello-stimulus#controllers-bring-html-to-life
[Progressively Enhance]: https://developer.mozilla.org/en-US/docs/Glossary/Progressive_Enhancement

## Preserving scroll state

Since our original implementation relied upon full-page redirection,
user-initiated Form Submissions would discard any user-initiated scrolling and
would scroll to the top of the new page, falling back to the browser's built-in
behavior.

When the response to a Form Submission is a redirect _back to the current page_,
how might we preserve that browser's scroll state?

During a navigation, Turbo Drive dispatches various [events][]. To start, we'll
cache the page's scroll state before the Visit. We'll route
[turbo:before-visit][] events to a `cache(event)` action declared within a
`scroll` controller by declaring `[data-controller]` and `[data-action]`
attributes on our document's `<html>` element:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
<!DOCTYPE html>
-<html>
+<html data-controller="scroll"
+      data-action="turbo:before-visit->scroll#cache">
   <head>
     <title>HotwireExampleTemplate</title>
     <meta name="viewport" content="width=device-width,initial-scale=1">
```

Next, we'll declare the controller's implementation:

```javascript
// app/javascript/controllers/scroll_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get values() { return { top: Number } }

  cache() {
    this.topValue = this.element.scrollTop
  }
}
```

We persist the `<html>` element's scroll depth by assigning its value to a
[Stimulus Value][] named `top`. Our controller instance has access through the
`this.topValue` property. Any changes to that property are written to the
`<html>` element's `[data-scroll-top-value]` attribute.

In some situations, we might want to invalidate that cache if the Visit is to
another page. This action poses an opportunity for applications to encode
whatever invalidation logic they need. We can do so from an `invalidate()`
action that resets the `topValue` property whenever the `turbo:before-visit`
event's fires with an `event.details.url` that's different from the  `pathname`
of the [window.location][]:

```diff
--- a/app/javascript/controllers/scroll_controller.js
+++ b/app/javascript/controllers/scroll_controller.js
   cache() {
     this.topValue = this.element.scrollTop
   }
+
+  invalidate({ detail: { url } }) {
+    const { pathname } = new URL(url)
+
+    if (window.location.pathname != pathname) this.topValue = 0
+  }
```

We'll declare a second `[data-action]` entry to route `turbo:before-visit`
events to that action in the same way as the `scroll#cache` action:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
 <!DOCTYPE html>
 <html data-controller="scroll"
-      data-action="turbo:before-visit->scroll#cache">
+      data-action="turbo:before-visit->scroll#cache
+                   turbo:before-visit->scroll#invalidate">
```

[events]: https://turbo.hotwired.dev/reference/events
[turbo:before-visit]: https://turbo.hotwired.dev/handbook/drive#canceling-visits-before-they-start
[window.location]: https://developer.mozilla.org/en-US/docs/Web/API/Window/location
[Stimulus Value]: https://stimulus.hotwired.dev/reference/values

Next, we'll want to read from that cache and restore the document's scroll depth
following a successful Turbo Drive Visit. To do so, we'll route `turbo:load`
events to a `read(event)` action in our `scroll` controller:

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
 <!DOCTYPE html>
 <html data-controller="scroll"
       data-action="turbo:before-visit->scroll#cache
-                   turbo:before-visit->scroll#invalidate">
+                   turbo:before-visit->scroll#invalidate
+                   turbo:load->scroll#read">
```

The `read(event)` implementation reads from the `[data-scroll-top-value]`
attribute and assigns to the element's [scrollTop][] property:

```diff
--- a/app/javascript/controllers/scroll_controller.js
+++ b/app/javascript/controllers/scroll_controller.js
   invalidate({ detail: { url } }) {
     const { pathname } = new URL(url)

     if (window.location.pathname != pathname) this.topValue = 0
   }
+
+  read() {
+    this.element.scrollTop = this.topValue
+  }
}
```

[scrollTop]: https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollTop

**Caveat:** Current versions of Turbo (those `<= 7.1.0`) require a scrolling
work-around that prevents a Visit from scrolling so that applications can manage
scrolling on its behalf.

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
 <!DOCTYPE html>
 <html>
 <html data-controller="scroll"
       data-action="turbo:before-visit->scroll#cache
+                   turbo:visit->scroll#preventVisitScroll
                    turbo:load->scroll#read">
   <head>
     <title>HotwireExampleTemplate</title>
     <meta name="viewport" content="width=device-width,initial-scale=1">

--- a/app/javascript/controllers/scroll_controller.js
+++ b/app/javascript/controllers/scroll_controller.js
 import { Controller } from "@hotwired/stimulus"
+import { Turbo } from "@hotwired/turbo-rails"

 export default class extends Controller {
   static get values() { return { top: Number } }

   cache() {
     this.topValue = this.element.scrollTop
   }

   invalidate({ detail: { url } }) {
     const { pathname } = new URL(url)

     if (window.location.pathname != pathname) this.topValue = 0
   }

   read() {
     this.element.scrollTop = this.topValue
   }
+
+  preventVisitScroll() {
+    const { currentVisit } = Turbo.session.navigator
+
+    if (currentVisit) currentVisit.scrolled = true
+  }
}
```

What have we gained?
---

Since we're returned to "full-page" redirection, we no longer have to
micro-manage the _contents_ of our document. We don't need to create and manage
a dedicated `.turbo_stream.erb` template, and can rely on built-in browser
behavior and compliance with HTTP Standards.

At what cost?
---

While we don't have to manage the changing _contents_ of the page transition,
we're responsible for maintaining _context_ across changes.

Our scope changes from thinking in terms of elements to thinking in terms of
URLs and documents. This means that our application is responsible for managing
and invalidating cached scroll values.

While we've restored the scroll depth preserving behavior enabled by Turbo
Streams at the cost of regressions in the preservation of other state like the
expansion of disclosures and unsaved values in form fields:

https://user-images.githubusercontent.com/2575027/148579729-2479f8c8-f668-4a8e-9cc3-1af0c242f555.mov
