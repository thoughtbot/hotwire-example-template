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
