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
