-- Headless smoke test for the VimQuest engine.
--
--   nvim --headless -u init.lua -c "luafile tests/smoke.lua"
--
-- Exits non-zero on failure so CI (segment S6) can consume it directly.
-- Combat is driven with real keystrokes through nvim_feedkeys, because the
-- whole point of the game is that genuine vim commands do the work.
--
-- Saving is redirected to a temp directory: a test run must never be able to
-- touch a player's real progress.

local failures = 0

local function check(name, fn)
  local ok, err = pcall(fn)
  if ok then
    io.write("ok   - " .. name .. "\n")
  else
    failures = failures + 1
    io.write("FAIL - " .. name .. ": " .. tostring(err) .. "\n")
  end
end

local save_dir = vim.fs.joinpath(vim.fn.tempname(), "vimquest-test")

local vq = require("vimquest")
local state = require("vimquest.state")
local zones = require("vimquest.content.zones")
local grid = require("vimquest.engine.grid")
local combat = require("vimquest.engine.combat")
local skills = require("vimquest.systems.skills")
local save = require("vimquest.save")
local dialogue = require("vimquest.ui.dialogue")
local journal = require("vimquest.ui.journal")
local cheatsheet = require("vimquest.ui.cheatsheet")

vq.setup({ save = { dir = save_dir } })

--------------------------------------------------------------------- zone data

local zone

check("zone 0 loads", function()
  zone = zones.load("00_awakening")
  assert(zone.spawn, "no spawn point extracted")
  assert(#zone.entities >= 1, "no entities extracted")
  assert(#zone.triggers >= 5, "triggers missing")
  assert(#zone.exits >= 1, "zone has no exit - the player cannot finish it")
  assert(zone.brief and #zone.brief > 3, "zone has no opening briefing")
  assert(zone.exits[1].to == "01_rotwood", "zone 0 does not lead anywhere")
  assert(zone.combat == false, "zone 0 must stay a read-only zone")
end)

-- Every zone the game can reach. Adding one here is how it gets validated.
local ALL_ZONES = { "00_awakening", "01_rotwood", "02_coldbuffer", "03_ledger", "04_vaults" }

check("every zone has uniform row widths", function()
  for _, id in ipairs(ALL_ZONES) do
    local z = zones.load(id)
    local w = #z.map[1]
    for i, line in ipairs(z.map) do
      assert(#line == w, ("%s row %d width %d, expected %d"):format(id, i, #line, w))
    end
  end
end)

check("every zone is internally consistent", function()
  for _, id in ipairs(ALL_ZONES) do
    local z = zones.load(id)
    assert(z.spawn, id .. " has no spawn")
    assert(grid.walkable(z, z.spawn.row, z.spawn.col), id .. " spawns you inside a wall")
    assert(#z.exits >= 1, id .. " has no exit - the player could not leave")
    for _, x in ipairs(z.exits) do
      assert(grid.walkable(z, x.row, x.col), id .. " has an exit you cannot stand on")
      if x.to then
        assert(vim.tbl_contains(ALL_ZONES, x.to), ("%s leads to unknown zone '%s'"):format(id, x.to))
      end
    end
    for _, n in ipairs(z.npcs or {}) do
      assert(grid.walkable(z, n.row, n.col), id .. " has an unreachable npc: " .. tostring(n.id))
      assert(n.dialogue and n.dialogue[n.start or "start"], tostring(n.id) .. " has no opening line")
    end
    for _, s in ipairs(z.shrines or {}) do
      assert(grid.walkable(z, s.row, s.col), id .. " has an unreachable shrine")
    end
    for _, m in ipairs(z.mobs or {}) do
      -- Every cell a mob occupies must be walkable, or it cannot be attacked.
      for c = m.col, m.col + #m.text - 1 do
        assert(grid.walkable(z, m.row, c), ("%s: %s sits in a wall"):format(id, m.kind))
      end
    end
  end
end)

check("legend characters are painted over", function()
  -- '>' is intentionally left in place: the exit portal must stay visible.
  for i, line in ipairs(zone.map) do
    assert(not line:find("[@12345g]"), "legend char left in row " .. i .. ": " .. line)
  end
  local portals = 0
  for _, line in ipairs(zone.map) do
    portals = portals + select(2, line:gsub(">", ""))
  end
  assert(portals == #zone.exits, "portal glyphs do not match exit count")
end)

check("walkability", function()
  assert(grid.walkable(zone, zone.spawn.row, zone.spawn.col), "spawn is not walkable")
  assert(not grid.walkable(zone, 0, 0), "outer wall is walkable")
  assert(not grid.walkable(zone, -1, 0), "out of bounds is walkable")
end)

local rotwood

check("zone 1 extracts its text-mobs", function()
  rotwood = zones.load("01_rotwood")
  assert(rotwood.combat, "the Rotwood is not marked as a combat zone")
  assert(#rotwood.mobs >= 12, "expected a full roster, got " .. #rotwood.mobs)

  local kinds = {}
  for _, m in ipairs(rotwood.mobs) do
    kinds[m.kind] = (kinds[m.kind] or 0) + 1
    assert(m.text and #m.text > 0, "mob without a body")
    assert(m.weakness and #m.weakness > 0, m.kind .. " has no weakness")
    assert(m.teaches and next(m.teaches), m.kind .. " teaches nothing")
    -- The mob must fit on its row, or the buffer view would not match the map.
    local line = rotwood.map[m.row + 1]
    assert(line and m.col + #m.text <= #line, m.kind .. " overhangs its row")
  end
  for _, kind in ipairs({ "grub", "word_mob", "quoted_imp", "bracket_troll", "line_wraith", "swarm" }) do
    assert(kinds[kind], "the Rotwood teaches nothing about " .. kind)
  end
end)

check("mob runs of the wrong length are rejected", function()
  local ok = pcall(function()
    -- A three-character body authored as a two-character run must not load.
    package.loaded["vimquest.content.zones.zz_broken"] = {
      id = "zz_broken",
      map = { "#####", "#.rr#", "#####" },
      legend = { ["r"] = { type = "mob", mob = "word_mob", text = "rot" } },
    }
    zones.load("zz_broken")
  end)
  package.loaded["vimquest.content.zones.zz_broken"] = nil
  assert(not ok, "a mistyped mob run loaded silently")
end)

------------------------------------------------------------------- zone 0 flow

check("game starts with a briefing that freezes the world", function()
  vq.start()
  assert(state.running, "not running")
  assert(dialogue.current, "no opening briefing panel")
  assert(state.dialog_open, "briefing did not freeze the world")
  assert(#state.journal > 0, "briefing was not written to the journal")
  assert(state.buf and vim.api.nvim_buf_is_valid(state.buf), "no game buffer")
  assert(#state.entities == 1, "expected one entity, got " .. #state.entities)
  assert(vim.bo[state.buf].buftype == "nofile", "game buffer is not scratch")
  assert(vim.bo[state.buf].modifiable == false, "a non-combat zone must stay locked")
end)

check("dismissing the briefing resumes the world", function()
  dialogue.close()
  assert(not state.dialog_open, "world still frozen after dismissing briefing")
  assert(vim.api.nvim_get_current_buf() == state.buf, "focus did not return to the map")
end)

check("journal opens, holds the briefing, and closes", function()
  journal.toggle()
  assert(journal.current, "journal did not open")
  assert(state.dialog_open, "journal did not freeze the world")
  local lines = vim.api.nvim_buf_get_lines(journal.current.buf, 0, -1, false)
  assert(#lines > 1, "journal is empty")
  journal.toggle()
  assert(not journal.current, "journal did not close")
  assert(not state.dialog_open, "world still frozen after closing journal")
end)

check("world ticks and the shambler moves", function()
  local e = state.entities[1]
  local start_row, start_col = e.row, e.col
  vim.wait(1500, function()
    return e.row ~= start_row or e.col ~= start_col
  end, 50)
  assert(state.tick_count > 0, "tick loop never ran")
  assert(e.row ~= start_row or e.col ~= start_col, "chaser never moved")
end)

check("stamina drains and hp survives", function()
  local p = state.player
  assert(p.stamina <= p.max_stamina, "stamina above max")
  assert(p.hp > 0, "player died during idle smoke test")
end)

check("stepping onto the portal completes the zone", function()
  local ex = zone.exits[1]
  grid.set_cursor(state.win, ex.row, ex.col)
  require("vimquest.engine.collision").set_anchor(ex.row, ex.col)
  vim.wait(2000, function()
    return state.dialog_open
  end, 50)
  assert(state.dialog_open, "no ZONE CLEARED panel after reaching the portal")
  assert(state.zones_cleared["00_awakening"], "clearing the zone was not recorded")
end)

check("game quits cleanly", function()
  vq.quit()
  assert(not state.running, "still running after quit")
  assert(state.buf == nil, "state not reset")
end)

------------------------------------------------------------------------ combat

---Find the first living mob of a kind.
---@param kind string
---@return table
local function find(kind)
  for _, m in ipairs(state.mobs) do
    if m.alive and m.kind == kind then
      return m
    end
  end
  error("no living " .. kind .. " in the zone")
end

---Press keys for real and wait for combat to settle.
---@param mob table|nil the mob expected to die, or nil to just wait
---@param keys string
local function strike(mob, keys)
  local before = state.stats.kills + state.stats.misses
  -- "t" marks these as typed, so the keylog sees them exactly as it would see a
  -- human pressing them. Without it they arrive as untyped input and the
  -- recorder correctly ignores them.
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
  vim.wait(1000, function()
    if mob then
      return not mob.alive
    end
    return state.stats.kills + state.stats.misses > before
  end, 20)
end

check("the Rotwood unlocks the buffer and paints its mobs", function()
  vq.start("01_rotwood")
  dialogue.close()
  assert(vim.bo[state.buf].modifiable, "a combat zone must unlock the buffer")
  assert(combat.attached, "combat watcher is not attached")
  assert(#state.mobs >= 12, "mobs were not spawned")

  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  local grub = find("grub")
  assert(lines[grub.row + 1]:sub(grub.col + 1, grub.col + #grub.text) == grub.text, "mob body is not in the buffer")
  -- The authored map underneath stays clean; the buffer is only a view of it.
  assert(state.zone.map[grub.row + 1]:sub(grub.col + 1, grub.col + 1) == ".", "the map was overwritten by a mob")
end)

check("x kills a grub and awards xp", function()
  local grub = find("grub")
  local before = skills.get("operator").xp
  grid.set_cursor(state.win, grub.row, grub.col)
  strike(grub, "x")
  assert(not grub.alive, "the grub survived x")
  assert(skills.get("operator").xp > before or skills.get("operator").level > 1, "no xp for the kill")
  assert(state.stats.kills == 1, "kill was not counted")
  local line = vim.api.nvim_buf_get_lines(state.buf, grub.row, grub.row + 1, false)[1]
  assert(#line == #state.zone.map[grub.row + 1], "the row was not repaired after the kill")
end)

check("dw kills a blight-word", function()
  local word = find("word_mob")
  grid.set_cursor(state.win, word.row, word.col)
  strike(word, "dw")
  assert(not word.alive, "the blight-word survived dw")
  assert(state.stats.kills == 2, "kill was not counted")
end)

check('di" kills a quoted imp', function()
  local imp = find("quoted_imp")
  local before = skills.get("textobject").xp + (skills.get("textobject").level - 1) * 1000
  grid.set_cursor(state.win, imp.row, imp.col + 1)
  strike(imp, 'di"')
  assert(not imp.alive, 'the imp survived di"')
  local after = skills.get("textobject").xp + (skills.get("textobject").level - 1) * 1000
  assert(after > before, "killing an imp taught no text-object skill")
end)

check("ca( kills a bracket troll and leaves normal mode", function()
  local troll = find("bracket_troll")
  grid.set_cursor(state.win, troll.row, troll.col + 2)
  strike(troll, "ca(")
  assert(not troll.alive, "the troll survived ca(")
  vim.wait(300, function()
    return vim.api.nvim_get_mode().mode:sub(1, 1) == "n"
  end, 20)
  assert(vim.api.nvim_get_mode().mode:sub(1, 1) == "n", "a change-operator left the player stuck in insert")
end)

check("dd kills a line-wraith and restores the row", function()
  local wraith = find("line_wraith")
  local row = wraith.row
  grid.set_cursor(state.win, row, wraith.col)
  strike(wraith, "dd")
  assert(not wraith.alive, "the wraith survived dd")
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  assert(#lines == #state.zone.map, "the deleted line was not restored")
  assert(lines[row + 1] == state.zone.map[row + 1], "the wraith's row did not repaint to the authored map")
end)

check("a single dw is not enough for a swarm", function()
  local swarm = find("swarm")
  local misses = state.stats.misses
  grid.set_cursor(state.win, swarm.row, swarm.col)
  strike(nil, "dw")
  assert(swarm.alive, "the swarm died to a single dw")
  assert(state.stats.misses > misses, "a wrong strike was not counted as a miss")
  local line = vim.api.nvim_buf_get_lines(state.buf, swarm.row, swarm.row + 1, false)[1]
  assert(line:sub(swarm.col + 1, swarm.col + #swarm.text) == swarm.text, "the swarm was not repainted intact")
end)

check("3dw kills the swarm", function()
  local swarm = find("swarm")
  grid.set_cursor(state.win, swarm.row, swarm.col)
  strike(swarm, "3dw")
  assert(not swarm.alive, "the swarm survived 3dw")
  assert(skills.get("count").xp > 0 or skills.get("count").level > 1, "counts did not level")
end)

check("editing terrain repaints instead of corrupting the map", function()
  local misses = state.stats.misses
  -- A wall, as far from any mob as the map allows.
  local row, col = 0, 5
  vim.api.nvim_win_set_cursor(state.win, { row + 1, col })
  strike(nil, "x")
  assert(state.stats.misses > misses, "gouging terrain was not a miss")
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  assert(lines[row + 1] == state.zone.map[row + 1], "terrain was not repaired")
  assert(state.combo == 0, "a miss did not break the combo")
end)

check("the cheatsheet reflects what has been learned", function()
  local lines = cheatsheet.lines()
  local text = table.concat(lines, "\n")
  assert(text:find("Text objects", 1, true), "text objects stayed locked after killing an imp")
  assert(text:find("Skills", 1, true), "the cheatsheet shows no skill report")
  cheatsheet.toggle()
  assert(cheatsheet.current and state.dialog_open, "the cheatsheet did not open and freeze the world")
  cheatsheet.toggle()
  assert(not cheatsheet.current and not state.dialog_open, "the cheatsheet did not close")
end)

--------------------------------------------------------------- quests and perks

local quests = require("vimquest.systems.quests")
local perks = require("vimquest.systems.perks")
local bounties = require("vimquest.systems.bounties")
local travel = require("vimquest.systems.travel")
local converse = require("vimquest.ui.converse")
local skilltree = require("vimquest.ui.skilltree")
local questlog = require("vimquest.ui.questlog")

check("a quest tracks kills and only completes when every objective is met", function()
  quests.accept("cut_back_the_rot")
  assert(quests.status("cut_back_the_rot") == quests.ACTIVE, "quest was not accepted")
  assert(not quests.is_complete("cut_back_the_rot"), "quest completed before anything was done")

  local word = find("word_mob")
  grid.set_cursor(state.win, word.row, word.col)
  strike(word, "dw")
  local progress = state.quests["cut_back_the_rot"].progress
  assert(progress[1] == 1, "killing a blight-word did not advance the objective, got " .. tostring(progress[1]))

  local grub = find("grub")
  grid.set_cursor(state.win, grub.row, grub.col)
  strike(grub, "x")
  assert(state.quests["cut_back_the_rot"].progress[2] == 1, "the grub objective did not advance")
  assert(not quests.is_complete("cut_back_the_rot"), "quest completed with objectives outstanding")
end)

check("kill_with objectives care which command was used", function()
  local def = {
    id = "test_precision",
    name = "Precision",
    objectives = { { kind = "kill_with", mob = "quoted_imp", command = 'i"', count = 1 } },
    reward = {},
  }
  quests.accept("test_precision", def)

  -- da" kills the imp but takes the cage as well, so it must not count.
  local imp = find("quoted_imp")
  grid.set_cursor(state.win, imp.row, imp.col + 1)
  strike(imp, 'da"')
  assert(not imp.alive, 'da" did not kill the imp')
  assert((state.quests["test_precision"].progress[1] or 0) == 0, 'da" was wrongly credited to an i" objective')

  local imp2 = find("quoted_imp")
  grid.set_cursor(state.win, imp2.row, imp2.col + 1)
  strike(imp2, 'di"')
  assert(state.quests["test_precision"].progress[1] == 1, 'di" was not credited')
  assert(quests.is_complete("test_precision"), "single-objective quest did not complete")
end)

check("turning in a quest pays out", function()
  local before = skills.get("textobject").level
  assert(quests.turn_in("test_precision"), "could not turn in a complete quest")
  assert(quests.status("test_precision") == quests.TURNED_IN, "status did not change")
  assert(not quests.turn_in("test_precision"), "a quest was turned in twice")
  assert(skills.get("textobject").level >= before, "levels went backwards")
end)

check("bounties are generated from the roster and are stable within a day", function()
  local first = bounties.board()
  local second = bounties.board()
  assert(#first > 0, "the board was empty")
  assert(#first == #second, "the board changed between two looks at it")
  for i = 1, #first do
    assert(first[i].id == second[i].id, "the board is not stable within a session")
  end
  local def = first[1]
  assert(def.objectives[1].count and def.objectives[1].count > 0, "a bounty asked for nothing")
  quests.accept(def.id, def)
  assert(quests.status(def.id) == quests.ACTIVE, "bounty was not accepted")
  -- Once taken, it leaves the board rather than being offered twice.
  for _, still in ipairs(bounties.board()) do
    assert(still.id ~= def.id, "an accepted bounty was still on the board")
  end
end)

check("perk points come from levels and buy perks", function()
  state.perk_bonus = 5
  perks.restore(nil)
  perks.apply()
  local available = perks.available()
  assert(available >= 5, "perk points were not granted, got " .. available)

  local ok = perks.buy("sure_step")
  assert(ok, "could not buy an affordable perk with no requirements")
  assert(perks.owned("sure_step"), "the perk was not recorded")
  assert(perks.available() == available - 1, "the point was not spent")
  assert(require("vimquest.config").options.stamina_cost.h == 1, "the perk had no effect on stamina cost")

  assert(not perks.buy("sure_step"), "the same perk was bought twice")

  -- A perk whose requirement is not met must refuse, whatever the balance.
  skills.restore({ operator = { xp = 0, level = 1 } })
  local bought, why = perks.buy("steady_hand")
  assert(not bought and why, "a gated perk was sold without its requirement")
end)

check("perk effects reach the player and reset cleanly", function()
  perks.restore({ thick_hide = true })
  perks.apply()
  local with = state.player.max_hp
  perks.restore(nil)
  perks.apply()
  assert(state.player.max_hp == with - 3, "a removed perk kept giving health")
end)

check("the quest log and skill tree open, freeze the world, and close", function()
  for _, ui in ipairs({ questlog, skilltree }) do
    ui.toggle()
    assert(state.dialog_open, "a panel did not freeze the world")
    ui.toggle()
    assert(not state.dialog_open, "a panel did not release the world")
  end
end)

----------------------------------------------------------- nesting and the boss

check("a vault seal ignores di( and opens to 2di(", function()
  vq.quit()
  vq.start("04_vaults")
  dialogue.close()

  local seal = find("vault_seal")
  local misses = state.stats.misses
  -- Stand inside the inner pair: ((seal)) -> the 's' is two columns in.
  grid.set_cursor(state.win, seal.row, seal.col + 3)
  strike(nil, "di(")
  assert(seal.alive, "a shallow di( opened the seal")
  assert(state.stats.misses > misses, "the shallow strike was not a miss")
  local line = vim.api.nvim_buf_get_lines(state.buf, seal.row, seal.row + 1, false)[1]
  assert(line:sub(seal.col + 1, seal.col + #seal.text) == seal.text, "the seal was not repainted intact")

  grid.set_cursor(state.win, seal.row, seal.col + 3)
  strike(seal, "2di(")
  assert(not seal.alive, "2di( did not open the seal")
end)

check("the Nested Heart falls only to a three-deep strike", function()
  local heart = find("vault_heart")
  grid.set_cursor(state.win, heart.row, heart.col + 4)
  strike(nil, "2di(")
  assert(heart.alive, "the Heart fell to a two-deep strike")

  local before = skills.get("count").xp + skills.get("count").level * 1000
  grid.set_cursor(state.win, heart.row, heart.col + 4)
  strike(heart, "3ci(")
  assert(not heart.alive, "3ci( did not kill the Heart")
  vim.wait(300, function()
    return vim.api.nvim_get_mode().mode:sub(1, 1) == "n"
  end, 20)
  assert(vim.api.nvim_get_mode().mode:sub(1, 1) == "n", "the Heart left the player stuck in insert")
  local after = skills.get("count").xp + skills.get("count").level * 1000
  assert(after > before, "the boss taught no counts")
end)

--------------------------------------------------------------- hub and travel

check("the hub is a safe zone with people in it", function()
  vq.quit()
  vq.start("02_coldbuffer")
  dialogue.close()
  assert(state.zone.safe, "Coldbuffer is not marked safe")
  assert(#state.mobs == 0, "the hub has mobs in it")
  assert(#state.zone.npcs >= 4, "the hub is empty of people")
  assert(#state.zone.shrines >= 1, "the hub has no shrine")
  assert(vim.bo[state.buf].modifiable == false, "a non-combat zone must stay locked")
end)

check("walking into someone starts a conversation, once", function()
  local npc = state.zone.npcs[1]
  grid.set_cursor(state.win, npc.row, npc.col)
  vim.wait(1000, function()
    return converse.current ~= nil
  end, 20)
  assert(converse.current, "no conversation started")
  assert(state.dialog_open, "a conversation did not freeze the world")
  converse.close()
  assert(not converse.current, "the conversation did not close")
  -- Still standing on them: it must not reopen on the next tick.
  vim.wait(400, function()
    return converse.current ~= nil
  end, 20)
  assert(not converse.current, "the conversation reopened while standing still")
end)

check("a shrine binds to a mark and the mark travels", function()
  local shrine = state.zone.shrines[1]
  grid.set_cursor(state.win, shrine.row, shrine.col)
  require("vimquest.engine.collision").set_anchor(shrine.row, shrine.col)
  assert(travel.mark("a"), "could not bind a shrine while standing on it")
  assert(state.shrines.a and state.shrines.a.zone == "02_coldbuffer", "the mark was not recorded")

  -- Away from a shrine, m explains itself rather than silently failing.
  local spawn = state.zone.spawn
  grid.set_cursor(state.win, spawn.row, spawn.col)
  require("vimquest.engine.collision").set_anchor(spawn.row, spawn.col)
  assert(not travel.mark("b"), "a mark took hold away from a shrine")
  assert(not travel.jump("z"), "an unbound mark travelled somewhere")

  assert(travel.jump("a"), "could not return to a bound shrine in this zone")
  local row, col = grid.cursor(state.win)
  assert(row == shrine.row and col == shrine.col, "'a did not land on the shrine")
end)

check("walking into a hub portal travels with no summary screen", function()
  local portal
  for _, x in ipairs(state.zone.exits) do
    if x.travel and x.to == "01_rotwood" then
      portal = x
    end
  end
  assert(portal, "the hub has no portal to the Rotwood")
  grid.set_cursor(state.win, portal.row, portal.col)
  require("vimquest.engine.collision").set_anchor(portal.row, portal.col)
  vim.wait(3000, function()
    return state.running and state.zone and state.zone.id == "01_rotwood"
  end, 20)
  assert(state.zone.id == "01_rotwood", "the portal did not carry the player through")
  assert(#state.mobs > 0, "arrived in the Rotwood with nothing in it")

  -- Back to the hub for the next check, the same way.
  vq.travel("02_coldbuffer")
  vim.wait(3000, function()
    return state.running and state.zone and state.zone.id == "02_coldbuffer"
  end, 20)
  assert(state.zone.id == "02_coldbuffer", "could not get back to the hub")
end)

check("a mark travels across zones", function()
  vq.travel("01_rotwood")
  vim.wait(2000, function()
    return state.running and state.zone and state.zone.id == "01_rotwood"
  end, 20)
  assert(state.zone.id == "01_rotwood", "travelling to another zone failed")
  assert(state.shrines.a, "bound shrines did not survive the journey")

  travel.jump("a")
  vim.wait(2000, function()
    return state.running and state.zone and state.zone.id == "02_coldbuffer"
  end, 20)
  assert(state.zone.id == "02_coldbuffer", "'a did not cross zones")
  local row, col = grid.cursor(state.win)
  assert(row == state.shrines.a.row and col == state.shrines.a.col, "arrived somewhere other than the shrine")
end)

----------------------------------------------------------------------- saving

local levels_before, xp_before

check("quitting writes a save", function()
  skills.ensure()
  levels_before = skills.get("operator").level
  xp_before = skills.get("operator").xp
  vq.quit()
  assert(save.exists(), "no save file at " .. save.path())
  local data = assert(save.read())
  assert(data.schema_version == save.SCHEMA_VERSION, "save is not stamped with the schema version")
  assert(data.skills.operator, "skills were not serialised")
end)

check("progress survives a relaunch", function()
  vq.start("01_rotwood")
  dialogue.close()
  assert(skills.get("operator").level == levels_before, "operator level was not restored")
  assert(skills.get("operator").xp == xp_before, "operator xp was not restored")
  assert(state.zones_cleared["00_awakening"], "cleared zones were not restored")
  assert(state.stats.kills > 0, "lifetime kills were not restored")
  -- S3 progression rides in the same file.
  assert(quests.status("cut_back_the_rot") == quests.ACTIVE, "an active quest was lost")
  assert(state.quests["cut_back_the_rot"].progress[1] == 1, "quest progress was lost")
  assert(quests.status("test_precision") == quests.TURNED_IN, "a finished quest was forgotten")
  assert(state.quests["test_precision"].def, "a radiant quest lost the definition it carried")
  assert(perks.owned("thick_hide") == false, "a perk the player does not own came back")
  assert(state.shrines.a and state.shrines.a.zone == "02_coldbuffer", "a bound shrine was lost")
  -- Mobs are fresh again: progression persists, the world does not.
  assert(#state.mobs >= 12, "the zone did not repopulate")
  local alive = select(1, combat.census())
  assert(alive == #state.mobs, "a killed mob stayed dead across runs")
  vq.quit()
end)

check("an older save migrates forward", function()
  local legacy = {
    skills = { operator = { xp = 3, level = 4 } },
    zones_cleared = { ["00_awakening"] = true },
    stats = { kills = 99 },
  }
  vim.fn.mkdir(save.dir(), "p")
  vim.fn.writefile({ vim.json.encode(legacy) }, save.path())

  local data = assert(save.read())
  assert(data.schema_version == save.SCHEMA_VERSION, "migration did not stamp the new version")
  assert(data.skills.operator.level == 4, "migration lost skill levels")
  assert(type(data.quests) == "table", "the 1->2 migration did not add quests")
  assert(type(data.perks) == "table", "the 1->2 migration did not add perks")

  vq.start("01_rotwood")
  dialogue.close()
  assert(skills.get("operator").level == 4, "migrated levels did not reach the player")
  assert(state.stats.kills == 99, "migrated totals did not reach the player")
  assert(next(state.quests) == nil, "a pre-quest save invented quests")
  assert(state.player.max_hp > require("vimquest.config").options.player.max_hp, "levels granted no health")
  vq.quit()
end)

check("reset erases progress", function()
  assert(save.exists(), "nothing to reset")
  vq.reset()
  assert(not save.exists(), "the save file survived a reset")
end)

check("nothing was written outside the test save directory", function()
  local real = vim.fs.joinpath(vim.fn.stdpath("data"), "vimquest", "save.json")
  assert(save.dir():find("vimquest%-test"), "the test was not redirected away from real progress")
  assert(vim.fn.isdirectory(save_dir) == 1 or not save.exists(), "test save directory missing")
  assert(real ~= save.path(), "the test wrote to the real save path")
end)

io.write(failures == 0 and "\nSMOKE PASS\n" or ("\nSMOKE FAIL (" .. failures .. ")\n"))
vim.cmd("qa!")
os.exit(failures == 0 and 0 or 1)
