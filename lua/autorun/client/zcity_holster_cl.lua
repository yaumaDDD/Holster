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

-- Точка привязки модели — КОСТЬ ХВАТА, ровно как это делает сам пак.
--
-- Z-City и Remorseim Gun Pack ставят модель относительно кости хвата
-- (weapon_rem_melee_base:DrawWorldModel2 -> GetBoneMatrix(self.basebone or 1),
-- у биты basebone = 94). Модели паков сделаны так, что в руках оружие
-- красиво висит именно от этой точки, а НЕ от origin и НЕ от центра.
--
-- Поэтому и на спине мы цепляем это же место: тогда оружие на спине стоит
-- так же, как стояло бы в руке, и pos/ang означают «куда на спине приходит
-- точка хвата». Никаких измерений bbox (он раздут анимациями вьюмодели) и
-- никаких «центров» — только кость, которую использует сам пак.
--
-- ВАЖНО (проверено логом holster_diag на реальных моделях):
--   * Z-City-оружие (WorldModel, w_*.mdl) — у моделей всего 1-4 кости, и
--     никакой кости хвата там нет. Сервер для них bone_index НЕ передаёт, и
--     привязка должна оставаться по origin (нулевое смещение) — именно так
--     эти модели и размечены в positions.lua.
--   * Remorseim-оружие с моделью из рук (v_*.mdl) — 95+ костей, и кость
--     хвата (basebone, обычно 94) реально есть.
-- Поэтому: якорь применяем ТОЛЬКО когда сервер передал bone_index и такая
-- кость в модели существует. Никакого поиска «похожих» костей по имени:
-- в мировых моделях попадаются кости вида ValveBiped.Bip01_L_Hand, и
-- цепляние за них уводило оружие с тела (мачете, лом, топорик).
local function GetModelAnchor(prop, headBone)
    if not IsValid(prop) then return Vector(0, 0, 0) end

    local bone = tonumber(headBone)
    if not bone then return Vector(0, 0, 0) end

    local okBones, count = pcall(prop.GetBoneCount, prop)
    count = okBones and tonumber(count) or 0
    if count <= 0 or bone < 0 or bone >= count then
        return Vector(0, 0, 0)
    end

    -- Меряем смещение кости в локальных координатах модели: временно ставим
    -- модель в ноль, чтобы кость отдала локальную позицию.
    local savedPos, savedAng = prop:GetPos(), prop:GetAngles()
    prop:SetPos(vector_origin)
    prop:SetAngles(angle_zero)
    prop:SetupBones()

    local ok, p = pcall(prop.GetBonePosition, prop, bone)
    local anchor = (ok and p) and Vector(p.x, p.y, p.z) or Vector(0, 0, 0)

    prop:SetPos(savedPos)
    prop:SetAngles(savedAng)
    prop:SetupBones()

    return anchor
end

-- ============================================================
--  ДИАГНОСТИКА (для отладки моделей на спине)
-- ============================================================
-- Пишет в консоль и в файл garrysmod/data/holster_diag.txt полный отчёт:
-- какая модель у каждого оружия из списка, сколько у неё костей, есть ли
-- кость хвата (basebone / *_R_Hand), какой получен якорь и куда в итоге
-- встала бы модель. Если что-то встаёт криво — по этому логу видно, на
-- каком шаге и почему.
local DIAG_FILE = "holster_diag.txt"
local DiagLines = {}

local function Diag(line)
    DiagLines[#DiagLines + 1] = line
    MsgC(Color(120, 200, 255), "[Holster] ", Color(255, 255, 255), line .. "\n")
end

local function DiagFlush()
    local body = table.concat(DiagLines, "\n")
    file.Write(DIAG_FILE, body .. "\n")
    Diag("Отчёт записан: garrysmod/data/" .. DIAG_FILE)
end

local function DiagModel(prop, cls, model, scale, basebone)
    local okCount, count = pcall(prop.GetBoneCount, prop)
    count = okCount and tonumber(count) or 0

    local handIdx, handName = -1, "нет"
    for _, name in ipairs({ "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_R_Forearm" }) do
        local ok, idx = pcall(prop.LookupBone, prop, name)
        if ok and tonumber(idx) and tonumber(idx) > 0 then
            handIdx, handName = tonumber(idx), name
            break
        end
    end

    local bb = tonumber(basebone)
    local bbValid = bb and bb >= 0 and bb < count

    Diag(string.format("  %s", cls))
    Diag(string.format("    модель : %s", tostring(model)))
    Diag(string.format("    масштаб: %s", tostring(scale)))
    Diag(string.format("    костей : %d", count))
    Diag(string.format("    basebone: %s (%s)", tostring(basebone), bbValid and "есть" or "НЕТ такой кости"))
    Diag(string.format("    кость руки: %s (%s)", tostring(handIdx), handName))

    if bbValid then
        Diag("    -> привязка по basebone (как в руках у пака)")
    else
        Diag("    -> привязка по origin модели (норма для мировых моделей Z-City)")
    end
end

local function RunDiag()
    DiagLines = {}
    Diag("=== Holster: проверка моделей на спине ===")
    Diag(string.format("оружий в списке: %d", (function()
        local n = 0
        for _ in pairs(HolsterConfig or {}) do n = n + 1 end
        return n
    end)()))

    local list = weapons.GetList and weapons.GetList() or {}
    local found = 0
    for _, wepTbl in pairs(list) do
        local cls = wepTbl.Classname or wepTbl.ClassName
        if isstring(cls) and isstring(wepTbl.WorldModel) then
            local hasEntry = HolsterConfig and HolsterConfig[cls] ~= nil
            if hasEntry or string.sub(cls, 1, 16) == "weapon_rem_melee" then
                local model, scale = wepTbl.WorldModel, 1
                if string.sub(cls, 1, 16) == "weapon_rem_melee" then
                    if isstring(wepTbl.WorldModelExchange) and wepTbl.WorldModelExchange ~= "" then
                        model, scale = wepTbl.WorldModelExchange, tonumber(wepTbl.modelscale) or 1
                    elseif isstring(wepTbl.WorldModelReal) and wepTbl.WorldModelReal ~= "" then
                        model, scale = wepTbl.WorldModelReal, tonumber(wepTbl.modelscale2) or 1
                    end
                end

                found = found + 1
                if not hasEntry then
                    Diag(string.format("  %s — НЕ в списке positions.lua (за спину не попадёт)", cls))
                else
                    pcall(util.PrecacheModel, model)
                    local prop = ClientsideModel(model, RENDERGROUP_OPAQUE)
                    if not IsValid(prop) then
                        Diag(string.format("  %s — не удалось создать модель %s", cls, tostring(model)))
                    else
                        if prop:GetModel() == "models/error.mdl" then
                            Diag(string.format("  %s — МОДЕЛЬ НЕ НАЙДЕНА: %s", cls, tostring(model)))
                        else
                            prop:SetNoDraw(true)
                            prop:SetModelScale(scale)
                            DiagModel(prop, cls, model, scale, wepTbl.basebone)
                        end
                        prop:Remove()
                    end
                end
            end
        end
    end

    Diag(string.format("проверено оружий: %d", found))
    DiagFlush()
end

concommand.Add("holster_diag", function()
    RunDiag()
end)

-- Автоматически один раз после загрузки (не мешает игре, просто пишет лог).
timer.Simple(6, function()
    pcall(RunDiag)
end)

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

                        local anchor = GetModelAnchor(prop, weaponData.bone_index)
                        if not RemHolsterAnnounced[weaponData.class] then
                            RemHolsterAnnounced[weaponData.class] = true
                            print("[Holster] На спине: " .. tostring(weaponData.class) .. " -> " .. tostring(model))
                        end

                        ply.HolsterModels[1] = {
                            ent = prop,
                            bone = config.bone,
                            pos = config.pos,
                            ang = config.ang,
                            anchor = anchor
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

                    -- Цепляем оружие за ту же точку, что и в руках (кость хвата).
                    local c = modelData.anchor
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
