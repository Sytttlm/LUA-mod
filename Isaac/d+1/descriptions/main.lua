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

 local function IdRealPlus1(initialid)
    local TargetId =  maxToMin(idPlus1(initialid))

    --在贪婪模式中，标签“非贪婪模式”的道具会被跳过
    if game:IsGreedMode() then  --判断是否处于贪婪模式
        if itemConfig:GetCollectible(TargetId):HasTags(ItemConfig.TAG_NO_GREED) then --判断是否含有非贪婪标签
            TargetId = idPlus1(TargetId) -- 递归
        end
    end
    --在挑战中，标签“非挑战”的道具会被跳过。
    if  game.Challenge ~= 0 then --判断是否处于挑战模式
        if itemConfig:GetCollectible(TargetId):HasTags(ItemConfig.TAG_NO_CHALLENGE) then --判断是否含有非挑战标签
            TargetId = idPlus1(TargetId) -- 递归
        end
    end
    --未解锁的道具会根据配置选择是否被跳过
    if not itemConfig:GetCollectible(TargetId):IsAvailable() and EID.Config["SpindownDiceSkipLocked"] then
        TargetId = idPlus1(TargetId) -- 递归
    end
    return TargetId
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
				    if EID.itemUnlockStates[refID] == false then EID:appendToDescription(descObj, "?") end
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