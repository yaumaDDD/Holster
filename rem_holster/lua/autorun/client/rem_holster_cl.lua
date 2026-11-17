-- Remorseim Back Holster (client).
-- Временная установка: файлы лежат прямо в директории Гмода —
-- garrysmod/lua/autorun/server, garrysmod/lua/autorun/client и
-- garrysmod/lua/rem_holster (позиции). Пока не собраны в отдельный аддон.
--
-- Оружие, которое носится за спиной, и его позиции редактируются в
-- lua/rem_holster/positions.lua (это белый список для сервера и клиента сразу).
-- Если файл не загрузится или в нём ошибка, используются встроенные значения.
-- Модели берутся из самих оружий Remorseim по их путям (сервер присылает путь).

-- Встроенный запасной вариант (зеркало lua/rem_holster/positions.lua).
local BuiltinPositions = {
    weapons = {
        weapon_rem_melee_hg_spear = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0), ang = Angle(0, -20, -2.5) },
        weapon_rem_melee_hg_sledgehammer = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0), ang = Angle(0, -90, -2.5) },
        weapon_rem_melee_hg_shovel = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 2.5, 0), ang = Angle(65, 0, 265) },
        weapon_rem_melee_hg_spear_pro = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0), ang = Angle(90, -15, -2.5) },
        weapon_rem_melee_hg_machete = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(0, 60, -5) },
        weapon_rem_melee_hatchet = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0), ang = Angle(0, 120, -5) },
        weapon_rem_melee_hg_axe = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(90, 120, -5) },
        weapon_rem_melee_hg_crowbar = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(0, -60, 0) },
        weapon_rem_melee_chainsaw = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0), ang = Angle(0, -90, -2.5) },
        weapon_rem_melee_bat = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3), ang = Angle(0, -115, -5) },
        weapon_rem_melee_metalbat = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3), ang = Angle(0, -115, -5) }
    },
    default = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0), ang = Angle(0, 90, 170) }
}

local function LoadPositions()
    local ok, result = pcall(include, "rem_holster/positions.lua")
    local positions = nil
    if ok and istable(result) and istable(result.weapons) then
        positions = result
    elseif istable(RemHolsterPositions) and istable(RemHolsterPositions.weapons) then
        positions = RemHolsterPositions
    end

    if not positions then
        if not ok then
            print("[Rem Holster] Не удалось загрузить lua/rem_holster/positions.lua: " .. tostring(result))
        else
            print("[Rem Holster] lua/rem_holster/positions.lua не содержит таблицу weapons, используются встроенные позиции.")
        end
        positions = BuiltinPositions
    elseif not istable(positions.default) then
        positions.default = BuiltinPositions.default
    end

    return positions.weapons, positions.default
end

local HolsterConfig, DefaultHolsterConfig = LoadPositions()

-- ============================================================
-- Модели оружия: показывать СВОЮ модель (WorldModel), а не подменную.
-- У части Rem-оружий WorldModelExchange указывает на ВНЕШНЮЮ модель
-- (models/tfa_nmrih/w_bat.mdl, ravaged, re9 — «не из реморсеима»), и сам пак
-- рисует именно её в руках, на земле и при дропе. Принудительно возвращаем
-- модель самого оружия — везде: в руках, на земле, при дропе и на спине.
-- (Та же правка есть в серверном файле — поля SWEP не сетуются, поэтому
-- патч должен выполняться в обоих realm.)
-- ============================================================

-- Привязки в руках как у ZCity-аналогов с той же моделью (см. серверный файл).
local RemModelTune = {
    weapon_rem_melee_bat = { pos = {1.5, 0.2, -0.2}, ang = {-79, 5, -4} },
    weapon_rem_melee_hg_sledgehammer = { pos = {0, 0, 0}, ang = {0, -90, 0} },
    weapon_rem_melee_hg_crowbar = { pos = {0, 0, -15}, ang = {0, -90, 0} },
    weapon_rem_melee_hatchet = { pos = {0, 5, -2}, ang = {0, -90, 0} },
}

local function PatchRemWeapon(class, tbl)
    if not istable(tbl) then return end
    local wm = tbl.WorldModel
    local ex = tbl.WorldModelExchange
    if not (isstring(wm) and wm ~= "" and isstring(ex) and ex ~= "" and ex ~= wm) then return end

    tbl.WorldModelExchange = wm
    tbl.modelscale = 1

    local tune = RemModelTune[class]
    if tune then
        tbl.weaponPos = Vector(tune.pos[1], tune.pos[2], tune.pos[3])
        tbl.weaponAng = Angle(tune.ang[1], tune.ang[2], tune.ang[3])
    end

    if isfunction(tbl.SetModelScale) then
        pcall(tbl.SetModelScale, tbl, 1)
    end
end

-- Патчим и таблицы классов (наследуются всеми будущими экземплярами),
-- и уже созданные экземпляры (в т.ч. оружие, лежащее на земле).
local function PatchRemModels()
    for class in pairs(HolsterConfig) do
        PatchRemWeapon(class, weapons.GetStored(class))
    end
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and HolsterConfig[ent:GetClass()] then
            PatchRemWeapon(ent:GetClass(), ent)
        end
    end
end

PatchRemModels()
hook.Add("InitPostEntity", "Rem_HolsterModelFix", PatchRemModels)
timer.Create("Rem_HolsterModelFixTimer", 2, 0, PatchRemModels)

local function ClearHolsters(ply)
    if not istable(ply.RemHolsterModels) then
        ply.RemHolsterModels = {}
        return
    end

    for _, modelData in ipairs(ply.RemHolsterModels) do
        if istable(modelData) and IsValid(modelData.ent) then
            modelData.ent:Remove()
        end
    end
    ply.RemHolsterModels = {}
end

net.Receive("Rem_Holster_Sync", function()
    local ply = net.ReadEntity()
    local weapons = net.ReadTable()
    if not IsValid(ply) then return end

    ClearHolsters(ply)
    if not istable(weapons) then return end

    local active = ply:GetActiveWeapon()
    local activeClass = IsValid(active) and active:GetClass() or ""

    -- Server sends zero or one candidate. Keep the client-side cap as a safeguard.
    -- Dead players get their last holstered weapon here too, so it stays on the ragdoll.
    for _, weaponData in ipairs(weapons) do
        if istable(weaponData) and (not ply:Alive() or weaponData.class ~= activeClass) then
            local config = HolsterConfig[weaponData.class] or DefaultHolsterConfig
            local model = weaponData.model

            if config and isstring(model) and model ~= "" and util.IsValidModel(model) then
                local prop = ClientsideModel(model, RENDERGROUP_OPAQUE)
                if IsValid(prop) then
                    prop:SetNoDraw(true)
                    ply.RemHolsterModels[1] = {
                        ent = prop,
                        bone = config.bone,
                        pos = config.pos,
                        ang = config.ang
                    }
                    break
                end
            end
        end
    end
end)

-- Draws the holstered models attached to `ent` (a player or a ragdoll with the same skeleton).
local function DrawHolstersOn(ent, owner)
    if not IsValid(ent) or not istable(owner.RemHolsterModels) then return end

    for _, modelData in ipairs(owner.RemHolsterModels) do
        local prop = modelData.ent
        if IsValid(prop) then
            local boneIndex = ent:LookupBone(modelData.bone)
            if boneIndex then
                local matrix = ent:GetBoneMatrix(boneIndex)
                if matrix then
                    local bonePos = matrix:GetTranslation()
                    local boneAng = matrix:GetAngles()
                    local worldPos = bonePos
                        + boneAng:Forward() * modelData.pos.x
                        + boneAng:Right() * modelData.pos.y
                        + boneAng:Up() * modelData.pos.z

                    -- Rotate a copy, not the angle returned by the bone matrix.
                    local worldAng = Angle(boneAng.p, boneAng.y, boneAng.r)
                    worldAng:RotateAroundAxis(boneAng:Forward(), modelData.ang.p)
                    worldAng:RotateAroundAxis(boneAng:Right(), modelData.ang.y)
                    worldAng:RotateAroundAxis(boneAng:Up(), modelData.ang.r)

                    prop:SetPos(worldPos)
                    prop:SetAngles(worldAng)
                    prop:SetupBones()
                    prop:DrawModel()
                end
            end
        end
    end
end

-- Living players: drawn with the player model.
hook.Add("PostPlayerDraw", "Rem_RenderHolsters", function(ply)
    if not IsValid(ply) or not ply:Alive() or not istable(ply.RemHolsterModels) then return end
    DrawHolstersOn(ply, ply)
end)

-- Ragdolls (death corpse or FakeRagdoll of a living player): drawn on the ragdoll bones.
local function GetPlayerRagdoll(ply)
    local rag = ply.FakeRagdoll
    if not IsValid(rag) then rag = ply:GetNWEntity("FakeRagdoll", NULL) end
    if not IsValid(rag) then rag = ply:GetNWEntity("RagdollDeath", NULL) end
    if IsValid(rag) and rag ~= ply then return rag end
end

hook.Add("PostDrawOpaqueRenderables", "Rem_RenderHolstersRagdoll", function()
    for _, ply in ipairs(player.GetAll()) do
        if istable(ply.RemHolsterModels) and #ply.RemHolsterModels > 0 then
            local rag = GetPlayerRagdoll(ply)
            if IsValid(rag) then
                DrawHolstersOn(rag, ply)
            end
        end
    end
end)

hook.Add("EntityRemoved", "Rem_CleanHolsters", function(ent)
    if ent:IsPlayer() then
        ClearHolsters(ent)
    end
end)
