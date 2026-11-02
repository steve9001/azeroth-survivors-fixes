-- HeroHealthBar: a plain health bar just under the hero, so health reads without a look at the
-- top-left corner. The locked camera aims at the hero's chest, so the hero is the middle of the
-- screen; the bar hangs a fixed distance below that. The full width is always drawn (a dark
-- track), so the fill reads as a percentage at a glance.
--
--   /hpbar               the settings and commands
--   /hpbar y -40         distance from the screen's middle (negative is lower)
--   /hpbar width 90      /hpbar height 8
--   /hpbar move          drag it with the mouse; /hpbar move again to finish
--   /hpbar reset         back to the defaults

local DEFAULTS = { x = 0, y = -40, width = 90, height = 8 }
-- Phases (AZS_GetPhase) in which the bar shows; out of a run, dead or won it hides.
local SHOWN_IN = { ready = true, playing = true, choosing = true, paused = true }

local db
local moving = false

local bar = CreateFrame("StatusBar", "HeroHealthBarFrame", UIParent)
bar:SetFrameStrata("LOW")
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetMinMaxValues(0, 1)
bar:SetValue(1)
bar:EnableMouse(false)
bar:SetMovable(true)
bar:SetClampedToScreen(true)
bar:Hide()

-- A black edge one pixel out, then the dark track the fill runs over.
local edge = bar:CreateTexture(nil, "BACKGROUND")
edge:SetTexture(0, 0, 0, 0.9)
edge:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
edge:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
local track = bar:CreateTexture(nil, "BORDER")
track:SetTexture(0.15, 0.15, 0.15, 0.85)
track:SetAllPoints(bar)

local function say(msg)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd100HeroHealthBar:|r " .. msg) end
end

local function layout()
  bar:SetWidth(db.width)
  bar:SetHeight(db.height)
  bar:ClearAllPoints()
  bar:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
end

-- Green when full, through yellow, to red when empty.
local function colour(p)
  if p > 0.5 then
    bar:SetStatusBarColor((1 - p) * 2, 1, 0)
  else
    bar:SetStatusBarColor(1, p * 2, 0)
  end
end

local function inRun()
  if type(AZS_GetPhase) ~= "function" then return true end
  local ph = AZS_GetPhase()
  return ph ~= nil and SHOWN_IN[ph] ~= nil
end

-- Health as the portrait's own bar shows it (PlayerFrameHealthBar, stock PlayerFrame.xml), so
-- the two never disagree; the unit API where that bar is missing. Returns current, max.
local function health()
  local hb = PlayerFrameHealthBar
  if hb and hb.GetMinMaxValues then
    local lo, hi = hb:GetMinMaxValues()
    if hi and lo and hi > lo then return (hb:GetValue() or lo) - lo, hi - lo end
  end
  return UnitHealth("player") or 0, UnitHealthMax("player") or 0
end

local function update()
  local cur, max = health()
  if not db or max <= 0 or not (inRun() or moving) then
    bar:Hide()
    return
  end
  local p = cur / max
  if p < 0 then p = 0 elseif p > 1 then p = 1 end
  bar:SetValue(p)
  colour(p)
  bar:Show()
end

-- Events where the client sends them, and a tenth-of-a-second poll for whatever it does not.
local ev = CreateFrame("Frame")
ev:RegisterEvent("VARIABLES_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("UNIT_HEALTH")
ev:RegisterEvent("UNIT_MAXHEALTH")
ev:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" or event == "PLAYER_ENTERING_WORLD" then
    HeroHealthBarDB = HeroHealthBarDB or {}
    db = HeroHealthBarDB
    for k, v in pairs(DEFAULTS) do
      if type(db[k]) ~= "number" then db[k] = v end
    end
    layout()
  end
  if db and (arg1 == nil or arg1 == "player") then update() end
end)
local since = 0
ev:SetScript("OnUpdate", function()
  since = since + (arg1 or 0)
  if since >= 0.1 then
    since = 0
    if db then update() end
  end
end)

bar:SetScript("OnMouseDown", function()
  if moving then this:StartMoving() end
end)
bar:SetScript("OnMouseUp", function()
  if not moving then return end
  this:StopMovingOrSizing()
  -- Keep it as an offset from the screen's middle, as layout() places it.
  local cx, cy = this:GetCenter()
  local ux, uy = UIParent:GetCenter()
  local s = this:GetEffectiveScale() / UIParent:GetEffectiveScale()
  db.x = math.floor(cx * s - ux + 0.5)
  db.y = math.floor(cy * s - uy + 0.5)
  layout()
end)

local function settings()
  say(string.format("x %d, y %d, width %d, height %d. Commands: y <n>, x <n>, width <n>, height <n>, move, reset.",
    db.x, db.y, db.width, db.height))
end

SLASH_HEROHEALTHBAR1 = "/hpbar"
SLASH_HEROHEALTHBAR2 = "/herohealthbar"
SlashCmdList["HEROHEALTHBAR"] = function(msg)
  if not db then return end
  local _, _, cmd, val = string.find(string.lower(msg or ""), "^%s*(%a*)%s*(%-?%d*)")
  local n = tonumber(val)
  if (cmd == "x" or cmd == "y") and n then
    db[cmd] = n
  elseif cmd == "width" and n and n >= 10 then
    db.width = n
  elseif cmd == "height" and n and n >= 2 then
    db.height = n
  elseif cmd == "move" then
    moving = not moving
    bar:EnableMouse(moving)
    if moving then
      say("drag the bar, then /hpbar move again to finish.")
    else
      say("placed.")
    end
  elseif cmd == "reset" then
    for k, v in pairs(DEFAULTS) do db[k] = v end
  else
    settings()
    return
  end
  layout()
  update()
end
