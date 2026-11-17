-- ============================================================
--  Z-City + Remorseim Back Holster — список back-оружия и позиции
-- ============================================================
-- Это ГЛАВНЫЙ файл настроек. Редактируйте его, код трогать не нужно.
-- Один и тот же файл работает и для милишек Z-City, и для милишек
-- Remorseim Gun Pack — просто дописывайте/убирайте строки в секции weapons.
--
-- Оружия из секции weapons — это полный белый список back-оружия: любое
-- оружие, которого здесь нет (бутылка, огнетушитель, обрезки, нож-на-палке
-- и т.п.), за спину НЕ попадает вообще: оно не защищено от выброса и не
-- показывается на спине.
--
-- Структура записи:
--   bone — кость игрока, к которой крепится модель
--          (ValveBiped.Bip01_Spine2 — позвоночник, т.е. спина);
--   pos  — смещение относительно кости, Vector(вперёд/назад, влево/вправо, вверх/низ);
--   ang  — поворот модели, Angle(pitch, yaw, roll) в градусах.
--
-- Модель на спине — ровно та, что оружие показывает в руках и на земле при
-- выбрасывании: WorldModelExchange, иначе WorldModelReal, иначе WorldModel
-- (именно так это делает и Z-City, и Remorseim Gun Pack). Ставится она своим
-- ЦЕНТРОМ, поэтому pos/ang означают одно и то же для любого оружия.
--
-- Чтобы добавить оружие за спину, допишите строку вида:
--     weapon_class = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 5, 0), ang = Angle(0, 90, 170) },
-- После перезапуска сервера / смены карты оно станет back-оружием с этой позицией.
--
--   weapons — оружия, которым можно быть за спиной, и их отображение;
--   default — запасная позиция (на случай ошибки загрузки файла).
-- ============================================================

local positions = {
    weapons = {
        -- ============ Милишки Z-City ============
        weapon_hg_axe          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(90, 120, -5) },
        weapon_hg_sledgehammer = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),   ang = Angle(0, -90, -2.5) },
        weapon_hg_shovel       = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 2.5, 0),  ang = Angle(65, 0, 265) },
        weapon_hg_spear_pro    = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),    ang = Angle(90, -15, -2.5) },
        weapon_hg_spear        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),    ang = Angle(0, -20, -2.5) },
        weapon_tomahawk        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0),    ang = Angle(90, 120, -5) },
        weapon_hatchet         = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0),    ang = Angle(0, 120, -5) },
        weapon_hg_crowbar      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, -60, 0) },
        weapon_bat             = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),   ang = Angle(0, -115, -5) },
        weapon_hg_machete      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, 60, -5) },

        -- ============ Милишки Remorseim Gun Pack ============
        weapon_rem_melee_hg_spear        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),   ang = Angle(0, -20, -2.5) },
        weapon_rem_melee_hg_spear_pro    = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),   ang = Angle(90, -15, -2.5) },
        weapon_rem_melee_hg_sledgehammer = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        weapon_rem_melee_hg_shovel       = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 2.5, 0), ang = Angle(65, 0, 265) },
        weapon_rem_melee_chainsaw        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        weapon_rem_melee_hg_axe          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(90, 120, -5) },
        weapon_rem_melee_bat             = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),  ang = Angle(0, -115, -5) },
        weapon_rem_melee_metalbat        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),  ang = Angle(0, -115, -5) },
        weapon_rem_melee_hg_machete      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(0, 60, -5) },
        weapon_rem_melee_hatchet         = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0),   ang = Angle(0, 120, -5) },
        weapon_rem_melee_hg_crowbar      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0), ang = Angle(0, -60, 0) },
    },

    -- Позиция по умолчанию (используется только при битом файле/запасе).
    default = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0), ang = Angle(0, 90, 170) },
}

-- Дублируем в глобал: если include() не пробросит возвращаемое значение,
-- код и сервера, и клиента найдёт таблицу здесь.
ZCityHolsterPositions = positions

return positions
