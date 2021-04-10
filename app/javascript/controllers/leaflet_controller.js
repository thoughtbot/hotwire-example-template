import L from "https://cdn.skypack.dev/leaflet@1.6.0"
import { Controller } from "@hotwired/stimulus"

const targetsToMaps = new WeakMap
const mapsToTileLayers = new WeakMap
const mapsToGeoJsonLayers = new WeakMap

export default class extends Controller {
  static get targets() { return [ "bbox", "map", "template" ] }
  static get values() { return { tileLayer: Object, geoJsonLayer: Object } }

  initialize() {
    this.leaflet = targetsToMaps.get(this.mapTarget) || L.map(this.mapTarget)

    targetsToMaps.set(this.mapTarget, this.leaflet)
  }

  connect() {
    this.leaflet.on("moveend", this.prepareSearch)
  }

  disconnect() {
    this.leaflet.off("moveend", this.prepareSearch)
  }

  tileLayerValueChanged({ templateUrl, ...options }) {
    const layer = L.tileLayer(templateUrl, options)
    const existingLayer = mapsToTileLayers.get(this.leaflet)

    layer.addTo(this.leaflet).bringToBack()
    mapsToTileLayers.set(this.leaflet, layer)

    if (existingLayer) {
      existingLayer.removeFrom(this.leaflet)
    }
  }

  geoJsonLayerValueChanged({ bbox: [ west, south, east, north ], ...featureCollection }) {
    const { pointToLayer } = this
    const bounds = L.latLngBounds([ south, west ], [ north, east ])
    const layer = L.geoJSON(featureCollection, { pointToLayer })
    const existingLayer = mapsToGeoJsonLayers.get(this.leaflet)

    layer.addTo(this.leaflet).bringToFront()
    mapsToGeoJsonLayers.set(this.leaflet, layer)

    if (existingLayer) {
      this.leaflet.once("zoomend", () => existingLayer.removeFrom(this.leaflet))
      this.leaflet.flyToBounds(bounds)
    } else {
      this.leaflet.fitBounds(bounds)
    }
  }

  prepareSearch = ({ target }) => {
    const bbox = target.getBounds().toBBoxString()
    this.bboxTarget.value = bbox
  }

  pointToLayer = ({ properties: { icon: { id, ...options } } }, latLng) => {
    const html = this.templateTarget.content.getElementById(id).cloneNode(true)

    return L.marker(latLng, { icon: L.divIcon({ html, ...options }) })
  }
}
