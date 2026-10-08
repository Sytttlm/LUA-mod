local TAG = "[LegionPatch]"

---@class LegionPatchApi
---@field version string
---@field modname string
---@field hooks integer

---@class LegionPatchUtil
---@field DEBUG boolean
---@field api LegionPatchApi
---@field log fun(...)
---@field patch_component fun(inst:any, compname:string, fn:fun(comp:any, inst:any))
---@field get_tools_legion fun():table|nil

---@type LegionPatchUtil
LPUtil = {}          -- ← 故意不加 local：直接建在本 mod 的环境上，全 mod 可见

--=============================================================================
-- 一、配置开关
--=============================================================================

--读取DEBUG的开启状态
LPUtil.DEBUG = GetModConfigData("DEBUG") == true

--=============================================================================
-- 二、日志
--=============================================================================

--为日志提供统一前缀
-- 要"只在调试时打印"的日志，就写：
--     if LPUtil.DEBUG then LPUtil.log(...) end
-- 故意不把它做成一个包装函数：函数实参在进入函数体之前就求值完了，
-- 包装版会把 string.format / tostring 的开销留到 DEBUG 关着的时候白算一遍。
function LPUtil.log(...)
    print(TAG, ...)
end

--=============================================================================
-- 三、常用工具
--=============================================================================

--安全地拿到实体身上的组件再改，避免 nil 报错
function LPUtil.patch_component(inst, compname, fn)
    local c = inst and inst.components and inst.components[compname]
    if c then  --组件真的拿到了再运行，防止nil
        fn(c, inst)
    elseif LPUtil.DEBUG then  --如果没拿到，并且开启了DEBUG，就打印一下信息
        LPUtil.log(string.format("跳过：%s 上没有 %s 组件", tostring(inst and (inst.prefab or inst.GUID)), compname))
    end
end


--这个暂时没用到
-- 懒加载 require 棱镜的明文模块。
-- 棱镜加载时把自己的 scripts\ 目录前插进了 package.path（mods.lua:567），
-- 所以这里能直接 require 到它的明文模块：
--     tools_legion / tools_plant_legion / datafix_legion / recipes_legion ...
-- 只能 require 明文那批：modmain.lua 是混淆的，modmainNN.lua 是加密二进制。
local tools_legion
function LPUtil.get_tools_legion()
    if tools_legion == nil then
        local ok, mod = pcall(require, "tools_legion")
        tools_legion = ok and mod or false
        if not ok then LPUtil.log("警告：require('tools_legion') 失败。") end
    end
    return tools_legion or nil
end

--=============================================================================
-- 四、对外探针：游戏内按 ~ 输入
--c_announce("ver="..tostring(LEGION_PATCH.version).." hooks="..tostring(LEGION_PATCH.hooks))
--就能看到LPUtil.api里存的内容
--=============================================================================

LPUtil.api = {
    version = (modinfo and modinfo.version) or "0.0.0",  --读取版本号，若没有就设为0.0.0。and的意思是，前者为真就继续往后找，为假就截断为前者
    modname = modname,
    hooks   = 0,      -- 已注册的钩子数，初始化为0，由各补丁文件自己 +1
}
--把LPUtil.api存到LEGION_PATCH里
GLOBAL.rawset(GLOBAL, "LEGION_PATCH", LPUtil.api)
