# Template-powered nested attributes

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-template-powered-nested-attributes

## Our starting point

This branch will skip the process of [progressively enhancing][] a foundation
built on form submissions, URL parameters, and HTTP requests. If you're
interested in learning more about that process, read the
[hotwire-example-turbo-frame-powered-nested-attributes][] branch.

[progressively enhancing]: https://developer.mozilla.org/en-US/docs/Glossary/Progressive_Enhancement
[hotwire-example-turbo-frame-powered-nested-attributes]: https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-turbo-frame-powered-nested-attributes

Our models:

```ruby
# app/models/applicant.rb

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

Our controller:

```ruby
# app/controllers/applicants_controller.rb

class ApplicantsController < ApplicationController
  def new
    @applicant = Applicant.new
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

Our view partials:

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
      <%= form.fields :references_attributes, model: reference,
                                              index: index do |reference_form| %>
        <%= render partial: "references/form", object: reference_form %>
      <% end %>
    <% end %>
  </ol>

  <button type="button">
    Add personal reference
  </button>
</fieldset>

<%= form.button %>
```

```erb
<%# app/views/references/_form.html.erb %>

<%= tag.li class: "mt-2", hidden: form.object.marked_for_destruction? do %>
  <div class="grid gap-2">
    <%= form.hidden_field :id %>

    <%= form.label :name %>
    <%= form.text_field :name %>

    <%= form.label :email_address %>
    <%= form.email_field :email_address %>

    <div>
      <%= form.check_box :_destroy %>
      <%= form.label :_destroy %>
    </div>
  </div>
<% end %>
```

<img  src="https://images.thoughtbot.com/blog-vellum-image-uploads/c1xKD3NsQvsT36Tf4GFv_nested-attributes-edit.png"
      alt="A form to edit an Applicant and their personal references">

## Adding nested fields

```diff
--- a/app/views/applicants/_form.html.erb
+++ b/app/views/applicants/_form.html.erb
   </ol>

   <button type="button">
     Add personal reference
+
+    <template>
+      <turbo-stream action="append" target="<%= form.field_id(:references_attributes) %>">
+        <template>
+          <%= form.fields :references_attributes, model: form.object.references.new,
+                                                  index: form.object.references.size do |reference_form| %>
+            <%= render partial: "references/form", object: reference_form %>
+          <% end %>
+        </template>
+      </turbo-stream>
+    </template>
   </button>
 </fieldset>
```

```diff
--- a/app/views/applicants/_form.html.erb
+++ b/app/views/applicants/_form.html.erb
 <fieldset>
   <legend>Personal references</legend>

-  <ol>
+  <ol id="<%= form.field_id(:references_attributes) %>">
```

```diff
--- a/app/views/applicants/_form.html.erb
+++ b/app/views/applicants/_form.html.erb
   </ol>

-  <button type="button">
+  <button type="button" data-controller="clone" data-action="click->clone#append">
     Add personal reference

-    <template>
+    <template data-clone-target="template">
       <turbo-stream action="append" target="<%= form.field_id(:references_attributes) %>">
         <template>
           <%= form.fields :references_attributes, model: form.object.references.new,
                                                   index: form.object.references.size do |reference_form| %>
             <%= render partial: "references/form", object: reference_form %>
           <% end %>
         </template>
       </turbo-stream>
     </template>
   </button>
 </fieldset>
```

```javascript
// app/javascript/controllers/clone_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "template" ]

  append() {
    for (const { content } of this.templateTargets) {
      this.element.append(content.cloneNode(true))
    }
  }
}
```

### Incrementing the nested attributes key

```diff
--- a/app/views/applicants/_form.html.erb
+++ b/app/views/applicants/_form.html.erb
   </ol>

-  <button type="button" data-controller="clone" data-action="click->clone#append">
+  <button type="button" data-controller="clone template-parts" data-action="click->clone#append"
+                        data-template-parts-key-value="id"
+                        data-template-parts-index-value="<%= form.object.references.size %>">
     Add personal reference

     <template data-clone-target="template">
       <turbo-stream action="append" target="<%= form.field_id(:references_attributes) %>">
-        <template>
+        <template data-template-parts-target="template">
           <%= form.fields :references_attributes, model: form.object.references.new,
-                                                  index: form.object.references.size do |reference_form| %>
+                                                  index: "{{id}}" do |reference_form| %>
             <%= render partial: "references/form", object: reference_form %>
           <% end %>
         </template>
       </turbo-stream>
     </template>
 </fieldset>
```

```javascript
// app/javascript/controllers/template_parts_controller.js

import { Controller } from "@hotwired/stimulus"
import { TemplateInstance } from "https://cdn.skypack.dev/@github/template-parts"

export default class extends Controller {
  static targets = [ "template" ]
  static values = { index: Number, key: String }

  templateTargetConnected(target) {
    const templateInstance = new TemplateInstance(target, {
      [this.keyValue]: this.indexValue
    })

    target.content.replaceChildren(templateInstance)

    this.indexValue++
  }
}
```

https://user-images.githubusercontent.com/2575027/152659893-fe4b4b49-4828-485d-8db3-6a08a2914814.mov

## Removing nested fields

```diff
--- a/app/views/references/_form.html.erb
+++ b/app/views/references/_form.html.erb
-<%= tag.li class: "mt-2", hidden: form.object.marked_for_destruction? do %>
+<%= tag.li class: "mt-2", hidden: form.object.marked_for_destruction?,
+           data: { controller: "element" } do %>
   <div class="grid gap-2">
     <%= form.hidden_field :id %>
```

```javascript
// app/javascript/controllers/element_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  hide() {
    this.element.hidden = true
  }
}
```

```diff
--- a/app/views/references/_form.html.erb
+++ b/app/views/references/_form.html.erb
   <div>
-    <%= form.check_box :_destroy, data: { action: "input->element#hide" } %>
+    <%= form.check_box :_destroy, data: { action: "input->element#hide" },
+                                  autocomplete: "off" %>
     <%= form.label :_destroy %>
   </div>
```

https://user-images.githubusercontent.com/2575027/152659921-f52ad040-d2d4-4f35-8b15-74964c16cdac.mov
