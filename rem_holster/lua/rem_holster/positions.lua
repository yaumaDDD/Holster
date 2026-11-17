-- ============================================================
--  Remorseim Back Holster — список back-оружия и позиции его отображения
-- ============================================================
-- Это ГЛАВНЫЙ файл настроек. Редактируйте его, код трогать не нужно.
--
-- Здесь ВСЁ ближнее оружие Remorseim Gun Pack (33 класса). Оружия из
-- секции weapons — это полный белый список: любое оружие, которого в
-- списке нет, за спину НЕ попадает вообще (оно не защищено от выброса
-- и не показывается на спине). Чтобы убрать оружие со спины — удалите
-- его строку; чтобы добавить своё — допишите строку в том же формате.
--
-- Структура записи:
--   bone — кость игрока, к которой крепится модель
--          (ValveBiped.Bip01_Spine2 — позвоночник, т.е. спина);
--   pos  — смещение относительно кости, Vector(вперёд/назад, влево/вправо, вверх/низ);
--   ang  — поворот модели, Angle(pitch, yaw, roll) в градусах.
--
--   weapons — оружия, которым можно быть за спиной, и их отображение;
--   default — запасная позиция (на случай ошибки загрузки файла).
--
-- Позиции проставлены по аналогии со стандартными Z-City аналогами
-- (см. lua/holster/positions.lua в zcity_holster) и служат стартовыми —
-- подкручивайте под себя. Модели берутся из самих оружий Remorseim
-- (WorldModelExchange — своя модель реморсеима, та же, что в руках;
-- иначе WorldModel), поэтому на спине будут именно ремовские модели.
-- ============================================================

local positions = {
    weapons = {
        -- ================= Крупное =================
        -- Копьё (Rem) — как weapon_hg_spear
        weapon_rem_melee_hg_spear          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),    ang = Angle(0, -20, -2.5) },
        -- Копьё-нож (Rem) — как weapon_hg_spear
        weapon_rem_melee_hg_spear_knife    = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),    ang = Angle(0, -20, -2.5) },
        -- Про-копьё (Rem) — как weapon_hg_spear_pro
        weapon_rem_melee_hg_spear_pro      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 4, 0),    ang = Angle(90, -15, -2.5) },
        -- Кувалда (Rem) — как weapon_hg_sledgehammer
        weapon_rem_melee_hg_sledgehammer   = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        -- Таран (Rem) — как кувалда
        weapon_rem_melee_ram               = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        -- Лопата (Rem) — как weapon_hg_shovel
        weapon_rem_melee_hg_shovel         = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(0, 2.5, 0),  ang = Angle(65, 0, 265) },
        -- Бензопила (Rem) — как кувалда (большой предмет, подкрутите под себя)
        weapon_rem_melee_chainsaw          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        -- Пожарный топор (Rem) — как weapon_hg_axe
        weapon_rem_melee_hg_axe            = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(90, 120, -5) },
        -- Бита (Rem) — как weapon_bat
        weapon_rem_melee_bat               = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),   ang = Angle(0, -115, -5) },
        -- Алюминиевая бита (Rem) — как weapon_bat
        weapon_rem_melee_metalbat          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),   ang = Angle(0, -115, -5) },
        -- Ножка стула (Rem) — как бита
        weapon_rem_melee_chair_leg         = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),   ang = Angle(0, -115, -5) },
        -- Ножка стола (Rem) — как бита
        weapon_rem_melee_table_leg         = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 4, 3),   ang = Angle(0, -115, -5) },
        -- Огнетушитель (Rem) — крупный вертикально, как кувалда
        weapon_rem_melee_hg_extinguisher   = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        -- Баллистический щит (Rem) — как default, подкрутите под себя
        weapon_rem_melee_ballistic_shield  = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0),  ang = Angle(0, 90, 170) },

        -- ================= Среднее =================
        -- Мачете (Rem) — как weapon_hg_machete
        weapon_rem_melee_hg_machete        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, 60, -5) },
        -- Топорик (Rem) — как weapon_hatchet
        weapon_rem_melee_hatchet           = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(4, 4, 0),    ang = Angle(0, 120, -5) },
        -- Лом (Rem) — как weapon_hg_crowbar
        weapon_rem_melee_hg_crowbar        = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, -60, 0) },
        -- Лом Гордона (Rem) — как weapon_hg_crowbar
        weapon_rem_melee_hg_crowbar_gordon = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, -60, 0) },
        -- Молоток (Rem) — как кувалда
        weapon_rem_melee_hammer            = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-5, 4, 0),  ang = Angle(0, -90, -2.5) },
        -- Свинцовая труба (Rem) — как лом
        weapon_rem_melee_leadpipe          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, -60, 0) },
        -- Тонфа (Rem) — как лом
        weapon_rem_melee_hg_tonfa          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, -60, 0) },
        -- Шоковая дубинка (Rem) — как лом
        weapon_rem_melee_hg_stunstick      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, -60, 0) },

        -- ================= Ножи =================
        -- Боевой нож (Rem) — как мачете
        weapon_rem_melee_combatknife       = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, 60, -5) },
        -- Нож Buck (Rem) — как мачете
        weapon_rem_melee_buck200knife      = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, 60, -5) },
        -- Нож SOG (Rem) — как мачете
        weapon_rem_melee_sogknife          = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, 60, -5) },
        -- Карманный нож (Rem) — как мачете
        weapon_rem_melee_pocketknife       = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(2, 3.5, 0),  ang = Angle(0, 60, -5) },

        -- ================= Мелочь (по default, подкрутите или удалите) =================
        -- Кирпич (Rem)
        weapon_rem_melee_brick             = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0),  ang = Angle(0, 90, 170) },
        -- Бутылка (Rem)
        weapon_rem_melee_hg_bottle         = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0),  ang = Angle(0, 90, 170) },
        -- Разбитая бутылка (Rem)
        weapon_rem_melee_hg_bottlebroken   = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0),  ang = Angle(0, 90, 170) },
        -- Кружка (Rem)
        weapon_rem_melee_hg_mug            = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0),  ang = Angle(0, 90, 170) },
        -- Осколок стекла (Rem)
        weapon_rem_melee_hg_glassshard     = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0),  ang = Angle(0, 90, 170) },
        -- Осколок стекла с изолентой (Rem)
        weapon_rem_melee_hg_glassshard_taped = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0), ang = Angle(0, 90, 170) },
        -- Сковорода (Rem)
        weapon_rem_melee_pan               = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0),  ang = Angle(0, 90, 170) },
    },

    -- Позиция по умолчанию (используется только при битом файле/запасе).
    default = { bone = "ValveBiped.Bip01_Spine2", pos = Vector(-3, 5, 0), ang = Angle(0, 90, 170) },
}

-- Дублируем в глобал: если include() не пробросит возвращаемое значение,
-- код и сервера, и клиента найдёт таблицу здесь.
RemHolsterPositions = positions

return positions
