-- keydrill — a flashcard trainer for *this* config's binds, run inside nvim.
--
-- Why in-editor and not a web page: muscle memory is built by the real fingers
-- on the real keyboard in the real place. The drill reads raw keystrokes with
-- getcharstr() instead of installing mappings, so it sees exactly what the
-- terminal delivers — an Alt chord swallowed by the multiplexer or a <S-CR>
-- that arrives as a plain <CR> shows up here as a miss, which is the truth.
--
--   :KeyDrill                 25 reps from the default mix
--   :KeyDrill motion compose  only those categories
--   :KeyDrill 50              50 reps
--   :KeyDrill all             include the `optional` (Alt-chord) drills
--   :KeyDrillStats            per-bind accuracy, worst first
--   :KeyDrillCheatsheet       the whole catalogue, grouped
--
-- Ctrl-C quits a session. Every other key is fair game as an answer, which is
-- why quit isn't <Esc>/F13 — F13 is itself a drill.
local M = {}

local catalogue = require('keydrill.drills')

local STATS_PATH = vim.fn.stdpath('data') .. '/keydrill-stats.json'
local DEFAULT_REPS = 25
local HINT_MS = 3000   -- reveal the first key
local ANSWER_MS = 6000 -- reveal the rest

-- ───────────────────────────────────────────────────────────── keycodes ──

local function termcodes(s)
  return vim.api.nvim_replace_termcodes(s, true, true, true)
end

-- Every byte string that counts as "typed this bind". More than one because the
-- same physical key can arrive differently depending on terminal and protocol.
local function variants(keys)
  local lhs = keys:gsub('<[lL]eader>', function() return vim.g.mapleader or '\\' end)
  local out = { termcodes(lhs) }

  -- Alt as ESC-prefix: terminals that don't set the 8th bit send <Esc>x.
  if lhs:find('<M%-') then
    local esc = lhs:gsub('<M%-C%-(%a)>', '<Esc><C-%1>'):gsub('<M%-(%a)>', '<Esc>%1')
    table.insert(out, termcodes(esc))
  end

  -- F13-F24 are encoded by the terminal as *shifted* F1-F12 (see the note in
  -- config/keymaps.lua) — nvim decodes F13 back as <S-F3>.
  if lhs:find('<F13>') then
    table.insert(out, termcodes((lhs:gsub('<F13>', '<S-F3>'))))
  end

  -- Backspace: keycode, ^H and DEL are all in the wild.
  if lhs:find('<BS>') then
    table.insert(out, (lhs:gsub('<BS>', '\8')))
    table.insert(out, (lhs:gsub('<BS>', '\127')))
  end

  return out
end

-- Input that is never an answer: mouse traffic, focus events, resize.
local IGNORED = {}
for _, k in ipairs({
  '<LeftMouse>', '<LeftDrag>', '<LeftRelease>', '<RightMouse>', '<RightDrag>',
  '<RightRelease>', '<MiddleMouse>', '<MiddleRelease>', '<MouseMove>',
  '<ScrollWheelUp>', '<ScrollWheelDown>', '<ScrollWheelLeft>', '<ScrollWheelRight>',
  '<FocusGained>', '<FocusLost>', '<Ignore>',
}) do
  IGNORED[termcodes(k)] = true
end

-- Human-readable form of what was typed, for the echo line.
local function pretty(s)
  return (vim.fn.keytrans(s):gsub(' ', '<Space>'))
end

local function label(keys)
  return (keys:gsub('<[lL]eader>', '<Space>'))
end

-- ──────────────────────────────────────────────────────────────── stats ──

local function load_stats()
  local f = io.open(STATS_PATH, 'r')
  if not f then return {} end
  local raw = f:read('*a')
  f:close()
  local ok, decoded = pcall(vim.json.decode, raw)
  return (ok and type(decoded) == 'table') and decoded or {}
end

local function save_stats(stats)
  local f = io.open(STATS_PATH, 'w')
  if not f then return end
  f:write(vim.json.encode(stats))
  f:close()
end

local function entry(stats, drill)
  local e = stats[drill.keys]
  if not e then
    e = { seen = 0, miss = 0, total_ms = 0 }
    stats[drill.keys] = e
  end
  return e
end

-- Weighted so the binds you fumble (and the ones you've never met) come round
-- more often — the whole reason the stats file exists.
local function weight(stats, drill)
  local e = stats[drill.keys]
  if not e or e.seen == 0 then return 3.5 end
  local w = 1 + 4 * (e.miss / e.seen)
  local avg = e.total_ms / e.seen
  if avg > 1500 then w = w + 1 elseif avg > 900 then w = w + 0.5 end
  return w
end

local function pick(session)
  local pool, total = {}, 0
  for _, d in ipairs(session.pool) do
    if d ~= session.drill or #session.pool == 1 then
      local w = weight(session.stats, d)
      total = total + w
      table.insert(pool, { d = d, acc = total })
    end
  end
  local r = math.random() * total
  for _, item in ipairs(pool) do
    if r <= item.acc then return item.d end
  end
  return pool[#pool].d
end

-- ─────────────────────────────────────────────────────────────────── UI ──

local HL = {
  title  = 'KeyDrillTitle',
  prompt = 'KeyDrillPrompt',
  good   = 'KeyDrillGood',
  bad    = 'KeyDrillBad',
  dim    = 'KeyDrillDim',
  key    = 'KeyDrillKey',
}

local function define_hl()
  local links = {
    [HL.title] = 'Title', [HL.prompt] = 'Normal', [HL.good] = 'DiagnosticOk',
    [HL.bad] = 'DiagnosticError', [HL.dim] = 'Comment', [HL.key] = 'Special',
  }
  for name, link in pairs(links) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
  vim.api.nvim_set_hl(0, HL.prompt, { bold = true, default = true })
end

local WIDTH, HEIGHT = 66, 15

local function open_win(session)
  session.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[session.buf].bufhidden = 'wipe'
  session.win = vim.api.nvim_open_win(session.buf, true, {
    relative = 'editor',
    width = WIDTH,
    height = HEIGHT,
    row = math.max(0, math.floor((vim.o.lines - HEIGHT) / 2) - 1),
    col = math.floor((vim.o.columns - WIDTH) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' keydrill ',
    title_pos = 'center',
  })
  vim.wo[session.win].winhl = 'Normal:NormalFloat,FloatBorder:FloatBorder'
  vim.wo[session.win].cursorline = false
end

local function close_win(session)
  if session.win and vim.api.nvim_win_is_valid(session.win) then
    vim.api.nvim_win_close(session.win, true)
  end
end

local function center(text)
  local pad = math.max(0, math.floor((WIDTH - vim.fn.strdisplaywidth(text)) / 2))
  return string.rep(' ', pad) .. text
end

-- lines = list of { text, hl }
local function draw(session, lines)
  while #lines < HEIGHT do table.insert(lines, { '', nil }) end
  local text = vim.tbl_map(function(l) return l[1] end, lines)
  vim.bo[session.buf].modifiable = true
  vim.api.nvim_buf_set_lines(session.buf, 0, -1, false, text)
  vim.bo[session.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(session.buf, session.ns, 0, -1)
  for i, l in ipairs(lines) do
    if l[2] and l[1] ~= '' then
      vim.api.nvim_buf_set_extmark(session.buf, session.ns, i - 1, 0, {
        end_col = #l[1], hl_group = l[2],
      })
    end
  end
end

local function accuracy(session)
  if session.done == 0 then return 100 end
  return math.floor(((session.done - session.misses) / session.done) * 100 + 0.5)
end

local function avg_ms(session)
  if session.hit_count == 0 then return 0 end
  return session.hit_total_ms / session.hit_count
end

local function render(session)
  local L = {}
  local function blank() table.insert(L, { '', nil }) end
  local function line(text, hl) table.insert(L, { center(text), hl }) end

  if session.state == 'intro' then
    blank()
    line('keydrill', HL.title)
    blank()
    line(session.cat_label, HL.dim)
    line(session.total .. ' reps · weighted toward what you miss', HL.dim)
    blank()
    blank()
    line('press any key to start', HL.prompt)
    blank()
    line('Ctrl-C quits at any time', HL.dim)
    draw(session, L)
    return
  end

  if session.state == 'summary' then
    blank()
    line('session done', HL.title)
    blank()
    line(string.format('%d%% accuracy   %d/%d clean',
      accuracy(session), session.done - session.misses, session.done),
      accuracy(session) >= 90 and HL.good or HL.prompt)
    line(string.format('%.2fs average on the hits', avg_ms(session) / 1000), HL.dim)
    blank()
    if #session.worst > 0 then
      line('still shaky:', HL.dim)
      for _, w in ipairs(session.worst) do
        line(string.format('%s   %s', label(w.keys), w.prompt), HL.bad)
      end
    else
      line('nothing missed. do it faster next time.', HL.good)
    end
    blank()
    line('r = again    any other key = close', HL.dim)
    draw(session, L)
    return
  end

  -- active drill
  local head = string.format('%d/%d', session.done + 1, session.total)
  table.insert(L, { '  ' .. head .. string.rep(' ', WIDTH - #head - 4 - 20)
    .. string.format('streak %-3d %3d%%', session.streak, accuracy(session)), HL.dim })
  blank()
  line(session.drill.prompt, HL.prompt)
  blank()

  if session.state == 'miss' then
    line('✗  ' .. label(session.drill.keys), HL.bad)
    blank()
    line(session.drill.note or '', HL.dim)
    blank()
    line('type it to carry on', HL.dim)
  else
    local elapsed = (vim.uv.hrtime() - session.t0) / 1e6
    local echo = session.typed ~= '' and pretty(session.typed) or '·'
    line(echo, session.typed ~= '' and HL.key or HL.dim)
    blank()
    if elapsed > ANSWER_MS then
      line(label(session.drill.keys), HL.dim)
      blank()
      line(session.drill.note or '', HL.dim)
    elseif elapsed > HINT_MS then
      line('starts with  ' .. label(session.drill.keys):sub(1, 1), HL.dim)
    end
  end

  if session.last then
    L[HEIGHT] = { center(session.last[1]), session.last[2] }
  end
  draw(session, L)
end

-- ──────────────────────────────────────────────────────────────── logic ──

local function next_drill(session)
  session.drill = pick(session)
  session.variants = variants(session.drill.keys)
  session.typed = ''
  session.state = 'ask'
  session.missed_here = false
  session.t0 = vim.uv.hrtime()
end

local function finish_drill(session)
  local ms = (vim.uv.hrtime() - session.t0) / 1e6
  local e = entry(session.stats, session.drill)
  e.seen = e.seen + 1
  e.total_ms = e.total_ms + ms

  session.done = session.done + 1
  if session.missed_here then
    e.miss = e.miss + 1
    session.misses = session.misses + 1
    session.streak = 0
    table.insert(session.worst, { keys = session.drill.keys, prompt = session.drill.prompt })
    session.last = { '✗ ' .. label(session.drill.keys), HL.bad }
  else
    session.streak = session.streak + 1
    session.best_streak = math.max(session.best_streak, session.streak)
    session.hit_count = session.hit_count + 1
    session.hit_total_ms = session.hit_total_ms + ms
    session.last = { string.format('✓ %s  %.2fs', label(session.drill.keys), ms / 1000), HL.good }
  end

  if session.done >= session.total then
    -- Keep the summary short: the three worst, no repeats.
    local seen, worst = {}, {}
    for _, w in ipairs(session.worst) do
      if not seen[w.keys] and #worst < 3 then
        seen[w.keys] = true
        table.insert(worst, w)
      end
    end
    session.worst = worst
    session.state = 'summary'
  else
    next_drill(session)
  end
end

local function handle(session, char)
  if IGNORED[char] then return end
  if char == '\3' then session.active = false return end

  if session.state == 'intro' then
    next_drill(session)
    return
  end
  if session.state == 'summary' then
    if char == 'r' then
      M.run(session.opts)
    end
    session.active = false
    return
  end

  session.typed = session.typed .. char
  for _, v in ipairs(session.variants) do
    if v == session.typed then
      finish_drill(session)
      return
    elseif v:sub(1, #session.typed) == session.typed then
      return -- valid prefix: wait for the rest
    end
  end

  -- wrong. One miss per drill, then it stays up until typed correctly.
  session.missed_here = true
  session.typed = ''
  session.state = 'miss'
end

-- ────────────────────────────────────────────────────────────── session ──

local function build_pool(cats)
  local wanted, all = {}, false
  for _, c in ipairs(cats) do
    if c == 'all' then all = true else wanted[c] = true end
  end
  local pool = {}
  for _, d in ipairs(catalogue) do
    local include
    if all then
      include = next(wanted) == nil or wanted[d.cat]
    elseif next(wanted) then
      include = wanted[d.cat]
    else
      include = not d.optional
    end
    if include then table.insert(pool, d) end
  end
  return pool
end

function M.run(opts)
  opts = opts or {}
  local pool = build_pool(opts.cats or {})
  if #pool == 0 then
    vim.notify('keydrill: no drills match ' .. table.concat(opts.cats or {}, ' '), vim.log.levels.WARN)
    return
  end

  define_hl()
  math.randomseed(os.time())

  local session = {
    opts = opts,
    pool = pool,
    stats = load_stats(),
    ns = vim.api.nvim_create_namespace('keydrill'),
    total = opts.reps or DEFAULT_REPS,
    cat_label = (opts.cats and #opts.cats > 0) and table.concat(opts.cats, ' + ')
      or (#pool .. ' binds, everything but the Alt chords'),
    state = 'intro',
    active = true,
    typed = '',
    done = 0,
    misses = 0,
    streak = 0,
    best_streak = 0,
    hit_count = 0,
    hit_total_ms = 0,
    worst = {},
    t0 = vim.uv.hrtime(),
  }

  open_win(session)
  local ok, err = pcall(function()
    while session.active do
      render(session)
      vim.cmd('redraw')
      -- Non-blocking read + an interruptible sleep, so the hint timers tick
      -- while we wait instead of freezing on a blocking getcharstr().
      local got, char = pcall(vim.fn.getcharstr, 0)
      if not got then session.active = false break end   -- Ctrl-C
      if char == '' then
        vim.cmd('sleep 20m')
      else
        handle(session, char)
      end
    end
  end)

  save_stats(session.stats)
  close_win(session)
  if not ok and err then
    vim.notify('keydrill: ' .. tostring(err), vim.log.levels.ERROR)
  end
end

-- ──────────────────────────────────────────────────────── stats / sheet ──

local function scratch(title, lines)
  vim.cmd('enew')
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_name(buf, title)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'markdown'
end

function M.stats()
  local stats = load_stats()
  local rows = {}
  for _, d in ipairs(catalogue) do
    local e = stats[d.keys]
    if e and e.seen > 0 then
      table.insert(rows, {
        keys = d.keys, prompt = d.prompt, seen = e.seen,
        acc = (e.seen - e.miss) / e.seen, avg = e.total_ms / e.seen,
      })
    end
  end
  if #rows == 0 then
    vim.notify('keydrill: no history yet — run :KeyDrill', vim.log.levels.INFO)
    return
  end
  -- Worst first: that's the list you act on.
  table.sort(rows, function(a, b)
    if a.acc ~= b.acc then return a.acc < b.acc end
    return a.avg > b.avg
  end)

  local lines = { '# keydrill stats', '', string.format('%-12s %5s %6s %8s  %s', 'keys', 'seen', 'acc', 'avg', 'what') , '' }
  for _, r in ipairs(rows) do
    table.insert(lines, string.format('%-12s %5d %5d%% %7.2fs  %s',
      label(r.keys), r.seen, math.floor(r.acc * 100 + 0.5), r.avg / 1000, r.prompt))
  end
  table.insert(lines, '')
  table.insert(lines, '_' .. STATS_PATH .. '_')
  scratch('keydrill://stats', lines)
end

function M.cheatsheet()
  local order, groups = {}, {}
  for _, d in ipairs(catalogue) do
    if not groups[d.cat] then
      groups[d.cat] = {}
      table.insert(order, d.cat)
    end
    table.insert(groups[d.cat], d)
  end
  local lines = { '# keydrill cheatsheet', '' }
  for _, cat in ipairs(order) do
    table.insert(lines, '## ' .. cat)
    table.insert(lines, '')
    for _, d in ipairs(groups[cat]) do
      table.insert(lines, string.format('  %-12s %s', label(d.keys), d.prompt))
    end
    table.insert(lines, '')
  end
  scratch('keydrill://cheatsheet', lines)
end

function M.reset()
  os.remove(STATS_PATH)
  vim.notify('keydrill: history cleared', vim.log.levels.INFO)
end

-- ───────────────────────────────────────────────────────────── commands ──

local function categories()
  local seen, out = {}, { 'all' }
  for _, d in ipairs(catalogue) do
    if not seen[d.cat] then
      seen[d.cat] = true
      table.insert(out, d.cat)
    end
  end
  return out
end

function M.setup()
  vim.api.nvim_create_user_command('KeyDrill', function(cmd)
    local opts = { cats = {} }
    for _, arg in ipairs(cmd.fargs) do
      local n = tonumber(arg)
      if n then opts.reps = math.max(1, math.floor(n)) else table.insert(opts.cats, arg) end
    end
    M.run(opts)
  end, {
    nargs = '*',
    desc = 'drill this config\'s keybindings',
    complete = function(lead)
      return vim.tbl_filter(function(c) return c:find(lead, 1, true) == 1 end, categories())
    end,
  })

  vim.api.nvim_create_user_command('KeyDrillStats', M.stats, { desc = 'keydrill: accuracy per bind, worst first' })
  vim.api.nvim_create_user_command('KeyDrillCheatsheet', M.cheatsheet, { desc = 'keydrill: the whole catalogue' })
  vim.api.nvim_create_user_command('KeyDrillReset', M.reset, { desc = 'keydrill: forget the history' })
end

return M
