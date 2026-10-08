local mod = DreamRecallModForConfigMenu
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
    MCM.AddText(ModName, "Info", "By Willow") --显示作者

    MCM.AddSetting(
    "Dream_Recall", -- This should be unique for your mod
    "Normal Settings", -- If you don't want multiple tabs, then set this to nil
    {
        Type = MCM.OptionType.BOOLEAN,
        CurrentSetting = function()
            return mod.storage.MCMKeepOpen
        end,
        Display = function()
            return "keep showing in starting room: " .. (mod.storage.MCMKeepOpen and "on" or "off")
        end,
        OnChange = function(b)
            mod.storage.MCMKeepOpen = b
            MCMFunction:save()
        end,
        Info = { -- This can also be a function instead of a table
            "For on, they will keep showing in starting room",
            "For off, they will Shown only on the first entry to the starting room.",
            }
    }
    )


    --中文翻译
    if MCM.i18n == "Chinese" then
        -- 1. 翻译菜单和子菜单名称（根据你的实际结构）
        MCM.SetCategoryNameTranslate("Dream_Recall", "捕梦网道具名称显示")
        MCM.SetSubcategoryNameTranslate("Dream_Recall", "Normal Settings", "常规设置")
        MCM.SetSubcategoryNameTranslate(ModName, "Info", "信息")

        -- 2. 翻译Display内容（函数类型，使用模式匹配）
        MCM.TranslateOptionsDisplayWithTable("Dream_Recall", "Normal Settings", {
            {"keep showing in starting room: on", "始终显示在初始房间: 是"},
            {"keep showing in starting room: off", "始终显示在初始房间: 否"},
        })

        MCM.TranslateOptionsDisplayWithTable(ModName, "Info", {
            {"Version", "版本"}
        })

        -- 3. 翻译Info内容（表格类型，使用严格匹配）
        MCM.TranslateOptionsInfoTextWithTable("Dream_Recall", "Normal Settings", {
            ["For on, they will keep showing in starting room"] = "开启时，将在初始房间始终显示",
            ["For off, they will Shown only on the first entry to the starting room."] = "关闭后，只在第一次进入初始房间时显示" ,
        })

        -- 信息页面文本翻译（固定字符串）
        MCM.TranslateOptionsDisplayTextWithTable(ModName, "Info", {
            [ModName] = "捕梦网道具名称显示",
            ["By Willow"] = "作者: 武珞"
        })
    end

end

return MCMFunction