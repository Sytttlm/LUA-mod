GLOBAL.setmetatable(env, { __index = function(_, k) return GLOBAL.rawget(GLOBAL, k) end })  --标准起手式

modimport("scripts/LegionPatch_core/LegionPatch_utils")  --导入工具

--=============================================================================
-- 前置检查
--=============================================================================

-- 棱镜在明文文件 scripts/datafix_legion.lua 里留了 TUNING["mod_legion_enabled"] = true，用于检测棱镜是否开启
local function IsLegionPresent()
    return (TUNING and TUNING["mod_legion_enabled"] == true)
        or (GLOBAL.rawget(GLOBAL, "CONFIGS_LEGION") ~= nil)
end

--如果没有启用棱镜，直接结束，后续代码将不再运行
if not IsLegionPresent() then
    LPUtil.log("未检测到棱镜 (Legion)，本补丁不生效。")
    return
end

--如果在设置里关闭了补丁，直接结束，后续代码将不再运行
if GetModConfigData("PATCH_ENABLED") == false then
    LPUtil.log("配置里已关闭，本补丁不生效。")
    return
end

LPUtil.log("检测到棱镜，开始注册补丁。")

--=============================================================================
-- 补丁列表
--=============================================================================
-- 加新补丁的流程：
--     1) 在 scripts/ 下新建 LegionPatch_NN_xxx.lua
--     2) 文件里直接用 LPUtil.log / LPUtil.patch_component /
--        AddPrefabPostInit / GetModConfigData ... （它们都是本 mod 环境的成员）
--     3) 在这里加一行 modimport
-- 模板抄 scripts/LegionPatch_templates.lua（那个文件不会被载入，纯参考）。

modimport("scripts/LegionPatch_01_siving")

--=============================================================================
-- 世界建好后，启动自检
--=============================================================================
AddSimPostInit(function()
    LPUtil.log(string.format("补丁已生效（已注册 %d 个显式钩子，版本 %s）。",
        LPUtil.api.hooks, LPUtil.api.version))
    if LPUtil.DEBUG then
        LPUtil.log("棱镜标记: mod_legion_enabled =",
            tostring(TUNING and TUNING["mod_legion_enabled"]))
    end
end)
