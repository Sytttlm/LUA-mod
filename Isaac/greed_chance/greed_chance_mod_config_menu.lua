local mod = GreedChanceModForConfigMenu
local MCM = ModConfigMenu;
local ModName = mod.Name;  --获取mod名
local Version = mod.VersionString  --获取mod版本号，在main.lua中写定
local json = require("json")


local MCMFunction = {}  --用于存储mod配置菜单中的函数
local mcm = mod.storage

function MCMFunction:save()
    local jsonString = json.encode(mcm)
    mod:SaveData(jsonString)
end

function MCMFunction:load()
    if not mod:HasData() then
        return
    end
    local jsonString = mod:LoadData()
    mcm = json.decode(jsonString)
end

if (MCM) then
    MCM.AddText(ModName, "Info", ModName) --显示mod名称
    MCM.AddSpace(ModName, "Info") --空一行
    MCM.AddText(ModName, "Info", function() return "Version " .. Version end) --显示版本号
    MCM.AddSpace(ModName, "Info") --空一行
    MCM.AddText(ModName, "Info", "By Willow(Programming) and Lonely night(Art)") --显示作者

    MCM.AddSetting(
    "greed_chance", -- This should be unique for your mod
    "Normal Settings", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
            return mod.storage.MCMCurrentChance
        end,
        Display = function()
            return "current greed chance: " .. (mod.storage.MCMCurrentChance and "on" or "off")
        end,
        OnChange = function(b)
            mod.storage.MCMCurrentChance = b
            MCMFunction:save()
        end,
        Info = { -- This can also be a function instead of a table
            "Display the current floor's Greed chance",
            "No clock on the bottom-left of the icon",
            }
    }
    )
    MCM.AddSetting(
    "greed_chance", -- This should be unique for your mod
    "Normal Settings", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
            return mod.storage.MCMNextChance
        end,
        Display = function()
            return "next greed chance: " .. (mod.storage.MCMNextChance and "on" or "off")
        end,
        OnChange = function(b)
            mod.storage.MCMNextChance = b
            MCMFunction:save()
        end,
        Info = { -- This can also be a function instead of a table
            "Display the next floor's Greed chance",
            "There's a clock on the bottom-left of the icon",
            }
    }
    )
    MCM.AddSetting(
    "greed_chance", -- This should be unique for your mod
    "Normal Settings", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
            return mod.storage.MCMLocationDown
        end,
        Display = function()
            return "move down one line: " .. (mod.storage.MCMLocationDown and "on" or "off")
        end,
        OnChange = function(b)
            mod.storage.MCMLocationDown = b
            MCMFunction:save()
        end,
        Info = { -- This can also be a function instead of a table
            "Move down one line",
            }
    }
    )
    MCM.AddSetting(
    "greed_chance", -- This should be unique for your mod
    "For Testing", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
            return mod.storage.MCMShowNumber
        end,
        Display = function()
            return "show greed number: " .. (mod.storage.MCMShowNumber and "on" or "off")
        end,
        OnChange = function(b)
            mod.storage.MCMShowNumber = b
            MCMFunction:save()
        end,
        Info = { -- This can also be a function instead of a table
            "Shop above, secret room below",
            "For testing. Not recommended to enable",
            }
    }
    )
    MCM.AddSetting(
    "greed_chance", -- This should be unique for your mod
    "For Testing", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
            return mod.storage.MCMRainbowGlasses
        end,
        Display = function()
            return "rainbow glasses: " .. (mod.storage.MCMRainbowGlasses and "on" or "off")
        end,
        OnChange = function(b)
            mod.storage.MCMRainbowGlasses = b
            MCMFunction:save()
        end,
        Info = { -- This can also be a function instead of a table
            "Put on rainbow glasses",
            "For testing. Not recommended to enable",
            }
    }
    )
    MCM.AddSetting(
    "greed_chance", -- This should be unique for your mod
    "For Testing", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
            return mod.storage.MCMColor
        end,
        Display = function()
            return "complementary color: " .. (mod.storage.MCMColor and "on" or "off")
        end,
        OnChange = function(b)
            mod.storage.MCMColor = b
            MCMFunction:save()
        end,
        Info = { -- This can also be a function instead of a table
            "Correct the color difference in the text",
            "For testing. Not recommended to enable",
            }
    }
    )

    --中文翻译
    if MCM.i18n == "Chinese" then
        -- 1. 翻译菜单和子菜单名称（根据你的实际结构）
        MCM.SetCategoryNameTranslate("greed_chance", "贪婪概率")
        MCM.SetSubcategoryNameTranslate("greed_chance", "Normal Settings", "常规设置")
        MCM.SetSubcategoryNameTranslate("greed_chance", "For Testing", "用于测试")
        MCM.SetSubcategoryNameTranslate(ModName, "Info", "信息")

        -- 2. 翻译Display内容（函数类型，使用模式匹配）
        MCM.TranslateOptionsDisplayWithTable("greed_chance", "Normal Settings", {
            {"current greed chance: on", "当前层贪婪概率: 是"},
            {"current greed chance: off", "当前层贪婪概率: 否"},
            {"next greed chance: on", "下一层贪婪概率: 是"},
            {"next greed chance: off", "下一层贪婪概率: 否"},
            {"move down one line: on", "向下挪一行: 是"},
            {"move down one line: off", "向下挪一行: 否"},
        })
        MCM.TranslateOptionsDisplayWithTable("greed_chance", "For Testing", {
            {"show greed number: on", "显示当前层贪婪数量: 是"},
            {"show greed number: off", "显示当前层贪婪数量: 否"},
            {"rainbow glasses: on", "彩虹眼镜: 开"},
            {"rainbow glasses: off", "彩虹眼镜: 关"},
            {"complementary color: on", "文字补色: 开"},
            {"complementary color: off", "文字补色: 关"},
        })

        MCM.TranslateOptionsDisplayWithTable(ModName, "Info", {
            {"Version", "版本"}
        })

        -- 3. 翻译Info内容（表格类型，使用严格匹配）
        MCM.TranslateOptionsInfoTextWithTable("greed_chance", "Normal Settings", {
            ["Display the current floor's Greed chance"] = "显示当前层贪婪概率" ,
            ["No clock on the bottom-left of the icon"] = "图标左下角没有时钟",
            ["Display the next floor's Greed chance"] = "显示下一层贪婪概率" ,
            ["There's a clock on the bottom-left of the icon"] = "图标左下角有时钟",
            ["Move down one line"] = "向下挪一行",
        })
        MCM.TranslateOptionsInfoTextWithTable("greed_chance", "For Testing", {
            ["Shop above, secret room below"] = "上面是商店，下面是隐藏" ,
            ["For testing. Not recommended to enable"] = "用于测试，不推荐开启",
            ["Put on rainbow glasses"] = "戴上彩虹眼镜" ,
            ["Correct the color difference in the text"] = "补上文字色差" ,
        })

        -- 信息页面文本翻译（固定字符串）
        MCM.TranslateOptionsDisplayTextWithTable(ModName, "Info", {
            [ModName] = "贪婪概率",
            ["By Willow(Programming) and Lonely night(Art)"] = "作者: 武珞(代码) 和 Lonely night(绘画)"
        })
    end

end

return MCMFunction