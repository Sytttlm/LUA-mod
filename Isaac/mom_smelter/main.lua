local mod = RegisterMod("mom_smelter", 1)  --注册mod
mod.VersionString = "1.0.1"

--突然发现不用检测妈包或肚脐
-- local function hasTwoTrinketSlots(playerWhoUsedItem) --判断角色是否具有双饰品槽位道具妈包139或肚脐458
--     local result = false --默认没有
--     if playerWhoUsedItem:HasCollectible(139, true) or playerWhoUsedItem:HasCollectible(458, true)then
--         result = true
--     end
--     return result
-- end

local function QueuedTrinket(playerWhoUsedItem) --判断举在手上的道具是否为饰品
    local result = true
    if playerWhoUsedItem:IsItemQueueEmpty() then --如果不在这边判断一次，下面会报QueuedItem为nil
        result = true
    elseif playerWhoUsedItem.QueuedItem.Item:IsTrinket() then
        result = false
    end
    return result
end

local function spawnTrinket(playerWhoUsedItem)--生成饰品
  
    Game():Spawn(
        EntityType.ENTITY_PICKUP, -- Type实体类型
        PickupVariant.PICKUP_TRINKET, -- Variant实体变体
        Game():GetRoom():FindFreePickupSpawnPosition ( playerWhoUsedItem.Position, 0, true, false ), -- Position生成位置
        Vector(0, 0), -- Velocity初始速度
        nil, -- Parent生成者
        0, -- SubType子类型/具体ID  这边填0的还就随机生成了
        1 --不知道为什么这个随机种子不会影响饰品的生成顺序，遂填1
    )
end

function mod:giveMeTrinket(_, rngObj, playerWhoUsedItem)--注意，函数的参数必须按顺序，所以要用到后面的变量但前面的没有用处时可以用"_"或其他变量名替代而非直接在第一个处当后面的变量使用
    local trinket1 = playerWhoUsedItem:GetTrinket(0)  --获取1号位饰品id
    local trinket2 = playerWhoUsedItem:GetTrinket(1)  --获取2号位饰品id
    if trinket1 == 0 and QueuedTrinket(playerWhoUsedItem) then
        spawnTrinket(playerWhoUsedItem)
    -- elseif trinket2 == 0 then
    --     if hasTwoTrinketSlots(playerWhoUsedItem) then
    --         spawnTrinket()
    --     end
    end
end

mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, mod.giveMeTrinket, CollectibleType.COLLECTIBLE_SMELTER)