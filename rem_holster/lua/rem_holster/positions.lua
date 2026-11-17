-- ============================================================
--  Remorseim Back Holster — список back-оружия и позиции его отображения
-- ============================================================
-- Это ГЛАВНЫЙ файл настроек. Редактируйте его, код трогать не нужно.
--
-- Сюда перенесено ВСЁ, что можно носить за спиной из Remorseim Gun Pack:
-- оружия из секции weapons — это полный белый список. Любое оружие,
-- которого в списке нет, за спину НЕ попадает вообще: оно не защищено
-- от выброса и не показывается на спине.
--
-- Структура записи:
--   bone — кость игрока, к которой крепится модель
--          (ValveBiped.Bip01_Spine2 — позвоночник, т.е. спина);
--   pos  — смещение относительно кости, Vector(вперёд/назад, влево/вправо, вверх/вниз);
--   ang  — поворот модели, Angle(pitch, yaw, roll) в градусах.
--
-- Чтобы добавить другое оружие за спину, допишите строку вида:
--     weapon_class = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 5, 0), ang = Angle(0, 90, 170) },
-- После перезапуска сервера / смены карты оно станет back-оружием с этой позицией.
--
--   weapons — оружия, которым можно быть за спиной, и их отображение;
--   default — запасная позиция (на случай ошибки загрузки файла).
--
-- Позиции ниже проставлены по аналогии со стандартными Z-City аналогами
-- (см. lua/holster/positions.lua в zcity_holster). Модели берутся из самих
-- оружий Remorseim по их путям (WorldModelExchange / WorldModel), поэтому
-- на спине будут именно ремовские модели, а не стандартные Z-City.
-- ============================================================

local positions = {
    weapons = {
        -- Копьё (Rem) — как weapon_hg_spear
        weapon_rem_melee_hg_spear          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),    ang = Angle(0, -20, -2.5) },
        -- Кувалда (Rem) — как weapon_hg_sledgehammer
        weapon_rem_melee_hg_sledgehammer   = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        -- Лопата (Rem) — как weapon_hg_shovel
        weapon_rem_melee_hg_shovel         = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 2.5, 0),  ang = Angle(65, 0, 265) },
        -- Про-копьё (Rem) — как weapon_hg_spear_pro
        weapon_rem_melee_hg_spear_pro      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),    ang = Angle(90, -15, -2.5) },
        -- Мачете (Rem) — как weapon_hg_machete
        weapon_rem_melee_hg_machete        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, 60, -5) },
        -- Топорик (Rem) — как weapon_hatchet
        weapon_rem_melee_hatchet           = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0),    ang = Angle(0, 120, -5) },
        -- Пожарный топор (Rem) — как weapon_hg_axe
        weapon_rem_melee_hg_axe            = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(90, 120, -5) },
        -- Лом (Rem) — как weapon_hg_crowbar
        weapon_rem_melee_hg_crowbar        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, -60, 0) },
        -- Бензопила (Rem) — как кувалда (большой предмет, подкрутите под себя)
        weapon_rem_melee_chainsaw          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        -- Бита (Rem) — как weapon_bat
        weapon_rem_melee_bat               = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),   ang = Angle(0, -115, -5) },
        -- Алюминиевая бита (Rem) — как weapon_bat
        weapon_rem_melee_metalbat          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),   ang = Angle(0, -115, -5) },
    },

    -- Позиция по умолчанию (используется только при битом файле/запасе).
    default = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0), ang = Angle(0, 90, 170) },
}

-- Дублируем в глобал: если include() не пробросит возвращаемое значение,
-- код и сервера, и клиента найдёт таблицу здесь.
RemHolsterPositions = positions

return positions
