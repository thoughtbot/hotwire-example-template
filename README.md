# Hotwire: Server-render alert messages for client-side actions

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-button-alert-template

Communicating feedback for user-initiated actions is a common pattern in Rails.
[Flash][]
Its [index.html.erb][] and [show.html.erb][] template generators include
scaffolding to render support for `notice` and `alert` messages provided by the
[ActionDispatch::Flash][] module.

All of this is made available during server-side rendering. How might we re-use
our architectural plumbing when a client-side interaction warrants a flash
message?

[Flash]: https://edgeguides.rubyonrails.org/action_controller_overview.html#the-flash
[ActionDispatch::Flash]: https://edgeapi.rubyonrails.org/classes/ActionDispatch/Flash.html
[index.html.erb]: https://github.com/rails/rails/blob/7-0-stable/railties/lib/rails/generators/erb/scaffold/templates/index.html.erb.tt#L1
[show.html.erb]: https://github.com/rails/rails/blob/7-0-stable/railties/lib/rails/generators/erb/scaffold/templates/show.html.erb.tt#L1

Appeal of client-side rendering like React:

* define HTML structure, styles, event responses in the same place in the
  codebase
  - the _content_ of the HTML's structure is either encoded _into_ the
    client-side, or re-hydrated with (JSON) data rendered server-side

* Stimulus strikes a balance in applications where HTML structure and styles are
  defined server-side
  - the `data-controller` and `data-action` definitions are determined at
    render-time on the server, and serve as a serialization format for
    client-side event listeners
  - the _content_ of the HTML is available at render-time on the server, but
    unavailable in dynamic responses to event listeners

[It all starts with HTML][].

When HTML serves as their [serialization format][], controllers and views
translate our application's state-of-the-world into a document, transmit that
document over HTTP to browsers that reconstruct it to enable end-users.

With the advent of [Stimulus Action Descriptors][] and [`<turbo-stream>`][Turbo
Stream] elements and their embedded [`<template>`][template] element content,
servers can even encode contingency plans directly into the document's elements.

**Rendering**: client-side, synchronous, immediate, Kinetic energy
**Callbacks**: client-side, asynchronous, deferred, Potential energy
**`<template>`-encoded rendering**: both server- and client-side, asynchronous, deferred, Potential energy

**Value proposition**: You have abstractions and extractions on the server-side,
re-use them to share concepts with the client-side without re-inventing parallel
versions of them.

The server encodes design decisions into the HTML in a way that's durable across
transmission and reconstruction. It controls the structure, content, and
presentation of the message, and the client controls the timing and conditions
of the message's presentation.

[serialization format]: https://en.wikipedia.org/wiki/Serialization
[Stimulus Action Descriptors]: https://stimulus.hotwired.dev/reference/actions#descriptors
[Turbo Stream]: https://turbo.hotwired.dev/handbook/streams

[Stimulus][] controllers [synchronize their state with the document's
HTML][stimulus-state] through [attribute][]-backed [Values][] and
[element][]-backed [Targets][].

Since this interaction is _only_ client-side in the browser, there's an
opportunity to do as much work as possible on the server, to the point where the
client's responsibilities are constrained, and only include appending to and
removing from the document

* co-locates decisions about structure, content, styles, and element references
  in the same server-generated template
* declarative, pre-populated state

[It All Starts With HTML]: https://stimulus.hotwired.dev/handbook/hello-stimulus#it-all-starts-with-html
[Stimulus]: https://stimulus.hotwired.dev/
[stimulus-state]: https://stimulus.hotwired.dev/handbook/managing-state
[attribute]: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes
[element]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element
[Values]: https://stimulus.hotwired.dev/handbook/managing-state#using-values
[Targets]: https://stimulus.hotwired.dev/reference/targets
[template]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/template
[_Building Something Real_]: https://stimulus.hotwired.dev/handbook/building-something-real
[Stimulus Handbook]: https://stimulus.hotwired.dev/handbook/introduction

We'll re-create an example from the [_Building Something Real_][] section of the
[Stimulus Handbook][]. To start, we'll enhance a button to copy an invitation
code to the end-user's clipboard. Next, we'll display a server-rendered alert
message to notify the end-user that they've copied the code. Finally, through
the passage of time, we'll dismiss the alert. Our implementation won't depend on
[XMLHttpRequest][], [fetch][], or any client-side templating.

The interaction will be entirely self-contained. The context encoded directly
into the `<button>` element's attributes and content will guide the behavior.

[XMLHttpRequest]: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
[fetch]: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API

The code samples shared in this article omit the majority of the application's
setup. The initial code was generated by executing `rails new`. The rest of the
[source code][] from this article (including a [suite of tests][]) can be found
on GitHub, and is best read either [commit-by-commit][], or as a [unified
diff][].

[source code]: https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-button-alert-template
[suite of tests]: https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-button-alert-template
[commit-by-commit]: https://github.com/thoughtbot/hotwire-example-template/commits/hotwire-example-button-alert-template
[unified diff]: https://github.com/thoughtbot/hotwire-example-template/compare/hotwire-example-button-alert-template

## Our starting point

`InvitationCodesController#show` serves as our only route. The `#show` action
assigns the value of `params[:id]` into the `@invitation_code` instance
variable. For example, a [`GET
http://localhost:3000/invitation_codes/abc123`][GET-abc123] request would assign
`@invitation_code = "abc123"`:

[GET-abc123]: http://localhost:3000/invitation_codes/abc123

```ruby
# app/controllers/invitation_codes_controller.rb

class InvitationCodesController < ApplicationController
  def show
    @invitation_code = params[:id]
  end
end
```

A more production-ready version might read an invitation code from the database,
or generate one on-the-fly.

The `app/views/invitation_codes/show.html.erb` template renders two `<fieldset>`
elements: the first presents an [`<input readonly>`][input-readonly] to copy the
invitation code out of, and the second presents an `<input>` to paste the code
into:

[input-readonly]: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/readonly

```erb
<%# app/views/invitation_codes/show.html.erb %>

<fieldset>
  <legend>Copy</legend>

  <label>
    Invitation code

    <input value="<%= @invitation_code %>" readonly>
  </label>

  <button type="button" value="<%= @invitation_code %>"
          data-controller="clipboard"
          data-action="click->clipboard#copy">
    Copy to clipboard
  </button>
</fieldset>

<fieldset>
  <legend>Paste</legend>

  <label>
    Invitation code
    <input>
  </label>
</fieldset>

<div id="alerts" class="absolute bottom-0 right-0 w-96"></div>
```

Since we'll be notifying end-user that they've copied the code to their
clipboard, we'll need somewhere to push those messages. We'll render a `<div>`
element at the bottom of the file and mark it with [id="alerts"][id-attr].

[id-attr]: https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/id

The first `<fieldset>` pairs the pre-populated `<input>` element with a
[`<button type="button">`][type="button"] element. The `<button>` [routes
`click` events][stimulus-actions] to a `clipboard` [controller][]. Like
_Building Something Real_'s [`clipboard` controller][example-controller], ours
calls [`navigator.clipboard.writeText`][writeText]:

[type="button"]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#attr-type
[readonly]: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/readonly
[Clipboard's]: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard
[stimulus-actions]: https://stimulus.hotwired.dev/reference/actions
[controller]: https://stimulus.hotwired.dev/reference/controllers
[example-controller]: https://stimulus.hotwired.dev/handbook/building-something-real#connecting-the-action
[writeText]: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText

```javascript
// app/javascript/controllers/clipboard_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  copy({ target: { value } }) {
    navigator.clipboard.writeText(value)
  }
}
```

https://user-images.githubusercontent.com/2575027/154692773-cc91ff39-63e3-4e4e-857d-0657ea39d56e.mov
