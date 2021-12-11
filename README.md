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
