-- Put this file in lua/autorun/server/zcity_holster_sv.lua
--
-- Back holster for melee weapons.
--  * Any melee weapon (NoHolster == true, or listed below) can be holstered on the back.
--  * Only ONE holstered melee weapon is carried. Picking up another one drops the previous one.
--  * Two-handed firearms (TwoHanded or bigNoDrop) are never dropped by implicit drops
--    (e.g. when another weapon is dropped).
--  * Explicit drop commands (radial menu / bind) still drop them.
--  * The drop-command bypass is weapon-specific: only the exact weapon the command
--    would drop (the active weapon when the command was issued) is allowed through
--    for DROP_FLAG_TIME seconds, so protected weapons stay put even mid-window.

util.AddNetworkString("ZCity_Holster_Sync")

hg = hg or {}

-- Extra melee weapons that are always holstered even if NoHolster is not set.
local ExtraBackMelee = {
    weapon_hg_axe = true,
    weapon_hg_sledgehammer = true,
    weapon_hg_shovel = true,
    weapon_hg_spear_pro = true,
    weapon_hg_spear = true,
    weapon_tomahawk = true,
    weapon_hatchet = true,
    weapon_hg_extinguisher = true,
    weapon_hg_crowbar = true,
    weapon_bat = true,
    weapon_hg_machete = true
}

-- Returns true for any melee weapon that is allowed on the back.
local function IsBackMelee(wep)
    if not IsValid(wep) then return false end
    if ExtraBackMelee[wep:GetClass()] then return true end
    -- Firearms (bigNoDrop) never go on the back.
    return wep.NoHolster == true and wep.bigNoDrop ~= true
end
hg.IsBackMelee = IsBackMelee

-- Two-handed firearms (TwoHanded or bigNoDrop) must not be dropped by the holster.
local function IsTwoHandedFirearm(wep)
    return IsValid(wep) and (wep.TwoHanded == true or wep.bigNoDrop == true)
        and not IsBackMelee(wep)
end

-- A holstered weapon is one that is carried but is not the active weapon.
local function IsHolstered(ply, wep)
    return IsValid(wep) and IsBackMelee(wep) and wep ~= ply:GetActiveWeapon()
end

-- True only for the ONE weapon the player intentionally asked to drop
-- (the active weapon at the moment the drop command was issued) or for
-- internally forced drops. Other weapons stay protected even inside the
-- drop-command window, so an implicit drop (PlayerThink, sling drop, etc.)
-- can't take the main/back weapon along with the dropped one.
local function IsExplicitDrop(ply, wep)
    if ply.ZCityHolsterForceDrop then return true end
    if not ply.IsSpammingDropCommand then return false end
    return IsValid(ply.ZCityHolsterDropTarget) and wep == ply.ZCityHolsterDropTarget
end

-- Block ordinary drops, but keep ZCity's intentional drop-command bypass
-- (ply.IsSpammingDropCommand). Captured originals keep this safe if another addon wraps these methods.
-- Единая проверка: нужно ли блокировать дроп этого оружия.
-- Пропускаем только то оружие, для которого дроп был запрошен явно
-- (ply.ZCityHolsterDropTarget), либо принудительный дроп.
local function ShouldBlockDrop(ply, wep)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if IsExplicitDrop(ply, wep) then return false end
    if IsTwoHandedFirearm(wep) then return true end
    return IsHolstered(ply, wep)
end

-- Block ordinary drops at the method level, so direct calls
-- (Weapon:Drop / Player:DropWeapon) can't bypass the check.
local weaponMeta = debug.getregistry().Weapon
if weaponMeta and not weaponMeta.ZCityHolsterDropPatched then
    local oldWeaponDrop = weaponMeta.Drop
    if isfunction(oldWeaponDrop) then
        weaponMeta.ZCityHolsterDropPatched = true
        weaponMeta.Drop = function(self, ...)
            local owner = IsValid(self) and self:GetOwner()
            if IsValid(owner) and owner:IsPlayer() and ShouldBlockDrop(owner, self) then
                return
            end
            return oldWeaponDrop(self, ...)
        end
    end
end

local playerMeta = debug.getregistry().Player
if playerMeta and not playerMeta.ZCityHolsterDropWeaponPatched then
    local oldDropWeapon = playerMeta.DropWeapon
    if isfunction(oldDropWeapon) then
        playerMeta.ZCityHolsterDropWeaponPatched = true
        playerMeta.DropWeapon = function(self, wep, ...)
            if ShouldBlockDrop(self, wep) then
                return
            end
            return oldDropWeapon(self, wep, ...)
        end
    end
end

-- Drop a weapon on purpose (used when replacing the back weapon).
local function ForceDropWeapon(ply, wep)
    ply.ZCityHolsterForceDrop = true
    ply:DropWeapon(wep)
    ply.ZCityHolsterForceDrop = nil
end

-- Allow melee drops that come from the intentional drop commands:
-- the radial menu ("Drop Weapon" runs RunConsoleCommand("drop")) and any
-- player bind to "drop"/"dropweapon". ZCity's sv_drop.lua registers these
-- commands; we wrap them after all files are loaded and set the flag for
-- the duration of the drop (drop() defers DropWeapon with timer.Simple(0)).
local DROP_COMMANDS = { "drop", "dropweapon", "-drop", "-dropweapon" }
local DROP_FLAG_TIME = 0.25

local function MarkDropCommand(ply)
    if not IsValid(ply) then return end
    -- hg.drop drops the ACTIVE weapon when no explicit weapon is passed to the command,
    -- so remember it now and only allow this exact weapon through during the window.
    -- Anything else (e.g. the two-handed firearm on the back, force-dropped by
    -- homigrad-dropholstered or other implicit code) stays protected.
    local target = ply:GetActiveWeapon()
    ply.IsSpammingDropCommand = true
    ply.ZCityHolsterDropTarget = IsValid(target) and target or nil
    timer.Create("ZCity_HolsterDropFlag_" .. ply:EntIndex(), DROP_FLAG_TIME, 1, function()
        if IsValid(ply) then
            ply.IsSpammingDropCommand = nil
            ply.ZCityHolsterDropTarget = nil
        end
    end)
end

local function WrapDropCommands()
    local origDrop = hg and hg.drop
    if not isfunction(origDrop) then
        print("[ZCity Holster] hg.drop not found; melee drop command bypass not installed.")
        return
    end

    for _, name in ipairs(DROP_COMMANDS) do
        concommand.Add(name, function(ply, ...)
            if IsValid(ply) and ply:IsPlayer() then
                MarkDropCommand(ply)
            end
            return origDrop(ply, ...)
        end)
    end
end

hook.Add("InitPostEntity", "ZCity_HolsterDropCommands", WrapDropCommands)

hook.Add("PlayerCanDropWeapon", "ZCity_KeepTwoHandedFirearm", function(ply, wep)
    if IsTwoHandedFirearm(wep) and not IsExplicitDrop(ply, wep) then
        return false
    end
end)

hook.Add("PlayerCanDropWeapon", "ZCity_PreventMeleeDrop", function(ply, wep)
    if IsHolstered(ply, wep) then
        return IsExplicitDrop(ply, wep) and true or false
    end
end)

hook.Add("WeaponEquip", "ZCity_BypassTwoHanded", function(wep)
    if IsBackMelee(wep) then
        wep.TwoHanded = false
        wep.Weight = -1
    end
end)

-- Only one melee weapon is carried. When a new one is picked up, the previous one is dropped.
-- Picking up is never blocked, so the new weapon always goes to the back.
hook.Add("WeaponEquip", "ZCity_ReplaceBackMelee", function(wep, ply)
    if not IsValid(wep) or not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsBackMelee(wep) then return end

    -- Work on a snapshot: dropping removes weapons from ply:GetWeapons(),
    -- and mutating the table during ipairs would skip the next weapon.
    local weapons = ply:GetWeapons()
    local snapshot = {}
    for i = 1, #weapons do
        snapshot[i] = weapons[i]
    end

    for _, other in ipairs(snapshot) do
        if other ~= wep and IsValid(other) and IsBackMelee(other) then
            -- If the old weapon was in hand, the new one takes over the hand first.
            if ply:GetActiveWeapon() == other then
                ply:SelectWeapon(wep:GetClass())
            end
            ForceDropWeapon(ply, other)
        end
    end
end)

-- Send at most one holstered melee weapon to the client for the back holster.
-- The active weapon is held, not shown on the back.
local function SyncWeapons(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local data = {}
    local active = ply:GetActiveWeapon()

    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) and IsBackMelee(wep) and wep ~= active then
            local model = wep:GetWeaponWorldModel()
            if not isstring(model) or model == "" then
                model = wep.WorldModel
            end

            if isstring(model) and model ~= "" then
                data[1] = {
                    class = wep:GetClass(),
                    model = model
                }
                break
            end
        end
    end

    -- Remember the last holstered weapon so it can still be shown on the
    -- ragdoll after death (weapons are usually gone by then).
    if data[1] then
        ply.ZCityHolsterSnapshot = data
    elseif not ply:Alive() and ply.ZCityHolsterSnapshot then
        data = ply.ZCityHolsterSnapshot
    elseif ply:Alive() then
        ply.ZCityHolsterSnapshot = nil
    end

    net.Start("ZCity_Holster_Sync")
        net.WriteEntity(ply)
        net.WriteTable(data)
    net.Broadcast()
end

local function QueueSync(ply)
    timer.Simple(0.1, function()
        if IsValid(ply) then SyncWeapons(ply) end
    end)
end

hook.Add("WeaponEquip", "ZCity_Holster_Equip", function(_, ply)
    QueueSync(ply)
end)

hook.Add("PlayerSwitchWeapon", "ZCity_Holster_Switch", function(ply)
    QueueSync(ply)
end)

hook.Add("PlayerDroppedWeapon", "ZCity_Holster_Drop", function(ply)
    QueueSync(ply)
end)

hook.Add("PlayerDeath", "ZCity_Holster_Death", function(ply)
    QueueSync(ply)
end)

hook.Add("PlayerSpawn", "ZCity_Holster_Respawn", function(ply)
    QueueSync(ply)
end)

hook.Add("PlayerInitialSpawn", "ZCity_Holster_SpawnSync", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then SyncWeapons(ply) end
    end)
end)
