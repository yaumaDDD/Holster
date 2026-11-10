-- ============================================================
--  Z-City Back Holster — позиции отображения оружия за спиной
-- ============================================================
-- Это файл настроек. Редактируйте его под себя, код трогать не нужно.
--
-- Каждая запись описывает, как рисуется оружие на спине игрока:
--   bone — кость игрока, к которой крепится модель
--          (ValveBiped.Bip01_Spine2 — позвоночник, т.е. спина);
--   pos  — смещение относительно кости, Vector(вперёд/назад, влево/вправо, вверх/вниз);
--   ang  — поворот модели, Angle(pitch, yaw, roll) в градусах.
--
-- Сюда можно добавить ЛЮБОЕ оружие, которому можно находиться за спиной
-- (то, что сервер считает back-melee: NoHolster-оружие или оружие из списка
-- ExtraBackMelee в lua/autorun/server/zcity_holster_sv.lua). Просто допишите
-- строку вида:
--     weapon_class = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 5, 0), ang = Angle(0, 90, 170) },
--
--   weapons — позиции для конкретных классов оружия;
--   default — используется для любого оружия, которого нет в списке weapons.
-- ============================================================

local positions = {
    weapons = {
        weapon_hg_axe         = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 5, 4),   ang = Angle(0, 90, 160) },
        weapon_hg_sledgehammer = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 6, 2),  ang = Angle(0, 90, 160) },
        weapon_hg_shovel      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 5, 0),   ang = Angle(0, 90, 160) },
        weapon_hg_spear_pro   = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 5, -2),  ang = Angle(0, 100, 150) },
        weapon_hg_spear       = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 5, -2),  ang = Angle(0, 100, 150) },
        weapon_tomahawk       = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 6),   ang = Angle(0, 90, 180) },
        weapon_hatchet        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 6),   ang = Angle(0, 90, 180) },
        weapon_hg_extinguisher = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-4, 7, 0),  ang = Angle(0, 90, 0) },
        weapon_hg_crowbar     = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, -4),  ang = Angle(0, 85, 170) },
        weapon_bat            = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 0, -2),  ang = Angle(0, 90, 170) },
        weapon_hg_machete     = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, -4),  ang = Angle(0, 90, 190) },
    },

    -- Позиция для любого back-оружия, которого нет в списке выше.
    default = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0), ang = Angle(0, 90, 170) },
}

-- Дублируем в глобал: если include() не пробросит возвращаемое значение,
-- клиентский код найдёт таблицу здесь.
ZCityHolsterPositions = positions

return positions
