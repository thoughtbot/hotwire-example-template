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

## Adding nested fields

```diff
--- a/app/controllers/applicants_controller.rb
+++ b/app/controllers/applicants_controller.rb
 class ApplicantsController < ApplicationController
   def new
-    @applicant = Applicant.new
-    @applicant.references.new
+    @applicant = Applicant.new applicant_params
   end
```

```diff
--- a/app/controllers/applicants_controller.rb
+++ b/app/controllers/applicants_controller.rb
   def edit
     @applicant = Applicant.find params[:id]
+    @applicant.assign_attributes applicant_params
   end
```

```diff
--- a/app/controllers/applicants_controller.rb
+++ b/app/controllers/applicants_controller.rb
   private

   def applicant_params
-    params.require(:applicant).permit(
+    params.fetch(:applicant, {}).permit(
       :name,
       references_attributes: [ :name, :email_address, :id, :_destroy ],
     )
```

```diff
--- a/app/views/applicants/_form.html.erb
+++ b/app/views/applicants/_form.html.erb
   </ol>
+
+  <%= form.fields :references_attributes, index: form.object.references.size do |reference_form| %>
+    <%= reference_form.button :_destroy, value: false,
+                                         formaction: form.object.persisted? ?
+                                           edit_applicant_path(form.object) :
+                                           new_applicant_path,
+                                         formmethod: "get" do %>
+      Add personal reference
+    <% end %>
+  <% end %>
 </fieldset>

 <%= form.button %>
```

https://user-images.githubusercontent.com/2575027/152659554-c69dd665-f96c-4a91-a7f2-e39e7d9a7e07.mov

### Handling implicit submissions

> User agents may establish a button in each form as being the form's **default
> button**. This should be the **first submit button in tree order whose form
> owner is that form element**, but user agents may pick another button if
> another would be more appropriate for the platform. If the platform supports
> letting the user submit a form implicitly (for example, on some platforms
> hitting the <kbd>enter</kbd> key while a text field is focused implicitly
> submits the form), then doing so must cause the form's default button's
> activation behavior, if any, to be run.
>
> [4.10.22.2 Implicit submission][implicit submission]

Any time we render a `<button>` element with a `[formaction]` or `[formmethod]`
attribute, we run the risk of changing the `<form>` element's implicit
submission mechanism.

In our case, the candidates for **default button** are the "Add personal
reference" or "Destroy" buttons, since they appear before the "Create Applicant"
or "Update Applicant" in the document's [tree order][]. This means that if a
user pressed the <kbd>enter</kbd> key when a field within the "Personal
reference" fieldset has focus, the browser would click the first "Destroy"
button on their behalf.

We can exert control over which button is the **default button**, and which
mechanism handles implicit submissions. We'll declare a `<button>` element as
the form's first element. The element won't be visible to end-users or assistive
technology, and won't be able to receive focus:

```diff
--- a/app/views/applicants/_form.html.erb
+++ b/app/views/applicants/_form.html.erb
+<button class="hidden" tabindex="-1" aria-hidden="true"></button>
+
 <fieldset>
   <legend>Applicant</legend>
```

[implicit submission]: https://dev.w3.org/html5/spec-LC/association-of-controls-and-forms.html#implicit-submission
[tree order]: https://dev.w3.org/html5/spec-LC/infrastructure.html#tree-order

https://user-images.githubusercontent.com/2575027/152659647-b2e021f2-5f6f-4384-924c-2660a5d00e37.mov
