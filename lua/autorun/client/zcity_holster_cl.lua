-- Z-City Back Holster (client). Put this addon into garrysmod/addons/.
--
-- Позиции отображения оружия за спиной редактируются в lua/holster/positions.lua —
-- любое back-оружие можно добавить туда по имени класса.
-- Если файл не загрузится или в нём ошибка, используются встроенные значения.

-- Встроенный запасной вариант (зеркало lua/holster/positions.lua).
local BuiltinPositions = {
    weapons = {
        weapon_hg_axe = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 5, 4), ang = Angle(0, 90, 160) },
        weapon_hg_sledgehammer = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 6, 2), ang = Angle(0, 90, 160) },
        weapon_hg_shovel = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 5, 0), ang = Angle(0, 90, 160) },
        weapon_hg_spear_pro = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 5, -2), ang = Angle(0, 100, 150) },
        weapon_hg_spear = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 5, -2), ang = Angle(0, 100, 150) },
        weapon_tomahawk = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 6), ang = Angle(0, 90, 180) },
        weapon_hatchet = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 6), ang = Angle(0, 90, 180) },
        weapon_hg_extinguisher = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 7, 0), ang = Angle(0, 90, 0) },
        weapon_hg_crowbar = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, -4), ang = Angle(0, 85, 170) },
        weapon_bat = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 0, -2), ang = Angle(0, 90, 170) },
        weapon_hg_machete = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, -4), ang = Angle(0, 90, 190) }
    },
    default = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0), ang = Angle(0, 90, 170) }
}

local function LoadPositions()
    local ok, result = pcall(include, "holster/positions.lua")
    local positions = nil
    if ok and istable(result) and istable(result.weapons) then
        positions = result
    elseif istable(ZCityHolsterPositions) and istable(ZCityHolsterPositions.weapons) then
        positions = ZCityHolsterPositions
    end

    if not positions then
        if not ok then
            print("[ZCity Holster] Не удалось загрузить lua/holster/positions.lua: " .. tostring(result))
        else
            print("[ZCity Holster] lua/holster/positions.lua не содержит таблицу weapons, используются встроенные позиции.")
        end
        positions = BuiltinPositions
    elseif not istable(positions.default) then
        positions.default = BuiltinPositions.default
    end

    return positions.weapons, positions.default
end

local HolsterConfig, DefaultHolsterConfig = LoadPositions()

local function ClearHolsters(ply)
    if not istable(ply.HolsterModels) then
        ply.HolsterModels = {}
        return
    end

    for _, modelData in ipairs(ply.HolsterModels) do
        if istable(modelData) and IsValid(modelData.ent) then
            modelData.ent:Remove()
        end
    end
    ply.HolsterModels = {}
end

net.Receive("ZCity_Holster_Sync", function()
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
                    ply.HolsterModels[1] = {
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
    if not IsValid(ent) or not istable(owner.HolsterModels) then return end

    for _, modelData in ipairs(owner.HolsterModels) do
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
hook.Add("PostPlayerDraw", "ZCity_RenderHolsters", function(ply)
    if not IsValid(ply) or not ply:Alive() or not istable(ply.HolsterModels) then return end
    DrawHolstersOn(ply, ply)
end)

-- Ragdolls (death corpse or FakeRagdoll of a living player): drawn on the ragdoll bones.
local function GetPlayerRagdoll(ply)
    local rag = ply.FakeRagdoll
    if not IsValid(rag) then rag = ply:GetNWEntity("FakeRagdoll", NULL) end
    if not IsValid(rag) then rag = ply:GetNWEntity("RagdollDeath", NULL) end
    if IsValid(rag) and rag ~= ply then return rag end
end

hook.Add("PostDrawOpaqueRenderables", "ZCity_RenderHolstersRagdoll", function()
    for _, ply in ipairs(player.GetAll()) do
        if istable(ply.HolsterModels) and #ply.HolsterModels > 0 then
            local rag = GetPlayerRagdoll(ply)
            if IsValid(rag) then
                DrawHolstersOn(rag, ply)
            end
        end
    end
end)

hook.Add("EntityRemoved", "ZCity_CleanHolsters", function(ent)
    if ent:IsPlayer() then
        ClearHolsters(ent)
    end
end)
