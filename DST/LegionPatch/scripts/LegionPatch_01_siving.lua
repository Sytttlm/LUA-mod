--=============================================================================
--  补丁 1：子圭·崇溟（siving_ctlall）的肥料值上限
--=============================================================================
--  载入方式：modmain.lua 里 modimport("scripts/LegionPatch_01_siving")
--  公共工具在 scripts/LegionPatch_core/LegionPatch_utils.lua：LPUtil.log / LPUtil.DEBUG / LPUtil.patch_component
--
--  棱镜源码定位（参考mod\棱镜\scripts\prefabs\siving_related.lua）：
--     371-436  MakeItem      → 物品 siving_ctlall_item（"未放置的子圭·崇溟"）
--     437-514  MakeConstruct → 结构 siving_ctlall（放置后的崇溟）
--                              其中 491 行 AddComponent("botanycontroller")
--     639-656  崇溟的 MakeConstruct 调用，fn_server 里设死了两个上限：
--                 650:  inst.components.botanycontroller.moisture_max = 6000
--                 651:  inst.components.botanycontroller.nutrient_max = 2400  ← 要改的
--     325      Fn_dealdata_sivctl 把上限【写死成字符串】给鼠标提示用：
--                 dd.nmax = inst.ctltype_l == 3 and "2400" or "800"
--              → 只改组件值的话，鼠标提示还会显示 "/2400"，所以一并接管。
--
--  botanycontroller 是纯服务端组件（棱镜没写 botanycontroller_replica.lua），客户端上 inst.components.botanycontroller 是 nil，所以必须判空。
--  上限只影响服务端计算；进度条是靠 siving_ctl_bar 子实体的动画百分比同步给客户端的，客户端不需要知道这个数值。
--=============================================================================

local VANILLA_NUTRIENT_MAX = 2400  --记录原版数值
local NUTRIENT_MAX = GetModConfigData("SIVING_CTLALL_NUTRIENT_MAX") or VANILLA_NUTRIENT_MAX  --存储数值，若配置选项为false则退回原版数值

-- 棱镜可能会在更晚的阶段才写 STRINGS，取一次有拿到 nil 的风险。
-- 写成函数，每次用的时候重新取
local function GetSivCtlTemplate()  --成功的话会拿到GLOBAL.STRINGS.NAMEDETAIL_L.SIVCTL
    local s = GLOBAL.STRINGS
    local nd = s and s.NAMEDETAIL_L
    return nd and nd.SIVCTL
end

-- 复刻棱镜 siving_related.lua:319-332 的 Fn_dealdata_sivctl，只把写死的 nmax
-- 换成我们的值，其余（含 momax = "6000"）逐字保持原样，避免行为漂移。
-- subfmt 是原版全局函数（scripts/stringutil.lua:475），靠 env 的 __index 回落拿到。
local function DealData_SivCtl(inst, data)
    local dd = {}
    if inst.ctltype_l ~= 1 then
        dd.n1 = tostring(data.n1 or 0)
        dd.n2 = tostring(data.n2 or 0)
        dd.n3 = tostring(data.n3 or 0)
        dd.nmax = inst.ctltype_l == 3 and tostring(NUTRIENT_MAX) or "800"  --
    end
    if inst.ctltype_l ~= 2 then
        dd.mo = tostring(data.mo or 0)
        dd.momax = inst.ctltype_l == 3 and "6000" or "2000"
    end
    return subfmt(GetSivCtlTemplate()[inst.ctltype_l], dd)
end

-- 接管鼠标提示。
-- 棱镜的 tools_legion.lua:1193 InitMouseInfo 本质上就是
--     inst.mouseinfo_l = { limitedtime=..., fn_dealdata=..., str=..., dd=..., fn_getdata=... }
-- 所以直接替换其中的 fn_dealdata 就是等价且最小侵入的做法。
local function OverrideSivCtlTooltip(inst)
    if GetSivCtlTemplate() == nil or subfmt == nil then return end  --得防nil
    local mi = inst.mouseinfo_l
    if mi == nil or mi.fn_dealdata == nil then return end
    mi.fn_dealdata = DealData_SivCtl  --把自己的DealData_SivCtl函数替换进去
end

if NUTRIENT_MAX ~= VANILLA_NUTRIENT_MAX then  --修改了数值再运行
    -- 放置后的结构：改真正的上限 + 工具提示
    AddPrefabPostInit("siving_ctlall", function(inst)
        local bc = inst.components and inst.components.botanycontroller
        if bc ~= nil then
            bc.nutrient_max = NUTRIENT_MAX  --改上限
        end
        OverrideSivCtlTooltip(inst)  --改工具提示
    end)
    LPUtil.api.hooks = LPUtil.api.hooks + 1  --钩子计数

    -- 物品形态只显示同一个提示文本，没有 botanycontroller，只改提示
    AddPrefabPostInit("siving_ctlall_item", function(inst)
        OverrideSivCtlTooltip(inst)  --改工具提示
    end)
    LPUtil.api.hooks = LPUtil.api.hooks + 1  --钩子计数

    LPUtil.log(string.format("子圭·崇溟 肥料上限：%d → %d", VANILLA_NUTRIENT_MAX, NUTRIENT_MAX))
else
    LPUtil.log("子圭·崇溟 肥料上限保持原版 2400，未打补丁。")
end
