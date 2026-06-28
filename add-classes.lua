-- add-classes.lua

-- All the per-element rules live in this table, then get applied in
-- one pass via doc:walk() inside the Pandoc() function at the bottom.
-- We do it this way (instead of just defining global Header(), etc.)
-- so we can reliably set document metadata (has-code) AFTER scanning
-- the whole document, which plain top-level functions don't guarantee.

-- Run with: pandoc input.md -o output.html --lua-filter=add-classes.lua

local rules = {}

-- h1 gets centered; add more `elseif el.level == N` branches for h2-h6
function rules.Header(el)
  if el.level == 1 then
    el.classes:insert("text-center")
  end
  return el
end

-- "> quoted text" -> styled like your .msg box
function rules.BlockQuote(el)
  return pandoc.Div(el.content, {class = "msg"})
end

-- tables -> your existing .table class
function rules.Table(el)
  el.classes:insert("table")
  return el
end

-- ::yes:: and ::no:: shortcodes -> consistently colored check/cross
-- Add more shortcodes to this table as needed without touching the
-- Str walker below.
local icons = {
  ["::yes::"] = '<span style="color:green">✔</span>',
  ["::no::"]  = '<span style="color:red">✘</span>',
}

function rules.Str(el)
  local replacement = icons[el.text]
  if replacement then
    return pandoc.RawInline("html", replacement)
  end
  -- ::co2:0.68mg:: -> co2 badge with extracted value
  local val = el.text:match("^::co2:(.-)::$")
  if val then
      return pandoc.RawInline("html", '<a href="https://carbonneutralwebsite.org/" target="_blank" rel="noreferrer"><span class="co2">' .. val .. ' CO₂/load</span></a>')
    end
  return el
end

-- Top-level entry point: walk the whole doc applying the rules above,
-- then wrap everything in div.container and add bottom padding.
--
-- NOTE: the container wrap is done with raw HTML markers, not
-- pandoc.Div(). Wrapping via Div caused Pandoc's HTML5 writer to merge
-- the wrapper into an auto-generated <section> tied to the first
-- heading (a writer quirk where Div+Header combos get reinterpreted),
-- bleeding the heading's own classes into the container. Raw HTML
-- passes through untouched, avoiding that entirely.
function Pandoc(doc)
  doc.blocks = pandoc.walk_block(pandoc.Div(doc.blocks), rules).content

  -- spacer at the very end, always present regardless of content length.
  -- height (not padding) so it actually reserves visible space.
  -- size is controlled in CSS via .bottom-spacer { height: 10rem }
  table.insert(doc.blocks, pandoc.RawBlock("html", '<div class="bottom-spacer"></div>'))

  -- wrap everything (including the spacer above) in div.container
  table.insert(doc.blocks, 1, pandoc.RawBlock("html", '<div class="container">'))
  table.insert(doc.blocks, pandoc.RawBlock("html", '</div>'))

  return doc
end