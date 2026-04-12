return {
  "vyfor/cord.nvim",
  build = "./build || .\\build",
  event = "VeryLazy",
  opts = {
    editor = {
      client = "astronvim",
      tooltip = "AstroNvim",
    },
    display = {
      show_time = true,
    },
  },
}
