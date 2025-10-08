-- [nfnl] fnl/hover/init.fnl
local function disable_diagnostic(bufid)
  if vim.diagnostic.is_enabled({bufnr = bufid}) then
    return pcall(vim.diagnostic.enable, false, {bufnr = bufid})
  else
    return nil
  end
end
local function open_hover_window(text_or_lines, title, callback)
  local lines
  do
    local _2_ = type(text_or_lines)
    if (_2_ == "string") then
      lines = vim.fn.split(text_or_lines, "\n", true)
    else
      local _ = _2_
      lines = text_or_lines
    end
  end
  local max_cols = 0
  for _, l in ipairs(lines) do
    max_cols = math.max(max_cols, vim.api.nvim_strwidth(l))
  end
  local bufid = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufid, 0, -1, false, lines)
  local win_opts = {title = title, relative = "cursor", row = 1, col = 0, width = max_cols, height = math.min(16, #lines), style = "minimal"}
  local winid = vim.api.nvim_open_win(bufid, true, win_opts)
  disable_diagnostic(bufid)
  vim.bo[bufid]["readonly"] = true
  vim.bo[bufid]["modifiable"] = false
  vim.wo[winid]["wrap"] = false
  if callback then
    return callback(bufid, winid)
  else
    return nil
  end
end
local function get_current_file()
  return vim.fn.expand("%")
end
local function get_cursor_location()
  return vim.fn.line("."), vim.fn.col(".")
end
local function get_cursor_word()
  return vim.fn.expand("<cword>")
end
local function get_selection_text()
  vim.cmd("exe  \"normal \\<Esc>\"")
  vim.cmd("normal! gv\"xy")
  return vim.fn.trim(vim.fn.getreg("x"))
end
local function on_v_modes()
  local v_block_mode = vim.api.nvim_replace_termcodes("<C_V>", true, true, true)
  local v_modes = {"v", "V", v_block_mode}
  return vim.list_contains(v_modes, vim.fn.mode())
end
local function get_cursor_text()
  local _5_ = on_v_modes()
  if (_5_ == false) then
    return get_cursor_word()
  elseif (_5_ == true) then
    return get_selection_text()
  else
    return nil
  end
end
local function do_run(_7_)
  local run = _7_["run"]
  local line_number, column_number = get_cursor_location()
  return run({file = get_current_file(), line = line_number, column = column_number, text = get_cursor_text(), open_hover_window = open_hover_window})
end
local function add_keymap(item, bufid)
  local name = item["name"]
  local key = item["key"]
  local mode = item["mode"]
  local function _8_()
    return do_run(item)
  end
  return vim.keymap.set(mode, key, _8_, {buffer = bufid, desc = name})
end
local function create_autocmd(item)
  local name = item["name"]
  local event = item["event"]
  local pattern = item["pattern"]
  local opts
  local function _10_(_9_)
    local bufid = _9_["buf"]
    add_keymap(item, bufid)
    return nil
  end
  opts = {desc = name, pattern = pattern, callback = _10_}
  return vim.api.nvim_create_autocmd(event, opts)
end
local M = {}
M.setup = function(config)
  local items
  local _12_
  do
    local t_11_ = config
    if (nil ~= t_11_) then
      t_11_ = t_11_.items
    else
    end
    _12_ = t_11_
  end
  items = (_12_ or {})
  for _, item in ipairs(items) do
    create_autocmd(item)
  end
  return nil
end
return M
