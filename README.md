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
submit as an [HTTP GET][] request and the `[formaction="/buildings/new"]`
attribute directs the `<Form>` to submit to the `/buildings/new` path. This
verb-path pairing might seem familiar: it's the same request our browser will
make when we visit the current page.

Submitting `<form>` as a `GET` request will encode all of the fields' values
into [URL parameters][]. We can read those values in our `buildings#new` action
whenever they're provided, and use them when rendering the `<form>` element and
its fields:

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

It's worth noting that there are countries that don't have "State" options (like
Vatican City), so we'll also want to account for that case in our
`buildings/new` template:

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

Submitting the form's values as query parameters comes with two caveats:

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

In the case of our simple example `<form>`, neither points pose any risk.

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

First, to control whether or not the values are submitted to the server, we can
conditionally render them with the [disabled][fieldset-disabled] attribute.

We can base the presence or absence of the attribute on the selected value
(which is read from a URL parameter or defaults to "Owned"):

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

Next, we can control whether or not the `<fieldset>` element is visible based on
whether or not it matches the [:disabled][] pseudo-class:

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
[:disabled]: https://developer.mozilla.org/en-US/docs/Web/CSS/:disabled
[autocomplete="off"]: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete#values
