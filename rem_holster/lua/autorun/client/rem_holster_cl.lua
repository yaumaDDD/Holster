-- Remorseim Back Holster (client).
-- Временная установка: файлы кидаются в папки Гмода —
-- lua/autorun/server (rem_holster_sv.lua + rem_holster_positions.lua) и
-- lua/autorun/client (этот файл). Пока не собраны в отдельный аддон.
--
-- Позиции настраиваются в lua/autorun/server/rem_holster_positions.lua —
-- сервер читает их сам и присылает клиентам; на клиенте файл не нужен.
-- Модели берутся из самих оружий Remorseim по их путям (сервер присылает путь).

-- Встроенный запасной вариант (зеркало конфига позиций с сервера).
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

-- Позиции приходят с сервера (Rem_Holster_Config); до первого сообщения
-- работают встроенные значения. Файл конфига на клиенте НЕ нужен и никак
-- не запрашивается.
local HolsterConfig, DefaultHolsterConfig = BuiltinPositions.weapons, BuiltinPositions.default

net.Receive("Rem_Holster_Config", function()
    local cfg = net.ReadTable()
    if istable(cfg) and istable(cfg.weapons) then
        HolsterConfig = cfg.weapons
        DefaultHolsterConfig = istable(cfg.default) and cfg.default or BuiltinPositions.default
    end
end)

-- ================= Построение моделей ВСЕХ оружий =================
-- Профилактика бага «моделька не рисуется»: модели паков (Remorseim и не
-- только) используются через ClientsideModel/пропы, а не через регистрацию
-- SWEP, поэтому движок может их не знать. При старте собираем ВСЕ .mdl-пути
-- из ВСЕХ зарегистрированных оружий (включая будущие) и прекешируем их —
-- построение моделей одинаково для всех, чтобы багов не было потом.
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
-- Initialize/InitPostEntity: в GMod ошибка одного обработчика обрывает
-- остальные хуки того же события (так из-за нас мог не создаться чат zchat:
-- его CreateChat висит на InitPostEntity, hg.chat оставался nil и при ESC
-- вылетала ошибка sh_chat.lua:45). Теперь наша ошибка не может никому мешать.
timer.Simple(2, function()
    pcall(RemHolsterPrecacheAllModels)
end)

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

-- Центр геометрии модели в её локальных координатах.
-- Зачем: у моделей пака origin стоит НЕ в середине оружия (у биты — на
-- ручке), поэтому если поставить в спину сам origin, оружие уходит вперёд
-- на пол-длины. У «деревянной» (мировые модели w_*) origin как раз в центре,
-- и она встаёт правильно — значит меряем центр и ставим его.
--
-- МЕРИМ ПО КОСТЯМ, а не по границам модели: у вьюмоделей bbox раздут
-- анимациями (в разы), и сдвиг по нему уводит оружие с тела. Кости лежат
-- вдоль самого оружия и дают его настоящую длину.
local function MeasureModelCenter(prop, fallbackScale)
    local scale = tonumber(fallbackScale) or 1

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

local RemHolsterAnnounced = {}
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

            if config and isstring(model) and model ~= "" then
                -- ВАЖНО: модельки реморсеима (WorldModelExchange — например
                -- models/tfa_nmrih/w_bat.mdl) пак рисует только через
                -- ClientsideModel и движок их не прекеширует, поэтому
                -- util.IsValidModel для них возвращает false — раньше здесь
                -- была тихая просадка («моделька не рисуется»). Прекешируем
                -- сами и не отбрасываем модель из-за этой проверки.
                pcall(util.PrecacheModel, model)

                local prop = ClientsideModel(model, RENDERGROUP_OPAQUE)
                if IsValid(prop) then
                    if prop:GetModel() == "models/error.mdl" then
                        print("[Rem Holster] Модель не найдена, на спине не будет: " .. tostring(model))
                        prop:Remove()
                    else
                        prop:SetNoDraw(true)
                        -- Масштаб как в игре (modelscale у пака).
                        local scale = tonumber(weaponData.scale) or 1
                        prop:SetModelScale(scale)

                        -- pos/ang размечены под МИРОВЫЕ модели (у них origin в
                        -- центре оружия). Модель из рук может иметь origin на
                        -- ручке — тогда ставим в спину её центр, и оружие сидит
                        -- ровно там же, где сидела бы мировая модель.
                        local center = MeasureModelCenter(prop, scale)
                        if not RemHolsterAnnounced[weaponData.class] then
                            RemHolsterAnnounced[weaponData.class] = true
                            print("[Rem Holster] На спине: " .. tostring(weaponData.class) .. " -> " .. tostring(model))
                        end
                        ply.RemHolsterModels[1] = {
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
