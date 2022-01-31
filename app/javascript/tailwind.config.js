tailwind.config = {
  corePlugins: {
    preflight: false,
  },
  plugins: [
    tailwind.plugin(function({ addVariant }) {
      addVariant("group-inline-edit", ".group.inline-edit &")
    })
  ]
}
