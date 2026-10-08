local mod = Da1
local MCM = ModConfigMenu;
local ModName = mod.Name;
local Version = mod.VersionString

local Da1Settings = {
    emptyPedestal = true,
    cycle = true,
    changeEffect = true,
    whichEffect = true,
    -- maxcharges = true, --为真就是6充能，为假就是4充能
}

local function LoadSettings()
  local str = Isaac.LoadModData(mod)
  if str == nil then
    str = "1111" -- All one by default
  end
  Da1Settings.emptyPedestal = str:sub(1, 1) == "1"
  Da1Settings.cycle = str:sub(2, 2) == "1"
  Da1Settings.changeEffect = str:sub(3, 3) == "1"
    Da1Settings.whichEffect = str:sub(4, 4) == "1"
end

local function SaveSettings()
  local str = ""
  str = str .. (Da1Settings.emptyPedestal and "1" or "0")
  str = str .. (Da1Settings.cycle and "1" or "0")
  str = str .. (Da1Settings.changeEffect and "1" or "0")
    str = str .. (Da1Settings.whichEffect and "1" or "0")
  Isaac.SaveModData(mod, str)
end

if (MCM) then -- MCM已加载
    LoadSettings()
    -- MCM.SetCategoryInfo(ModName, "Rerolls all pedestal items in a room by adding one to their internal ID number until a valid item is rolled.") --显示描述
    -- MCM.AddSpace(ModName, "Info"); --空一行
    MCM.AddText(ModName, "Info", ModName) --显示mod名称
    MCM.AddSpace(ModName, "Info") --空一行
    MCM.AddText(ModName, "Info", function() return "Version " .. Version end) --显示版本号
    MCM.AddSpace(ModName, "Info") --空一行
    MCM.AddText(ModName, "Info", "By Willow(Programming) and Lonely night(Art)") --显示作者

    MCM.AddSetting(--是否可以对空底座使用,使其变为悲伤洋葱
    "D+1", -- This should be unique for your mod
    "Normal Settings", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
        return Da1Settings.emptyPedestal
        end,
        Display = function()
        return "Empty Pedestal: " .. (Da1Settings.emptyPedestal and "on" or "off")
        end,
        OnChange = function(b)
        Da1Settings.emptyPedestal = b
        SaveSettings()
        end,
        Info = { -- This can also be a function instead of a table
        "Enable or disable rerolling empty pedestals into The Sad Onion",
        -- "More info on 2nd line",
        }
    }
    )

    MCM.AddSetting(--是否可以对id最大道具使用,使其变为id为1的悲伤洋葱
    "D+1", -- This should be unique for your mod
    "Normal Settings", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
        return Da1Settings.cycle
        end,
        Display = function()
        return "Cycle: " .. (Da1Settings.cycle and "on" or "off")
        end,
        OnChange = function(b)
        Da1Settings.cycle = b
        SaveSettings()
        end,
        Info = { -- This can also be a function instead of a table
        "Enable or disable rerolling the item with the maximum ID",
        "into The Sad Onion with ID 1",
        -- "More info on 2nd line",
        }
    }
    )

    MCM.AddSetting(--开启烟雾修改
    "D+1", -- This should be unique for your mod
    "Smoke Settings", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
        return Da1Settings.changeEffect
        end,
        Display = function()
        return "Change: " .. (Da1Settings.changeEffect and "off" or "on") --开启或关闭
        end,
        OnChange = function(b)
        Da1Settings.changeEffect = b
        SaveSettings()
        end,
        Info = { -- This can also be a function instead of a table
        "Change the smoke effect",
        -- "More info on 2nd line",
        }
    }
    )

    MCM.AddSetting(--烟雾特效 Smoke 
    "D+1", -- This should be unique for your mod
    "Smoke Settings", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
        return Da1Settings.whichEffect
        end,
        Display = function()
        return "Smoke: " .. (Da1Settings.whichEffect and "Reverse" or "Bang") --倒放  爆炸
        end,
        OnChange = function(b)
        Da1Settings.whichEffect = b
        SaveSettings()
        end,
        Info = { -- This can also be a function instead of a table
        "Reverse or Bang when rolling",
        "Bang come with sound",
        -- "More info on 2nd line",
        }
    }
    )

    -- MCM.AddSetting(--充能4或6
    -- "D+1", -- This should be unique for your mod
    -- "Settings", -- If you don't want multiple tabs, then set this to nil
    -- {
    --     Type = MCM.OptionType.BOOLEAN,
    --     CurrentSetting = function()
    --     return Da1Settings.maxcharges
    --     end,
    --     Display = function()
    --     return "maxcharges: " .. (Da1Settings.maxcharges and "6" or "4")
    --     end,
    --     OnChange = function(b)
    --     Da1Settings.maxcharges = b
    --     SaveSettings()
    --     end,
    --     Info = { -- This can also be a function instead of a table
    --     "maxcharges = 4 or 6",
    --     -- "More info on 2nd line",
    --     }
    -- }
    -- )


-- 首先检查是否为MCM中文版
if MCM.i18n == "Chinese" then
    
    -- 1. 翻译菜单和子菜单名称（根据你的实际结构）
    MCM.SetCategoryNameTranslate("D+1", "D+1")
    MCM.SetSubcategoryNameTranslate("D+1", "Normal Settings", "常规设置")
    MCM.SetSubcategoryNameTranslate("D+1", "Smoke Settings", "烟雾特效")
    MCM.SetSubcategoryNameTranslate(ModName, "Info", "信息")
    
    -- 2. 翻译Display内容（函数类型，使用模式匹配）
    MCM.TranslateOptionsDisplayWithTable("D+1", "Normal Settings", {
        {"Empty Pedestal: on", "是否可以对空底座使用: 是"},
        {"Empty Pedestal: off", "是否可以对空底座使用: 否"},
        {"Cycle: on", "是否开启循环: 是"},
        {"Cycle: off", "是否开启循环: 否"},
    })

    MCM.TranslateOptionsDisplayWithTable("D+1", "Smoke Settings", {
        {"Change: off", "改变: 关闭"},
        {"Change: on", "改变: 开启"},
        {"Smoke: Reverse", "烟雾特效: 倒放"},
        {"Smoke: Bang", "烟雾特效: 爆炸"}
    })

    MCM.TranslateOptionsDisplayWithTable(ModName, "Info", {
        {"Version", "版本"}
    })
    
    -- 3. 翻译Info内容（表格类型，使用严格匹配）
    MCM.TranslateOptionsInfoTextWithTable("D+1", "Normal Settings", {
        ["Enable or disable rerolling empty pedestals into The Sad Onion"] = "是否可以对空底座使用,使其变为悲伤洋葱" ,
        ["Enable or disable rerolling the item with the maximum ID"] = "是否可以对id最大道具使用",
        ["into The Sad Onion with ID 1"] = "使其变成id为1的悲伤洋葱",
    })

    MCM.TranslateOptionsInfoTextWithTable("D+1", "Smoke Settings", {
        ["Change the smoke effect"] = "改变roll道具产生的烟雾",
        ["Bang come with sound"] = "爆炸会带有音效",
        ["Reverse or Bang when rolling"] = "倒放或爆炸",
    })


        -- 信息页面文本翻译（固定字符串）
    MCM.TranslateOptionsDisplayTextWithTable(ModName, "Info", {
        [ModName] = "D+1",
        ["By Willow(Programming) and Lonely night(Art)"] = "作者: 武珞(代码) 和 Lonely night(绘画)"
    })
    
end
end