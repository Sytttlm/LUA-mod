local mod = RegisterMod("Dream_Recall", 1)  --注册mod
mod.VersionString = "1.1"
local json = require("json")
DreamRecallModForConfigMenu = mod  --把mod传给greed_chance_mod_config_menu.lua

if (ModConfigMenu) then --ModConfigMenu的api网址https://github.com/Zamiell/isaac-mod-config-menu/blob/main/README.md
    require("dream_recall_mod_config_menu");
end

-- function mod:shouldHide()  --哪些地方得关闭ui显示
--     local inGame = Game():GetLevel() ~= nil
--     local list = {
--         not inGame,  --不在游戏中就不触发
--         not Game():GetHUD():IsVisible(),  --不知道什么地方用到这个，借鉴自星象房概率mod
--         -- Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD),  --某些彩蛋种子会关闭HUD，借鉴自星象房概率mod
--     }
--     return list[1] or list[2]
-- end

function mod:getItem(collectible, itemPoolType, decrease, seed)
    if self.storage.collectibleID1 == 0 then
        self.storage.collectibleID1 = collectible  -- 这就是下一层宝箱房的道具 ID
    elseif self.storage.collectibleID2 == 0 then
        self.storage.collectibleID2 = collectible
    elseif self.storage.collectibleID3 == 0 then
        self.storage.collectibleID3 = collectible
    elseif self.storage.collectibleID4 == 0 then
        self.storage.collectibleID4 = collectible
    end
end

--进入新楼层触发
function mod:newLevel()
    --清除过往数据
    self.storage.collectibleID1 = 0
    self.storage.collectibleID2 = 0
    self.storage.collectibleID3 = 0
    self.storage.collectibleID4 = 0
    self.storage.record = 0
    local level = Game():GetLevel()
    self.storage.startRoomIndex = level:GetCurrentRoomIndex()  --获取初始房间索引号
end

--暂停一结束，这个就运行
function mod:update()
    --如果self.storage.record为0，说明刚刚下层刚刚进入初始房间，什么都还没来得及动
    if self.storage.record == 0 then
        self.storage.record = 1  --为1将阻止mod:checkIt()修改所记录的道具id，防在初始房间不出去的时候生成道具
    end
end

function mod:checkIt()
    --如果self.storage.record为0，说明还在过场动画期间，此时记录下来的都是捕梦网roll的
    if self.storage.record == 0 then
        self.storage.recordCollectibleID1 = self.storage.collectibleID1
        self.storage.recordCollectibleID2 = self.storage.collectibleID2
        self.storage.recordCollectibleID3 = self.storage.collectibleID3
        self.storage.recordCollectibleID4 = self.storage.collectibleID4
    end

    if not EID then return end  -- 确保 EID 已加载
    --加了这个就不知道为什么莫名其妙的会让mod配置选项失效，只能注释掉了
    -- if mod:shouldHide() then return end  --如果需要关闭显示，那就停止渲染

    if self.storage.startRoomIndex == Game():GetLevel():GetCurrentRoomIndex()then
        if self.storage.MCMKeepOpen == true or (self.storage.MCMKeepOpen == false and Game():GetRoom():IsFirstVisit() == true)then
            local pos1 = Vector(140, 22)  --指定渲染起点（屏幕坐标）
            local pos2 = Vector(240, 22)
            local pos3 = Vector(140, 34)
            local pos4 = Vector(240, 34)
            local desc1
            local desc2
            local desc3
            local desc4
            if self.storage.recordCollectibleID1 ~= 0 then
                -- desc.Name        道具名（已翻译）
                -- desc.Description 描述文本（含 EID markup，如 {{Tears}} / ↑ / # 换行）
                -- desc.Quality     品质 1-4
                -- desc.Transformation 变身
                -- desc.Icon        图标信息
                desc1 = EID:getDescriptionObj(5, 100, self.storage.recordCollectibleID1, nil, false)  --取 EID 描述对象（第 4 参 entity 传 nil，第 5 参 false = 跳过动态修饰，更稳）
                --渲染道具名（EID 字体支持 UTF8/中文；用 EID 的颜色常量）
                EID.font:DrawStringScaledUTF8(
                    desc1.Name,
                    pos1.X, pos1.Y,
                    EID.Scale, EID.Scale,
                    EID:getNameColor(),   -- 名字颜色（KColor）
                    0, false
                )
            end
            if self.storage.recordCollectibleID2 ~= 0 then
                desc2 = EID:getDescriptionObj(5, 100, self.storage.recordCollectibleID2, nil, false)
                EID.font:DrawStringScaledUTF8(
                desc2.Name,
                pos2.X, pos2.Y,
                EID.Scale, EID.Scale,
                EID:getNameColor(),   -- 名字颜色（KColor）
                0, false
                )
            end
            if self.storage.recordCollectibleID3 ~= 0 then
                desc3 = EID:getDescriptionObj(5, 100, self.storage.recordCollectibleID3, nil, false)
                EID.font:DrawStringScaledUTF8(
                desc3.Name,
                pos3.X, pos3.Y,
                EID.Scale, EID.Scale,
                EID:getNameColor(),   -- 名字颜色（KColor）
                0, false
                )
            end
            if self.storage.recordCollectibleID4 ~= 0 then
                desc4 = EID:getDescriptionObj(5, 100, self.storage.recordCollectibleID4, nil, false)
                EID.font:DrawStringScaledUTF8(
                desc4.Name,
                pos4.X, pos4.Y,
                EID.Scale, EID.Scale,
                EID:getNameColor(),   -- 名字颜色（KColor）
                0, false
                )
            end
        end
    end

    -- if self.storage.currentDungeon ~= Game():GetLevel():GetDungeonPlacementSeed() then
    --     print("PlacementSeed: " .. Game():GetLevel():GetDungeonPlacementSeed())
    --     self.storage.currentDungeon = Game():GetLevel():GetDungeonPlacementSeed()
    -- end
    -- print(Game():GetRoom():IsFirstVisit())
    -- if self.storage.test1 ~= self.storage.recordCollectibleID1 then
    --     print(self.storage.recordCollectibleID1)
    --     self.storage.test1 = self.storage.recordCollectibleID1
    -- end
    -- if self.storage.test2 ~= self.storage.recordCollectibleID2 then
    --     print(self.storage.recordCollectibleID2)
    --     self.storage.test2 = self.storage.recordCollectibleID2
    -- end
end

function mod:initialize(bool)
    -- if bool == false then
    --     mod:initStore()
    -- end
    if bool == true then
        if mod:HasData() then
            self.storage = json.decode(mod:LoadData())
        end
    else
        mod:initStore()
    end
end

--对局退出的时候运行
function mod:exit()
    --存储当前storage的数据
    local jsonString = json.encode(mod.storage)
    mod:SaveData(jsonString)
end

function mod:initStore()
    self.storage = {}

    --存储抓取到的道具id，空底座的道具id是0，所以应该不会误判。由于最多抓取到两个宝箱房各两个道具一共四个，所以这里存四个
    self.storage.collectibleID1 = 0  --抓取到的第一个道具id，初始化为0。
    self.storage.collectibleID2 = 0  --抓取到的第二个道具id，初始化为0。
    self.storage.collectibleID3 = 0  --抓取到的第三个道具id，初始化为0。
    self.storage.collectibleID4 = 0  --抓取到的第四个道具id，初始化为0。

    --用于转存记录到的道具id，防初始房间生成道具。
    self.storage.recordCollectibleID1 = 0
    self.storage.recordCollectibleID2 = 0
    self.storage.recordCollectibleID3 = 0
    self.storage.recordCollectibleID4 = 0

    self.storage.startRoomIndex = 0  --本层初始房间的索引。使用Game():GetLevel():GetDungeonPlacementSeed()获取
    self.storage.record = 0  --道具id是否被记录，为1则是已记录。用于防初始房间生成道具。

    --配置文件
    self.storage.MCMKeepOpen = false  --默认关闭 在初始房间始终显示捕梦网道具

    if (ModConfigMenu) and mod:HasData() then
        local jsonString = mod:LoadData()
        local fullData = json.decode(jsonString)
        if fullData.MCMKeepOpen == nil then
            mod:SaveData(json.encode(mod.storage))
        else
            self.storage.MCMKeepOpen = fullData.MCMKeepOpen
        end
    end
end

mod:initStore()  --启动游戏加载模组的时候运行一次初始化

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.exit)  --退出游戏时触发
mod:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE,mod.getItem)  --从道具池中选取道具时触发，例如进宝箱房的瞬间、d6roll道具、捕梦网下层瞬间
-- mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,mod.newRoom)  --进入新房间之后触发
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,mod.newLevel) --完成一个新关卡或者进入新楼层触发。总是在MC_POST_NEW_ROOM之后触发
mod:AddCallback(ModCallbacks.MC_POST_UPDATE,mod.update)  --非暂停期间触发，每秒30次
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.checkIt) --每次游戏渲染后调用（每秒60次）
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.initialize) --新游戏开始时初始化