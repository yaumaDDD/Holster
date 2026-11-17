-- ============================================================
--  Remorseim Back Holster — позиции отображения за спиной
-- ============================================================
-- Этот файл лежит в ПАПКЕ lua/autorun/server РЯДОМ с rem_holster_sv.lua.
-- Сервер читает его при старте и сам присылает позиции всем клиентам —
-- настраивать нужно только на сервере, клиентам ничего не надо.
--
-- Здесь ВСЁ ближнее оружие Remorseim Gun Pack, которое носится за спиной.
-- Оружия из секции weapons — это полный белый список: оружия, которого в
-- списке нет, за спину НЕ попадает (и выбрасывается как обычное). Чтобы
-- убрать оружие со спины — удалите его строку; чтобы добавить — допишите.
--
-- Структура записи:
--   bone — кость игрока, к которой крепится модель
--          (ValveBiped.Bip01_Spine2 — позвоночник, т.е. спина);
--   pos  — смещение относительно кости, Vector(вперёд/назад, влево/вправо, вверх/низ);
--          сюда встаёт ЦЕНТР модели (точка привязки у ручки, как у
--          алюминиевой биты, компенсируется автоматически);
--   ang  — поворот модели, Angle(pitch, yaw, roll) в градусах.
--
-- ВАЖНО про модель биты: на спине стоит та же модель, что в руках
-- (у алюминиевой биты — v_me_bat_metal). У неё точка привязки на РУЧКЕ,
-- но центр модели аддон считает сам — pos/ang работают как обычно.
--
-- Правки применяются после перезапуска сервера / смены карты.
-- ============================================================

local positions = {
    weapons = {
        -- ================= Крупное =================
        -- Копьё (Rem) — как weapon_hg_spear
        weapon_rem_melee_hg_spear          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),    ang = Angle(0, -20, -2.5) },
        -- Про-копьё (Rem) — как weapon_hg_spear_pro
        weapon_rem_melee_hg_spear_pro      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),    ang = Angle(90, -15, -2.5) },
        -- Кувалда (Rem) — как weapon_hg_sledgehammer
        weapon_rem_melee_hg_sledgehammer   = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        -- Лопата (Rem) — как weapon_hg_shovel
        weapon_rem_melee_hg_shovel         = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 2.5, 0),  ang = Angle(65, 0, 265) },
        -- Бензопила (Rem) — как кувалда (большой предмет, подкрутите под себя)
        weapon_rem_melee_chainsaw          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        -- Пожарный топор (Rem) — как weapon_hg_axe
        weapon_rem_melee_hg_axe            = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(90, 120, -5) },
        -- Бита (Rem) — как weapon_bat
        weapon_rem_melee_bat               = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),   ang = Angle(0, -115, -5) },
        -- Алюминиевая бита (Rem) — как weapon_bat; модель с точкой на ручке,
        -- центр компенсируется автоматически
        weapon_rem_melee_metalbat          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),   ang = Angle(0, -115, -5) },

        -- ================= Среднее =================
        -- Мачете (Rem) — как weapon_hg_machete
        weapon_rem_melee_hg_machete        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, 60, -5) },
        -- Топорик (Rem) — как weapon_hatchet
        weapon_rem_melee_hatchet           = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0),    ang = Angle(0, 120, -5) },
        -- Лом (Rem) — как weapon_hg_crowbar
        weapon_rem_melee_hg_crowbar        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, -60, 0) },
    },

    -- Позиция по умолчанию (используется только при битом файле/запасе).
    default = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0), ang = Angle(0, 90, 170) },
}

-- Дублируем в глобал: если include() не пробросит возвращаемое значение,
-- код сервера найдёт таблицу здесь.
RemHolsterPositions = positions

return positions
