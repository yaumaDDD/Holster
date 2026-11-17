-- Z-City + Remorseim Back Holster (client).
-- Put this addon into garrysmod/addons/.
-- Один аддон для милишек Z-City и Remorseim Gun Pack: общий белый список,
-- общий файл позиций lua/holster/positions.lua.
--
-- Оружие, которое носится за спиной, и его позиции редактируются в
-- lua/holster/positions.lua (это белый список для сервера и клиента сразу).
-- Если файл не загрузится или в нём ошибка, используются встроенные значения.

-- Встроенный запасной вариант (зеркало lua/holster/positions.lua).
local BuiltinPositions = {
    weapons = {
        weapon_hg_axe = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(90, 120, -5) },
        weapon_hg_sledgehammer = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0), ang = Angle(0, -90, -2.5) },
        weapon_hg_shovel = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 2.5, 0), ang = Angle(65, 0, 265) },
        weapon_hg_spear_pro = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0), ang = Angle(90, -15, -2.5) },
        weapon_hg_spear = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0), ang = Angle(0, -20, -2.5) },
        weapon_tomahawk = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0), ang = Angle(90, 120, -5) },
        weapon_hatchet = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0), ang = Angle(0, 120, -5) },
        weapon_hg_crowbar = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(0, -60, 0) },
        weapon_bat = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3), ang = Angle(0, -115, -5) },
        weapon_hg_machete = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(0, 60, -5) },

        -- Remorseim Gun Pack
        weapon_rem_melee_hg_spear = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0), ang = Angle(0, -20, -2.5) },
        weapon_rem_melee_hg_spear_pro = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0), ang = Angle(90, -15, -2.5) },
        weapon_rem_melee_hg_sledgehammer = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0), ang = Angle(0, -90, -2.5) },
        weapon_rem_melee_hg_shovel = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 2.5, 0), ang = Angle(65, 0, 265) },
        weapon_rem_melee_chainsaw = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0), ang = Angle(0, -90, -2.5) },
        weapon_rem_melee_hg_axe = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(90, 120, -5) },
        weapon_rem_melee_bat = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3), ang = Angle(0, -115, -5) },
        weapon_rem_melee_metalbat = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3), ang = Angle(0, -115, -5) },
        weapon_rem_melee_hg_machete = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(0, 60, -5) },
        weapon_rem_melee_hatchet = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0), ang = Angle(0, 120, -5) },
        weapon_rem_melee_hg_crowbar = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(0, -60, 0) }
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
            print("[Holster] Не удалось загрузить lua/holster/positions.lua: " .. tostring(result))
        else
            print("[Holster] lua/holster/positions.lua не содержит таблицу weapons, используются встроенные позиции.")
        end
        positions = BuiltinPositions
    elseif not istable(positions.default) then
        positions.default = BuiltinPositions.default
    end

    return positions.weapons, positions.default
end

local HolsterConfig, DefaultHolsterConfig = LoadPositions()

-- Центр геометрии модели в её локальных координатах.
-- У части моделей точка привязки стоит НЕ в середине оружия (например у
-- алюминиевой биты Remorseim — на ручке), поэтому оружие ставится в спину
-- своим ЦЕНТРОМ: так pos/ang означают одно и то же для любого оружия, и
-- модель в руках садится туда же, куда села бы мировая.
-- Меряем по КОСТЯМ, а не по границам модели: у вьюмоделей bbox раздут
-- анимациями в разы и сдвиг по нему уводит оружие с тела.
local function MeasureModelCenter(prop, scale)
    scale = tonumber(scale) or 1

    local boneCount = 0
    local okBones, count = pcall(prop.GetBoneCount, prop)
    if okBones and tonumber(count) then boneCount = tonumber(count) end

    local mins, maxs
    if boneCount > 0 then
        local savedPos, savedAng = prop:GetPos(), prop:GetAngles()
        prop:SetPos(vector_origin)
        prop:SetAngles(angle_zero)
        prop:SetupBones()

        local bmin, bmax
        for i = 0, boneCount - 1 do
            local p = prop:GetBonePosition(i)
            if p then
                if not bmin then
                    bmin = Vector(p.x, p.y, p.z)
                    bmax = Vector(p.x, p.y, p.z)
                else
                    bmin = Vector(math.min(bmin.x, p.x), math.min(bmin.y, p.y), math.min(bmin.z, p.z))
                    bmax = Vector(math.max(bmax.x, p.x), math.max(bmax.y, p.y), math.max(bmax.z, p.z))
                end
            end
        end

        prop:SetPos(savedPos)
        prop:SetAngles(savedAng)
        prop:SetupBones()

        if bmin and bmax then
            mins, maxs = bmin, bmax -- кости уже с учётом масштаба
        end
    end

    if not mins or not maxs then
        local ok, a, b = pcall(prop.GetModelRenderBounds, prop)
        if ok and a and b then
            mins, maxs = a * scale, b * scale
        end
    end

    if not mins or not maxs then return Vector(0, 0, 0) end
    return (mins + maxs) * 0.5
end

-- Прекеш моделей всех оружий на клиенте: у паков модели рисуются через
-- ClientsideModel, и движок иначе может их не знать («моделька не рисуется»).
timer.Simple(2, function()
    pcall(function()
        local seen, out = {}, {}
        local function collect(tbl, depth)
            if type(tbl) ~= "table" or seen[tbl] or (depth or 0) > 6 then return end
            seen[tbl] = true
            for _, v in pairs(tbl) do
                if type(v) == "string" and string.sub(v, -4) == ".mdl" then
                    out[v] = true
                elseif type(v) == "table" then
                    collect(v, (depth or 0) + 1)
                end
            end
        end
        for _, wepTbl in pairs(weapons.GetList()) do collect(wepTbl, 0) end
        for mdl in pairs(out) do pcall(util.PrecacheModel, mdl) end
    end)
end)

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

local RemHolsterAnnounced = {}
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

            if config and isstring(model) and model ~= "" then
                -- Модели паков (например models/weapons/tfa_nmrih/v_me_bat_metal.mdl)
                -- движок не знает, пока их не прекешируешь: util.IsValidModel для
                -- них возвращает false, поэтому не отбрасываем модель по этой
                -- проверке, а прекешируем сами.
                pcall(util.PrecacheModel, model)

                local prop = ClientsideModel(model, RENDERGROUP_OPAQUE)
                if IsValid(prop) then
                    if prop:GetModel() == "models/error.mdl" then
                        print("[Holster] Модель не найдена, на спине не будет: " .. tostring(model))
                        prop:Remove()
                    else
                        prop:SetNoDraw(true)
                        -- Масштаб как в игре (modelscale2 — им пак рисует модель в руках).
                        local scale = tonumber(weaponData.scale) or 1
                        prop:SetModelScale(scale)

                        local center = MeasureModelCenter(prop, scale)
                        if not RemHolsterAnnounced[weaponData.class] then
                            RemHolsterAnnounced[weaponData.class] = true
                            print("[Holster] На спине: " .. tostring(weaponData.class) .. " -> " .. tostring(model))
                        end

                        ply.HolsterModels[1] = {
                            ent = prop,
                            bone = config.bone,
                            pos = config.pos,
                            ang = config.ang,
                            center = center
                        }
                        break
                    end
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

                    -- Ставим в спину ЦЕНТР оружия, а не его origin.
                    local c = modelData.center
                    if c then
                        worldPos = worldPos
                            - worldAng:Forward() * c.x
                            - worldAng:Right() * c.y
                            - worldAng:Up() * c.z
                    end

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
