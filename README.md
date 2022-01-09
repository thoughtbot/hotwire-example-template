# Hotwire: Dynamic form fields

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-dynamic-form-fields

To start, we'll experiment with JavaScript-free strategies for dynamically
rendering fields with round-trips and full-page navigations. Once we've
established a suitable baseline, we'll experiment with two progressive
enhancement strategies to improve the form's interactivity:

1. rendering _all combinations_ for a form's fields, enabling the appropriate
   fields associated with a selected value, then disabling the others
2. rendering _one combination_ at a time, then fetching a new combination from
   the server when a selected values changes

The code samples contained within omit the majority of the application’s setup.
While reading, know that the application’s baseline code was generated via rails
new. The rest of the [source code][] from this article can be found on GitHub,
and is best read [commit-by-commit][].

[source code]: https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-dynamic-form-fields
[commit-by-commit]: https://github.com/thoughtbot/hotwire-example-template/compare/hotwire-example-dynamic-form-fields

## Our starting point

We'll render a form that collects information about `Building` records. We're
interested in the address and whether it's "owned", "leased", or "other". When
it's "leased", we'll require that the submission includes a management phone
number. When it's "other", we'll require a description. Otherwise, both fields
are optional.

A `Building` record's `country` column will default to the United States (that
is, a `country` attribute with a value of `"US"`). We're relying on the
[city-state][] gem to provide our form with a collection of "Country" and
"State" options.

In addition to validations, the `Building` model class defines an
[enumeration][] and some convenience methods to access Countries and States
provided by the `city-state` gem (invoked about through the `CS` class):

```ruby
class Building < ApplicationRecord
  enum :building_type, owned: 0, leased: 1, other: 2

  with_options presence: true do
    validates :line_1
    validates :line_2
    validates :city
    validates :postal_code
  end

  validates :state, inclusion: { in: -> record { record.states.keys }, allow_blank: true },
                    presence: { if: -> record { record.states.present? } }

  validates :management_phone_number, presence: { if: :leased? }
  validates :building_type_description, presence: { if: :other? }

  def countries
    CS.countries.with_indifferent_access
  end

  def country_name
    countries[country]
  end

  def states
    CS.states(country).with_indifferent_access
  end

  def state_name
    states[state]
  end
end
```

[city-state]: https://github.com/loureirorg/city-state/
[enumeration]: https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html

The `buildings/new` template collects values and submits the `<form>` as a
`POST` request to the `BuildingsController#create` action:

```erb
<%# app/views/buildings/new.html.erb %>

<section class="w-full max-w-lg">
  <h1>New building</h1>

  <%= form_with model: @building do |form| %>
    <%= render partial: "errors", object: @building.errors %>

    <%= field_set_tag "Describe the building" do %>
      <%= form.collection_radio_buttons :building_type, Building.building_types.keys, :to_s, :humanize do |builder| %>
        <span>
          <%= builder.radio_button %>
          <%= builder.label %>
        </span>
      <% end %>
    <% end %>

    <%= field_set_tag "Leased" do %>
      <%= form.label :management_phone_number %>
      <%= form.telephone_field :management_phone_number %>
    <% end %>

    <%= field_set_tag "Address", class: "flex flex-col gap-2" do %>
      <%= form.label :line_1 %>
      <%= form.text_field :line_1 %>

      <%= form.label :line_2 %>
      <%= form.text_field :line_2 %>

      <%= form.label :city %>
      <%= form.text_field :city %>

      <%= form.label :state %>
      <%= form.select :state, @building.states.invert %>

      <%= form.label :postal_code %>
      <%= form.text_field :postal_code %>
    <% end %>

    <%= form.button %>
  <% end %>
</section>
```

![A form collecting information about a Building, including its address and other incidental information](https://user-images.githubusercontent.com/2575027/148697152-195a44fe-906a-4200-b8a2-312c63b67d63.png)

When the submission's data is invalid thecontroller re-renders the
`bulidings#new` template, responds with a [422 Unprocessable Entity][422], and
renders `application/errors` partial. That partial's [source
code](./app/views/application/_errors.html.erb) is omitted here, but it's very
similar to [Rails' scaffolds for new models][scaffolds]:

[422]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/422
[scaffolds]: https://github.com/rails/rails/blob/984c3ef2775781d47efa9f541ce570daa2434a80/railties/lib/rails/generators/erb/scaffold/templates/_form.html.erb.tt#L2-L12

![Validation error messages rendered above the form's fields](https://user-images.githubusercontent.com/2575027/148697211-3599a283-0a8b-4071-b00b-768341e87dfe.png)

When the submission is valid, the record is created, the data is written to the
database, and the controller serves an [HTTP redirect response][redirect] to the
`buildings#show` route:

[redirect]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Redirections

```ruby
# app/controllers/buildings_controller.rb

class BuildingsController < ApplicationController
  def new
    @building = Building.new
  end

  def create
    @building = Building.new building_params

    if @building.save
      redirect_to building_url(@building)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @building = Building.find params[:id]
  end

  private

  def building_params
    params.require(:building).permit(
      :building_type,
      :management_phone_number,
      :line_1,
      :line_2,
      :city,
      :state,
      :postal_code,
    )
  end
end
```

## Interactivity and dynamic options

Our starting point serves as a solid, reliable, and robust foundation. The
"moving parts" are kept to a minimum. The form collects information with or
without the presence of a JavaScript-capable browsing environment.

With that being said, there is still an opportunity to improve the end-user
experience. We'll start with a JavaScript-free baseline, then we'll
progressively the form, adding dynamism and improving its interactivity along
the way.

To start, let's support `Building` record in Countries outside the United
States. We'll add a `<select>` to our provide end-users with a collection of
Country options:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Address", class: "flex flex-col gap-2" do %>
+      <%= form.label :country %>
+      <%= form.select :country, @building.countries.invert %>
+
       <%= form.label :line_1 %>
       <%= form.text_field :line_1 %>
```

Along with the new field, we'll add a matching key name to the
`BuildingsController#building_params` implementation to read the new value from
a submission's parameters:

```diff
--- a/app/controllers/buildings_controller.rb
+++ b/app/controllers/buildings_controller.rb
   def building_params
     params.require(:building).permit(
       :building_type,
       :management_phone_number,
       :building_type_description,
       :line_1,
       :line_2,
       :city,
       :state,
       :postal_code,
+      :country,
     )
   end
 end
```

While the new `<select>` provides an opportunity to pick a different Country,
that choice won't be reflected in the `<form>` element's collection of States.

What tools do we have at our disposal to synchronize the "States" `<select>`
with what's chosen in the "Countries" `<select>`? Could we fetch new `<select>`
and `<option>` elements from the server without without using
[XMLHttpRequest][], [fetch][], or any JavaScript at all?

[XMLHttpRequest]: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
[fetch]: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API

### Fetching remote data without JavaScript

Browsers provide a built-in mechanism to submit HTTP requests without JavaScript
code: `<form>` elements. By clicking `<button>` and `<input type="submit">`
elements, end-users submit `<form>` elements and issue HTTP requests. What's
more, those `<button>` elements are capable of overriding _where_ and _how_ that
`<form>` element transmits its submission by through their [formmethod][] and
[formaction][] attributes.

We'll change our `<form>` to present a "Select country" `<button>` element to
refresh the page's "State" options:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Address", class: "flex flex-col gap-2" do %>
       <%= form.label :country %>
       <%= form.select :country, @building.countries.invert %>
+      <button formmethod="get" formaction="<%= new_building_path %>">Select country</button>

       <%= form.label :line_1 %>
```

The `<button>` element's `[formmethod="get"]` attribute directs the `<form>` to
_submit as_ an [HTTP GET][] request and `[formaction="/buildings/new"]` directs
the `<form>` to _submit to_ the `/buildings/new` path. This pairing of HTTP verb
and path might seem familiar: it's the same pairing of HTTP verb and path that
our browser uses to navigate to the form's page. Submitting `<form>` as a `GET`
request encodes all of its fields' values into [URL parameters][].

We'll change the `BuildingsController#building_params` method to be capable of
reading those values whenever they're available and using them to construct the
`BuildingsController#new` action's `Building` record instance:

```diff
--- a/app/controllers/buildings_controller.rb
+++ b/app/controllers/buildings_controller.rb
 class BuildingsController < ApplicationController
   def new
-    @building = Building.new
+    @building = Building.new building_params
   end

   def create
@@ -20,7 +20,7 @@ class BuildingsController < ApplicationController
   private

   def building_params
-    params.require(:building).permit(
+    params.fetch(:building, {}).permit(
       :building_type,
       :management_phone_number,
       :building_type_description,
       :line_1,
       :line_2,
       :city,
       :state,
       :postal_code,
       :country,
     )
   end
 end
```

https://user-images.githubusercontent.com/2575027/148697350-1051ef05-0671-4c80-b120-88b37d6bfd46.mov

By supporting Countries other than the United States, our form is responsible
for omitting the "State" options whenever the Country doesn't have States (for
example, the British Virgin Islands or Vatican City). We'll add a conditional to
the `buildings/new` template so that the form only includes the `<select>` when
necessary:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
       <%= form.text_field :city %>

+      <% if @building.states.any? %>
         <%= form.label :state %>
         <%= form.select :state, @building.states.invert %>
+      <% end %>

       <%= form.label :postal_code %>
       <%= form.text_field :postal_code %>
```

https://user-images.githubusercontent.com/2575027/148697400-3668ed1d-f2b1-4923-b8ca-3558650eb517.mov

It's worth noting that submitting form values as query parameters comes with two
caveats:

1.  Any selected `<input type="file">` values will be discarded

2.  according to the [HTTP specification][], there are no limits on the length of
    a URI:

    > The HTTP protocol does not place any a priori limit on the length of
    > a URI. Servers MUST be able to handle the URI of any resource they
    > serve, and SHOULD be able to handle URIs of unbounded length if they
    > provide GET-based forms that could generate such URIs.
    >
    > - 3.2.1 General Syntax

    Unfortunately, in practice, [conventional wisdom][] suggests that URLs over
    2,000 characters are risky.

In the case of our example `<form>`, neither points pose significant risk. Forms
that have more fields than ours, or collect fields with the potential to exceed
the 2,000 character limit would benefit from an different submission mechanism.
More on that later!

[HTTP specification]: https://tools.ietf.org/html/rfc2616#section-3.2.1
[conventional wisdom]: https://stackoverflow.com/a/417184
[URL parameters]: https://developer.mozilla.org/en-US/docs/Learn/Common_questions/What_is_a_URL#parameters
[formmethod]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#attr-formmethod
[formaction]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#attr-formaction
[HTTP GET]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET

### Controlling local data without JavaScript

The "Describe the building" collection of `<input type="radio">` elements and
the optional `<input>` elements in their corresponding `<fieldset>` element pose
a similar opportunity. How might we conditionally present (and require!) those
fields based on the current `<input type="radio">` selection?

We can use the `<fieldset>` element's [disabled][fieldset-disabled] attribute to
control whether or not its descendant fields are encoded into the request and
transmitted to the server when the `<form>` is submitted.

The `[disabled]` attribute is a [boolean attribute][], so its presence alone is
enough to omit the element and its descendants. We'll base the presence or
absence on whether or not the `<fieldset>` corresponds to the currently selected
"building type" (i.e. "owned", "leased", and "other"):

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
-    <%= field_set_tag "Leased" do %>
+    <%= field_set_tag "Leased", disabled: !@building.leased? do %>
       <%= form.label :management_phone_number %>
       <%= form.telephone_field :management_phone_number %>
     <% end %>

-    <%= field_set_tag "Other" do %>
+    <%= field_set_tag "Other", disabled: !@building.other? do %>
       <%= form.label :building_type_description %>
       <%= form.text_field :building_type_description %>
     <% end %>
```

Encoding the `[disabled]` attribute into the HTML affords an opportunity to
apply specific styles to the `<fieldset>` when it matches the [:disabled][]
pseudo-class. For example, when the `<fieldset>` is disabled, apply the
[display: none][] rule:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
-    <%= field_set_tag "Leased", disabled: !@building.leased? do %>
+    <%= field_set_tag "Leased", disabled: !@building.leased?, class: "disabled:hidden" do %>
       <%= form.label :management_phone_number %>
       <%= form.telephone_field :management_phone_number %>
     <% end %>

-    <%= field_set_tag "Other", disabled: !@building.other? do %>
+    <%= field_set_tag "Other", disabled: !@building.other?, class: "disabled:hidden" do %>
       <%= form.label :building_type_description %>
       <%= form.text_field :building_type_description %>
     <% end %>
```

Like the pairing of the "Country" and "State" `<select>` elements, this poses an
opportunity for the interface to grow out of synchronization. We can present the
end-user with a "Select type" button, similar to the "Select country" button
we're rendering earlier in the page:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Describe the building" do %>
       <%= form.collection_radio_buttons :building_type, Building.building_types.keys, :to_s, :humanize do |builder| %>
         <span>
           <%= builder.radio_button %>
           <%= builder.label %>
         </span>
       <% end %>
+      <button formmethod="get" formaction="<%= new_building_path %>">Select type</button>
     <% end %>
```

https://user-images.githubusercontent.com/2575027/148697443-1d406296-85a0-41d8-b8d0-f6fd1a3c9c54.mov

Finally, it's important to render the `<input type="radio">` elements with
[autocomplete="off"][] so that browser-initiated optimizations don't introduce
inconsistencies between the initial client-side selection and the
server-rendered selection:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
@@ -7,18 +7,19 @@
     <%= field_set_tag "Describe the building" do %>
       <%= form.collection_radio_buttons :building_type, Building.building_types.keys, :to_s, :humanize do |builder| %>
         <span>
-          <%= builder.radio_button %>
+          <%= builder.radio_button autocomplete: "off" %>
           <%= builder.label %>
         </span>
       <% end %>
       <button formmethod="get" formaction="<%= new_building_path %>">Select type</button>
     <% end %>
```

[fieldset-disabled]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/fieldset#attr-disabled
[boolean attribute]: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes#boolean_attributes
[:disabled]: https://developer.mozilla.org/en-US/docs/Web/CSS/:disabled
[display: none]: https://developer.mozilla.org/en-US/docs/Web/CSS/display#box
[autocomplete="off"]: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete#values

### Controlling local data with JavaScript

Now that we've established a baseline foundation of JavaScript-free
improvements, there are opportunities to [progressively enhance][] those
experience. In the case of our `<input type"radio">` collection, we can toggle
the visibility of their corresponding `<fieldset>` elements, and so that the
end-user choices are reflected locally without additional form submissions to
the server.

To preserve our JavaScript-free behavior, we'll nest the `<button
formmethod="get">` in a [`<noscript>` element][noscript] so that it's present
with JavaScript is disabled and absent otherwise:

[noscript]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/noscript

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Describe the building" do %>
       <%= form.collection_radio_buttons :building_type, Building.building_types.keys, :to_s, :humanize do |builder| %>
         <span>
           <%= builder.radio_button autocomplete: "off" %>
           <%= builder.label %>
         </span>
       <% end %>
+      <noscript>
         <button formmethod="get" formaction="<%= new_building_path %>">Select type</button>
+      </noscript>
     <% end %>
```

Next, we'll create our application's first [Stimulus Controller][]. We'll modify
our `<form>` element to declare the `[data-controller="fields"]` attribute. The
`fields` token corresponds to our new controller's [identifier][]:

[progressively enhance]: https://developer.mozilla.org/en-US/docs/Glossary/Progressive_Enhancement
[Stimulus Controller]: https://stimulus.hotwired.dev/handbook/hello-stimulus#controllers-bring-html-to-life
[identifier]: https://stimulus.hotwired.dev/reference/controllers#identifiers

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
 <section class="w-full max-w-lg">
   <h1>New building</h1>

-  <%= form_with model: @building do |form| %>
+  <%= form_with model: @building, data: { controller: "fields" } do |form| %>
     <%= render partial: "errors", object: @building.errors %>

     <%= field_set_tag "Describe the building" do %>
```

To listen for changes in selection, we'll route [input][] events to our `fields`
controller by annotating each `<input type="radio">` element with the
`[data-action="input->fields#enable"]` attribute:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
       <%= form.collection_radio_buttons :building_type, Building.building_types.keys, :to_s, :humanize do |builder| %>
         <span>
-          <%= builder.radio_button autocomplete: "off" %>
+          <%= builder.radio_button autocomplete: "off",
+                                   data: { action: "input->fields#enable" } %>
           <%= builder.label %>
         </span>
       <% end %>
```

The `[data-action]` attribute's value is a [Stimulus Action][] descriptor, which
instructs Stimulus on how to respond to `input` events that fire within the
document.

[input]: https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/input_event
[Stimulus Action]: https://stimulus.hotwired.dev/reference/actions

The `fields#enable` implementation reads the `<input type="radio">` element's
[name][] and [aria-controls][] attributes and finds `<fieldset>` elements with
corresponding attributes. We'll mark each `<fieldset>` with the
[disabled][fieldset-disabled], then remove the attribute for the `<fieldset>`
whose `[name]` matches the `<input type="radio">` element's `[name]`, and whose
`[id]` matches the `<input type="radio">` element's `[aria-controls]`:

[name]:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input#attr-name
[aria-controls]: https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-controls

```javascript
// app/javascript/controllers/fields_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  enable({ target }) {
    const elements = Array.from(this.element.elements)
    const selectedElements = [ target ]

    for (const element of elements.filter(element => element.name == target.name)) {
      if (element instanceof HTMLFieldSetElement) element.disabled = true
    }

    for (const element of controlledElements(...selectedElements)) {
      if (element instanceof HTMLFieldSetElement) element.disabled = false
    }
  }
}

function controlledElements(...selectedElements) {
  return selectedElements.flatMap(selectedElement =>
    getElementsByTokens(selectedElement.getAttribute("aria-controls"))
  )
}

function getElementsByTokens(tokens) {
  const ids = (tokens ?? "").split(/\s+/)

  return ids.map(id => document.getElementById(id))
}
```

To ensure the relationship between the `<input type="radio">` elements and their
corresponding `<fieldset>` elements, we'll update our `buildings/new` template
to encode those values during rendering:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Describe the building" do %>
       <%= form.collection_radio_buttons :building_type, Building.building_types.keys, :to_s, :humanize do |builder| %>
         <span>
           <%= builder.radio_button autocomplete: "off",
+                                   aria: { controls: form.field_id(:building_type, builder.value, :fieldset) },
                                    data: { action: "input->fields#enable" } %>
           <%= builder.label %>
         </span>
       <% end %>
       <noscript>
         <button formmethod="get" formaction="<%= new_building_path %>">Select type</button>
       </noscript>
     <% end %>

-    <%= field_set_tag "Leased", disabled: !@building.leased?, class: "disabled:hidden" do %>
+    <%= field_set_tag "Leased", disabled: !@building.leased?, class: "disabled:hidden",
+                                id: form.field_id(:building_type, :leased, :fieldset),
+                                name: form.field_name(:building_type) do %>
       <%= form.label :management_phone_number %>
       <%= form.telephone_field :management_phone_number %>
     <% end %>

-    <%= field_set_tag "Other", disabled: !@building.other?, class: "disabled:hidden" do %>
+    <%= field_set_tag "Other", disabled: !@building.other?, class: "disabled:hidden",
+                               id: form.field_id(:building_type, :other, :fieldset),
+                               name: form.field_name(:building_type) do %>
       <%= form.label :building_type_description %>
       <%= form.text_field :building_type_description %>
     <% end %>
```

https://user-images.githubusercontent.com/2575027/148697502-24076160-603c-4c52-ad6b-aa8163def4f9.mov

While `<input type="radio">` elements are an appropriate choice for our set of
three possible choices, it's worthwhile to consider how we might handle a larger
set of choices. A natural progression might involve replacing the `<input
type="radio">` buttons with a `<select>`:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Describe the building" do %>
-      <%= form.collection_radio_buttons :building_type, Building.building_types.keys, :to_s, :humanize do |builder| %>
-        <span>
-          <%= builder.radio_button autocomplete: "off",
-                                   aria: { controls: form.field_id(:building_type, builder.value, :fieldset) },
-                                   data: { action: "input->fields#enable" } %>
-          <%= builder.label %>
-        </span>
+      <%= form.label :building_type %>
+      <%= form.select :building_type, {}, {}, autocomplete: "off",
+                      data: { action: "change->fields#enable" } do %>
+        <% Building.building_types.keys.each do |value| %>
+          <%= tag.option value.humanize, value: value,
+                         aria: { controls: form.field_id(:building_type, value, :fieldset) } %>
+        <% end %>
       <% end %>
```

Since it's possible for a `<select>` to have multiple "selected" options, we'd
need to account for that possibility in the `fields` controller:

```diff
--- a/app/javascript/controllers/fields_controller.js
+++ b/app/javascript/controllers/fields_controller.js
@@ -2,7 +2,9 @@ import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
   enable({ target }) {
-    const selectedElements = [ target ]
+    const selectedElements = "selectedOptions" in target ?
+      target.selectedOptions :
+      [ target ]

     for (const field of this.element.elements.namedItem(target.name)) {
       if (field instanceof HTMLFieldSetElement) field.disabled = true
```

https://user-images.githubusercontent.com/2575027/148697637-ea9512ae-0fee-4a7d-b0d2-065839f3b3b4.mov

## Fetching remote data with JavaScript

While it might be tempting to deploy this same strategy for our "Country" and
"State" `<select>` element pairing, rendering all possible combinations of
Country and State would be far too expensive:

```ruby
irb(main):001:0> country_codes = CS.countries.keys
=>
[:AD,
...
irb(main):002:0> country_codes.flat_map { |code| CS.states(code).keys }.count
=> 3391
```

Instead, we can render a single pairing of Country and State values, then fetch
a new pair when the `<select>` element's selected options change.

A `<button formmethod="get">` element powers the original (JavaScript-free)
version of State options fetching. End-users manually click the `<button>` to
fetch new options. In cases where the visiting browsing environment has
JavaScript disabled, we'll continue to support that behavior.

To do so, we'll nest the `<button>` within a [`<noscript>` element][noscript] so
that it's present with JavaScript enabled, but absent otherwise:

[noscript]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/noscript

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Address", class: "flex flex-col gap-2" do %>
       <%= form.label :country %>
       <%= form.select :country, @building.countries.invert %>
+      <noscript>
         <button formmethod="get" formaction="<%= new_building_path %>">Select country</button>
+      </noscript>

       <%= form.label :line_1 %>
       <%= form.text_field :line_1 %>
```

In it's place, we'll introduce a visually-hidden `<input type="submit">`
counterpart that our application's JavaScript code will programmatically click
on the end-user's behalf:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Address", class: "flex flex-col gap-2" do %>
       <%= form.label :country %>
       <%= form.select :country, @building.countries.invert %>
+
+      <input type="submit" formmethod="get" formaction="<%= new_building_path %>" hidden>
       <noscript>
         <button formmethod="get" formaction="<%= new_building_path %>">Select country</button>
       </noscript>
```

We'll introduce a Stimulus controller to monitor changes to the `<select>`
element's selected options. Whenever a [change][] event fires on the `<select>`
element, we'll programmatically click the `<input type="submit">`.

To scope the event monitoring to this cluster of fields, we'll nest the
`<label>`, `<select>`, and `<input type="submit">` elements within a `<div
data-controller="element">` element. We'll declare the `<div>` to have
[`display: contents`][contents] so that its descendants can continue to
participate in the `<fieldset>` element's flexbox layout:

[contents]: https://developer.mozilla.org/en-US/docs/Web/CSS/display#box
[change]: https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/change_event

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Address", class: "flex flex-col gap-2" do %>
+      <div class="contents" data-controller="element">
         <%= form.label :country %>
         <%= form.select :country, @building.countries.invert %>

         <input type="submit" formmethod="get" formaction="<%= new_building_path %>" hidden>
         <noscript>
           <button formmethod="get" formaction="<%= new_building_path %>">Select country</button>
         </noscript>
+      </div>
```

Next, we'll mark the `<input type="submit">` element with the
`[data-element-target="click"]` attribute so that the `element` controller can
access the element directly. We'll also route `change` events fired by the
`<select>` element to the `element#click` action:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
     <%= field_set_tag "Address", class: "flex flex-col gap-2" do %>
       <div class="contents" data-controller="element">
         <%= form.label :country %>
-        <%= form.select :country, @building.countries.invert %>
+        <%= form.select :country, @building.countries.invert, {},
+                        data: { action: "change->element#click" } %>

-        <input type="submit" formmethod="get" formaction="<%= new_building_path %>" hidden>
+        <input type="submit" formmethod="get" formaction="<%= new_building_path %>" hidden
+               data-element-target="click">
         <noscript>
           <button formmethod="get" formaction="<%= new_building_path %>">Select country</button>
         </noscript>
       </div>
```

The `element` controller's implementation is minimal and extremely specific.
Clicking its "click" targets is its one and only behavior:

```javascript
// app/javascript/controllers/element_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "click" ]

  click() {
    this.clickTargets.forEach(target => target.click())
  }
}
```

Similar to our `<input type="radio">` monitoring implmentation, it's important
to render the `<select>` element with [autocomplete="off"][] so that
browser-initiated optimizations don't introduce inconsistencies between the
initial client-side selection and the server-rendered selection:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
         <%= form.label :country %>
-        <%= form.select :country, @building.countries.invert, {},
+        <%= form.select :country, @building.countries.invert, {}, autocomplete: "off",
                         data: { action: "change->element#click" } %>

         <input type="submit" formmethod="get" formaction="<%= new_building_path %>" hidden
                data-element-target="click">
```

https://user-images.githubusercontent.com/2575027/148697670-29b8dde5-2ce4-40a7-943e-23cdb68b3dd5.mov

## Fetching remote data with Turbo Frames

While we've enhanced our JavaScript-free solution for maintaining
synchronization between the "Country" and "State" `<select>` elements, there are
still some quirks to improve.

For example, because the `<form>` submission triggers a full-page navigation,
our application will discard any client-side state like, which element has focus
or how far down the page the end-user has scrolled. Ideally, a change to the
"Country" `<select>` element's current option would fetch and replace an HTML
fragment that _only_ contained the "State" `<select>` element, and left the rest
of the page undisturbed.

Lucky for us, [Turbo Frames][] are well suited for that purpose! Through the
[`<turbo-frame>`][] custom element (and its [src][turbo-frame-src] attribute),
our application can manage fragments of our document asynchronously.

We can scope our "Country" `<select>`-driven requests the portion of our from that contains the "State" `<select>` and `<label>` elements.

First, we'll wrap the "State" portion of the form in a
[`<turbo-frame>`][turbo-frame] element, and assign it an `[id]` attribute that
is unique across the document:

[Turbo Frames]: https://turbo.hotwired.dev/handbook/frames
[turbo-frame]: https://turbo.hotwired.dev/reference/frames#basic-frame
[turbo-frame-src]: https://turbo.hotwired.dev/reference/frames#html-attributes
[FrameElement]: https://turbo.hotwired.dev/reference/frames#properties
[data-turbo-frame]: https://turbo.hotwired.dev/handbook/frames#targeting-navigation-into-or-out-of-a-frame

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
       <%= form.label :city %>
       <%= form.text_field :city %>

+      <turbo-frame id="<%= form.field_id(:state, :turbo_frame) %>" class="contents">
         <% if @building.states.any? %>
           <%= form.label :state %>
           <%= form.select :state, @building.states.invert %>
         <% end %>
+      </turbo-frame>

       <%= form.label :postal_code %>
       <%= form.text_field :postal_code %>
```

There are several ways to navigate the frame. For example, if it better suits
your use-case, you can retrieve the [FrameElement][] instance, and interact with
the `[src]` property directly.

Since we're already rendering an `<input type="submit">` element that
declaratively encodes all the pertinent, concrete details of the submission (for
example, the `[formmethod]` and `[formaction]` attributes), we'll rely on the
fact that we're programmatically clicking the `<input type="submit">` element.

Not only does the `<input type="submit">` encode _where_ and _how_ to make our
submission, the browser's built-in form field encoding mechanisms to control
_what_ to include in the submission.

To target and drive the `<turbo-frame>` element, we'll render the `<input
type="submit">` element with a [data-turbo-frame][] attribute that references
the `<turbo-frame>` element's `[id]` attribute:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
         <input type="submit" formmethod="get" formaction="<%= new_building_path %>" hidden
-               data-element-target="click">
+               data-element-target="click" data-turbo-frame="<%= form.field_id(:state, :turbo_frame) %>">
         <noscript>
           <button formmethod="get" formaction="<%= new_building_path %>">Select country</button>
         </noscript>
```

With those enhancements in place, changes to the "Country" `<select>` element
refreshes the "State" `<select>` element's collection of options while
retaining client-side state like which element is focused (in this case, the
"Country" `<select>` _retains_ focus throughout), and how far down the page the
user has scrolled:

https://user-images.githubusercontent.com/2575027/148697719-3c524202-c1dd-4aa9-80d2-215a409d2fd3.mov

Now that we're navigating a fragment of the page, there's an opportunity to
reduce the amount of data we're encoding into the `GET` request. In our
example's case, we're unlikely to exceed the URL's 2,000 character limit.
However, that might not be true for every use case. As an alternative to
submitting _all_ of the `<form>` element's fields' data to the `<turbo-frame>`,
we'll introduce a `search-params` controller to only encode the _changed_
field's data into an `<a>` element's [href][] attribute.

[href]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a#attr-href

First, we'll replace the visually hidden `<input type="submit">` with a visually
hidden `<a>` element, and mark that element with the
`[data-search-params-target="anchor"]` attribute:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
       <div class="contents" data-controller="element">
         <%= form.label :country %>
         <%= form.select :country, @building.countries.invert, {}, autocomplete: "off",
                         data: { action: "change->element#click" } %>

-        <input type="submit" formmethod="get" formaction="<%= new_building_path %>" hidden
-               data-element-target="click" data-turbo-frame="<%= form.field_id(:state, :turbo_frame) %>">
+        <a href="<%= new_building_path %>" data-search-params-target="anchor" hidden
+               data-element-target="click" data-turbo-frame="<%= form.field_id(:state, :turbo_frame) %>"></a>
         <noscript>
           <button formmethod="get" formaction="<%= new_building_path %>">Select country</button>
         </noscript>
```

In our template, we can add `search-params` to the list of tokens declared on
our `<div data-controller="element">` element. In this case, the order that the
tokens are declared is not significant:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
-      <div class="contents" data-controller="element">
+      <div class="contents" data-controller="search-params element">
         <%= form.label :country %>
         <%= form.select :country, @building.countries.invert, {}, autocomplete: "off",
                         data: { action: "change->element#click" } %>

         <a href="<%= new_building_path %>" data-search-params-target="anchor" hidden
                data-element-target="click" data-turbo-frame="<%= form.field_id(:state, :turbo_frame) %>"></a>
```

Next, we'll add a `change->search-params#encode` action routing descriptor to
the `<select>` element's `[data-action]` attribute:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
       <div class="contents" data-controller="search-params element">
         <%= form.label :country %>
         <%= form.select :country, @building.countries.invert, {}, autocomplete: "off",
-                        data: { action: "change->element#click" } %>
+                        data: { action: "change->search-params#encode change->element#click" } %>

         <a href="<%= new_building_path %>" data-search-params-target="anchor" hidden
                data-element-target="click" data-turbo-frame="<%= form.field_id(:state, :turbo_frame) %>"></a>
```

The order that the tokens are declared **is significant**. According to the
Stimulus documentation for [declaring multiple actions][multiple-actions]:

> When an element has more than one action for the same event, Stimulus invokes
> the actions from left to right in the order that their descriptors appear.

In our case, we need `search-params#encode` to precede `element#click`, so that
the value is encoded into the `<a href="...">` attribute before we navigate the
related `<turbo-frame>` element.

[multiple-actions]: https://stimulus.hotwired.dev/reference/actions#multiple-actions

The `search-params` controller's `encode` action transforms the target element's
`name` and `value` properties into a [URLSearchParams][] instance's key-value
pair, then assigns it to the [HTMLAnchorElement.search][] property across its
collection of `anchorTargets`:

[URLSearchParams]: https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams
[HTMLAnchorElement.search]: https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/search

```javascript
// app/javascript/controllers/search_params_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "anchor" ]

  encode({ target: { name, value } }) {
    for (const anchor of this.anchorTargets) {
      anchor.search = new URLSearchParams({ [name]: value })
    }
  }
}
```

With those changes in place, the `<a>` element's `[href]` attribute only encodes
the pertinent values (e.g. `/buildings/new?building%5Bcountry%5D=US`).

## Controlling local data with Turbo Streams

To push our feature set one step further, imagine if our form needed to include
a server-side calculation that factored-in the `Building` record's Country (for
example, an estimated arrival date).

How might we incorporate a new piece of dynamic data into our existing set of
enhancements?

Consider a `buildings/building` view partial to surface our server-side
calculation:

```erb
<%# app/views/buildings/_building.html.erb %>

<div id="<%= dom_id(building) %>">
  <p>Estimated arrival: <%= distance_of_time_in_words_to_now building.estimated_arrival_on %> from now.</p>
</div>
```

We'll render the partial at the bottom of the form, as a sibling to the
`<turbo-frame>`:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
           <%= form.select :state, @building.states.invert %>
         <% end %>
       </turbo-frame>

       <%= form.label :postal_code %>
       <%= form.text_field :postal_code %>
+
+      <%= render partial: "buildings/building", object: @building %>
     <% end %>

     <%= form.button %>
```

Unfortunately, since the changes to the page are constrained to the
`<turbo-frame>` element that contains the "State" `<select>`, the estimated
arrival text will be incorrect whenever the client-side "Country" selection
changes.

While it might be tempting to reach for [XMLHttpRequest][] or [fetch][] to
refresh the data, there's an opportunity to utilize another Turbo-provided
custom element: the [`<turbo-stream>`][turbo-stream].

Most of the fanfare for Turbo Streams is in in the context of Web Socket
broadcasts or Form Submissions. While Turbo Streams can be extremely useful in
those situations, the `<turbo-stream>` element can be rendered directly into the
document like any other HTML element. We'll leverage that fact by rendering a
`<turbo-stream>` element within our "States" `<turbo-frame>` element.

[turbo-stream]: https://turbo.hotwired.dev/handbook/streams#stream-messages-and-actions

We'll rely on the content refresh mechanisms we've been constructing thus far to
drive the `<turbo-frame>` element. When the `<turbo-frame>` "navigates" and
fetches new content, that content will include a `<turbo-stream>` element that
encodes an operation to modify the content of the document.

We'll render a declarative [Element.replaceWith()][] command as a
`<turbo-stream>` element through the [action="replace"][] attribute, and we'll
nest the new document fragment within a [`<template>`][template] element:

[replaceWith]: https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceWith
[template]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/template

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
@@ -58,6 +58,9 @@
           <%= form.select :state, @building.states.invert %>
         <% end %>
         <%= turbo_stream.replace dom_id(@building), partial: "buildings/building", object: @building %>
+        <turbo-stream target="<%= dom_id(@building) %>" action="replace">
+          <template><%= render partial: "buildings/building", object: @building %></template>
+        </turbo-stream>
       </turbo-frame>

       <%= form.label :postal_code %>
```

Since the contents of the `<turbo-stream>` element's nested `<template>` renders
the `buildings/building` partial, we can replace the HTML version with a call to
the [`turbo_stream.replace`][turbo_stream_helper] provided by Turbo Rails:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
           <%= form.select :state, @building.states.invert %>
         <% end %>
-        <turbo-stream target="<%= dom_id(@building) %>" action="replace">
-          <template><%= render partial: "buildings/building", object: @building %></template>
-        </turbo-stream>
+        <%= turbo_stream.replace dom_id(@building), partial: "buildings/building", object: @building %>
       </turbo-frame>
```

With that change in place, driving the `<turbo-frame>` element replaces its own
content with a new set of "State" options, _and_ it replaces content elsewhere
in the document, all without discarding other client-side state like focus or
scroll:

https://user-images.githubusercontent.com/2575027/148697842-3bfad620-98da-449a-a582-403055fe4b42.mov

The `turbo_stream.replace` call accepts the same options as the
[`render`][render] call, and supports the same
[`to_partial_path`][to_partial_path]-reliant short-hand notation:

```diff
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
           <%= form.select :state, @building.states.invert %>
         <% end %>
-        <%= turbo_stream.replace dom_id(@building), partial: "buildings/building", object: @building %>
+        <%= turbo_stream.replace @building %>
       </turbo-frame>

       <%= form.label :postal_code %>
       <%= form.text_field :postal_code %>
     <% end %>

-    <%= render partial: "buildings/building", object: @building %>
+    <%= render @building %>

     <%= form.button %>
   <% end %>
```

[action="replace"]: https://turbo.hotwired.dev/reference/streams#replace
[XMLHttpRequest]: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
[fetch]: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API
[Custom Element]: https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_custom_elements
[turbo_stream_helper]: https://github.com/hotwired/turbo-rails/blob/v1.0.0/app/models/turbo/streams/tag_builder.rb#L53-L61
[render]: https://edgeapi.rubyonrails.org/classes/ActionView/Helpers/RenderingHelper.html#method-i-render
[to_partial_path]: https://guides.rubyonrails.org/layouts_and_rendering.html#passing-local-variables

## Wrapping up

<details>
  <summary>The total diff:</summary>

```diff
diff --git a/app/controllers/buildings_controller.rb b/app/controllers/buildings_controller.rb
index 8cb6c6e..3b4e6b0 100644
--- a/app/controllers/buildings_controller.rb
+++ b/app/controllers/buildings_controller.rb
@@ -1,6 +1,6 @@
 class BuildingsController < ApplicationController
   def new
-    @building = Building.new
+    @building = Building.new building_params
   end

   def create
@@ -20,7 +20,7 @@ class BuildingsController < ApplicationController
   private

   def building_params
-    params.require(:building).permit(
+    params.fetch(:building, {}).permit(
       :building_type,
       :management_phone_number,
       :building_type_description,
@@ -29,6 +29,7 @@ class BuildingsController < ApplicationController
       :city,
       :state,
       :postal_code,
+      :country,
     )
   end
 end
diff --git a/app/javascript/controllers/element_controller.js b/app/javascript/controllers/element_controller.js
new file mode 100644
index 0000000..87fd306
--- /dev/null
+++ b/app/javascript/controllers/element_controller.js
@@ -0,0 +1,9 @@
+import { Controller } from "@hotwired/stimulus"
+
+export default class extends Controller {
+  static get targets() { return [ "click" ] }
+
+  click() {
+    this.clickTargets.forEach(target => target.click())
+  }
+}
diff --git a/app/javascript/controllers/fields_controller.js b/app/javascript/controllers/fields_controller.js
new file mode 100644
index 0000000..932b270
--- /dev/null
+++ b/app/javascript/controllers/fields_controller.js
@@ -0,0 +1,30 @@
+import { Controller } from "@hotwired/stimulus"
+
+export default class extends Controller {
+  enable({ target }) {
+    const elements = Array.from(this.element.elements)
+    const selectedElements = "selectedOptions" in target ?
+      target.selectedOptions :
+      [ target ]
+
+    for (const element of elements.filter(element => element.name == target.name)) {
+      if (element instanceof HTMLFieldSetElement) element.disabled = true
+    }
+
+    for (const element of controlledElements(...selectedElements)) {
+      if (element instanceof HTMLFieldSetElement) element.disabled = false
+    }
+  }
+}
+
+function controlledElements(...selectedElements) {
+  return selectedElements.flatMap(selectedElement =>
+    getElementsByTokens(selectedElement.getAttribute("aria-controls"))
+  )
+}
+
+function getElementsByTokens(tokens) {
+  const ids = (tokens ?? "").split(/\s+/)
+
+  return ids.map(id => document.getElementById(id))
+}
diff --git a/app/javascript/controllers/search_params_controller.js b/app/javascript/controllers/search_params_controller.js
new file mode 100644
index 0000000..b190b1d
--- /dev/null
+++ b/app/javascript/controllers/search_params_controller.js
@@ -0,0 +1,11 @@
+import { Controller } from "@hotwired/stimulus"
+
+export default class extends Controller {
+  static get targets() { return [ "anchor" ] }
+
+  encode({ target: { name, value } }) {
+    for (const anchor of this.anchorTargets) {
+      anchor.search = new URLSearchParams({ [name]: value })
+    }
+  }
+}
diff --git a/app/models/building.rb b/app/models/building.rb
index 81cb5b8..ffacc5d 100644
--- a/app/models/building.rb
+++ b/app/models/building.rb
@@ -29,4 +29,8 @@ class Building < ApplicationRecord
   def state_name
     states[state]
   end
+
+  def estimated_arrival_on
+    countries.keys.index(country).days.from_now
+  end
 end
diff --git a/app/views/buildings/_building.html.erb b/app/views/buildings/_building.html.erb
new file mode 100644
index 0000000..0d56cf1
--- /dev/null
+++ b/app/views/buildings/_building.html.erb
@@ -0,0 +1,3 @@
+<div id="<%= dom_id(building) %>">
+  <p>Estimated arrival: <%= distance_of_time_in_words_to_now building.estimated_arrival_on %> from now.</p>
+</div>
diff --git a/app/views/buildings/new.html.erb b/app/views/buildings/new.html.erb
index 9c6641e..6c58944 100644
--- a/app/views/buildings/new.html.erb
+++ b/app/views/buildings/new.html.erb
@@ -1,29 +1,50 @@
 <section class="w-full max-w-lg">
   <h1>New building</h1>

-  <%= form_with model: @building do |form| %>
+  <%= form_with model: @building, data: { controller: "fields" } do |form| %>
     <%= render partial: "errors", object: @building.errors %>

     <%= field_set_tag "Describe the building" do %>
-      <%= form.collection_radio_buttons :building_type, Building.building_types.keys, :to_s, :humanize do |builder| %>
-        <span>
-          <%= builder.radio_button %>
-          <%= builder.label %>
-        </span>
+      <%= form.label :building_type %>
+      <%= form.select :building_type, {}, {}, autocomplete: "off",
+                      data: { action: "change->fields#enable" } do %>
+        <% Building.building_types.keys.each do |value| %>
+          <%= tag.option value.humanize, value: value,
+                         aria: { controls: form.field_id(:building_type, value, :fieldset) } %>
         <% end %>
       <% end %>
+      <noscript>
+        <button formmethod="get" formaction="<%= new_building_path %>">Select type</button>
+      </noscript>
+    <% end %>

-    <%= field_set_tag "Leased" do %>
+    <%= field_set_tag "Leased", disabled: !@building.leased?, class: "disabled:hidden",
+                                id: form.field_id(:building_type, :leased, :fieldset),
+                                name: form.field_name(:building_type) do %>
       <%= form.label :management_phone_number %>
       <%= form.telephone_field :management_phone_number %>
     <% end %>

-    <%= field_set_tag "Other" do %>
+    <%= field_set_tag "Other", disabled: !@building.other?, class: "disabled:hidden",
+                               id: form.field_id(:building_type, :other, :fieldset),
+                               name: form.field_name(:building_type) do %>
       <%= form.label :building_type_description %>
       <%= form.text_field :building_type_description %>
     <% end %>

     <%= field_set_tag "Address", class: "flex flex-col gap-2" do %>
+      <div class="contents" data-controller="search-params element">
+        <%= form.label :country %>
+        <%= form.select :country, @building.countries.invert, {}, autocomplete: "off",
+                        data: { action: "change->search-params#encode change->element#click" } %>
+
+        <a href="<%= new_building_path %>" data-search-params-target="anchor" hidden
+               data-element-target="click" data-turbo-frame="<%= form.field_id(:state, :turbo_frame) %>"></a>
+        <noscript>
+          <button formmethod="get" formaction="<%= new_building_path %>">Select country</button>
+        </noscript>
+      </div>
+
       <%= form.label :line_1 %>
       <%= form.text_field :line_1 %>

@@ -33,13 +54,20 @@
       <%= form.label :city %>
       <%= form.text_field :city %>

+      <turbo-frame id="<%= form.field_id(:state, :turbo_frame) %>" class="contents">
+        <% if @building.states.any? %>
           <%= form.label :state %>
           <%= form.select :state, @building.states.invert %>
+        <% end %>
+        <%= turbo_stream.replace @building %>
+      </turbo-frame>

       <%= form.label :postal_code %>
       <%= form.text_field :postal_code %>
     <% end %>

+    <%= render @building %>
+
     <%= form.button %>
   <% end %>
 </section>
```

</details>

We were able to progressively enhance while keeping all the details of our
requests declaratively encoded into the document's HTML.

While our example never called for us to make [XMLHttpRequest][] or [fetch][]
requests directly, there might be situations that arise that require more
bespoke JavaScript. For example, it might behoove us to synthesize a `<form>`
element outside the scope of the current `<form>` in the same way as
`@rails/ujs`-powered [remote fields][], or we might want to encode a subset of a
`<form>` element's values into a URL's [searchParams][] instance.

Regardless of the situations constraints, we should start our problem solving
with the help of browsers' built-in, HTML Specification-compliant features.

[remote fields]: https://guides.rubyonrails.org/working_with_javascript_in_rails.html#data-url-and-data-params
[searchParams]: https://developer.mozilla.org/en-US/docs/Web/API/URL/searchParams
