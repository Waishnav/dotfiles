return {
	"OXY2DEV/markview.nvim",
	lazy = false,

	opts = {
		-- Disable everything except markdown tables
		html = { enable = false },
		latex = { enable = false },
		typst = { enable = false },
		yaml = { enable = false },
		markdown_inline = { enable = false },

		markdown = {
			enable = true,

			block_quotes = { enable = false },
			code_blocks = { enable = false },
			headings = { enable = false },
			horizontal_rules = { enable = false },
			list_items = { enable = false },
			metadata_minus = { enable = false },
			metadata_plus = { enable = false },
			reference_definitions = { enable = false },

			-- Tables with rounded ASCII borders (default markview style)
			tables = {
				enable = true,
				block_decorator = true,
				use_virt_lines = false,

				parts = {
					top = { "╭", "─", "╮", "┬" },
					header = { "│", "│", "│" },
					separator = { "├", "─", "┤", "┼" },
					row = { "│", "│", "│" },
					bottom = { "╰", "─", "╯", "┴" },

					overlap = { "┝", "━", "┥", "┿" },

					align_left = "╼",
					align_right = "╾",
					align_center = { "╴", "╶" },
				},
			},
		},
	},
}
