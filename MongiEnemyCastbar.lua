--
-- * Add second bar to castbar which shows the rank 1 length, maybe not visually good?
--

MongiEnemyCastbar = CreateFrame("frame", "MongiEnemyCastbar")

local print = function(output)
    DEFAULT_CHAT_FRAME:AddMessage(string.format(output))
end

local events = {
    'CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS',
    'CHAT_MSG_COMBAT_SELF_HITS',
    'CHAT_MSG_COMBAT_SELF_MISSES',
    'CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS',
    'CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES',
    'CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS',
    'CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES',
    'CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS',
    'CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES',
    'CHAT_MSG_SPELL_SELF_BUFF',
    'CHAT_MSG_SPELL_SELF_DAMAGE',
    'CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE',
    'CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF',
    'CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE',
    'CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF',
    'CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE',
    'CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF',
    'CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE',
    'CHAT_MSG_SPELL_PARTY_BUFF',
    'CHAT_MSG_SPELL_PARTY_DAMAGE',
    'CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS',
    'CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS',
    'CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE',
    'CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE',
    'CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS',
    'CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE',
    'CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS',
    'CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE',
    'CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE',
    'CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS',
    'CHAT_MSG_SPELL_AURA_GONE_OTHER'
}

-- session variables
local casts = {}
local buffs = {}

local CreateCastbar = function(nameplate)
    nameplate.castbar = CreateFrame("StatusBar", nil, nameplate)
    nameplate.castbar:Hide()
    nameplate.castbar:SetPoint("CENTER", nameplate, "CENTER", 9, -24)
    nameplate.castbar:SetWidth(97)
    nameplate.castbar:SetHeight(10)
    nameplate.castbar:SetValue(0)
    nameplate.castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar", "BORDER")
    nameplate.castbar:SetMinMaxValues(0, 1)
    nameplate.castbar:SetStatusBarColor(0, .75, 0)
    
    nameplate.castbar.border = nameplate.castbar:CreateTexture(nil, "ARTWORK")
    nameplate.castbar.border:SetTexture("Interface\\Tooltips\\Nameplate-Border")
    nameplate.castbar.border:SetPoint("CENTER", nameplate, "CENTER", 0, -16)
    nameplate.castbar.border:SetWidth(124)
    nameplate.castbar.border:SetHeight(32)
    nameplate.castbar.border:SetTexCoord(1, 0, 0, 1)
    
    nameplate.castbar.background = CreateFrame("StatusBar", nil, nameplate)
    nameplate.castbar.background:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    nameplate.castbar.background:SetPoint("CENTER", nameplate, "CENTER", 9, -24)
    nameplate.castbar.background:SetWidth(97)
    nameplate.castbar.background:SetHeight(10)
    nameplate.castbar.background:SetValue(1)
    nameplate.castbar.background:SetMinMaxValues(0, 1)
    nameplate.castbar.background:SetStatusBarColor(0, 0, 0, 0.5)

    nameplate.castbar.icon = nameplate.castbar:CreateTexture(nil, "OVERLAY")
    nameplate.castbar.icon:SetPoint("TOP", nameplate.castbar.border, "LEFT", 11, -1)
    nameplate.castbar.icon:SetTexture([[Interface\Icons\Spell_fire_flamebolt]])
    nameplate.castbar.icon:SetWidth(14)
    nameplate.castbar.icon:SetHeight(14)
end

-- new cast-object
local CreateCastObject = function(unit, spell)
    local spellinformation = CASTING_SPELLS[spell]
    local cast = {}
    cast.unit = unit
    cast.spell = spell
    cast.starttime = GetTime()
    cast.endtime = GetTime() + spellinformation[2]
    cast.lowestrank = spellinformation[3]
    cast.highestrank = spellinformation[2]
    cast.icon = spellinformation[1]
    cast.pushback = 0
    return cast
end

-- loop through casts-array and remove old cast if unit is existing
local RemoveDuplicates = function(unit)
    for key, value in ipairs(casts) do
        if value.unit == unit then
            table.remove(casts, key)
            --print('Removed ' .. value.unit .. ' from casts.')
        end
    end
end

-- checks for duplicates, creates new cast-object and insert it to casts-variable
local createCast = function(unit, spell)
    if CASTING_SPELLS[spell] then
        local c = CreateCastObject(unit, spell)
        table.insert(casts, c)
        --print('Inserted ' .. spell .. ' into casts.')
    end
end

local interruptCast = function(target, spell)
    local interrupt = INTERRUPTS_SPELLS[spell]
    if interrupt then
        for key, value in ipairs(casts) do
            if value.unit == target then
                table.remove(casts, key)
            end
        end
    end
end

-- pserver pushback is wierd and it doesn't seem to work on mombs on K4 so I removed it.
local pushback = function(unit)
    for key, value in ipairs(casts) do
        if value.unit == unit and value.pushback < 1 then
            if value.starttime + .5 < GetTime() then
                value.starttime = value.starttime + .5
                value.endtime = value.endtime + .5
                value.pushback = value.pushback + 1
            else
                local push = GetTime() - value.starttime
                value.starttime = GetTime()
                value.endtime = value.endtime + push
                value.pushback = value.pushback + 1
            end
        end
    end
end

local fear = function(target)
    for key, value in ipairs(casts) do
        if value.unit == target then
            table.remove(casts, key)
        end
    end
end

local CreateBuff = function(buff, unit)
    local buffinformation = BUFF_TRACK[buff]
    local b = {}
    b.buff = buff
    b.unit = unit
    b.icon = buffinformation[1]
    b.endtime = GetTime() + buffinformation[2]
    return b
end

local RemoveDuplicateBuffs = function(buff, unit)
    for key, value in ipairs(buffs) do
        if value.unit == unit and value.buff == buff then
            table.remove(buffs, key)
        end
    end
end

local AddBuff = function(unit, buff)
    if BUFF_TRACK[buff] then
        RemoveDuplicateBuffs(buff, unit)
        local b = CreateBuff(buff, unit)
        table.insert(buffs, b)
        print(buff .. ' added.')
    end
end

-- controls every casting combat log event
local CastingController = function() 
    local _, _, caster, castspell                   = string.find(arg1, '(.+) begins to cast (.+).')
    local _, _, crafter, craftspell                 = string.find(arg1, '(.+) -> (.+).')
    local _, _, performer, performspell             = string.find(arg1, '(%a+) begins to perform (.+).')

    local _, _, gainer, gainspell                   = string.find(arg1, '(.+) gains (.+).')
    local _, _, fadespell, fader                    = string.find(arg1, '(.+) fades from (.+).')
    local _, _, afflicter, afflictspell             = string.find(arg1, '(.+) is afflicted by (.+).')
    local _, _, remer, remspell                     = string.find(arg1, '(.+)\'s (.+) is removed.')

    local _, _, hitter, hitspell, hitted            = string.find(arg1, '(.+)\'s (.+) hits (.+) for')
    local _, _, critter, critspell, critted         = string.find(arg1, '(.+)\'s (.+) crits (.+) for')
    local _, _, absorber, absorbspell, absorbed     = string.find(arg1, '(.+)\'s (.+) is absorbed by (.+).')

    local _, _, playerhitspell, playerhitted        = string.find(arg1, 'Your (.+) hits (.+) for')
    local _, _, playercritspell, playercritted      = string.find(arg1, 'Your (.+) crits (.+) for')
    local _, _, playerabsorbspell, playerabsorbed   = string.find(arg1, 'Your (.+) is absorbed by (.+).')

    local _, _, meleehitter, meleehitted            = string.find(arg1, '(.+) hits (.+) for')
    local _, _, meleecritter, meleecritted          = string.find(arg1, '(.+) crits (.+) for')
    local _, _, meleemisser                         = string.find(arg1, '(.+) misses (.+).')
    local _, _, meleedogder                         = string.find(arg1, '(.+) attacks. (.+) dodges.')
    local _, _, meleeparrier                        = string.find(arg1, '(.+) attacks. (.+) parries.')

    local _, _, playermeleehitted                   = string.find(arg1, 'You hit (.+) for')
    local _, _, playermeleecritted                  = string.find(arg1, 'You crit (.+) for')

    local _, _, channeldotted, _, channeldotter, channeldotspell    = string.find(arg1, '(.+) suffers (.+) from (.+)\'s (.+).')
    local _, _, _, playerchanneldotter, playerchanneldotspell       = string.find(arg1, 'You suffer (.+) from (.+)\'s (.+).')

    local _, _, channeldotterres, channeldotterres, channeldottedres                   = string.find(arg1, '(.+)\'s (.+) was resisted by (.+).')
    local _, _, playerchanneldotterres, playerchanneldotterres, playerchanneldottedres = string.find(arg1, '(.+)\'s (.+) was resisted.')

    local _, _, feared                              = string.find(arg1, '(.+) attempts to run away in fear!')

    local _, _, healer, healingspell                = string.find(arg1, '(.+)\'s (.+) heals (.+) for')

    if caster then RemoveDuplicates(caster) createCast(caster, castspell)
    elseif crafter then RemoveDuplicates(crafter) createCast(craft, craftspell)
    elseif performer then RemoveDuplicates(performer) createCast(perform, performspell)
    elseif gainer then interruptCast(gainer, gainspell)
    --elseif fader then --interruptCast(fader, fadespell) 
    elseif afflicter then interruptCast(afflicter, afflictspell) AddBuff(afflicter, afflictspell)
    --elseif remer then --createCast(rem, remspell)
    --elseif hitter then pushback(hitted) RemoveDuplicates(hitter) interruptCast(hitted, hitspell)
    elseif hitter then RemoveDuplicates(hitter) interruptCast(hitted, hitspell)
    --elseif critter then pushback(critted) RemoveDuplicates(critter) interruptCast(critted, critspell)
    elseif critter then RemoveDuplicates(critter) interruptCast(critted, critspell)
    elseif absorber then RemoveDuplicates(absorber) interruptCast(absorbed, absorbspell)
    --elseif playerhitspell then pushback(playerhitted) interruptCast(playerhitted, playerhitspell)
    --elseif playerhitspell then pushback(playerhitted) interruptCast(playerhitted, playerhitspell)
    elseif playercritspell then interruptCast(playercritted, playercritspell)
    elseif playercritspell then interruptCast(playercritted, playercritspell)
    elseif playerabsorbedspell then interruptCast(playerabsorbed, playerabsorbspell)
    --elseif meleehitter then RemoveDuplicates(meleehitter) pushback(meleehitted)
    elseif meleehitter then RemoveDuplicates(meleehitter)
    --elseif meleecritter then RemoveDuplicates(meleecritter) pushback(meleecritted)
    elseif meleecritter then RemoveDuplicates(meleecritter)
    --elseif playermeleehitted then pushback(playermeleehitted)
    --elseif playermeleecritted then pushback(playermeleecritted)
    elseif meleemisser then RemoveDuplicates(meleemisser)
    elseif meleedodger then RemoveDuplicates(meleedodger)
    elseif meleeparrier then RemoveDuplicates(meleeparrier)
    elseif healer then RemoveDuplicates(healer)
    elseif feared then fear(feared)
    end
end

-- checks if frame is a nameplate
local IsNameplate = function(frame)
    if frame:GetObjectType() ~= "Button" then return nil end
    local regions = frame:GetRegions()
    if not regions then return nil end
    if not regions.GetObjectType then return nil end
    if not regions.GetTexture then return nil end
    if regions:GetObjectType() ~= "Texture" then return nil end
    return regions:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
end

local UIUpdateController = function()
    local worldframes = { WorldFrame:GetChildren() }
    for _, frame in ipairs(worldframes) do
        if IsNameplate(frame) and frame:IsVisible() then
            local _, _, framename = frame:GetRegions()
            local name = framename:GetText()
            if not frame.created then
                CreateCastbar(frame)
                frame.created = true
            end
            for key, value in ipairs(casts) do
                if name == value.unit then
                    frame.castbar:SetMinMaxValues(value.starttime, value.endtime)
                    frame.castbar.icon:SetTexture(value.icon)
                    frame.castbar:SetValue(GetTime())
                    frame.castbar:Show()
                else
                    frame.castbar:Hide()
                    frame.castbar:SetValue(0)
                end
            end
            if not casts[1] then
                frame.castbar:Hide()
                frame.castbar:SetValue(0)
            end
        end
    end
end

local UpdateController = function()
    for key, value in ipairs(casts) do
        if value.endtime < GetTime() then
            table.remove(casts, key)
        end
    end
    for key, value in ipairs(buffs) do
        if value.endtime < GetTime() then
            table.remove(buffs, key)
        end
    end
end

-- loop and register all events
local UpdateInterval = 1 / 30
local LastUpdate = 0
MongiEnemyCastbar:SetScript('OnUpdate', function()
    LastUpdate = LastUpdate + arg1
    if (LastUpdate > UpdateInterval) then
        UpdateController()
        UIUpdateController()
        LastUpdate = 0
    end
end)

for key, value in pairs(events) do
    MongiEnemyCastbar:RegisterEvent(value)
end

MongiEnemyCastbar:SetScript('OnEvent', function() 
    CastingController()
end)
