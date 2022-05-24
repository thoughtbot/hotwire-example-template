# Hotwire Example AG Grid

This repository is an experiment to investigate what it'd be like to drive an
[AG Grid][] instance with a Stimulus controller and a `<turbo-frame>`.

There are several facets of the experiment of note:

* The row data is serialized to a [`<meta>` element][meta] that encodes the
  payload into its `[content]` attribute as JSON
* Both client-side and server-side datasets are loaded with the same
  `<turbo-frame>` and `<meta>` pair mechanism
* The `grid` Stimulus controller integrates with the server-side datasource
  pagination interface by dispatching a custom `grid:pagination` event, which
  the view-layer routes to the `grid#loadRows` Stimulus action by declaring a
  `[data-action]` attribute on the `<turbo-frame>`
* The pagination event listener only encodes a limited set of data retrieval
  query parameters (the `startRow` and `endRow` values), but could be extended
  to incorporate more contextual values (like sort order or filter model)

[AG Grid]: https://www.ag-grid.com/
[meta]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta

There are two noteworthy files:

* The `grids#show` template that renders a `<div data-controller="grid">`
  element and a `<turbo-frame>` element
* The `grid` Stimulus controller

The `grids#show` template relies on query parameters to conditionally render the
dataset.

For the sake of this demonstrating the client-side version of this example, both
a server-side and client-side example are rendered as part of the same page.

The server-side version determines whether or not to render the dataset based on
the `?load=true` query. When the `load` query parameter is absent, the template
render the page with an empty dataset (the `rows = []` assignment below). When
the `load` query parameter is present, the template will render the grid with a
page-worth of data (determined by the `startRow` and `endRow` query parameters,
defaulting to `0` and `100`):

```erb
<h1 class="text-lg">Server-side pagination</h1>

<%
    if params[:load].nil?
      # the grid is initially rendered empty, but ready to fetch data
      src = grid_path(load: true)
      rows = []
    else
      # the grid renders the data set that as part of a remote fetch
      min, max = params.values_at :startRow, :endRow
      min = min || 0
      max = max || 100
      min, max = [min, max].map(&:to_i).minmax

      src = nil
      rows = min...max
    end
%>

<%= tag.div class: "h-[40vh]", data: {
      controller: "grid",
      grid_options_value: {
        columnDefs: [
          { field: "a" },
          { field: "b" },
          { field: "c" },
        ],
        pagination: true,
        rowModelType: "serverSide",
        serverSideStoreType: "partial",
      },
    } do %>
  <%= turbo_frame_tag "grid-datasource", src: src,
                      data: { action: "grid:pagination->grid#loadRows" } do %>
    <%= tag.meta data: { grid_target: "datasource" },
                 content: {
                   rowData: rows.map { |index| { a: index, b: index, c: index } },
                   rowCount: 1_000,
                 }.to_json %>
  <% end %>

  <div class="h-full ag-theme-alpine"
       data-grid-target="table"></div>
<% end %>
```

The client-side version skips any server-side pagination and renders the
`<meta>` element with the dataset already encoded. This represents grids with a
dataset that's paginated entirely up-front on the client, without making
additional HTTP requests. Note the absence of the `src:` option from the
`turbo_frame_tag` call, and the omission of the `serverSideStoreType:` key
within the `grid_options_value:` arguments:

```erb
<h1 class="text-lg">Client-side pagination</h1>

<%
    # the grid is pre-rendered with data
    rows = 0...1_000
%>

<%= tag.div class: "h-[40vh]", data: {
      controller: "grid",
      grid_options_value: {
        columnDefs: [
          { field: "d" },
          { field: "e" },
          { field: "f" },
        ],
        pagination: true,
        rowModelType: "serverSide",
      },
    } do %>
  <%= turbo_frame_tag "grid-datasource",
                      data: { action: "grid:pagination->grid#loadRows" } do %>
    <%= tag.meta data: { grid_target: "datasource" },
                 content: {
                   rowData: rows.map { |index| { d: index, e: index, f: index } },
                   rowCount: 1_000,
                 }.to_json %>
  <% end %>

  <div class="h-full ag-theme-alpine"
       data-grid-target="table"></div>
<% end %>
```

Navigation and links from elsewhere in the application would drive traffic to
the page _without_ the `load` parameter. Once the page is loaded, the
`<turbo-frame>` will lazily-load the data by visiting _the same route_ with the
`?load=true` query parameter.

```js
// app/javascript/controllers/grid_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "datasource", "table" ]
  static values = { options: Object }

  connect() {
    this.grid = new agGrid.Grid(this.tableTarget, this.optionsValue)
    this.grid.gridOptions.api.setServerSideDatasource({
      getRows: params => {
        const event = new CustomEvent("grid:pagination", { detail: { params }, bubbles: true })

        this.datasourceTarget.dispatchEvent(event)
      }
    })
  }

  disconnect() {
    this.grid.destroy()
  }

  async loadRows({ currentTarget, detail: { params } }) {
    if (currentTarget.src) {
      const { startRow, endRow } = params.request
      const url = new URL(currentTarget.src, currentTarget.baseURI)
      url.searchParams.set("startRow", startRow)
      url.searchParams.set("endRow", endRow)

      currentTarget.src = url
    }

    try {
      await currentTarget.loaded

      const rows = JSON.parse(this.datasourceTarget.content)
      params.success(rows)
    } catch {
      params.fail()
    }
  }
}
```

## Why explore alternatives to our current implementation?

Stimulus Action routing idioms tend to push event listener attachment logic out
of controller code and into the HTML layer. Similarly, `<turbo-frame>` elements
are a declarative alternative to imperative `fetch` code.

In that same vein, any behavior that constructs URLs in JavaScript code has a
potential to be better served by Rails code and its access to routing helpers.

By pushing client-side event routing, configuration, data, and HTTP
interoperability into server-generated HTML, we limit our controller's burden of
responsibility.

## What might this unlock?

Some potential follow-up changes might include:

* Refreshing the dataset with an `<a>` click or `<form>` submission that targets
  the `<turbo-frame>` through a `[data-turbo-frame="grid-datasource"]`
* Deferring data retrieval for grids that are below the fold with [`<turbo-frame
  loading="lazy">`][loading-lazy]
* Declaring event listeners for `turbo:frame-load` elsewhere in the document
* Deep linking to pages and filtered datasets by encoding
  `?startRow=200&endRow=300` into the URL as query parameters

[loading-lazy]: https://turbo.hotwired.dev/handbook/frames#lazy-loading-frames

## How to experiment with this repository

[![Run on Repl.it](https://repl.it/badge/github/seanpdoyle/hotwire-example-template)](https://repl.it/github/seanpdoyle/hotwire-example-template)

You can fork the [@seanpdoyle/hotwire-example-ag-grid][] sandbox project on
[replit.com][].

[replit.com]: https://replit.com/
[@seanpdoyle/hotwire-example-ag-grid]: https://replit.com/@seanpdoyle/hotwire-example-ag-grid

## How to read this repository

Through the power of incremental Git diffs, each of this repository's
[branches][] provides a step-by-step demonstration of how to implement a feature
or behavior.

This repository's [main][] branch serves as the root all of the other branches,
and consists of a handful of commits generated by the Rails command line
interface.

Some branches are works-in-progress. Others are more refined. Some noteworthy
branches include:

* [hotwire-example-live-preview](https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-live-preview)
* [hotwire-example-typeahead-search](https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-typeahead-search)
* [hotwire-example-tooltip-fetch](https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-tooltip-fetch)
* [hotwire-example-stimulus-dynamic-forms](https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-stimulus-dynamic-forms)
* [hotwire-example-turbo-dynamic-forms](https://github.com/thoughtbot/hotwire-example-template/tree/hotwire-example-turbo-dynamic-forms)

A branch's [README.md](./README.md) includes a prose explanation of the patterns
at-play. When reading a branch's source code, read the changes commit-by-commit
either on the branch comparison page (for example,
[main...hotwire-example-live-preview][]), the branch's commits page (for
example, [hotwire-example-live-preview][]), or the branch's `README.md` file
(for example, [hotwire-example-live-preview][README]).

To experiment with a branch on your own, clone the repository, check out the
branch, execute its set up script, start the local server, then visit
<http://localhost:3000>:

```sh
bin/setup
bin/rails server
open http://localhost:3000
```

[branches]: https://github.com/thoughtbot/hotwire-example-template/branches/all
[main]: https://github.com/thoughtbot/hotwire-example-template/tree/main
[main...hotwire-example-live-preview]: https://github.com/thoughtbot/hotwire-example-template/compare/hotwire-example-live-preview
[hotwire-example-live-preview]: https://github.com/thoughtbot/hotwire-example-template/commits/hotwire-example-live-preview
[README]: https://github.com/thoughtbot/hotwire-example-template/blob/hotwire-example-live-preview/README.md
