-- local action_state = require "telescope.actions.state"
-- local action_set = require "telescope.actions.set"
local actions = require "telescope.actions"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
-- local previewers = require "telescope.previewers"
local sorters = require "telescope.sorters"
-- local utils = require "telescope.utils"
local conf = require("telescope.config").values
-- local log = require "telescope.log"

local Path = require "plenary.path"

local flatten = vim.tbl_flatten
local filter = vim.tbl_filter

local opts_contain_invert = function(args)
  local invert = false
  local files_with_matches = false

  for _, v in ipairs(args) do
    if v == "--invert-match" then
      invert = true
    elseif v == "--files-with-matches" or v == "--files-without-match" then
      files_with_matches = true
    end

    if #v >= 2 and v:sub(1, 1) == "-" and v:sub(2, 2) ~= "-" then
      local non_option = false
      for i = 2, #v do
        local vi = v:sub(i, i)
        if vi == "=" then -- ignore option -g=xxx
          break
        elseif vi == "g" or vi == "f" or vi == "m" or vi == "e" or vi == "r" or vi == "t" or vi == "T" then
          non_option = true
        elseif non_option == false and vi == "v" then
          invert = true
        elseif non_option == false and vi == "l" then
          files_with_matches = true
        end
      end
    end
  end
  return invert, files_with_matches
end

local get_open_filelist = function(grep_open_files, cwd)
  if not grep_open_files then
    return nil
  end

  local bufnrs = filter(function(b)
    if 1 ~= vim.fn.buflisted(b) then
      return false
    end
    return true
  end, vim.api.nvim_list_bufs())
  if not next(bufnrs) then
    return
  end

  local filelist = {}
  for _, bufnr in ipairs(bufnrs) do
    local file = vim.api.nvim_buf_get_name(bufnr)
    table.insert(filelist, Path:new(file):make_relative(cwd))
  end
  return filelist
end

local kensaku = function(opts)
  local vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
  local search_dirs = opts.search_dirs
  local grep_open_files = opts.grep_open_files
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()

  local filelist = get_open_filelist(grep_open_files, opts.cwd)
  if search_dirs then
    for i, path in ipairs(search_dirs) do
      search_dirs[i] = vim.fn.expand(path)
    end
  end

  local additional_args = {}
  if opts.additional_args ~= nil then
    if type(opts.additional_args) == "function" then
      additional_args = opts.additional_args(opts)
    elseif type(opts.additional_args) == "table" then
      additional_args = opts.additional_args
    end
  end

  if opts.type_filter then
    additional_args[#additional_args + 1] = "--type=" .. opts.type_filter
  end

  if type(opts.glob_pattern) == "string" then
    additional_args[#additional_args + 1] = "--glob=" .. opts.glob_pattern
  elseif type(opts.glob_pattern) == "table" then
    for i = 1, #opts.glob_pattern do
      additional_args[#additional_args + 1] = "--glob=" .. opts.glob_pattern[i]
    end
  end

  local args = flatten { vimgrep_arguments, additional_args }
  opts.__inverted, opts.__matches = opts_contain_invert(args)

  local live_grepper = finders.new_job(function(prompt)
    if not prompt or prompt == "" then
      return nil
    end

    local search_list = {}

    if grep_open_files then
      search_list = filelist
    elseif search_dirs then
      search_list = search_dirs
    end

    local regex = vim.fn["kensaku#query"](prompt)

    return flatten { args, "--", regex, search_list }
  end, opts.entry_maker or make_entry.gen_from_vimgrep(opts), opts.max_results, opts.cwd)

  pickers
    .new(opts, {
      prompt_title = "Kensaku",
      finder = live_grepper,
      previewer = conf.grep_previewer(opts),
      -- TODO: It would be cool to use `--json` output for this
      -- and then we could get the highlight positions directly.
      sorter = sorters.highlighter_only(opts),
      attach_mappings = function(_, map)
        map("i", "<c-space>", actions.to_fuzzy_refine)
        return true
      end,
    })
    :find()
end

return kensaku
