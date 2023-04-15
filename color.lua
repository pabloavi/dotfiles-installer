-- print with color

local M = {}

---Print text with color
---@param color string black|red|green|yellow|blue|magenta|cyan|white|light_red|light_green|light_yellow|light_blue|light_magenta|light_cyan
---@param text string
M.print_color = function(text, color)
	local color_codes = {
		black = 30,
		red = 31,
		green = 32,
		yellow = 33,
		blue = 34,
		magenta = 35,
		cyan = 36,
		white = 37,
		light_red = 91,
		light_green = 92,
		light_yellow = 93,
		light_blue = 94,
		light_magenta = 95,
		light_cyan = 96,
	}

	local reset_code = "\27[0m"
	local color_code = "\27[" .. color_codes[color] .. "m"

	print(color_code .. text .. reset_code)
end

return M
