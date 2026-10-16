local mod = RegisterMod("D+1", 1)  --注册mod
local Dp1 = Isaac.GetItemIdByName("D+1") --根据物品名称获取真实id，这个id就是spawn 5.100.id
mod.VersionString = "1.4.1"
local game = Game()
local itemConfig = Isaac.GetItemConfig()
local idOfSadOnion = 1 --悲伤洋葱的id是1
Da1 = mod


----------------------------------下面动画相关------------------
local myEffectId = 36046  --特效id

function mod:onDPlus1EffectInit(effect)
    -- 效果初始化时的处理
    local sprite = effect:GetSprite()
    local modData = Isaac.LoadModData(mod) or "1111"
    if modData:sub(4,4) == "1" then  --若开启修改，默认是倒放
        sprite:Load("gfx/myEffect/ywdf.anm2", true)
        sprite:Play("Poof", true)
    end
    if modData:sub(4,4) ~= "1" then
        sprite:Load("gfx/myEffect/bztx.anm2", true)
        sprite:Play("bztx", true)
    end


effect.RenderZOffset = 9999 --特效置于 图层最上方
end

function mod:onDPlus1EffectUpdate(effect)
    -- 每帧更新动画
    local sprite = effect:GetSprite()
    sprite:Update()
    
    -- 动画完成后移除实体
    if sprite:IsFinished() then
        effect:Remove()
    end
end

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.onDPlus1EffectInit, myEffectId)
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.onDPlus1EffectUpdate, myEffectId)

local function realEffectId()
    local realId
    local modData = Isaac.LoadModData(mod) or "1111"
    if  modData:sub(3,3) == "1" then
        realId = EffectVariant.POOF01 --默认关闭修改，为原版烟雾特效
    else
        realId = myEffectId
    end
    return realId
end

----------------------------------上面动画相关--------------------
--https://steamcommunity.com/sharedfiles/filedetails/?id=3604699870

local function MorphItem(pickup, targetId) --转换道具函数，借鉴自Cuerzor大佬的猪骰 D-jw模组
    pickup:Morph(pickup.Type, pickup.Variant, targetId, true); -- 将道具变为目标ID
    pickup.Touched = false; -- 重置触碰状态，防止玩家意外捡起
    pickup.Wait = 20; -- 设置一个短暂的等待时间
    Isaac.Spawn(EntityType.ENTITY_EFFECT, realEffectId(), 0, pickup.Position, Vector.Zero, nil); -- 生成一个烟雾特效
end

--跳过处，其中：59彼列之书（被动道具形式），656达摩克里斯之剑（被动道具形式），714召回，715保留。其余为断点
local SKIP_IDS = {
    [42] = 44,   [58] = 60,   [60] = 62,   [234] = 236,
    [586] = 588, [612] = 614, [619] = 621, [629] = 631,
    [647] = 649, [655] = 657, [661] = 663, [665] = 667,
    [713] = 716, [717] = 719
}

local function maxToMin(TargetId)
        --加到超出id上限变成洋葱
        local idid = TargetId
    if not itemConfig:GetCollectible(TargetId)then
        idid = idOfSadOnion
    end
    return idid
end

local function idPlus1(initialid) --d+1,顺便跳过不对劲的东西
    --我真的服了，官方的id怎么这么多断点，一开始发现roll的时候到某个地方就随机跳，给我整不会了
    -- 处理跳过的ID
    local TargetId
    if SKIP_IDS[initialid] then
        TargetId = SKIP_IDS[initialid]
    else
        TargetId = initialid + 1
    end
    return TargetId
end

--判断是否因为标签的原因被禁止。返回true则被禁止，返回false则没被禁止
local function isBlockedByTags(cfg)
    if cfg == nil or cfg.Tags == nil then return false end  --防nil

    ----在贪婪模式中，标签“非贪婪模式”的道具会被跳过
    if game:IsGreedMode() and cfg:HasTags(ItemConfig.TAG_NO_GREED) then
        return true
    end
    --在挑战中，标签“非挑战”的道具会被跳过。
    if game.Challenge ~= 0 and cfg:HasTags(ItemConfig.TAG_NO_CHALLENGE) then
        return true
    end

    return false
end

--判断是否为两个特殊角色：里罗、长子权表罗
local function isSpecialRole()
    for i = 0, Game():GetNumPlayers() - 1 do  --遍历房间所有角色
        local player = Isaac.GetPlayer(i)
        local playerType = player:GetPlayerType()
        if playerType == PlayerType.PLAYER_THELOST_B then  -- 31里罗
            return true
        elseif playerType == PlayerType.PLAYER_THELOST then  -- 10表罗，需要判断是否持有长子权
            if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
                return true
            end
        end
    end
    return false
end

--判断道具是否解锁，不全用IsAvailable是因为它同时会判断是否被标签禁用。
--涉及到的角色有里罗、长子权表罗，这两人若不加忏悔龙，仅可判断是否默认解锁。
--其实还有表店里店，但是他俩只禁一磅肉，而且拿了之后没有任何效果，就不管了
--为真表示已解锁，为假表示未解锁
local function isUnlocked(cfg)
    if cfg == nil then return false end  --防nil
    if cfg.AchievementID == -1 then  --道具对应成就id为-1说明是无需解锁，一来就有
        return true
    elseif isSpecialRole() then  --若道具需要解锁，且为两种特殊情况
        if REPENTOGON then  --若有忏悔龙就精准判断
            return Isaac.GetPersistentGameData():Unlocked(cfg.AchievementID)
        else  --没有忏悔龙，就让里罗和长子权表罗可以roll出未解锁道具和被移出道具池的道具
            return true
        end
    end
    return cfg:IsAvailable()
end

local function isUsableCollectible(initialid)
    local cfg = itemConfig:GetCollectible(initialid)  --获取id对应的道具
    if cfg == nil then return false end  --虽然后面正常处理的话这边不会出nil，但以防万一还是判一下

    if isBlockedByTags(cfg) then return false end  --贪婪模式和挑战模式禁用的道具
    if isUnlocked(cfg) == false then return false end  --未解锁道具
    return true
end


local function IdRealPlus1(initialid)
    local targetId =  initialid
    local maxSteps = 700  --递归循环的上限，防死循环
    for _ = 1, maxSteps do
        targetId = maxToMin(idPlus1(targetId))
        if isUsableCollectible(targetId) then return targetId end
    end
    return targetId
end

local function Dplus1(initialEntity) --输入一个实体，传出应该变成的道具的id
    local initialid = initialEntity.SubType
    local targetId = IdRealPlus1(initialid)
    return targetId
end

function mod:RedButtonUse(item) --这个函数叫RedButtonUse是因为当时跟的视频教程就用的这个名字来写一个主动道具
    local roomEntities = Isaac.GetRoomEntities()
    if FontRenderSettings ~= nil then --FontRenderSettings是忏悔+新增的类，检测这个类是否为空就能知道忏悔+是否开启
        SFXManager():Play(SoundEffect.SOUND_D6_ROLL)
    end
    local modData = Isaac.LoadModData(mod) or "1111"  -- 默认值"11"表示两个选项都开启
    if modData:sub(3,3) ~= "1" and modData:sub(4,4) ~= "1" then
        mod.bzyx = Isaac.GetSoundIdByName("bzyx");
        SFXManager():Play(mod.bzyx)
    end
    for _, entity in ipairs(roomEntities) do
        if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then --判断是否是道具
            if  entity.SubType >= 4294966272 and entity.SubType <= 4294967295 then --判断是否为错误道具
                entity.Remove(entity)  --删除实体
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, nil); -- 生成一个烟雾特效
            elseif entity.SubType~=668 then --爸爸的便条不roll
            if entity.SubType == 0 or not itemConfig:GetCollectible(idPlus1(entity.SubType)) then
                if (ModConfigMenu) then
                    --Isaac.LoadModData(mod):sub(1,1) == "1" --判断emptyPedestal是否为真，1为真，0为假
                    local modData = Isaac.LoadModData(mod) or "1111"  -- 默认值"11"表示两个选项都开启
                    local emptyPedestalEnabled = modData:sub(1,1) == "1"
                    local cycleEnabled = modData:sub(2,2) == "1"
                    local shouldProcess = false
                if entity.SubType == 0 then -- 空底座
                    shouldProcess = emptyPedestalEnabled
                elseif not itemConfig:GetCollectible(idPlus1(entity.SubType)) then -- 循环roll
                    shouldProcess = cycleEnabled
                else -- 正常道具
                    shouldProcess = true
                end
                
                if shouldProcess then
                    local pickup = entity:ToPickup()
                    local targetId = Dplus1(entity)
                    MorphItem(pickup, targetId)
                end
                else--如果没有装配置mod，那就默认都可以roll
                    local pickup = entity:ToPickup();
                    local targetId = Dplus1(entity)
                    MorphItem(pickup, targetId)
                end
            else--如果底座不为空且不是最大id道具
                local pickup = entity:ToPickup();
                local targetId = Dplus1(entity)
                MorphItem(pickup, targetId)
            end
            end
        end
    end

    return {
        Discharge = true, --使用后是否消耗充能
        Remove = false, --使用后是否消失
        ShowAnim = true --使用后是否播放举手动画
    }
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RedButtonUse, Dp1) --当第三个参数符合要求才会触发第二个参数的函数

if (ModConfigMenu) then --ModConfigMenu的api网址https://github.com/Zamiell/isaac-mod-config-menu/blob/main/README.md
    require("Dp1_mod_config_menu");
end

if (EID) then --eid的api网址https://github.com/wofsauge/External-Item-Descriptions/wiki
    include("descriptions/main");
end