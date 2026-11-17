-- Remorseim Back Holster (server).
-- Временная установка: файлы кидаются в папки Гмода —
-- lua/autorun/server (этот файл + rem_holster_positions.lua) и
-- lua/autorun/client (rem_holster_cl.lua). Пока не собраны в отдельный аддон.
-- Отдельная система для милишек Remorseim Gun Pack. Работает рядом с zcity_holster:
-- у каждого свой белый список, свои позиции, свой net-канал и свои хуки,
-- поэтому они не конфликтуют. Модели берутся из самих оружий по их путям
-- (WorldModelExchange / WorldModelReal — «своя» модель Remorseim), а не хардкодятся.

-- Отдать клиенту клиентскую часть (нужно на выделенном сервере без мастерской).
-- Конфиг позиций клиенту НЕ отдаётся — сервер присылает значения сам.
AddCSLuaFile("autorun/client/rem_holster_cl.lua")

-- Back holster for Remorseim melee weapons.
--  * Back-оружие — это ровно белый список из rem_holster_positions.lua (секция weapons).
--  * Only ONE Remorseim back weapon is carried. Picking up another one drops the previous one.
--  * Two-handed firearms (TwoHanded or bigNoDrop) are never dropped by implicit drops.
--  * Explicit drop commands (radial menu / bind) still drop them.
--  * The drop-command bypass is weapon-specific: only the exact weapon the command
--    would drop (the active weapon when the command was issued) is allowed through
--    for DROP_FLAG_TIME seconds, so protected weapons stay put even mid-window.
--  * Совместимость с zcity_holster: hg.IsBackMelee расширяется и на Rem-оружия,
--    поэтому стоковый хук homigrad-dropholstered (и его замена из zcity_holster)
--    не трогает и Rem-оружия за спиной. Явный дроп помечает оба флага
--    (Rem и ZCity), чтобы любой из двух аддонов, чей wrapper остался активным,
--    корректно пропускал только запрошенное оружие.

util.AddNetworkString("Rem_Holster_Sync")
util.AddNetworkString("Rem_Holster_Config")

hg = hg or {}

-- ================= Построение моделей ВСЕХ оружий =================
-- Профилактика бага «моделька не рисуется»: модели паков используются
-- через ClientsideModel/пропы, а не через регистрацию SWEP, поэтому движок
-- может их не знать (и пропы выброшенного оружия тоже). При старте собираем
-- ВСЕ .mdl-пути из ВСЕХ зарегистрированных оружий (включая будущие) и
-- прекешируем их — построение моделей одинаково для всех, без багов потом.
local function CollectModelStrings(tbl, depth, seen, out)
    if type(tbl) ~= "table" or seen[tbl] or (depth or 0) > 6 then return end
    seen[tbl] = true
    for _, v in pairs(tbl) do
        if type(v) == "string" and string.sub(v, -4) == ".mdl" then
            out[v] = true
        elseif type(v) == "table" then
            CollectModelStrings(v, (depth or 0) + 1, seen, out)
        end
    end
end

local ModelsPrechachedReported = false

local function RemHolsterPrecacheAllModels()
    local out, seen = {}, {}
    for _, wepTbl in pairs(weapons.GetList()) do
        CollectModelStrings(wepTbl, 0, seen, out)
    end

    local n = 0
    for mdl in pairs(out) do
        pcall(util.PrecacheModel, mdl)
        n = n + 1
    end

    if not ModelsPrechachedReported then
        ModelsPrechachedReported = true
        print("[Rem Holster] Построение моделей: прекешировано моделей оружия — " .. n)
    end
end

-- Запускаем ТОЛЬКО через таймер и под pcall — сознательно НЕ вешаемся на
-- Initialize/InitPostEntity: ошибка одного обработчика в GMod обрывает
-- остальные хуки того же события, а это ломает чужие системы.
timer.Simple(2, function()
    pcall(RemHolsterPrecacheAllModels)
end)

-- Встроенный запасной список back-оружия — используется, если конфиг не найден.
local BuiltinRemBackMelee = {
    weapon_rem_melee_hg_spear = true,
    weapon_rem_melee_hg_sledgehammer = true,
    weapon_rem_melee_hg_shovel = true,
    weapon_rem_melee_hg_spear_pro = true,
    weapon_rem_melee_hg_machete = true,
    weapon_rem_melee_hatchet = true,
    weapon_rem_melee_hg_axe = true,
    weapon_rem_melee_hg_crowbar = true,
    weapon_rem_melee_chainsaw = true,
    weapon_rem_melee_bat = true,
    weapon_rem_melee_metalbat = true
}

-- Конфиг позиций ищется в нескольких местах — чтобы файл можно было просто
-- кинуть в папку lua/autorun/server рядом с этим файлом. Позиции читает
-- ТОЛЬКО сервер и рассылает клиентам — на клиенте никакой файл не нужен.
local ConfigPaths = {
    "autorun/server/rem_holster_positions.lua", -- основной: рядом с этим файлом
    "rem_holster/positions.lua",                -- старый путь (если уже настроен)
    "autorun/server/rem_holster/positions.lua",
    "rem_holster_positions.lua",
}

local function LoadHolsterConfig()
    for _, path in ipairs(ConfigPaths) do
        local ok, result = pcall(include, path)
        if ok and istable(result) and istable(result.weapons) then
            return result
        end
        if istable(RemHolsterPositions) and istable(RemHolsterPositions.weapons) then
            return RemHolsterPositions
        end
    end
    return nil
end

local HolsterConfigTable = LoadHolsterConfig()

-- Белый список back-оружия: это ключи секции weapons конфига позиций.
local ExtraRemBackMelee = (function()
    if HolsterConfigTable then
        local list = {}
        for class in pairs(HolsterConfigTable.weapons) do
            list[class] = true
        end
        if next(list) then
            return list
        end
    end
    print("[Rem Holster] Конфиг позиций не найден — используются встроенные значения (положи lua/autorun/server/rem_holster_positions.lua).")
    return BuiltinRemBackMelee
end)()

-- Returns true for any Remorseim weapon allowed on the back (white list only).
local function IsRemBackMelee(wep)
    if not IsValid(wep) then return false end
    return ExtraRemBackMelee[wep:GetClass()] == true
end
hg.IsRemBackMelee = IsRemBackMelee

-- Расширяем общий hg.IsBackMelee (если он уже есть от zcity_holster) и на Rem-оружия.
-- Тогда замена хука homigrad-dropholstered из zcity_holster тоже не трогает Rem-оружия.
local origIsBackMelee = hg.IsBackMelee
if isfunction(origIsBackMelee) then
    hg.IsBackMelee = function(wep)
        if IsRemBackMelee(wep) then return true end
        return origIsBackMelee(wep)
    end
else
    hg.IsBackMelee = IsRemBackMelee
end

-- Двуручность милишки (TwoHanded) — это хват (огнетушитель, кувалда...), а
-- не признак ствола: милишка вне белого списка должна выбрасываться как
-- обычное оружие. Поэтому защита «двуручных стволов» от неявного выброса
-- действует только на НЕ-мелишное оружие.
local function IsMeleeWeapon(wep)
    if not IsValid(wep) then return false end
    local class = wep:GetClass()
    if not isstring(class) then return false end
    if string.sub(class, 1, 16) == "weapon_rem_melee" then return true end
    if weapons.IsBasedOn then
        return weapons.IsBasedOn(class, "weapon_melee") or weapons.IsBasedOn(class, "weapon_rem_melee_base")
    end
    return false
end

-- Two-handed firearms (TwoHanded or bigNoDrop) must not be dropped by the holster.
local function IsTwoHandedFirearm(wep)
    return IsValid(wep) and (wep.TwoHanded == true or wep.bigNoDrop == true)
        and not IsRemBackMelee(wep) and not IsMeleeWeapon(wep)
end

-- A holstered weapon is one that is carried but is not the active weapon.
local function IsHolstered(ply, wep)
    return IsValid(wep) and IsRemBackMelee(wep) and wep ~= ply:GetActiveWeapon()
end

-- True only for the ONE weapon the player intentionally asked to drop
-- (the active weapon at the moment the drop command was issued) or for
-- internally forced drops. Проверяем оба флага (Rem и ZCity), чтобы явный
-- дроп работал независимо от того, чей wrapper команд drop/dropweapon активен.
local function IsExplicitDrop(ply, wep)
    if ply.RemHolsterForceDrop or ply.ZCityHolsterForceDrop then return true end
    if not ply.IsSpammingDropCommand then return false end
    if IsValid(ply.RemHolsterDropTarget) and wep == ply.RemHolsterDropTarget then return true end
    if IsValid(ply.ZCityHolsterDropTarget) and wep == ply.ZCityHolsterDropTarget then return true end
    return false
end

-- Block ordinary drops, but keep ZCity's intentional drop-command bypass
-- (ply.IsSpammingDropCommand). Captured originals keep this safe if another addon wraps these methods.
local function ShouldBlockDrop(ply, wep)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if IsExplicitDrop(ply, wep) then return false end
    if IsTwoHandedFirearm(wep) then return true end
    return IsHolstered(ply, wep)
end

-- Block ordinary drops at the method level, so direct calls
-- (Weapon:Drop / Player:DropWeapon) can't bypass the check.
-- Флаги свои (RemHolster...), чтобы не конфликтовать с патчами zcity_holster:
-- каждый аддон оборачивает текущий Drop и вызывает предыдущий, поэтому
-- защита обоих списков работает при любом порядке загрузки.
local weaponMeta = debug.getregistry().Weapon
if weaponMeta and not weaponMeta.RemHolsterDropPatched then
    local oldWeaponDrop = weaponMeta.Drop
    if isfunction(oldWeaponDrop) then
        weaponMeta.RemHolsterDropPatched = true
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
if playerMeta and not playerMeta.RemHolsterDropWeaponPatched then
    local oldDropWeapon = playerMeta.DropWeapon
    if isfunction(oldDropWeapon) then
        playerMeta.RemHolsterDropWeaponPatched = true
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
    ply.RemHolsterForceDrop = true
    ply.ZCityHolsterForceDrop = true
    ply:DropWeapon(wep)
    ply.RemHolsterForceDrop = nil
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
    local target = ply:GetActiveWeapon()
    ply.IsSpammingDropCommand = true
    ply.RemHolsterDropTarget = IsValid(target) and target or nil
    -- Ставим и флаг zcity_holster, чтобы его IsExplicitDrop тоже сработал,
    -- если активен именно наш wrapper (и наоборот — наш IsExplicitDrop
    -- проверяет оба флага, поэтому порядок загрузки не важен).
    ply.ZCityHolsterDropTarget = IsValid(target) and target or nil
    timer.Create("Rem_HolsterDropFlag_" .. ply:EntIndex(), DROP_FLAG_TIME, 1, function()
        if IsValid(ply) then
            ply.IsSpammingDropCommand = nil
            ply.RemHolsterDropTarget = nil
            ply.ZCityHolsterDropTarget = nil
        end
    end)
end

local function WrapDropCommands()
    local origDrop = hg and hg.drop
    if not isfunction(origDrop) then
        print("[Rem Holster] hg.drop not found; melee drop command bypass not installed.")
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

hook.Add("InitPostEntity", "Rem_HolsterDropCommands", function()
    pcall(WrapDropCommands)
end)

-- Заменяет стоковый хук ZCity "homigrad-dropholstered" (sv_util.lua), который
-- насильно выбрасывает любое подобранное NoHolster-оружие не в руках, на версию,
-- которая не трогает оружие за спиной (hg.IsBackMelee уже включает Rem-оружия).
-- Если zcity_holster тоже заменил этот хук, победит последний по InitPostEntity —
-- обе версии проверяют hg.IsBackMelee, поэтому Rem-оружия защищены в любом случае.
local function ReplaceDropHolsteredHook()
    hook.Add("Player Think", "homigrad-dropholstered", function(ply)
        if (ply.thinkdropwep or 0) > CurTime() then return end
        ply.thinkdropwep = CurTime() + 0.1
        if ply.organism and ply.organism.allowholster then return end

        local activewep = ply:GetActiveWeapon()
        local weps = ply:GetWeapons()
        -- Итерация по снапшоту: дроп может менять список оружия игрока.
        local snapshot = {}
        for i = 1, #weps do
            snapshot[i] = weps[i]
        end
        for i = 1, #snapshot do
            local wep = snapshot[i]

            -- Стоковое поведение, но back-оружие (hg.IsBackMelee / IsRemBackMelee) остаётся на спине.
            if wep.NoHolster and activewep ~= wep and wep.picked and not (hg.IsBackMelee and hg.IsBackMelee(wep)) and not IsRemBackMelee(wep) then
                ply:DropWeapon(wep)
            end
        end
    end)
end

ReplaceDropHolsteredHook()
hook.Add("InitPostEntity", "Rem_HolsterDropHolsteredFix", function()
    pcall(ReplaceDropHolsteredHook)
end)

hook.Add("PlayerCanDropWeapon", "Rem_KeepTwoHandedFirearm", function(ply, wep)
    if IsTwoHandedFirearm(wep) and not IsExplicitDrop(ply, wep) then
        return false
    end
end)

hook.Add("PlayerCanDropWeapon", "Rem_PreventMeleeDrop", function(ply, wep)
    if IsHolstered(ply, wep) then
        return IsExplicitDrop(ply, wep) and true or false
    end
end)

hook.Add("WeaponEquip", "Rem_BypassTwoHanded", function(wep)
    if IsRemBackMelee(wep) then
        wep.TwoHanded = false
        wep.Weight = -1
    end
end)

-- Only one Remorseim back weapon is carried. When a new one is picked up, the previous one is dropped.
-- Picking up is never blocked, so the new weapon always goes to the back.
-- ZCity-оружия за спиной не трогаем: у каждого аддона свой слот (максимум 1+1).
hook.Add("WeaponEquip", "Rem_ReplaceBackMelee", function(wep, ply)
    if not IsValid(wep) or not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsRemBackMelee(wep) then return end

    -- Work on a snapshot: dropping removes weapons from ply:GetWeapons(),
    -- and mutating the table during ipairs would skip the next weapon.
    local weapons = ply:GetWeapons()
    local snapshot = {}
    for i = 1, #weapons do
        snapshot[i] = weapons[i]
    end

    for _, other in ipairs(snapshot) do
        if other ~= wep and IsValid(other) and IsRemBackMelee(other) then
            -- If the old weapon was in hand, the new one takes over the hand first.
            if ply:GetActiveWeapon() == other then
                ply:SelectWeapon(wep:GetClass())
            end
            ForceDropWeapon(ply, other)
        end
    end
end)

-- Модель для спины = ровно та, что пак рисует в руках и на земле при
-- выбрасывании (DrawWorldModel2): WorldModelExchange @ modelscale,
-- иначе WorldModelReal @ modelscale2, иначе WorldModel @ modelscale2.
-- Масштаб берём ИМЕННО тот, которым пак рисует эту модель, иначе оружие на
-- спине будет другого размера, чем в руках (например бита: modelscale 1.45
-- относится к WorldModel, а модель в руках рисуется с modelscale2 = 1).
-- Ничего не хардкодим и не фильтруем по имени файла: у пака своя модель на
-- каждое оружие, и на спине должна стоять именно она.
local function GetBackModel(wep)
    if not IsValid(wep) then return nil end

    if isstring(wep.WorldModelExchange) and wep.WorldModelExchange ~= "" then
        return wep.WorldModelExchange, tonumber(wep.modelscale) or 1
    end

    if isstring(wep.WorldModelReal) and wep.WorldModelReal ~= "" then
        return wep.WorldModelReal, tonumber(wep.modelscale2) or 1
    end

    if isstring(wep.WorldModel) and wep.WorldModel ~= "" then
        return wep.WorldModel, tonumber(wep.modelscale2) or 1
    end

    return nil
end

-- Send at most one holstered Remorseim weapon to the client for the back holster.
-- The active weapon is held, not shown on the back.
-- Конфиг позиций уходит клиенту один раз при заходе — настраивать нужно
-- только на сервере (lua/autorun/server/rem_holster_positions.lua).
local function SendHolsterConfig(ply)
    if not HolsterConfigTable or not IsValid(ply) then return end
    net.Start("Rem_Holster_Config")
        net.WriteTable(HolsterConfigTable)
    net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "Rem_Holster_ConfigSync", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then SendHolsterConfig(ply) end
    end)
end)

local function SyncWeapons(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    if not ply.RemHolsterConfigSent then
        ply.RemHolsterConfigSent = true
        SendHolsterConfig(ply)
    end

    local data = {}
    local active = ply:GetActiveWeapon()

    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) and IsRemBackMelee(wep) and wep ~= active then
            local model, scale = GetBackModel(wep)
            if isstring(model) and model ~= "" then
                data[1] = {
                    class = wep:GetClass(),
                    model = model,
                    scale = scale or 1
                }
                break
            end
        end
    end

    -- Remember the last holstered weapon so it can still be shown on the
    -- ragdoll after death (weapons are usually gone by then).
    if data[1] then
        ply.RemHolsterSnapshot = data
    elseif not ply:Alive() and ply.RemHolsterSnapshot then
        data = ply.RemHolsterSnapshot
    elseif ply:Alive() then
        ply.RemHolsterSnapshot = nil
    end

    net.Start("Rem_Holster_Sync")
        net.WriteEntity(ply)
        net.WriteTable(data)
    net.Broadcast()
end

local function QueueSync(ply)
    timer.Simple(0.1, function()
        if IsValid(ply) then SyncWeapons(ply) end
    end)
end

hook.Add("WeaponEquip", "Rem_Holster_Equip", function(_, ply)
    QueueSync(ply)
end)

hook.Add("PlayerSwitchWeapon", "Rem_Holster_Switch", function(ply)
    QueueSync(ply)
end)

hook.Add("PlayerDroppedWeapon", "Rem_Holster_Drop", function(ply)
    QueueSync(ply)
end)

hook.Add("PlayerDeath", "Rem_Holster_Death", function(ply)
    QueueSync(ply)
end)

hook.Add("PlayerSpawn", "Rem_Holster_Respawn", function(ply)
    QueueSync(ply)
end)

hook.Add("PlayerInitialSpawn", "Rem_Holster_SpawnSync", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then SyncWeapons(ply) end
    end)
end)
