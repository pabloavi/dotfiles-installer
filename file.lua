local M = {}

M.get_name = function(file)
	return string.match(file, "/([^/]+)$")
end

M.get_path = function(file)
	return string.match(file, "(.+)/[^/]+$")
end

return M
