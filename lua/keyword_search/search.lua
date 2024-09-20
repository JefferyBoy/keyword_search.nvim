local M = {}
local string_util = require("keyword_search.string_util")

local CMDS = {
	{
		name = "SearcheInWord",
		opts = {
			desc = "搜索当前光标位置的单词",
			nargs = 1,
			bar = true,
		},
		command = function(c)
			M.search_in_word(c.args)
		end,
	},
	{
		name = "UnSearcheInWord",
		opts = {
			desc = "取消搜索光标处的单词",
		},
		command = function()
			M.unsearch_in_word()
		end,
	},
	{
		name = "SearcheCurrentBufferToNew",
		opts = {
			desc = "搜索当前文件到新buffer",
		},
		command = function()
			M.search_this_buffer_to_new()
		end,
	},
	{
		name = "SearcheAllFilesToNew",
		opts = {
			desc = "搜索所有文件到新buffer",
		},
		command = function()
			M.search_all_file_to_new()
		end,
	},
}

-- 运行命令并在当前buffer的下面显示结果
local function run_cmd_and_show_result(cmd, title)
	-- local output = vim.fn.systemlist(cmd)
  local output = vim.fn.split(vim.fn.system(cmd), '\n', 1)
	if output[1] ~= "" then
		-- 在当前buffer的下面拆分创建新的buffer
		-- vim.api.nvim_command("botright new")
		local buf_name = vim.api.nvim_buf_get_name(0)
		if title ~= nil and type(title) == "string" then
			buf_name = title
		end
		buf_name = string.match(buf_name, "([^/]+)$") or ""
		local nbuf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_command("buffer " .. nbuf)
		vim.api.nvim_buf_set_name(nbuf, buf_name)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
		vim.api.nvim_buf_set_option(0, "buftype", "nofile")
		-- vim.api.nvim_buf_set_option(0, "bufhidden", "delete")
		vim.api.nvim_buf_set_option(0, "swapfile", false)
		vim.api.nvim_buf_set_option(0, "buflisted", true)
		vim.api.nvim_buf_set_option(0, "filetype", "git")
	else
		vim.api.nvim_echo({ { "Error output is empty", "ErrorMsg" } }, true, {})
	end
end

-- 搜索剪贴板的内容
function M.search_copy_text()
	local text = vim.fn.eval('@"')
	if text ~= "" then
		vim.cmd('let @/ = "' .. vim.fn.escape(text, "\\/") .. '"')
		-- 回到普通模式
		vim.cmd("normal! n<CR>")
		-- vim.api.nvim_feedkeys("\\<Esc>", "n", true)
	end
end

-- 搜索光标处单词
function M.search_in_word(append)
	local z = vim.fn.eval("@z")
	vim.cmd("normal! viw")
	vim.cmd('normal! "zy')
	local text = vim.fn.eval("@z")
	-- 恢复寄存器的值
	vim.cmd("let @z = '" .. z .. "'")
	if append == "true" then
		-- 搜索内容已经存在后，不需要再次添加
		local old_search = vim.fn.eval("@/")
		if string.find(old_search, text) ~= nil then
			return
		end
		text = vim.fn.eval("@/") .. "\\|" .. text
	end
	vim.cmd('let @/ = "' .. vim.fn.escape(text, "\\/") .. '"')
	vim.cmd("normal! nN<CR>")
end

function M.unsearch_in_word()
	local z = vim.fn.eval("@z")
	vim.cmd("normal! viw")
	vim.cmd('normal! "zy')
	local text = vim.fn.eval("@z")
	vim.cmd("let @z = '" .. z .. "'")
	local old_search = vim.fn.eval("@/")
  local pos = string.find(old_search, text)
	if pos >= 0 and string.len(text) > 0 then
    local t1 = string.gsub(old_search, '\\|' .. text , '')
    text = string.gsub(t1, text .. '\\|', '')
    vim.cmd('let @/ = "' .. vim.fn.escape(text, '\\|') .. '"')
	end
end

-- 搜索当前buffer内容并放到新的buffer中显示
function M.search_this_buffer_to_new()
	local buf = vim.api.nvim_get_current_buf()
	local pattern = vim.fn.eval("@/")
	local results = {}
	local results_buf_name = "Search: " .. pattern .. " buf = " .. buf
	for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
		local buf_name = vim.api.nvim_buf_get_name(buf_id)
		buf_name = string.match(buf_name, "([^/]+)$") or ""
		if buf_name == results_buf_name then
			vim.api.nvim_command("buffer " .. buf_id)
			return
		end
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
	for _, line in ipairs(lines) do
		if string_util.find_ignore_case(line, pattern) then
			table.insert(results, line)
		end
	end
	if #results == 0 then
		print("search result empty")
		return
	end
	-- local nbuf = vim.api.nvim_create_buf(true, true)
	-- vim.api.nvim_command("edit " .. results_buf_name)
	-- vim.api.nvim_buf_set_name(0, results_buf_name)
	vim.api.nvim_command("tabedit " .. results_buf_name)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, results)
	vim.api.nvim_buf_set_option(0, "buftype", "nofile")
	vim.api.nvim_buf_set_option(0, "swapfile", false)
	-- vim.api.nvim_buf_set_option(nbuf, "buflisted", true)
	-- vim.api.nvim_buf_set_option(nbuf, "bufhidden", "delete")
	-- vim.api.nvim_buf_set_option(nbuf, "filetype", "git")
end

-- 搜索项目的所有内容到新的buffer
function M.search_all_file_to_new()
	local dir = vim.fn.getcwd()
	local pattern = vim.fn.eval("@/")
  local cmd = ''
	pattern = string.gsub(pattern, "\\", "")
  if vim.fn.executable("rg") then
	  cmd = 'rg -ai "' .. pattern .. '" "' .. dir .. '" | cut -d : -f 2- | sort'
  else
    cmd = 'grep -ari "' .. pattern .. '" "' .. dir .. '" | cut -d : -f 2- | sort'
  end
	run_cmd_and_show_result(cmd, "SearchAll: " .. pattern)
end

function M.setup()
	for _, cmd in pairs(CMDS) do
		local opts = vim.tbl_extend("force", cmd.opts, { force = true })
		vim.api.nvim_create_user_command(cmd.name, cmd.command, opts)
	end
	-- vim.cmd([[command! -nargs=1 SearcheInWord :lua require("plugins.searcher").search_in_word(<q-args>)]])
	-- vim.cmd([[command! -nargs=0 UnSearcheInWord :lua require("plugins.searcher").unsearch_in_word()]])
	-- vim.cmd([[command! -nargs=0 SearcheCurrentBufferToNew :lua require("plugins.searcher").search_this_buffer_to_new()]])
	-- vim.cmd([[command! -nargs=0 SearcheAllFilesToNew :lua require("plugins.searcher").search_all_file_to_new()]])
end

return M

