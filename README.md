# Hotwire: Mapping Locations with a Leaflet.js

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)][heroku-deploy-app]

[heroku-deploy-app]: https://heroku.com/deploy?template=https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-map

[Leaflet.js][] is an open-source JavaScript library for mobile-friendly
interactive maps. In order to use it in our application, we'll need to
add it as an in-browser dependency, then configure it.

Creating our controller
---

First, let's declare a [Stimulus Controller][] to drive the map through
the Leaflet object instances. Let's use `leaflet` as the controller's
[identifier][] by declaring it in
`app/javascript/controllers/leaflet_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
}
```

Next, our controller will need an element in the [DOM][] to control.
We'll introduce the `locations/leaflet` partial, then render the
`locations/leaflet` it into the `locations/index` template:

By rendering a `<section data-controller="leaflet">` element, Stimulus
will connect the `Controller` descendant we've declared in
`app/javascript/controllers/leaflet_controller.js` whenever the
`<section data-controller="leaflet">` element is present in the
document.

Before we start making substantial changes to our new element, let's
extract a new `locations/leaflet` view partial:

```erb
<%# app/views/locations/_leaflet.html.erb %>

<%= tag.section data: {
  controller: "leaflet",
} do %>
  <h1>Map</h1>
<% end %>
```

```diff
--- a/app/views/locations/index.html.erb
+++ b/app/views/locations/index.html.erb
@@ -1,5 +1,10 @@
 <p id="notice"><%= notice %></p>

+<%= render partial: "locations/leaflet" %>

 <section id="locations">
   <h1>Locations</h1>
```

[Leaflet.js]: https://leafletjs.com
[Stimulus Controller]: https://stimulus.hotwire.dev/handbook/hello-stimulus#controllers-bring-html-to-life
[identifier]: https://stimulus.hotwire.dev/reference/controllers#identifiers
[DOM]: https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model

Utilizing Leaflet.js
---

Next, depend on Leaflet's JavaScript interface by importing the library
through [Skypack][]:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
+import L from "https://cdn.skypack.dev/leaflet@1.6.0"
 import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
 }
```

The Leaflet package also provides its own stylesheets, which we'll
consume through a [`<link>` element][link] referencing the assets via a
[Content Distribution Network][] (<abbr title="Content Distribution
Network">CDN</abbr>).

```diff
--- a/app/views/layouts/application.html.erb
+++ b/app/views/layouts/application.html.erb
     <%= csp_meta_tag %>

     <link rel="stylesheet" href="https://unpkg.com/trix@1.3.1/dist/trix.css"></link>
+    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.6.0/dist/leaflet.css"
+      integrity="sha512-xwE/Az9zrjBIphAcBb3F6JVqxf46+CDLwfLMHloNu6KEQCAWi6HcDUbeOfBIptF7tcCzusKFjFw2yuvEpDL9wQ=="
+      crossorigin="">

     <%= stylesheet_link_tag "inter-font", "data-turbo-track": "reload" %>
```

[Skypack]: https://docs.skypack.dev
[link]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/link
[Content Distribution Network]: https://developer.mozilla.org/en-US/docs/Glossary/CDN

Creating the map
---

Each Stimulus Controller instance retains a reference to its
corresponding element, which it can access through its [element][]
property. In addition, a controller can access descendant elements
through [Stimulus-powered Targets][]. Since our map will rely on
the controller to manage additional context and state, let's declare a
descendant target element (marked by the `[data-leaflet-target="map"]`
attribute), and use that as our map element:

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
@@ -0,0 +1,8 @@
 <%= tag.section data: {
   controller: "leaflet",
+  leaflet_geo_json_layer_value: geo_json_layer,
+  leaflet_tile_layer_value: tile_layer,
 } do %>
   <h1>Map</h1>
+  <article class="w-full h-96" data-leaflet-target="map"></article>
 <% end %>
```

After declaring the element's HTML, we'll define a matching [target][]
within our `leaflet` controller. Using the resulting `mapTarget`
property, we'll create an instance of [L.Map][] from within the
controller's [initialize()] callback:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
 import L from "https://cdn.skypack.dev/leaflet@1.6.0"
 import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
+  static get targets() { return [ "map" ] }
+
+  initialize() {
+    this.leaflet = L.map(this.mapTarget)
+  }
 }
```

Once the Leaflet map instance is initialized, we'll add an
[OpenStreetMap][]-powered [L.TileLayer][]. Our Leaflet instance will
need several configuration values and credentials to properly consume
the <abbr title="Open Street Map">OSM</abbr> tiles.

Out-of-the-box, Rails provides a robust configuration system through a
combination of the `config/` directory and
[Rails.application.config_for][]. We can leverage those utilities to
store and read our OSM configuration values. We'll declare them in a
`config/leaflet.yml` file:

```yml
shared:
  accessToken: your-access-token
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  id: mapbox/streets-v11
  maxZoom: 18
  templateUrl: https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}
  tileSize: 512
  zoomOffset: -1
```

Next, we'll read those values in a [custom configuration][] from within
our `config/application.rb`:

```diff
--- a/config/application.rb
+++ b/config/application.rb
@@ -18,5 +18,6 @@ module HotwireExampleTemplate
     #
     # config.time_zone = "Central Time (US & Canada)"
     # config.eager_load_paths << Rails.root.join("extras")
+    config.x.leaflet = config_for(:leaflet)
   end
 end
```

From our `locations/idnex` template, we'll read those values and pass it
into our `locations/leaflet` view partial as `tile_layer`:

```diff
--- a/app/views/locations/index.html.erb
+++ b/app/views/locations/index.html.erb
 <p id="notice"><%= notice %></p>

-<%= render partial: "locations/leaflet" %>
+<%= render partial: "locations/leaflet", locals: {
+  tile_layer: Rails.configuration.x.leaflet,
+} %>

 <section id="locations">
   <h1>Locations</h1>
```

From our view partial, we'll encode them into JSON then embed them
directly into HTML in a way that our `leaflet` controller instance can
access directly through [Stimulus-powered Values][]:

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
 <%= tag.section data: {
   controller: "leaflet",
+  leaflet_tile_layer_value: tile_layer,
 } do %>
   <h1>Map</h1>
   <article class="w-full h-96" data-leaflet-target="map"></article>
 <% end %>
```

With the values present in the HTML, we'll need to extend our `leaflet`
controller to access the configuration JSON embedded into the
`[data-leaflet-tile-layer-value]` attribute. We'll first declare a
static `values` accessor to return a mapping the `tileLayer` key to
`Object` to direct to Stimulus on how to encode and decode the value:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
 import L from "https://cdn.skypack.dev/leaflet@1.6.0"
 import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
   static get targets() { return [ "map" ] }
+  static get values() { return { tileLayer: Object } }

   initialize() {
     this.leaflet = L.map(this.mapTarget)
   }
 }
```

There are a few overlapping mechanisms in-play here that make this all
possible, and are worth emphasizing:

1.  Our YAML file read into the `Rails.configuration.x.leaflet` value is
    represented by a Ruby `Hash` instance

2.  Action View helpers transform `Hash` instances nested within `data:
    { }` options into HTML-escaped `JSON`

3.  The escaped JSON string is encoded into the
    `[data-leaflet-tile-layer-value]` HTML attribute

4.  Once connected, our `leaflet` Stimulus Controller reads the
    `[data-leaflet-tile-layer-value]` attribute as a `String`, then
    transforms that `String` into an `Object` by passing it to
    [JSON.parse][]

With that declaration in place, our controller gains access to a
`tileLayerValueChanged(value, oldValue)` callback that will fire
whenever the controlled element's `[data-leaflet-tile-layer-value]`
attribute changes. From within that callback, we'll construct an
[L.tileLayer] instance, add it to our map, then make sure it's rendered
at the bottom of map's stack of layers:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
 import L from "https://cdn.skypack.dev/leaflet@1.6.0"
 import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
   static get targets() { return [ "map" ] }
   static get values() { return { tileLayer: Object } }

   initialize() {
     this.leaflet = L.map(this.mapTarget)
   }
+
+  tileLayerValueChanged({ templateUrl, ...options }) {
+    const layer = L.tileLayer(templateUrl, options)
+
+    layer.addTo(this.leaflet).bringToBack()
+  }
 }
```

A note about operational security
---

It's worth highlighting the fact that by embedding our configuration
values _directly_ into our HTML and JavaScript code, we're transmitting
them to each client in plain text. That is acceptable in this case,
since the Leaflet configuration doesn't contain any credentials or
secrets.

The `L.TileLayer` initialization process requires a [MapBox token][] as
an argument, which would be transmitted in plain text even if we
declared it elsewhere in our client-side code. Keep this in mind when
considering encoding configuration values with
[Rails.application.config_for][].

[element]: https://stimulus.hotwire.dev/reference/controllers#properties
[Stimulus-powered Targets]: https://stimulus.hotwire.dev/handbook/hello-stimulus#targets-map-important-elements-to-controller-properties
[target]: https://stimulus.hotwire.dev/reference/targets#definitions
[L.Map]: https://leafletjs.com/reference-1.6.0.html#map-example
[initialize]: https://stimulus.hotwired.dev/reference/lifecycle-callbacks#methods
[L.TileLayer]: https://leafletjs.com/reference-1.6.0.html#tilelayer
[OpenStreetMap]: https://www.openstreetmap.org/about
[Rails.application.config_for]: https://edgeapi.rubyonrails.org/classes/Rails/Application.html#method-i-config_for
[custom configuration]: https://edgeguides.rubyonrails.org/configuring.html#custom-configuration
[Stimulus-powered Values]: https://stimulus.hotwire.dev/reference/values
[JSON.parse]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse

Translating `Location` records to map markers
---

Leaflet provides built-in support for translating [GeoJSON][] into a
[GeoJSON Layer][] of map markers through calls to [L.geoJSON][].

We can use the same [Stimulus-powered Values][] plumbing to encode
server-rendered JSON into our `leaflet` controller's HTML element.

First, we'll need to render the JSON. We'll, declare a pair of
[jbuilder][] view files. First, a template file for the
`locations#index` action to represent the set of `Location` records as a
GeoJSON "FeatureCollection":

```ruby
 # app/views/locations/index.json.jbuilder
 json.type "FeatureCollection"
 json.features @locations, partial: "locations/location", as: :location
```

Next, the `locations/location` view partial to transform an individual
`Location` record into GeoJSON:

```ruby
 # app/views/locations/index.json.jbuilder
 json.type "Feature"
 json.geometry do
   json.type "Point"
   json.coordinates location.values_at(:longitude, :latitude)
 end
```

Next, we'll pass the rendered template into our `locations/leaflet`
partial:

```diff
--- a/app/views/locations/index.html.erb
+++ b/app/views/locations/index.html.erb
 <p id="notice"><%= notice %></p>

 <%= render partial: "locations/leaflet", locals: {
+  geo_json_layer: render(template: "locations/index", formats: :json),
   tile_layer: Rails.configuration.x.leaflet,
 } %>

 <section id="locations">
   <h1>Locations</h1>
```

From there, we'll encode it to the element as the
`[data-leaflet-geo-json-layer-value]` attribute:

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
 <%= tag.section data: {
   controller: "leaflet",
+  leaflet_geo_json_layer_value: geo_json_layer,
   leaflet_tile_layer_value: tile_layer,
 } do %>
   <h1>Map</h1>

   <article class="w-full h-96" data-leaflet-target="map"></article>
 <% end %>
```

Finally, pass the GeoJSON along to [L.geoJSON][] whenever the `leaflet`
element is [connected][] to the DOM:

```diff
 export default class extends Controller {
   static get targets() { return [ "map" ] }
-  static get values() { return { tileLayer: Object } }
+  static get values() { return { tileLayer: Object, geoJsonLayer: Object } }

   initialize() {
```

With that declaration, the controller gains access to a
`geoJsonLayerValueChanged(value, oldValue)` callback. From within that
callback, we'll create an [L.geoJSON][] instance, add it to the map, and
make sure it's rendered at the top of the map's stack of layers. We'll
also use it to determine the map's initial bounds, zoom, and center
location:

```diff
+++ a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
   tileLayerValueChanged({ templateUrl, ...options }) {
     const layer = L.tileLayer(templateUrl, options)

     layer.addTo(this.leaflet).bringToBack()
   }
+
+  geoJsonLayerValueChanged(value) {
+    const layer = L.geoJSON(value)
+
+    layer.addTo(this.leaflet).bringToFront()
+
+    this.leaflet.fitBounds(layer.getBounds())
+  }
 }
```

[MapBox token]: https://leafletjs.com/examples/quick-start/#setting-up-the-map
[GeoJSON]: https://tools.ietf.org/html/rfc7946
[GeoJSON layer]: https://leafletjs.com/reference-1.6.0.html#geojson
[L.tileLayer]: https://leafletjs.com/reference-1.6.0.html#tilelayer
[L.geoJSON]: https://leafletjs.com/reference-1.6.0.html#geojson
[jbuilder]: https://github.com/rails/jbuilder/tree/v2.11.2#jbuilder
[connected]: https://stimulus.hotwire.dev/reference/lifecycle-callbacks#connection

## Scoping Locations geographically

In the spirit of [Progressive Enhancement][], we'll implement the
feature as if Stimulus and Turbo were unavailable. Ignoring the map and
its markers for a moment, let's consider the changes we'll need to make
to `locations#index` controller action so that end-users can filter
Locations based on their geographies.

First, we'd need a `<form>` and `<input>` element to submit filter
information to the server. For the sake of getting an initial working
version, we'll accept the dimensions of a geographic bounding box's as a
quartet of latitudes and longitudes (comma delimited, of course):

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
   <h1>Map</h1>

   <article class="w-full h-96" data-leaflet-target="map"></article>
+
+  <form>
+    <label for="search_bbox">Bbox</label>
+    <input id="search_bbox" name="bbox" type="text">
+
+    <button>
+      Search this area
+    </button>
+  </form>
 <% end %>
```

For example, a bounding box query of
`-73.990441,40.735770,-73.982335,40.768116` would represent a geographic
box with a Western longitude of `-73.990441`, a Southern latitude of
`40.735770`, an Eastern longitude of -73.982335, and a Northern latitude
of `40.768116`.

Requests made from a `<form>` element _with_ `[method="get"]` and
_without_ an `[action]` attribute are submitted to the _current_ URL,
which is perfect for filtering.

[Progressive Enhancement]: https://developer.mozilla.org/en-US/docs/Glossary/Progressive_Enhancement
[action]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#attr-action
[form_with]: https://edgeapi.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with
[GET]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET
[query parameters]: https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams#examples

Once submitted, we'll transform the submission's filter paramters into
Active Record-powered `Location` queries:

```diff
--- a/app/controllers/locations_controller.rb
+++ b/app/controllers/locations_controller.rb
 def index
-  @locations = Location.all
+  bounding_box = BoundingBox.parse(params[:bbox])
+
+  if bounding_box.valid?
+    @locations = Location.within(bounding_box)
+    @bounding_box = bounding_box
+  else
+    @locations = Location.all
+    @bounding_box = BoundingBox.containing(@locations)
+  end
 end

--- a/app/models/location.rb
+++ b/app/models/location.rb
@@ -1,2 +1,3 @@
 class Location < ApplicationRecord
+  scope :within, ->(bounding_box) { where bounding_box.to_h }
 end
```

It's worth highlighting the fact that Postgres supports both [Geometric
Types][] and [Geographic Types][] (through [PostGIS][]). However, for
the sake of this article intends to illustrate Hotwire-specific
concepts, we'll forego more advance Postgres features in favor of a more
simplistic pairing of a bounding rectangle's [Range][] values:

[Geometric Types]: https://www.postgresql.org/docs/12/datatype-geometric.html
[Geographic Types]: https://postgis.net/docs/manual-3.1/postgis_usage.html#using_postgis_dbmanagement
[PostGIS]: https://postgis.net/docs/manual-3.1/
[Range]: https://ruby-doc.org/core-3.0.1/Range.html

```ruby
class BoundingBox
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :west, :decimal
  attribute :south, :decimal
  attribute :east, :decimal
  attribute :north, :decimal

  validates :west, :east, inclusion: { in: -180..180 }
  validates :south, :north, inclusion: { in: -90..90 }

  def self.parse(bbox)
    coordinates bbox.to_s.split(",")
  end

  def self.coordinates(coordinates)
    west, south, east, north = coordinates

    new west: west, south: south, east: east, north: north
  end

  def self.containing(locations)
    west, east = locations.pluck(:longitude).minmax
    south, north = locations.pluck(:latitude).minmax

    coordinates [ west, south, east, north ]
  end

  def to_h
    { longitude: west..east, latitude: south..north }
  end

  def to_a
    [ west, south, east, north ]
  end

  def to_s
    to_a.join(",")
  end
end
```

Make the Bounds available to the Leaflet map
---

Setting the `@bounding_box` instance variable within the
`locations#index` controller action makes it available within the
`app/views/locations/index` template. Within the GeoJSON template, rely
on the `BoundingBox#to_a` implementation to serialize the bounds to the
GeoJSON layer's data under the [`bbox` key][]:

```diff
--- a/app/views/locations/index.json.jbuilder
+++ b/app/views/locations/index.json.jbuilder
 json.type "FeatureCollection"
 json.features @locations, partial: "locations/location", as: :location
+json.bbox @bounding_box.to_a
```

[`bbox` key]: https://tools.ietf.org/html/rfc7946#section-5

Finally, the `leaflet` controller can read the bounds directly from the
GeoJSON dataset's `bbox` value, and fit the Leaflet map based on the
provided box:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
     layer.addTo(this.leaflet).bringToBack()
   }

-  geoJsonLayerValueChanged(value) {
+  geoJsonLayerValueChanged({ bbox: [ west, south, east, north ], ...featureCollection }) {
-    const layer = L.geoJSON(value)
+    const layer = L.geoJSON(featureCollection)
+    const bounds = L.latLngBounds([ south, west ], [ north, east ])

     layer.addTo(this.leaflet).bringToFront()

-    this.leaflet.fitBounds(layer.getBounds())
+    this.leaflet.fitBounds(bounds)
   }
 }
```

## Reading the query bounds from the map

Expecting end-users to provide fully-formed and valid `bbox` strings on
their own is unreasonable. Instead, let's set the `<form>` submission's
`bbox` field based on the [LatLngBounds][] of the map.

Whenever the map is panned or zoomed, the [L.Map][] instance will fire a
[moveend][] event via Leaflet's own event system. We'll declare the
`prepareSearch(event)` action to receive respond to the `moveend`
events. The event's `target` property is a reference to the `L.Map`
instance that fired the event. We'll read the current boundaries from
that instance by calling `getBounds()`, then serialize the results to a
"bounding box" string by calling `.toBBoxString()`:

```diff
--- a/app/assets/javascripts/controllers/leaflet_controller.js
+++ b/app/assets/javascripts/controllers/leaflet_controller.js
+
+  prepareSearch = ({ target }) => {
+    const bbox = target.getBounds().toBBoxString()
+  }
 }
```

Once we've generated the value, we'll encode it into a field without our
`<form>` element so that it's transmitted to the server during s
submission. The `<form>` currently encodes the `bbox` as an [`<input
type="text">`][type="text"]. We'll replace that field by
programmatically encoding the "bounding box" string value into a
`[name="bbox"]` and `[value]` pair onto the form's `<button>` element:

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
   <article class="w-full h-96" data-leaflet-target="map"></article>

   <form>
-    <label for="search_bbox">Bbox</label>
-    <input id="search_bbox" name="bbox" type="text">
-
-    <button>
+    <button name="bbox">
       Search this area
     </button>
   </form>
```

During the submission of a `<form>` element, the browser will encode any
`[name]` and `[value]` attributes declared on its submitter into the
request's data.

In order to write to the element, we'll need direct direct access from
our `leaflet` controller. We'll annotate the `<button>` with
`[data-leaflet-target="bbox"]`:

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
   <article class="w-full h-96" data-leaflet-target="map"></article>

   <form>
-    <button name="bbox">
+    <button name="bbox" data-leaflet-target="bbox">
       Search this area
     </button>
   </form>
```

Then, we'll declare a corresponding entry in the controller's static
`targets` property:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
 import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
-  static get targets() { return [ "map" ] }
+  static get targets() { return [ "bbox", "map" ] }
   static get values() { return { tileLayer: Object, geoJsonLayer: Object } }
```

Then set the `<button name="bbox">` element's [value][] to the
`bboxString` generated from the map's new bounds:

```diff
--- a/app/assets/javascripts/controllers/leaflet_controller.js
+++ b/app/assets/javascripts/controllers/leaflet_controller.js

   prepareSearch = ({ target }) => {
     const bbox = target.getBounds().toBBoxString()
+    this.bboxTarget.value = bbox
   }
 }
```

Whenever the user drags the map, Leaflet will fire a `moveend` event.
Our `leaflet` controller will respond by encoding the map's bounds to a
value that it directly encodes to the "Search this area" button. The
next time the user clicks that `<button>` element, the `<form>` will
submit a query, navigate the page, and render results that meet the
query's geographic criteria.

[bbox]: https://tools.ietf.org/html/rfc7946#section-5
[LatLngBounds]: https://leafletjs.com/reference-1.6.0.html#latlngbounds
[moveend]: https://leafletjs.com/reference-1.6.0.html#map-moveend
[L.Map]: https://leafletjs.com/reference-1.6.0.html#map
[Stimulus Controller Action]: https://stimulus.hotwire.dev/handbook/building-something-real#connecting-the-action
[type="text"]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/text
[value]: https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement#properties

## Rendering our own Location markers

Let's configure Leaflet to render each marker with a custom icon that we
provide. We'll encode the markers' HTML into our server-generated
`locations/leaflet` partial. We'll embed them into the response's
document with an HTML `<template>` element, making sure that each
element declares a unique `[id]` attribute:

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
 } do %>
   <h1>Map</h1>

+  <template>
+    <% locations.each do |location| %>
+      <%= tag.div id: dom_id(location, :marker) do %>
+        <span class="sr-only"><%= location.name %></span>
+        <%= inline_svg_tag "marker", class: "h-8 w-8" %>
+      <% end %>
+    <% end %>
+  </template>
+
   <article class="w-full h-96" data-leaflet-target="map"></article>

   <form>
```

The implementation for our `inline_svg_tag` helper draws inspiration
from a [tweet-size code snippet shared by George
Claghorn][inline_svg_tag]:

```ruby
module ApplicationHelper
  def inline_svg_tag(name, **options)
    svg_path(name).read.strip.then do |svg|
      raw options.any? ? svg.sub(/\A<svg(.*?)>/, "<svg\\1 #{tag.attributes(options)}>") : svg
    end
  end

  def svg_path(name)
    Rails.root.join("app/assets/images/#{name}.svg")
  end
end
```

The `"marker"` file referenced as an argument in the call to
`inline_svg_tag(name)` contains an `<svg>` element that we'll render
directly into our HTML template:

```html
<!-- app/assets/images/marker.svg -->

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 29 34" fill="none" role="presentation">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M23.9016 24.5C26.6454 21.9144 28.3582 18.2468 28.3582 14.1791C28.3582 6.3482 22.01 0 14.1791 0C6.3482 0 0 6.3482 0 14.1791C0 18.5588 1.98575 22.4748 5.10603 25.0757L14.5 34L24 24.5H23.9016Z" fill="currentColor"/>
</svg>
```

Once we've encoded the marker's HTML icon into our page, we'll need to
access it from our `leaflet` controller. Let's create a `templateTarget`
property to access the `<template>` element by pairing a
`[data-leaflet-target="template"]` attribute in our HTML with a
`"template"` entry in the `leaflet` controller's `targets` static
property:

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
 } do %>
   <h1>Map</h1>

-  <template>
+  <template data-leaflet-target="template">
     <% locations.each do |location| %>
       <%= tag.div id: dom_id(location, :marker) do %>
         <span class="sr-only"><%= location.name %></span>
         <%= inline_svg_tag "marker", class: "h-8 w-8" %>
       <% end %>
     <% end %>
   </template>

   <article class="w-full h-96" data-leaflet-target="map"></article>

   <form>

--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
 import { Controller } from "@hotwired/stimulus"

 export default class extends Controller {
-  static get targets() { return [ "bbox", "map" ] }
+  static get targets() { return [ "bbox", "map", "template" ] }
   static get values() { return { tileLayer: Object, geoJsonLayer: Object } }

   initialize() {
```

Leaflet's interface for [L.GeoJSON][] layers accepts a [pointToLayer][]
function to provide applications with a seam to transform GeoJSON data
into map markers. We'll declare a `pointToLayer` method to transform
GeoJSON into an [L.Marker][] instance:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
     const bbox = target.getBounds().toBBoxString()
     this.bboxTarget.value = bbox
   }
+
+  pointToLayer = ({ properties: { icon: { id, ...options } } }, latLng) => {
+    const html = this.templateTarget.content.getElementById(id).cloneNode(true)
+
+    return L.marker(latLng, { icon: L.divIcon({ html, ...options }) })
+  }
 }
```

We can pass that `pointToLayer` function, to our `L.geoJSON` call so
that we can transform the GeoJSON data that our controller's
`geoJsonLayerValue` property provides into instances of [L.DivIcon][]
and [L.Marker][]:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
   }

   geoJsonLayerValueChanged({ bbox: [ west, south, east, north ], ...featureCollection }) {
+    const { pointToLayer } = this
     const bounds = L.latLngBounds([ south, west ], [ north, east ])
-    const layer = L.geoJSON(featureCollection)
+    const layer = L.geoJSON(featureCollection, { pointToLayer })

     layer.addTo(this.leaflet).bringToFront()
```

Leveraging our existing server-to-client pipeline, we have an
opportunity to encode server-rendered HTML into our GeoJSON in a
Leaflet-compliant way.

According to the GeoJSON specifications:

> A [Feature][] object has a member with the name "properties".  The
> value of the properties member is an object (any JSON object or a
> JSON null value).

Since the structure of a Feature's `"properties"` key is free form,
let's serialize the data necessary for retrieving the icon's HTML from
our `<template data-leaflet-target="template">` element's content:

```diff
--- a/app/views/locations/_location.json.jbuilder
+++ b/app/views/locations/_location.json.jbuilder
   json.type "Point"
   json.coordinates location.values_at(:longitude, :latitude)
 end
+json.properties do
+  json.icon do
+    json.id dom_id(location, :marker)
+  end
+end
```

[L.GeoJSON]: https://leafletjs.com/reference-1.6.0.html#geojson
[pointToLayer]: https://leafletjs.com/reference-1.6.0.html#geojson-pointtolayer
[L.Marker]: https://leafletjs.com/reference-1.6.0.html#marker
[L.DivIcon]: https://leafletjs.com/reference-1.6.0.html#divicon
[GeoJSON]: https://tools.ietf.org/html/rfc7946
[Feature]: https://tools.ietf.org/html/rfc7946#section-3.2
[inline_svg_tag]: https://twitter.com/georgeclaghorn/status/1430211569212854272/photo/1
[Turbo-capable `<a>` element]: https://turbo.hotwire.dev/handbook/introduction#turbo-drive%3A-navigate-within-a-persistent-process

## Navigating from a list to a single Location

Now that our map can navigate from a list of Locations to a single
Location, let's render the map as part of our `locations#show` action.

To start, we'll render our `locations/leaflet` partial from without our
`locations/show` template, once again passing in the
`Rails.configuration.x.leaflet` value as the `tile_layer` partial-local
variable:

```diff
--- a/app/views/locations/show.html.erb
+++ b/app/views/locations/show.html.erb
 <p id="notice"><%= notice %></p>

+<%= render partial: "locations/leaflet", locals: {
+  locations: [ @location ],
+  tile_layer: Rails.configuration.x.leaflet,
+} %>

 <%= render @location %>
```

```diff
--- a/app/views/locations/show.json.jbuilder
+++ b/app/views/locations/show.json.jbuilder
+json.type "FeatureCollection"
+json.features [ @location ], partial: "locations/location", as: :location
```

Next, we'll create a `BoundingBox` instance in our controller action
and assign it to the `@bounding_box` instance variable:

```diff
--- a/app/controllers/locations_controller.rb
+++ b/app/controllers/locations_controller.rb
   def show
+    @bounding_box = BoundingBox.containing([ @location ])
   end
```

Then we'll encode the value into the GeoJSON:

```diff
--- a/app/views/locations/show.json.jbuilder
+++ b/app/views/locations/show.json.jbuilder
 json.type "FeatureCollection"
 json.features [ @location ], partial: "locations/location", as: :location
+json.bbox @bounding_box.to_a
```

```diff
--- a/app/views/locations/show.html.erb
+++ b/app/views/locations/show.html.erb
 <p id="notice"><%= notice %></p>

 <%= render partial: "locations/leaflet", locals: {
   locations: [ @location ],
+  geo_json_layer: render(template: "locations/show", formats: :json),
   tile_layer: Rails.configuration.x.leaflet,
 } %>

 <%= render @location %>
```

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
   <template data-leaflet-target="template">
     <% locations.each do |location| %>
-      <%= tag.div id: dom_id(location, :marker) do %>
+      <%= link_to location_path(location), id: dom_id(location, :marker) do %>
         <span class="sr-only"><%= location.name %></span>
         <%= inline_svg_tag "marker", class: "h-8 w-8" %>
       <% end %>
```

## Making our map's navigation a seamless experience

While navigating from the list of Locations to a single Location is
functional, it's a jarring experience. There is a noticeable flicker in
the map, and the immediate change in the map's bounds is disorienting.
If this were implemented as a [single-page application][] (<abbr
title="Single Page Application">SPA</abbr>), the application would
preserve the map's state across navigations, which could eliminate the
flickering and would provide an opportunity to animate from bounding box
to bounding box.

Luckily, Turbo supports preserving elements across page loads through
the [data-turbo-permanent][] attribute:

> Designate permanent elements by giving them an HTML `id` and
> annotating them with `data-turbo-permanent`.

Let's ensure that our Leaflet map's element isn't destroyed between
navigations:

```diff
--- a/app/views/locations/_leaflet.html.erb
+++ b/app/views/locations/_leaflet.html.erb
     <% end %>
   </template>

-  <article class="w-full h-96" data-leaflet-target="map"></article>
+  <article id="leaflet-map" class="w-full h-96" data-leaflet-target="map" data-turbo-permanent></article>

   <form>
```

While it might seem as simple as annotating an element with an `[id]`
and `[data-turbo-permanent]`, we're now responsible for maintaining the
element's long-lived state. Taking on that responsibility comes with
several considerations.

First of all, we don't want to re-initialize the map if we already have
access to one. As a [memoization][] strategy, we'll store the instance
of our [L.Map][] in a [WeakMap][] value, keyed by the long-lived
`HTMLElement` referenced by the `this.mapTarget` property. Since the
element's instance state will span page navigations, it will ferry our
map forward and backward through the browser's history. We'll check for
the presence of the memoized instance via [WeakMap.has()][] function:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
 import L from "https://cdn.skypack.dev/leaflet@1.6.0"
 import { Controller } from "@hotwired/stimulus"

+const targetsToMaps = new WeakMap
+
 export default class extends Controller {
   static get targets() { return [ "bbox", "map", "template" ] }
   static get values() { return { tileLayer: Object, geoJsonLayer: Object } }

   initialize() {
-    this.leaflet = L.map(this.mapTarget)
+    this.leaflet = targetsToMaps.get(this.mapTarget) || L.map(this.mapTarget)
+
+    targetsToMaps.set(this.mapTarget, this.leaflet)
   }
```

Then we'd need to persist the tile layer:

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
 import L from "https://cdn.skypack.dev/leaflet@1.6.0"
 import { Controller } from "@hotwired/stimulus"

 const targetsToMaps = new WeakMap
+const mapsToTileLayers = new WeakMap

 export default class extends Controller {
   static get targets() { return [ "bbox", "map", "template" ] }
```

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
   tileLayerValueChanged({ templateUrl, ...options }) {
     const layer = L.tileLayer(templateUrl, options)
+    const existingLayer = mapsToTileLayers.get(this.leaflet)

     layer.addTo(this.leaflet).bringToBack()
+    mapsToTileLayers.set(this.leaflet, layer)
+
+    if (existingLayer) {
+      existingLayer.removeFrom(this.leaflet)
+    }
   }
```

```diff
--- a/app/javascript/controllers/leaflet_controller.js
+++ b/app/javascript/controllers/leaflet_controller.js
   geoJsonLayerValueChanged({ bbox: [ west, south, east, north ], ...featureCollection }) {
     const { pointToLayer } = this
     const bounds = L.latLngBounds([ south, west ], [ north, east ])
     const layer = L.geoJSON(featureCollection, { pointToLayer })
+    const existingLayer = mapsToGeoJsonLayers.get(this.leaflet)

     layer.addTo(this.leaflet).bringToFront()
+    mapsToGeoJsonLayers.set(this.leaflet, layer)

-    this.leaflet.fitBounds(bounds)
+    if (existingLayer) {
+      this.leaflet.once("zoomend", () => existingLayer.removeFrom(this.leaflet))
+      this.leaflet.flyToBounds(bounds)
+    } else {
+      this.leaflet.fitBounds(bounds)
+    }
   }
```

By marking the element with `[data-turbo-permanent]` and handling those
circumstances, we're able to seamlessly animate the map between
navigations, achieving an SPA-like experience with server-rendered HTML.

[single-page application]: https://developer.mozilla.org/en-US/docs/Glossary/SPA
[data-turbo-permanent]: https://turbo.hotwire.dev/handbook/building#persisting-elements-across-page-loads
[fitBounds]: https://leafletjs.com/reference-1.6.0.html#map-fitbounds
[flyToBounds]: https://leafletjs.com/reference-1.6.0.html#map-flytobounds
[connect()]: https://stimulus.hotwire.dev/reference/lifecycle-callbacks#connection
[disconnect()]: https://stimulus.hotwire.dev/reference/lifecycle-callbacks#disconnection
[memoization]: https://en.wikipedia.org/wiki/Memoization
[WeakMap]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap
[WeakMap.has()]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap/has
