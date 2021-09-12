# Turbo Frame-powered nested attributes

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-turbo-frame-powered-nested-attributes

## Our starting point

This branch will demonstrate the process of [progressively enhancing][] a
foundation built on form submissions, URL parameters, and HTTP requests. If
you're interested in exploring alternatives that don't rely on HTTP, read the
[hotwire-example-template-powered-nested-attributes][] branch.

[progressively enhancing]: https://developer.mozilla.org/en-US/docs/Glossary/Progressive_Enhancement
[hotwire-example-template-powered-nested-attributes]: https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-template-powered-nested-attributes

Our models:

```ruby
# app/model/applicant.rb

class Applicant < ApplicationRecord
  has_many :references

  accepts_nested_attributes_for :references, allow_destroy: true

  validates_associated :references

  with_options presence: true do
    validates :name
    validates :references
  end
end

# app/models/reference.rb

class Reference < ApplicationRecord
  belongs_to :applicant

  with_options presence: true do
    validates :name
    validates :email_address
  end
end
```

```ruby
# app/controllers/applicants_controller.rb

class ApplicantsController < ApplicationController
  def new
    @applicant = Applicant.new
    @applicant.references.new
  end

  def create
    @applicant = Applicant.new applicant_params

    if @applicant.save
      redirect_to applicant_url(@applicant)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @applicant = Applicant.find params[:id]
  end

  def edit
    @applicant = Applicant.find params[:id]
  end

  def update
    @applicant = Applicant.find params[:id]

    if @applicant.update applicant_params
      redirect_to applicant_url(@applicant)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def applicant_params
    params.require(:applicant).permit(
      :name,
      references_attributes: [ :name, :email_address, :id, :_destroy ],
    )
  end
end
```

Our view templates:

```erb
<%# app/views/applicants/new.html.erb %>

<%= form_with model: @applicant, class: "grid gap-2" do |form| %>
  <%= render partial: "form", object: form %>
<% end %>

<%# app/views/applicants/edit.html.erb %>

<%= form_with model: @applicant, class: "grid gap-2" do |form| %>
  <%= render partial: "form", object: form %>
<% end %>
```

The `app/views/applicants/_form.html.erb` view partial:

```erb
<%# app/views/applicants/_form.html.erb %>

<fieldset>
  <legend>Applicant</legend>

  <%= form.label :name %>
  <%= form.text_field :name %>
</fieldset>

<fieldset>
  <legend>Personal references</legend>

  <ol>
    <% form.object.references.each_with_index do |reference, index| %>
      <%= form.fields :references_attributes, model: reference, index: index do |reference_form| %>
        <li <%= "hidden" if reference_form.object.marked_for_destruction? %> class="mt-2">
          <div class="grid gap-2">
            <%= reference_form.hidden_field :id %>
            <%= reference_form.hidden_field :_destroy %>

            <%= reference_form.label :name %>
            <%= reference_form.text_field :name %>

            <%= reference_form.label :email_address %>
            <%= reference_form.email_field :email_address %>
          </div>
        </li>
      <% end %>
    <% end %>
  </ol>
</fieldset>

<%= form.button %>
```

<img  src="https://images.thoughtbot.com/blog-vellum-image-uploads/YL51hm7cRtm1Y5kGqJOR_nested-attributes-edit.png"
      alt="A form to edit an Applicant and their personal references">
