local M = {}

M.split = function(input, delimiter)
	input = tostring(input)
	delimiter = tostring(delimiter)
	if delimiter == "" then
		return false
	end
	local pos, arr = 0, {}
	for st, sp in
		function()
			return string.find(input, delimiter, pos, true)
		end
	do
		table.insert(arr, string.sub(input, pos, st - 1))
		pos = sp + 1
	end
	table.insert(arr, string.sub(input, pos))
	return arr
end

M.find_ignore_case = function(content, filter)
  local low_content = string.lower(content)
  local low_filter = string.lower(filter)
  local splits = M.split(low_filter, "\\|")
  if #splits > 1 then
    for _, v in pairs(splits) do
      if string.find(low_content, v) then
        return content
      end
    end
  end
  if string.find(low_content, low_filter) then
    return content
  end
  return nil
end

return M

