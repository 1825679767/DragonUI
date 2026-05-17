-- ============================================================================
-- DragonUI - Imported User Default Overrides
-- Imported from client SavedVariables profile:
--   小丑猎 - 瓦兰奈尔
-- Source file used:
--   E:\World of Warcraft\WTF\Account\1825679767\SavedVariables\DragonUI.lua
-- ============================================================================

local addon = select(2, ...);

local profileOverrides = {
    xprepbar = {
        always_show_text = true,
        show_xp_percent = true,
    },
    additional = {
        totem = {
            posY = 0,
            posX = 0,
            anchor = "CENTER",
        },
        stance = {
            posY = 0,
            posX = 0,
            anchor = "CENTER",
        },
    },
    minimap = {
        indoorRotatePreference = "0",
        settings_button_angle = 202.8865669842404,
    },
    modules = {
        unitframe_layers = {
            enabled = true,
            missing_health = true,
        },
        chatmods = {
            editboxStyle = "dragon",
            chatStyle = "dragon",
            tabIdleAlpha = 1,
        },
        combuctor = {
            enabled = true,
            db = {
                inventory = {
                    h = 564.0000024619407,
                    exclude = {},
                    position = {
                        "RIGHT",
                        nil,
                        "RIGHT",
                        -174.8313452364971,
                        65.45238740194894,
                    },
                    sets = {
                        "全部",
                        "Equipment",
                        "Usable",
                        "任务",
                        "商品",
                        "其它",
                    },
                    bags = {
                        0,
                        1,
                        2,
                        3,
                        4,
                    },
                    w = 664.0000475975187,
                    showBags = true,
                },
                bank = {
                    h = 512,
                    exclude = {},
                    position = {
                        "LEFT",
                        nil,
                        "LEFT",
                        24,
                        0,
                    },
                    sets = {
                        "全部",
                        "Equipment",
                        "Usable",
                        "任务",
                        "商品",
                        "其它",
                    },
                    bags = {
                        -1,
                        5,
                        6,
                        7,
                        8,
                        9,
                        10,
                        11,
                    },
                    w = 512,
                    showBags = true,
                },
            },
        },
    },
    actionbars = {
        right_enabled = false,
        left_enabled = false,
    },
    unitframe = {
        player = {
            classcolor = true,
            dragon_decoration = "elite",
            classPortrait = true,
            alternativeClassIcons = true,
            showHealthTextAlways = true,
        },
    },
    micromenu = {
        bags_collapsed = true,
    },
    widgets = {
        lfgframe = {
            posY = 20.00000027354896,
            posX = -270.0000343303942,
        },
        mainbar = {
            posY = 22.00000205161718,
        },
        bottombarright = {
            posY = 105.0000036245237,
            posX = -10.00000013677448,
        },
        boss = {
            anchor = "TOPRIGHT",
            posY = -350.0000179174567,
            posX = -85.00000335097474,
        },
        party = {
            posY = -200.0000027354896,
            posX = 10.00000013677448,
        },
        target = {
            posY = -9.000000341936197,
            posX = 230.000016276163,
        },
        focus = {
            posY = -170.0000067019495,
            posX = 250.0000077961453,
        },
        bottombarleft = {
            posX = -10.00000013677448,
        },
        xpbar = {
            posY = 6.999999658063802,
        },
        repbar = {
            posY = 6.999999658063802,
        },
        vehicleExit = {
            posY = 144.999995418055,
            posX = -251.0000152503544,
        },
        tooltip = {
            posY = 100.0000013677448,
            posX = -90.00000560775364,
        },
        pet = {
            posY = -80.00000109419584,
            posX = 63.00000567614087,
        },
        buffs = {
            posY = -15.00000020516172,
            posX = -270.0000168232609,
        },
        rightbar = {
            posY = -70.00000533420467,
            posX = -5.00000006838724,
        },
        leftbar = {
            posY = -70.00000533420467,
            posX = -45.00000280387682,
        },
        player = {
            posY = -9.000000341936197,
            posX = 10.00000013677448,
        },
        playerCastbar = {
            anchor = "CENTER",
            posY = -215.296702893895,
            posX = 7.901178797685311,
        },
        micromenu = {
            posY = 2.999999931612761,
            posX = -2.999999931612761,
        },
        petbar = {
            anchor = "BOTTOMLEFT",
            posY = 6.285871654521891,
            posX = 222.9661403151599,
        },
        bagsbar = {
            posY = 45.00000280387682,
            posX = -2.999999931612761,
        },
        fot = {
            posY = 0,
        },
    },
};

local function deepMerge(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {};
            end
            deepMerge(value, target[key]);
        else
            target[key] = value;
        end
    end
end

if addon.defaults and addon.defaults.profile then
    deepMerge(profileOverrides, addon.defaults.profile);
end

if addon.db and addon.db.profile then
    deepMerge(profileOverrides, addon.db.profile);
end
