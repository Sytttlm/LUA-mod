local Mod = Da1;
local Dp1 = Isaac.GetItemIdByName("D+1") --根据物品名称获取真实id，这个id就是spawn 5.100.id
print("D+1 的道具ID:", Dp1)
local goingToSpindown1


local yourLanguage = EID:getLanguage() --获取当前语言，若没有，则默认为英文


EID:AddToCollectiblesToCheckList(Dp1) --我真服了，不注册的话collectiblesOwned就检测不到，原版collectiblesOwned只检测那几个特殊道具

EID:addCollectible(Dp1, "Rerolls all pedestal items in a room by adding one to their internal ID number until a valid item is rolled.","D+1","en_us")
EID:addCollectible(Dp1, "将房间中所有道具重置为内部ID加1的道具", "D+1","zh_cn")

----------------------------------------------------------------------------------------------
---id+1的函数一旦设置为全局，就会导致配置文件失效，很奇怪的bug，我不知道怎么解决，只能整个复制过来了

local itemConfig = Isaac.GetItemConfig()
local idOfSadOnion = 1 --悲伤洋葱的id是1
local game = Game()
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
    if isUnlocked(cfg) == false then
        if EID.Config["SpindownDiceSkipLocked"] then
            return false
        else
            return true
        end
    end  --未解锁道具，并且eid的配置
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
---------------------------------------------------------------------------------------------------------------------
local mod = Da1

local function spinupId(id)
    local targetId
    if (ModConfigMenu) then
        --Isaac.LoadModData(mod):sub(1,1) == "1" --判断emptyPedestal是否为真，1为真，0为假
        local modData = Isaac.LoadModData(mod) or "1111"  -- 默认值"11"表示两个选项都开启
        local cycleEnabled = modData:sub(2,2) == "1"
        local shouldProcess = false
    if not itemConfig:GetCollectible(idPlus1(id)) then -- 循环roll
        shouldProcess = cycleEnabled
    else -- 正常道具
        shouldProcess = true
    end
    if shouldProcess then
        targetId = IdRealPlus1(id)
    else
        targetId = idPlus1(id)
    end
    else--如果没有装配置mod，那就默认都可以roll
        targetId = IdRealPlus1(id)
    end
    return targetId
end

-- Handle Spindown Dice description addition
	local function SpinupDiceCallback(descObj) 
		-- don't display in item reminder, or if we've already printed it earlier in the desc
		if EID.InsideItemReminder or string.match(descObj.Description, "#{{Collectible"..Dp1.."}} :") then return descObj end
		-- get the ID of the player that owns the Spindown Dice
		local playerID = (EID.collectiblesOwned[Dp1] or EID.collectiblesAbsorbed[Dp1])
		EID:appendToDescription(descObj, "#{{Collectible"..Dp1.."}} :")
		local refID = descObj.ObjSubType
		local hasCarBattery = Isaac.GetPlayer(playerID):HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
		local firstID = 0
		for i = 1,EID.Config["SpindownDiceResults"] do --此处为最大循环数量
			local spinnedID = spinupId(refID)
			if hasCarBattery and spinnedID ~= 668 then
				refID = spinnedID
				spinnedID = spinupId(refID)
			end
			refID = spinnedID
			if refID > 0 and refID < 4294960000 then
                if itemConfig:GetCollectible(refID) then
                    if i == 1 then firstID = refID end
                    if i == 1 and EID.TabHeldThisFrame and (EID.collectiblesOwned[723] or EID.collectiblesAbsorbed[723])then
                        refID = spinupId(refID)
                    end
				    EID:appendToDescription(descObj, "{{Collectible"..refID.."}}")
				    if not isUnlocked(itemConfig:GetCollectible(refID)) then EID:appendToDescription(descObj, "?") end
				    if EID.Config["SpindownDiceDisplayID"] then --此处的true可以替换成配置选项的开启：是否开启id显示
					    EID:appendToDescription(descObj, "/".. refID)
				    end
				    if EID.Config["SpindownDiceDisplayName"] then
					    EID:appendToDescription(descObj, "/".. EID:getObjectName(5, 100, refID))
					    if refID == 668 then break end
					    if i ~= EID.Config["SpindownDiceResults"] then
						    EID:appendToDescription(descObj, "#{{Blank}}")
					    end
				    end

				    if refID == 668 then break end -- Dad's Note is not affected by Spindown Dice
				    if i ~= EID.Config["SpindownDiceResults"] then
					    EID:appendToDescription(descObj, " ->")
				    end
                else
                    if yourLanguage == "zh_cn" then
                        EID:appendToDescription(descObj, "保持不变")
                        break
                    else
                        EID:appendToDescription(descObj, "keep")
                        break
                    end
                end

			else --如果id不在范围内refID > 0 and refID < 4294960000
				local errorMsg = EID:getDescriptionEntry("spindownError") or ""
				EID:appendToDescription(descObj, errorMsg)
				break
			end
		end
		if hasCarBattery then
			EID:appendToDescription(descObj, " " .. EID:ReplaceVariableStr(EID:getDescriptionEntry("ResultsWithX"), 1, "{{Collectible356}}"))
		end
		-- if firstID ~= 0 and EID.TabPreviewID == 0 then
		-- 	EID.TabPreviewID = firstID
		-- 	EID:appendToDescription(descObj, "#{{Blank}} ".. EID:getDescriptionEntry("FlipItemToggleInfo"))
		-- end
		return descObj
	end

local function SpinUpEIDConditions(descObj)
	-- currently, only pickup descriptions have modifiers
	if descObj.ObjType ~= 5 then return false end

	EID:CheckPlayersCollectibles()

	local callbacks = {}

	-- Collectible Pedestal Callbacks
	if descObj.ObjVariant == PickupVariant.PICKUP_COLLECTIBLE then

		if EID.Config["SpindownDiceResults"] > 0 and (EID.collectiblesOwned[Dp1] or EID.collectiblesAbsorbed[Dp1]) and descObj.ObjSubType ~= 668 then
			goingToSpindown1 = true
			table.insert(callbacks, SpinupDiceCallback)

		else goingToSpindown1 = false end
			
	end
return callbacks
end
EID:addDescriptionModifier("spinup", SpinUpEIDConditions, nil)