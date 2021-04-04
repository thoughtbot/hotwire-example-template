import L from "https://cdn.skypack.dev/leaflet@1.6.0"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "bbox", "map" ] }
  static get values() { return { tileLayer: Object, geoJsonLayer: Object } }

  initialize() {
    this.leaflet = L.map(this.mapTarget)
  }

  connect() {
    this.leaflet.on("moveend", this.prepareSearch)
  }

  disconnect() {
    this.leaflet.off("moveend", this.prepareSearch)
  }

  tileLayerValueChanged({ templateUrl, ...options }) {
    const layer = L.tileLayer(templateUrl, options)

    layer.addTo(this.leaflet).bringToBack()
  }

  geoJsonLayerValueChanged({ bbox: [ west, south, east, north ], ...featureCollection }) {
    const bounds = L.latLngBounds([ south, west ], [ north, east ])
    const layer = L.geoJSON(featureCollection)

    layer.addTo(this.leaflet).bringToFront()

    this.leaflet.fitBounds(bounds)
  }

  prepareSearch = ({ target }) => {
    const bbox = target.getBounds().toBBoxString()
    this.bboxTarget.value = bbox
  }
}
