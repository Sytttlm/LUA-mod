name = "棱镜小修"
author = "武珞"
version = "1.0.0"
forumthread = ""
description = [[
需要同时开启 [DST] Legion-棱镜。

对棱镜的部分内容或数值进行修改。
]]
api_version = 10

--=============================================================================
-- scripts/mods.lua 里是 return apriority > bpriority，即【数值越大越先加载】。
-- 棱镜的 priority = -345，所以补丁必须比 -345 更小，才能"后加载"。
-- 如果哪天棱镜改了 priority，这里要跟着调小。
--=============================================================================
priority = -1000 --优先级

dst_compatible = true  -- 联机版适配性
dont_starve_compatible = false  -- 单机版适配性
reign_of_giants_compatible = false  -- 单机版：巨人国适配性
all_clients_require_mod = true  -- 服务端/所有端模组
-- server_only_mod = true -- 仅服务端模组
-- client_only_mod = true -- 仅客户端模组

--让棱镜被依赖开启
mod_dependencies = {
    {
        ["[DST] Legion"] = true,   -- true  = 这是 modinfo 里的显示名，会自动转成文件夹名
        ["[DST] 棱镜"] = true,
        workshop = "workshop-1392778117",
    },
}

server_filter_tags = {}  -- 创意工坊模组分类标签
icon_atlas = "modicon.xml"  -- 图集
icon = "modicon.tex"  -- 图标

configuration_options = {
    {
        name = "PATCH_ENABLED",
        label = "总开关",
        hover = "一键关闭所有修改",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,
    },
    {
        name = "SIVING_CTLALL_NUTRIENT_MAX",
        label = "子圭·崇溟 肥料值上限",
        hover = "子圭·崇溟能储存的肥料值上限，棱镜原版为 2400。",
        options = {
            { description = "2400 (棱镜原版)", data = 2400 },
            { description = "4800 (2 倍)", data = 4800 },
            { description = "9600 (4 倍)", data = 9600 },
            { description = "24000 (10 倍)", data = 24000 },
            { description = "240000 (100 倍)", data = 240000 },
        },
        default = 24000,
    },
    {
        name = "DEBUG",
        label = "开启调试",
        hover = "在日志里打印额外的调试信息",
        options = {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
}
