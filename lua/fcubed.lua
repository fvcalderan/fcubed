-- Fcubed - Felipe's Fuzzy Finder

local M = {}

-- Width and height to screen ratio for the finder window
local width_ratio = 0.8
local height_ratio = 0.8

-- Setup function
function M.setup(opts)
    width_ratio = opts.width_ratio or 0.8
    height_ratio = opts.height_ratio or 0.8
end

-- Current FZF window state
local state = {
    buf = -1,
    win = -1
}

-- Remove empty entries from a table
function RemoveEmptyEntries(tbl)
    for i = #tbl, 1, -1 do
        if tbl[i] == nil or tbl[i] == "" then
            table.remove(tbl, i)
        end
    end
end

-- Add lines to the quickfix list or jump to a single location
function OpenInBuffer(input)
    local qflist = {}
    local line_count = 0

    -- Process input table and build quickfix list
    for _, line in ipairs(input) do
        line_count = line_count + 1
        -- Extract file, line number, and content from each line
        local file, linenr, text = line:match("([^:]+):([^:]+):(.+)")
        if file and linenr and text then
            table.insert(qflist, {
                filename = file,
                lnum = tonumber(linenr),
                text = text
            })
        end
    end

    if line_count == 1 and #qflist > 0 then
        -- Single entry selected

        -- Jump to the location
        vim.cmd('edit ' .. qflist[1].filename)
        vim.fn.cursor(qflist[1].lnum, 1)
    else
        -- Multiple entries selected

        -- Set quickfix list
        vim.cmd('edit ' .. qflist[1].filename)
        vim.fn.cursor(qflist[1].lnum, 1)

        -- Jump to the location
        vim.fn.setqflist(qflist, 'r')
        vim.cmd('copen')
    end
end

local function create_window(title)
    -- Window size
    local width = vim.o.columns
    local height = vim.o.lines
    local win_width = math.floor(width * width_ratio)
    local win_height = math.floor(height * height_ratio)
    local row = math.floor((height - win_height) / 2) - 1
    local col = math.floor((width - win_width) / 2)

    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Create a new window using the created buffer
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "win",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = title,
        title_pos = "center",
        noautocmd = true,
    })

    return { buf = buf, win = win }
end

local function run_fzf(job, use_lines, title)
    state = create_window(title)

    -- Open terminal running fzf in the new window
    vim.fn.jobstart(job, {

        term = true,

        -- On exit, grab the return value and open in the previous buffer
        on_exit = function(_, exit_code)
            -- If return value is 0, open selected file
            if exit_code == 0 then
                -- Get the selected file from fzf output
                ---@diagnostic disable-next-line: param-type-mismatch
                local fzf_output = vim.fn.getbufline("%", 1, "$")
                RemoveEmptyEntries(fzf_output)

                -- Delete current buffer
                local buft = vim.api.nvim_get_current_buf()
                vim.api.nvim_buf_delete(buft, { force = true })

                -- Open the selected file(s)
                if use_lines then
                    -- Take into account line numbers
                    OpenInBuffer(fzf_output)
                else
                    -- Consider only file names
                    for _, file in ipairs(fzf_output) do
                        vim.cmd('edit ' .. file)
                    end
                end
            else -- Otherwise, just hide the window
                vim.api.nvim_win_hide(state.win)
            end
        end
    })

    -- Immediately enter insert mode
    vim.cmd("startinsert")
end

-- Seach files
vim.api.nvim_create_user_command("FcubedFile", function()
    if not vim.api.nvim_win_is_valid(state.win) then
        run_fzf("fzf --multi", false, "Fcubed File")
    else
        vim.api.nvim_win_close(state.win, true)
    end
end, {})

-- Search string
vim.api.nvim_create_user_command("FcubedString", function()
    if not vim.api.nvim_win_is_valid(state.win) then
        run_fzf("rg -Hn --trim --no-heading '^.+$' | fzf --multi", true, "Fcubed String")
    else
        vim.api.nvim_win_close(state.win, true)
    end
end, {})

-- Search string below cursor
vim.api.nvim_create_user_command("FcubedCursor", function()
    if not vim.api.nvim_win_is_valid(state.win) then
        run_fzf("rg -Hn --trim --no-heading " .. vim.fn.expand("<cword>") .. " | fzf --multi", true, "Fcubed Cursor")
    else
        vim.api.nvim_win_close(state.win, true)
    end
end, {})


-- Key mapping to trigger the function
-- vim.api.nvim_set_keymap("n", "-", ":FcubedCursor<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("n", "<leader>-", ":FcubedString<CR>", { noremap = true, silent = true })

return M
