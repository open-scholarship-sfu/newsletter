--[[
  newsletter.lua: turns a Quarto document into an email-safe HTML newsletter.

  Email clients (Outlook in particular) ignore most <style> CSS, so this filter
  writes every visual style inline and lays everything out with tables.
  Nothing needs to be installed beyond Quarto.

  Document structure
    * Content before the first level-2 heading is the intro.
    * Each "## Heading" starts a new section. Add {.tinted} for a shaded section.

  Components (fenced divs)
    ::: {.feature image="..." alt="..." link="..."}   story with a large image
    ::: {.event date="2026-11-18" time="..." place="..."}   event with a date tile
    ::: {.spotlight image="..." alt="..."}           person with a round photo
    ::: highlight                                     highlighted box
    ::: two-col  (containing two  ::: {.col image="..." link="..."}  divs)
    [Label](url){.button}   or   {.button .secondary}   buttons

  Configuration lives under `newsletter:` in _quarto.yml (see DEFAULTS below).
]]

local DEFAULTS = {
  name = "Open Scholarship News",
  org = "Simon Fraser University",
  ["image-base-url"] = "",
  ["in-this-issue"] = true,
  fragment = true,
  colors = {
    primary = "#26215C",          -- masthead, headings, buttons, footer
    accent = "#8FD9BF",           -- mint: masthead details, highlight boxes
    link = "#3B37B0",
    ink = "#24232E",              -- body text
    muted = "#686775",
    tint = "#F2F1F8",             -- shaded sections
    highlight = "#DDF3EA",        -- highlight box background
    line = "#E2E0EC",
    page = "#ECEBF3",             -- background around the email
    ["on-primary"] = "#FFFFFF",
    ["on-primary-muted"] = "#B9B6DC",
  },
  fonts = {
    heading = "'Helvetica Neue', Helvetica, Arial, sans-serif",
    body = "'Helvetica Neue', Helvetica, Arial, sans-serif",
  },
}

local W = 600          -- email width
local PAD = 40         -- side padding
local INNER = W - 2 * PAD

local cfg, C, F

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

local function str(x)
  if x == nil then return nil end
  local s = pandoc.utils.stringify(x)
  -- smart punctuation would break CSS font stacks and URLs
  s = s:gsub("[\226][\128][\152\153]", "'"):gsub("[\226][\128][\156\157]", '"')
  return s
end

local function esc(s)
  s = tostring(s or "")
  s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
  return s
end

local function deep_merge(base, over)
  local out = {}
  for k, v in pairs(base) do out[k] = v end
  for k, v in pairs(over or {}) do
    if type(v) == "table" and type(out[k]) == "table" then
      out[k] = deep_merge(out[k], v)
    else
      out[k] = v
    end
  end
  return out
end

-- Convert metadata into plain Lua values. Keys listed in `rich` keep
-- their Markdown and are rendered to HTML.
local function meta_to_lua(m, rich, key)
  local t = pandoc.utils.type(m)
  if t == "boolean" or type(m) == "boolean" then return m end
  if t == "Inlines" or t == "Blocks" or type(m) == "string" then
    if rich and rich[key] then
      local blocks = t == "Inlines" and { pandoc.Plain(m) } or m
      if type(m) == "string" then return m end
      return pandoc.write(pandoc.Pandoc(blocks), "html")
    end
    return str(m)
  end
  if t == "List" then
    local out = {}
    for i, v in ipairs(m) do out[i] = meta_to_lua(v, rich, key) end
    return out
  end
  if type(m) == "table" then
    local out = {}
    for k, v in pairs(m) do out[k] = meta_to_lua(v, rich, k) end
    return out
  end
  return m
end

local function css(t)
  local parts = {}
  for _, kv in ipairs(t) do parts[#parts + 1] = kv end
  return table.concat(parts, "; ")
end

local function absolutize(src)
  if not src or src == "" then return src end
  local base = cfg["image-base-url"] or ""
  if base == "" or src:match("^%a[%w+.-]*:") or src:match("^//") or src:match("^/") then
    return src
  end
  if not base:match("/$") then base = base .. "/" end
  return base .. src:gsub("^%./", "")
end

local function attr(el, k) local v = el.attributes[k]; if v == "" then return nil end; return v end

---------------------------------------------------------------------------
-- inline styles for elements produced by Pandoc's HTML writer
---------------------------------------------------------------------------

local TAG_STYLES, TABLE_STYLES

local function build_tag_styles()
  local body = "font-family:" .. F.body
  local head = "font-family:" .. F.heading
  TAG_STYLES = {
    p = css { "margin:0 0 16px 0", "font-size:16px", "line-height:26px" },
    h3 = css { "margin:6px 0 8px 0", head, "font-size:20px", "line-height:26px", "font-weight:bold", "letter-spacing:-0.2px", "color:" .. C.primary },
    h4 = css { "margin:4px 0 6px 0", body, "font-size:16px", "line-height:24px", "font-weight:bold", "color:" .. C.primary },
    a = css { "color:" .. C.link, "text-decoration:underline" },
    ul = css { "margin:0 0 16px 0", "padding:0 0 0 22px" },
    ol = css { "margin:0 0 16px 0", "padding:0 0 0 22px" },
    li = css { "margin:0 0 8px 0", "font-size:16px", "line-height:25px" },
    blockquote = css { "margin:0 0 16px 0", "padding:0", head, "font-size:19px", "line-height:28px", "color:" .. C.primary },
    img = css { "max-width:100%", "height:auto", "border:0", "display:block" },
    figure = css { "margin:0 0 16px 0" },
    figcaption = css { "margin:8px 0 0 0", "font-size:13px", "line-height:19px", "color:" .. C.muted },
    strong = css { "color:" .. C.ink },
    code = css { "font-family:Menlo, Consolas, monospace", "font-size:14px", "background-color:" .. C.tint, "padding:1px 4px" },
  }
  TABLE_STYLES = {
    table = css { "border-collapse:collapse", "width:100%", "margin:0 0 16px 0", "font-size:14px", "line-height:21px" },
    th = css { "text-align:left", "padding:6px 8px", "border-bottom:2px solid " .. C.line },
    td = css { "padding:6px 8px", "border-bottom:1px solid " .. C.line, "vertical-align:top" },
  }
end

-- Add inline styles to tags that do not already carry a style attribute.
local function style_html(html, styles)
  for tag, style in pairs(styles or TAG_STYLES) do
    html = html:gsub("<" .. tag .. "(%s?)([^>]*)>", function(sp, rest)
      if sp == "" and rest ~= "" then return nil end      -- e.g. <abbr> vs <a>
      if rest:find("style=", 1, true) then return nil end
      if rest:sub(-1) == "/" then
        return "<" .. tag .. ' style="' .. style .. '" ' .. rest .. ">"
      end
      return "<" .. tag .. ' style="' .. style .. '"' .. (sp ~= "" and " " .. rest or "") .. ">"
    end)
  end
  return html
end

local function to_html(blocks)
  if not blocks or #blocks == 0 then return "" end
  local out = pandoc.write(pandoc.Pandoc(blocks), "html")
  -- paragraphs inside quotes take the quote's larger type
  out = out:gsub("(<blockquote>.-</blockquote>)", function(q)
    return (q:gsub("<p>", '<p style="margin:0 0 12px 0; font-family:' .. F.heading .. '; font-size:19px; line-height:28px;">'))
  end)
  return style_html(out)
end

local function inlines_html(inl)
  return pandoc.write(pandoc.Pandoc({ pandoc.Plain(inl) }), "html")
end

---------------------------------------------------------------------------
-- components
---------------------------------------------------------------------------

local function button_cell(link)
  local secondary = link.classes:includes("secondary")
  local label = inlines_html(link.content)
  local href = esc(link.target)
  local cell, a
  if secondary then
    cell = css { "border:2px solid " .. C.primary, "border-radius:3px" }
    a = css { "display:inline-block", "padding:10px 20px", "font-family:" .. F.body, "font-size:15px", "line-height:20px", "font-weight:bold", "color:" .. C.primary, "text-decoration:none", "border-radius:3px" }
  else
    cell = css { "background-color:" .. C.primary, "border-radius:3px" }
    a = css { "display:inline-block", "padding:12px 22px", "font-family:" .. F.body, "font-size:15px", "line-height:20px", "font-weight:bold", "color:" .. C["on-primary"], "text-decoration:none", "border-radius:3px" }
  end
  local bg = secondary and "" or (' bgcolor="' .. C.primary .. '"')
  return '<td' .. bg .. ' style="' .. cell .. '"><a href="' .. href .. '" target="_blank" style="' .. a .. '">' .. label .. "</a></td>"
end

local function buttons_block(links)
  local cells = {}
  for i, l in ipairs(links) do
    if i > 1 then cells[#cells + 1] = '<td width="12" style="font-size:0; line-height:0;">&nbsp;</td>' end
    cells[#cells + 1] = button_cell(l)
  end
  return pandoc.RawBlock("html",
    '<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:4px 0 20px 0;"><tr>'
    .. table.concat(cells) .. "</tr></table>")
end

local function is_button(el) return el.t == "Link" and el.classes:includes("button") end

local function Para_buttons(p)
  local links = {}
  for _, el in ipairs(p.content) do
    if is_button(el) then
      links[#links + 1] = el
    elseif el.t ~= "Space" and el.t ~= "SoftBreak" and el.t ~= "LineBreak" then
      return nil
    end
  end
  if #links == 0 then return nil end
  return buttons_block(links)
end

local function img_tag(src, alt, width, extra_style, class)
  return '<img src="' .. esc(absolutize(src)) .. '" alt="' .. esc(alt or "") .. '" width="' .. width .. '"'
    .. (class and (' class="' .. class .. '"') or "")
    .. ' style="' .. css { "display:block", "width:100%", "max-width:" .. width .. "px", "height:auto", "border:0", extra_style or "" } .. '">'
end

local function maybe_link(html, href)
  if not href then return html end
  return '<a href="' .. esc(href) .. '" target="_blank" style="text-decoration:none;">' .. html .. "</a>"
end

local function feature(div, width)
  width = width or INNER
  local image = attr(div, "image")
  local html = '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 12px 0;">'
  if image then
    html = html .. '<tr><td style="padding:0 0 18px 0;">'
      .. maybe_link(img_tag(image, attr(div, "alt"), width, "", "nl-fluid"), attr(div, "link"))
      .. "</td></tr>"
  end
  html = html .. "<tr><td>" .. to_html(div.content) .. "</td></tr></table>"
  return pandoc.RawBlock("html", html)
end

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local MONTHS_LONG = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }

local function event(div)
  local date = attr(div, "date") or ""
  local y, m, d = date:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
  local tile_top, tile_big, long
  if y then
    m, d, y = tonumber(m), tonumber(d), tonumber(y)
    tile_top, tile_big = MONTHS[m], tostring(d)
    local wd = os.date("%A", os.time { year = y, month = m, day = d, hour = 12 })
    long = wd .. ", " .. MONTHS_LONG[m] .. " " .. d
  else
    tile_top, tile_big, long = "", (date ~= "" and date or "TBA"), nil
  end

  -- pull a leading heading out so the date/time line sits under it
  local blocks = div.content
  local head = {}
  if #blocks > 0 and blocks[1].t == "Header" then
    head = { blocks[1] }
    blocks = pandoc.List({ table.unpack(blocks, 2) })
  end

  local meta_lines = {}
  local when = long
  if attr(div, "time") then when = (when and (when .. ", ") or "") .. attr(div, "time") end
  if when then meta_lines[#meta_lines + 1] = esc(when) end
  if attr(div, "place") then meta_lines[#meta_lines + 1] = esc(attr(div, "place")) end
  local meta = ""
  if #meta_lines > 0 then
    meta = '<p style="' .. css { "margin:0 0 10px 0", "font-size:14px", "line-height:21px", "color:" .. C.muted } .. '">'
      .. table.concat(meta_lines, "<br>") .. "</p>"
  end

  local tile = '<td width="56" valign="top" style="width:56px; vertical-align:top; padding:2px 0 0 0;">'
    .. '<div style="' .. css { "font-family:" .. F.body, "font-size:14px", "line-height:16px", "font-weight:bold", "color:" .. C.muted } .. '">' .. esc(tile_top) .. "</div>"
    .. '<div style="' .. css { "font-family:" .. F.heading, "font-size:34px", "line-height:38px", "font-weight:bold", "letter-spacing:-1px", "color:" .. C.primary } .. '">' .. esc(tile_big) .. "</div></td>"

  local html = '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 22px 0;"><tr>'
    .. tile
    .. '<td width="14" style="font-size:0; line-height:0;">&nbsp;</td>'
    .. '<td valign="top">' .. to_html(head):gsub("margin:6px 0 8px 0", "margin:0 0 4px 0") .. meta .. to_html(blocks) .. "</td>"
    .. "</tr></table>"
  return pandoc.RawBlock("html", html)
end

local function spotlight(div)
  local image = attr(div, "image")
  local photo = ""
  if image then
    photo = '<td class="nl-stack nl-spot-img" width="112" valign="top" style="width:112px; padding:4px 20px 0 0;">'
      .. img_tag(image, attr(div, "alt"), 92, "border-radius:46px; width:92px; height:92px")
      .. "</td>"
  end
  local html = '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 12px 0;"><tr>'
    .. photo .. '<td class="nl-stack" valign="top">' .. to_html(div.content) .. "</td></tr></table>"
  return pandoc.RawBlock("html", html)
end

local function highlight(div)
  local html = '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:4px 0 20px 0;"><tr>'
    .. '<td bgcolor="' .. C.highlight .. '" style="' .. css { "background-color:" .. C.highlight, "padding:20px 24px 6px 24px" } .. '">'
    .. to_html(div.content) .. "</td></tr></table>"
  return pandoc.RawBlock("html", html)
end

local function two_col(div)
  local cols = {}
  for _, b in ipairs(div.content) do
    if b.t == "Div" and b.classes:includes("col") then cols[#cols + 1] = b end
  end
  if #cols ~= 2 then
    io.stderr:write("[newsletter] .two-col needs exactly two .col divs; found " .. #cols .. "\n")
    return nil
  end
  local colw = math.floor((INNER - 24) / 2)
  local function cell(col, side)
    local inner = ""
    local image = attr(col, "image")
    if image then
      inner = '<div style="margin:0 0 14px 0;">' .. maybe_link(img_tag(image, attr(col, "alt"), colw, "", "nl-fluid"), attr(col, "link")) .. "</div>"
    end
    local pad = side == "l" and "padding:0 12px 0 0" or "padding:0 0 0 12px"
    return '<td class="nl-stack nl-col-' .. side .. '" width="50%" valign="top" style="width:50%; ' .. pad .. ';">' .. inner .. to_html(col.content) .. "</td>"
  end
  local html = '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 8px 0;"><tr>'
    .. cell(cols[1], "l") .. cell(cols[2], "r") .. "</tr></table>"
  return pandoc.RawBlock("html", html)
end

local function rule()
  return '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:8px 0 24px 0;"><tr><td style="border-top:1px solid '
    .. C.line .. '; font-size:0; line-height:0;">&nbsp;</td></tr></table>'
end

---------------------------------------------------------------------------
-- page frame: masthead, issue title, sections, footer
---------------------------------------------------------------------------

local function row(inner, style, class)
  return '<tr><td class="' .. (class or "nl-pad") .. '" style="' .. style .. '">' .. inner .. "</td></tr>"
end

local function masthead(meta)
  local logo = ""
  if cfg.logo then
    local lw = tonumber(cfg["logo-width"] or 140) or 140
    logo = '<img src="' .. esc(absolutize(cfg.logo)) .. '" alt="' .. esc(cfg.org or "") .. '" width="' .. lw .. '" style="display:block; width:' .. lw .. 'px; height:auto; border:0; margin:0 0 22px 0;">'
  end
  local org = ""
  if cfg.org and cfg.org ~= "" then
    org = '<p style="' .. css { "margin:0 0 14px 0", "font-family:" .. F.body, "font-size:14px", "line-height:20px", "color:" .. C["on-primary-muted"] } .. '">' .. esc(cfg.org) .. "</p>"
  end
  local name = '<h1 class="nl-wordmark" style="' .. css { "margin:0", "font-family:" .. F.heading, "font-size:44px", "line-height:46px", "font-weight:bold", "letter-spacing:-1.5px", "color:" .. C["on-primary"] } .. '">' .. esc(cfg.name) .. "</h1>"

  local issue = meta.issue and ("Issue " .. esc(str(meta.issue))) or ""
  local date = meta.date and esc(str(meta.date)) or ""
  local mstyle = css { "font-family:" .. F.body, "font-size:14px", "line-height:20px", "color:" .. C.accent }
  local metarow = '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:22px 0 0 0;"><tr>'
    .. '<td class="nl-stack" style="' .. mstyle .. '">' .. issue .. "</td>"
    .. '<td class="nl-stack nl-meta-r" align="right" style="' .. mstyle .. '; text-align:right;">' .. date .. "</td>"
    .. "</tr></table>"

  return row(logo .. org .. name .. metarow,
      css { "background-color:" .. C.primary, "padding:30px " .. PAD .. "px 30px " .. PAD .. "px" })
end

local function issue_head(meta)
  if not meta.title then return "" end
  local h = '<h2 style="' .. css { "margin:0", "font-family:" .. F.heading, "font-size:30px", "line-height:36px", "font-weight:bold", "letter-spacing:-0.6px", "color:" .. C.primary } .. '">' .. inlines_html(meta.title) .. "</h2>"
  if meta.subtitle then
    h = h .. '<p style="' .. css { "margin:10px 0 0 0", "font-family:" .. F.body, "font-size:17px", "line-height:26px", "color:" .. C.muted } .. '">' .. inlines_html(meta.subtitle) .. "</p>"
  end
  return row(h, css { "padding:36px " .. PAD .. "px 6px " .. PAD .. "px" })
end

local function section_heading(h)
  local id = h.identifier ~= "" and (' id="' .. esc(h.identifier) .. '"') or ""
  return '<h2' .. id .. ' style="' .. css { "margin:0 0 16px 0", "font-family:" .. F.heading, "font-size:24px", "line-height:30px", "font-weight:bold", "letter-spacing:-0.4px", "color:" .. C.primary } .. '">'
    .. inlines_html(h.content) .. "</h2>"
end

local function section_row(inner, tinted, first)
  local style = {
    "padding:" .. (first and "26px" or "34px") .. " " .. PAD .. "px 14px " .. PAD .. "px",
    "font-family:" .. F.body, "font-size:16px", "line-height:26px", "color:" .. C.ink,
  }
  local bg = ""
  if tinted then
    style[#style + 1] = "background-color:" .. C.tint
    bg = ' bgcolor="' .. C.tint .. '"'
  end
  return '<tr><td class="nl-pad"' .. bg .. ' style="' .. css(style) .. '">' .. inner .. "</td></tr>"
end

local function separator()
  return '<tr><td class="nl-pad" style="padding:0 ' .. PAD .. 'px;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td style="border-top:1px solid '
    .. C.line .. '; font-size:0; line-height:0;">&nbsp;</td></tr></table></td></tr>'
end

local function toc_box(heads)
  local items = {}
  for _, h in ipairs(heads) do
    items[#items + 1] = '<a href="#' .. esc(h.identifier) .. '" style="color:' .. C.link .. '; text-decoration:underline;">' .. inlines_html(h.content) .. "</a>"
  end
  return '<tr><td class="nl-pad" style="' .. css { "padding:0 " .. PAD .. "px 26px " .. PAD .. "px", "font-family:" .. F.body, "font-size:15px", "line-height:24px", "color:" .. C.muted } .. '">'
    .. '<p style="margin:0; padding:14px 0 0 0; border-top:1px solid ' .. C.line .. ';"><strong style="color:' .. C.ink .. ';">In this issue:</strong> '
    .. table.concat(items, ", ") .. "</p></td></tr>"
end

local function footer()
  local f = cfg.footer or {}
  local muted = C["on-primary-muted"]
  local lnk = css { "color:" .. C["on-primary"], "text-decoration:underline" }
  local p = function(s, extra)
    return '<p style="' .. css { "margin:0 0 14px 0", "font-family:" .. F.body, "font-size:14px", "line-height:21px", "color:" .. muted, extra or "" } .. '">' .. s .. "</p>"
  end
  local function fix_links(s) return (s:gsub("<a href=", '<a style="' .. lnk .. '" href=')) end
  if f.about then f.about = fix_links(f.about) end
  if f["land-acknowledgement"] then f["land-acknowledgement"] = fix_links(f["land-acknowledgement"]) end
  local html = '<p style="' .. css { "margin:0 0 10px 0", "font-family:" .. F.heading, "font-size:20px", "line-height:26px", "font-weight:bold", "color:" .. C["on-primary"] } .. '">' .. esc(cfg.name) .. "</p>"
  if f.about then html = html .. p(f.about) end

  local contact = {}
  if f.email then contact[#contact + 1] = '<a href="mailto:' .. esc(f.email) .. '" style="' .. lnk .. '">' .. esc(f.email) .. "</a>" end
  if f.website then contact[#contact + 1] = '<a href="' .. esc(f.website.url) .. '" target="_blank" style="' .. lnk .. '">' .. esc(f.website.label or f.website.url) .. "</a>" end
  if #contact > 0 then html = html .. p(table.concat(contact, "<br>")) end

  if f.links and #f.links > 0 then
    local ls = {}
    for _, l in ipairs(f.links) do
      ls[#ls + 1] = '<a href="' .. esc(l.url) .. '" target="_blank" style="' .. lnk .. '">' .. esc(l.label) .. "</a>"
    end
    html = html .. p(table.concat(ls, "&nbsp;&nbsp;&nbsp; "))
  end

  if f["land-acknowledgement"] then
    html = html .. '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:8px 0 14px 0;"><tr><td style="border-top:1px solid ' .. muted .. '; font-size:0; line-height:0; opacity:0.4;">&nbsp;</td></tr></table>'
      .. p(f["land-acknowledgement"], "font-size:13px; line-height:20px")
  end
  if f["raw-html"] then html = html .. f["raw-html"] end

  return row(html, css { "background-color:" .. C.primary, "padding:32px " .. PAD .. "px 20px " .. PAD .. "px" })
end

---------------------------------------------------------------------------
-- main
---------------------------------------------------------------------------

function Pandoc(doc)
  local user = doc.meta.newsletter and meta_to_lua(doc.meta.newsletter, { about = true, ["land-acknowledgement"] = true, ["below-footer"] = true }) or {}
  cfg = deep_merge(DEFAULTS, user)
  C, F = cfg.colors, cfg.fonts
  build_tag_styles()

  -- pass 1: images, buttons, rules
  doc = doc:walk {
    Image = function(img)
      img.src = absolutize(img.src)
      return img
    end,
    Para = Para_buttons,
    Plain = Para_buttons,
    HorizontalRule = function() return pandoc.RawBlock("html", rule()) end,
    Table = function(t)
      local html = pandoc.write(pandoc.Pandoc({ t }), "html")
      return pandoc.RawBlock("html", style_html(style_html(html, TABLE_STYLES)))
    end,
  }

  -- pass 2: components (inner divs first, so .col content is already processed)
  doc = doc:walk {
    Div = function(div)
      if div.classes:includes("feature") then return feature(div) end
      if div.classes:includes("event") then return event(div) end
      if div.classes:includes("spotlight") then return spotlight(div) end
      if div.classes:includes("highlight") then return highlight(div) end
      if div.classes:includes("two-col") then return two_col(div) end
    end,
  }

  -- pass 3: split into sections at level-2 headings
  local chunks, cur = {}, { head = nil, blocks = {} }
  for _, b in ipairs(doc.blocks) do
    if b.t == "Header" and b.level == 2 then
      if cur.head or #cur.blocks > 0 then chunks[#chunks + 1] = cur end
      cur = { head = b, blocks = {} }
    else
      cur.blocks[#cur.blocks + 1] = b
    end
  end
  if cur.head or #cur.blocks > 0 then chunks[#chunks + 1] = cur end

  local heads = {}
  for _, ch in ipairs(chunks) do if ch.head then heads[#heads + 1] = ch.head end end

  local out = { masthead(doc.meta), issue_head(doc.meta) }
  local prev_tinted = true   -- no separator before the first section
  for i, ch in ipairs(chunks) do
    local tinted = ch.head and ch.head.classes:includes("tinted")
    local inner = (ch.head and section_heading(ch.head) or "") .. to_html(ch.blocks)
    if i > 1 and not tinted and not prev_tinted then out[#out + 1] = separator() end
    out[#out + 1] = section_row(inner, tinted, i == 1 and not ch.head)
    if i == 1 and not ch.head and cfg["in-this-issue"] and #heads > 1 then
      out[#out + 1] = toc_box(heads)
      prev_tinted = true
    else
      prev_tinted = tinted
    end
  end
  out[#out + 1] = footer()

  -- values for the shell template
  doc.meta["nl-page"] = pandoc.MetaString(C.page)
  doc.meta["nl-fragment"] = pandoc.MetaBool(cfg.fragment == true)
  local pt = cfg.name .. (doc.meta.title and (": " .. str(doc.meta.title)) or "")
  doc.meta.pagetitle = pandoc.MetaString(pt)
  if doc.meta.preheader then doc.meta.preheader = pandoc.MetaString(str(doc.meta.preheader)) end
  if cfg["below-footer"] then
    doc.meta["nl-below"] = pandoc.MetaBlocks({ pandoc.RawBlock("html",
      '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:600px; margin:0 auto;"><tr><td class="nl-pad" style="'
      .. css { "padding:18px " .. PAD .. "px 8px " .. PAD .. "px", "font-family:" .. F.body, "font-size:12px", "line-height:18px", "color:" .. C.muted, "text-align:center" } .. '">'
      .. style_html(cfg["below-footer"]) .. "</td></tr></table>") })
  end

  doc.blocks = { pandoc.RawBlock("html", table.concat(out, "\n")) }
  return doc
end
