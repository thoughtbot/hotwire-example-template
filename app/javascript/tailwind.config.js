import plugin from "https://cdn.skypack.dev/tailwindcss/plugin"

tailwind.config = {
  plugins: [
    plugin(function({ addVariant, e }) {
      addVariant("current", ({ modifySelectors, separator }) => {
        modifySelectors(({ className }) => {
          return `.current.${e(`current${separator}${className}`)}`
        })
      })

      addVariant("group-current", ({ modifySelectors, separator }) => {
        modifySelectors(({ className }) => {
          return `.group.current .${e(`group-current${separator}${className}`)}`
        })
      })
    })
  ],
  corePlugins: {
    preflight: false,
  }
}
