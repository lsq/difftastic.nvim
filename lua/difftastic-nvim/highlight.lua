--- Highlight group definitions.
local M = {}

--- Default opacity for background highlights (0-1)
M.bg_opacity = 0.38
M.line_bg_opacity = M.bg_opacity * 0.5
M.riff_style = true

--- Blend two colors with a given alpha.
--- @param fg string Foreground hex color (e.g., "#ff0000")
--- @param bg string Background hex color
--- @param alpha number Blend factor (0 = all bg, 1 = all fg)
--- @return string Blended hex color
local function blend(fg, bg, alpha)
    local function hex_to_rgb(hex)
        hex = hex:gsub("#", "")
        return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
    end

    local fg_r, fg_g, fg_b = hex_to_rgb(fg)
    local bg_r, bg_g, bg_b = hex_to_rgb(bg)

    local r = math.floor(fg_r * alpha + bg_r * (1 - alpha))
    local g = math.floor(fg_g * alpha + bg_g * (1 - alpha))
    local b = math.floor(fg_b * alpha + bg_b * (1 - alpha))

    return string.format("#%02x%02x%02x", r, g, b)
end

--- Get the foreground color from a highlight group.
--- @param name string Highlight group name
--- @return string|nil Hex color or nil
local function get_fg(name)
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl.fg then
        return string.format("#%06x", hl.fg)
    end
    return nil
end

--- Get the background color from Normal or fallback.
--- @return string Hex color
local function get_normal_bg()
    local hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    if hl.bg then
        return string.format("#%06x", hl.bg)
    end
    return "#1a1b26" -- fallback dark background
end

--- Linked highlight definitions (inherit from colorscheme)
--- @type table<string, vim.api.keyset.highlight>
M.linked = {
    -- Inline (riff-style) gutter prefix colors
    DifftInlineAddSign = { link = "Added" },
    DifftInlineDelSign = { link = "Removed" },
    DifftInlineContextSign = { link = "Comment" },

    -- Tree highlights
    DifftFileAdded = { link = "Added" },
    DifftFileDeleted = { link = "Removed" },
    DifftDirectory = { link = "Directory" },
    DifftTreeDirectory = { link = "Directory" },
    DifftTreeAdded = { link = "Added" },
    DifftTreeDeleted = { link = "Removed" },
    DifftTreeModified = { link = "Changed" },
    DifftTreeRenamed = { link = "Directory" },
    DifftTreeRange = { link = "BlueItalic" },

    -- Picker text highlights
    DifftPickerJjIconCurrent = { link = "Added" },
    DifftPickerJjIconImmutable = { link = "Removed" },
    DifftPickerJjIconNormal = { link = "Directory" },
    DifftPickerJjRevset = { link = "Identifier" },
    DifftPickerJjAge = { link = "Comment" },
}

--- Apply all highlight groups.
--- @param overrides table<string, vim.api.keyset.highlight> User overrides
local function apply_highlights(overrides)
    -- Setup linked highlights
    for name, default in pairs(M.linked) do
        local hl = vim.tbl_extend("force", default, overrides[name] or {})
        vim.api.nvim_set_hl(0, name, hl)
    end

    -- Setup derived highlights
    local normal_bg = get_normal_bg()
    local normal_fg = get_fg("Normal") or "#c0caf5"
    local comment_fg = get_fg("Comment") or "#565f89"
    local added_fg = get_fg("Added") or "#9ece6a"
    local removed_fg = get_fg("Removed") or "#f7768e"
    local changed_fg = get_fg("Changed") or get_fg("Identifier") or "#7aa2f7"

    local added_bg = blend(added_fg, normal_bg, M.bg_opacity)
    local removed_bg = blend(removed_fg, normal_bg, M.bg_opacity)
    local added_line_bg = blend(added_fg, normal_bg, M.line_bg_opacity)
    local removed_line_bg = blend(removed_fg, normal_bg, M.line_bg_opacity)
    local normal_blend = blend(normal_fg, normal_bg, M.bg_opacity)
    local tree_cursor_bg = blend(normal_fg, normal_bg, 0.14)
    local tree_panel_bg = blend(normal_fg, normal_bg, 0.03)

    local derived = {
        -- Riff-style: stronger token emphasis, keeps fg for readability
        DifftAddedRiff = { fg = added_fg, bg = added_bg, bold = true },
        DifftRemovedRiff = { fg = removed_fg, bg = removed_bg, bold = true },
        -- Stronger token emphasis for riff_style (bold on top of full-strength bg)
        DifftAddedBold = { fg = added_fg, bg = added_bg, bold = true },
        DifftRemovedBold = { fg = removed_fg, bg = removed_bg, bold = true },
        -- Background highlights (blended from fg colors)
        DifftAdded = { bg = added_bg },
        DifftRemoved = { bg = removed_bg },
        DifftAddedLine = { bg = added_line_bg },
        DifftRemovedLine = { bg = removed_line_bg },
        DifftTreeCurrent = { bg = normal_blend, bold = true },
        DifftTreeNormal = { bg = tree_panel_bg },
        DifftTreeCursorLine = { bg = tree_cursor_bg },
        DifftTreeEndOfBuffer = { fg = tree_panel_bg, bg = tree_panel_bg },
        DifftTreeTitle = { fg = normal_fg, bold = true },
        DifftTreeDivider = { fg = comment_fg },
        DifftTreeMuted = { fg = comment_fg },
        DifftTreeIndent = { fg = comment_fg },
        DifftTreeChevron = { fg = comment_fg },
        DifftTreeFile = { fg = normal_fg },
        DifftTreePathMuted = { fg = comment_fg },
        DifftTreeRange = { fg = changed_fg, italic = true },
        DifftTreeModified = { fg = changed_fg, bold = true },
        DifftPickerPreviewHover = { bg = normal_blend, bold = true },
        DifftPickerJjDesc = { fg = normal_fg },
        -- Foreground highlights
        DifftAddedFg = { fg = added_fg, bold = true },
        DifftRemovedFg = { fg = removed_fg, bold = true },
        DifftFiller = { fg = normal_blend },
    }

    for name, default in pairs(derived) do
        local hl = vim.tbl_extend("force", default, overrides[name] or {})
        vim.api.nvim_set_hl(0, name, hl)
    end
end

--- Setup highlight groups with optional overrides.
--- @param overrides table<string, vim.api.keyset.highlight>|nil User overrides
function M.setup(overrides)
    overrides = overrides or {}

    -- Apply highlights now
    apply_highlights(overrides)

    -- Reapply when the colorscheme or background mode changes
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("DifftHighlights", { clear = true }),
        callback = function()
            apply_highlights(overrides)
        end,
    })
    vim.api.nvim_create_autocmd("OptionSet", {
        group = vim.api.nvim_create_augroup("DifftHighlightOptions", { clear = true }),
        pattern = "background",
        callback = function()
            apply_highlights(overrides)
        end,
    })
end

--- Namespace for inline-mode diff extmarks.
M.inline_ns = vim.api.nvim_create_namespace("difft-inline")

--- Apply riff-style marks to one rendered inline line.
--- @param buf integer
--- @param lnum integer 0-based buffer line
--- @param side table  row.left / row.right
--- @param kind "add"|"delete"
--- @param prefix string "-"|"+"
function M.apply_inline_line(buf, lnum, side, kind, prefix)
    local ns = M.inline_ns
    -- gutter sign
    vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
        end_col = #prefix,
        hl_group = kind == "add" and "DifftInlineAddSign" or "DifftInlineDelSign",
        priority = 150,
    })
    -- token spans, shifted right by the prefix width
    local span_hl = kind == "add" and "DifftAddedRiff" or "DifftRemovedRiff"
    local line_hl = kind == "add" and "DifftAddedLine" or "DifftRemovedLine"
    for _, hl in ipairs(side.highlights or {}) do
        if hl["end"] == -1 then
            vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
                end_row = lnum + 1,
                end_col = 0,
                hl_group = line_hl,
                hl_eol = true,
                priority = 100,
            })
        else
            vim.api.nvim_buf_set_extmark(buf, ns, lnum, hl.start + #prefix, {
                end_row = lnum,
                end_col = hl["end"] + #prefix,
                hl_group = span_hl,
                priority = 200,
            })
        end
    end
end

return M
