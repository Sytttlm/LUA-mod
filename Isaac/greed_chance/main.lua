local mod = RegisterMod("greed_chance", 1)  --注册mod
mod.VersionString = "1.0.6"
local json = require("json")
GreedChanceModForConfigMenu = mod  --把mod传给greed_chance_mod_config_menu.lua
-- local Mcm = {} --读取配置文件返回的表
-- local MCMLoaded, MCM = pcall(require, "scripts.modconfig")
-- if MCMLoaded then
--     Mcm = require("greed_chance_mod_config_menu")
-- end

if (ModConfigMenu) then --ModConfigMenu的api网址https://github.com/Zamiell/isaac-mod-config-menu/blob/main/README.md
    require("greed_chance_mod_config_menu");
end

--ui位置的变动借鉴自星象房概率mod，贪婪概率由于没有官方api直接读取，只能皆基于经验公式检测计算
--引用星象房概率mod代码的行为已由该mod作者于红迪授权，非常感谢

local function levelForGreed(level)  --记录每一层是否可以刷贪婪，0为不能，1为能。这里的Level是LevelStage
    local list = {
        [0] = 0, [1] = 0, [2] = 0, [3] = 0,
        [4] = 1, [5] = 1, [6] = 1, [7] = 1,
        [8] = 1, [9] = 0, [10] = 1, [11] = 1,
        [12] = 1, [13] = 0, [14] = 0
    }
    return list[level]
end

local function howMany ()  --遍历房间，找到到底是哪个地方出贪婪
    local rooms = Game():GetLevel():GetRooms()
    for i = 0, rooms.Size-1 do
        local room = rooms:Get(i)
        local roomType = room.Data.Type

        --商店出贪婪
        if roomType == RoomType.ROOM_SHOP and room.SurpriseMiniboss == true then
            mod.storage.shopGreedNumber = 1
        end

        --隐藏出贪婪
        if roomType == RoomType.ROOM_SECRET and room.SurpriseMiniboss == true then
            mod.storage.secretGreedNumber = mod.storage.secretGreedNumber + 1
        end
    end
end

local function IsBeastRoom(room) -- same as how the vanilla game detects it  --判断是否处于祸兽战斗。借鉴自星象房概率mod
	return room and room:GetType() == RoomType.ROOM_DUNGEON and room:GetRoomConfigStage() == 35 -- home
end

local function CanRunUnlockAchievements() -- by Xalum   --判断是否可以解锁成就
	local machine = Isaac.Spawn(6, 11, 0, Vector.Zero, Vector.Zero, nil)
	local achievementsEnabled = machine:Exists()
	machine:Remove()

	return achievementsEnabled
end

--星象房概率mod加了，用于判断教条
local dogmaEnded = false

function mod:isDogmaDefeated()  --在教条的死亡动画播放80帧之后停止渲染。借鉴自星象房概率mod
	-- This is super lame, but the only way to avoid drawing over the death animation (dogma flash) is by considering dogma "dead" after 80 frames of his death animation have played. 
	if dogmaEnded then return true end
	local isDogma = Game():GetLevel():GetAbsoluteStage() == LevelStage.STAGE8 and Game():GetRoom():IsCurrentRoomLastBoss()
	if isDogma then
		for _,v in pairs(Isaac.GetRoomEntities()) do
			if v:IsBoss() and v:GetSprite():GetAnimation() == "Death" and v:GetSprite():GetFrame() > 80 then
				dogmaEnded = true
				return true
			end
		end
	end
	return false
end

function mod:shouldHide()  --哪些地方得关闭ui显示
    local inGame = Game():GetLevel() ~= nil
    local list = {
        not inGame,  --不在游戏中就不触发
        not Options.FoundHUD,   --关闭了属性界面
        not Game():GetHUD():IsVisible(),  --不知道什么地方用到这个，借鉴自星象房概率mod
        IsBeastRoom(Game():GetRoom()),  --是否处于祸兽战斗
        Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD),  --某些彩蛋种子会关闭HUD，借鉴自星象房概率mod
    }
    return list[1] or list[2] or list[3] or list[4] or list[5]
end

local function TextAcceleration(frame)  --借鉴自星象房概率mod。Overfit distance profile for difference text slide in
	frame = frame - 14
	if frame > 0 then
		return 0
	end
	return -(15.1 / (13 * 13)) * frame * frame
end

local function DidPlayerRibCountJustChange(player)
	local data = player:GetData()
	if data.greedChanceDidRibCountJustChange then
		return true
	end
	return false
end

local function DidPlayerDualityCountJustChange(player)  --二元性变化了。借鉴自星象房概率mod
	local data = player:GetData()
	if data.greedChanceDidDualityCountJustChange then
		return true
	end
	return false
end

local function DidPlayerCharacterJustChange(player)  --character just change。角色变化了，借鉴自星象房概率mod
	local data = player:GetData()
	if data.greedChancePlayerTypeJustChanged then
		return true
	end
	return false
end

local function rainbow(h)  --HSL转RGB实现的彩虹渐变函数
    local function f(t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1/6 then return 6 * t end
        if t < 1/2 then return 1 end
        if t < 2/3 then return (2/3 - t) * 6 end
        return 0
    end
    local hn = h / 360
    return f(hn + 1/3), f(hn), f(hn - 1/3)
end

function mod:updateText()  --下层的时候触发

    local level = Game():GetLevel():GetStage() --获取当前LevelStage
    local StageType = Game():GetLevel():GetStageType()  --获取当前StageType

    dogmaEnded = false  --教条死亡标记，重置为false

    self.storage.lastCurrentGreedChance = self.storage.currentGreedChance  --存储上一层贪婪概率，用于防rewind

    self.storage.lastDungeon = self.storage.currentDungeon  --当前层夹层种子还没来得及变，先存起来就是上一层的
    self.storage.currentDungeon = Game():GetLevel():GetDungeonPlacementSeed() --正式下层了，读一下当前层的夹层种子存起来

    if levelForGreed(level) == 0 then  --如果当前层根本不会出
        self.storage.initialCurrentGreedChance = 0
        self.storage.currentGreedChance = self.storage.initialCurrentGreedChance
        self.storage.beforeMeetSmallCurrentGreedChance = 0  --回到不能刷贪婪的层时清掉备份
        self.storage.beforeMeetBigCurrentGreedChance = 0  --回到不能刷贪婪的层时清掉备份
    elseif Game():GetLevel():IsPreAscent() then  --处于预回溯就取出专门存的概率。单独处理这边是因为，目前测出来只有这个情况会导致MC_POST_RENDER先于MC_POST_NEW_LEVEL触发
        self.storage.currentGreedChance = self.storage.PreAscentGreedChance
    else
        self.storage.currentGreedChance = self.storage.nextGreedChance  --把上一层算的下一层概率赋给当前层概率
        self.storage.beforeMeetSmallCurrentGreedChance = self.storage.currentGreedChance  --存个备用数据来防见完小贪婪rewind
        self.storage.beforeMeetBigCurrentGreedChance = self.storage.currentGreedChance  --存个备用数据来防见完大贪婪rewind
    end

    --测试代码
    self.storage.shopGreedNumber = 0
    self.storage.secretGreedNumber = 0
    howMany()

end

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

--检查是否需要更新
function mod:updateCheck()

    local level = Game():GetLevel():GetStage() --获取当前LevelStage
    local StageType = Game():GetLevel():GetStageType()  --获取当前StageType

    if level == 6 and (StageType == 0 or StageType == 1 or StageType == 2 ) then  --如果当前层有可能走回溯下陵墓，就时时刻刻存当前的下一层概率
        self.storage.PreAscentGreedChance = self.storage.nextGreedChance
    end

    --如果上一层的夹层种子跟这一层相同，说明下层又rewind回来了
    if self.storage.lastDungeon == Game():GetLevel():GetDungeonPlacementSeed() then

        self.storage.currentGreedChance = self.storage.lastCurrentGreedChance  --把存的上一层概率取回来返给当前层
        self.storage.beforeMeetSmallCurrentGreedChance = self.storage.currentGreedChance  --这俩别忘了
        self.storage.beforeMeetBigCurrentGreedChance = self.storage.currentGreedChance  --这俩别忘了
        
        self.storage.lastDungeon = 1 --把上层夹层种子初始化为1
        self.storage.currentDungeon = Game():GetLevel():GetDungeonPlacementSeed()  --重新赋值当前层夹层种子
    end
    
    --存储摧毁捐款机的楼层
    if self.storage.donationBrokenDungeon == 0 and Game():GetStateFlag(GameStateFlag.STATE_DONATION_SLOT_BROKEN) then  --如果还没记录，并且刚刚摧毁
        self.storage.donationBrokenDungeon = Game():GetLevel():GetDungeonPlacementSeed()
    end
    if self.storage.donationBrokenDungeon ~= 0 and Game():GetStateFlag(GameStateFlag.STATE_DONATION_SLOT_BROKEN) == false then  --如果记录了但实际没摧毁，说明rewind了
        self.storage.donationBrokenDungeon = 0
    end

    --存储见到小贪婪的楼层
    if self.storage.meetSmallDungeon == 0 and Game():GetStateFlag(GameStateFlag.STATE_GREED_SPAWNED) then  --如果还没记录，并且刚刚见到
        self.storage.meetSmallDungeon = Game():GetLevel():GetDungeonPlacementSeed()
    end
    if self.storage.meetSmallDungeon ~= 0 and Game():GetStateFlag(GameStateFlag.STATE_GREED_SPAWNED) == false then  --如果记录了但实际没摧毁，说明rewind了
        self.storage.meetSmallDungeon = 0
    end

    --初始化下一层贪婪概率
    if Game():IsGreedMode() then  --贪婪模式商店不会刷贪婪
        self.storage.initialNextGreedChance = 0  --下一层贪婪概率为0
        self.storage.nextGreedChance = self.storage.initialNextGreedChance
    elseif Game():GetLevel():IsAscent() then  --如果处于回溯
        self.storage.initialNextGreedChance = 0  --下一层贪婪概率为0
        self.storage.nextGreedChance = self.storage.initialNextGreedChance
    else
        if level == 0 or level == 1 or level == 12 or level == 13 or level == 14 or Game():GetLevel():IsPreAscent() then  --当在这几层的时候，下一层必定不会刷贪婪.Game():GetLevel():IsPreAscent()是判断是否处于预回溯的陵墓2
            self.storage.initialNextGreedChance = 0  --下一层层贪婪概率为0
            self.storage.nextGreedChance = self.storage.initialNextGreedChance
        elseif level == 2 and (StageType == 0 or StageType == 1 or StageType == 2 ) then  --在主线地下室第二层的时候，下一层必定不刷贪婪
            self.storage.initialNextGreedChance = 0  --下一层层贪婪概率为0
            self.storage.nextGreedChance = self.storage.initialNextGreedChance
        else
            --基础概率1/3   33.3%
            self.storage.initialNextGreedChance = 100/3 

            --拥有超过20枚硬币：+1/60   +1.66%
            if Isaac.GetPlayer(0):GetNumCoins() >= 20 then
                self.storage.coinsDifferenceChance = 5/3  --这个值防rewind
            else
                self.storage.coinsDifferenceChance = 0
            end

            --摧毁了捐款机:+1/30  +3.33%
            if Game():GetStateFlag(GameStateFlag.STATE_DONATION_SLOT_BROKEN) and self.storage.donationBrokenDungeon == Game():GetLevel():GetDungeonPlacementSeed() then
                self.storage.donationBrokenDifferenceChance = 10/3
            else
                self.storage.donationBrokenDifferenceChance = 0
            end

            --摧毁了商店店主：+1/150  +0.66%
            if Game():GetLevel():GetStateFlag(LevelStateFlag.STATE_SHOPKEEPER_KILLED_LVL) then
                self.storage.shopkeeperKilledDifferenceChance = 2/3
            else
                self.storage.shopkeeperKilledDifferenceChance = 0
            end
            
            --向捐款机捐款：每捐赠1枚硬币-1/60   -1.66%，捐赠5枚硬币后达到最大值，总计-1/12   -8.33%
            if Game():GetDonationModAngel() == 0 then  --实时计算捐了多少，可以防rewind
                self.storage.donation = 0
            elseif Game():GetDonationModAngel() > 5 then
                self.storage.donation = 5
            else
                self.storage.donation = Game():GetDonationModAngel()
            end
            self.storage.donationDifferenceChance = 0 - self.storage.donation*5/3
        end
    end

    --计算当前帧 下一层概率
    if self.storage.initialNextGreedChance ~= 0 then

        if Game():GetStateFlag(GameStateFlag.STATE_SUPERGREED_SPAWNED) == true then  --如果已经见过大的
            self.storage.nextGreedChance = 0
        else
            --真正的概率
            self.storage.nextGreedChance = self.storage.initialNextGreedChance + self.storage.coinsDifferenceChance + self.storage.donationBrokenDifferenceChance + self.storage.shopkeeperKilledDifferenceChance + self.storage.donationDifferenceChance
        end

    else
        self.storage.nextGreedChance = self.storage.initialNextGreedChance
    end

    --下一层概率有变化
    if self.storage.nextGreedChance ~= self.storage.nextGreedChanceOld then
        local difference = self.storage.nextGreedChance - self.storage.nextGreedChanceOld  --计算变化

        --判断当前是否有未显示完的变化,如果有，就合并
        if self.storage.changeAlphaNext == nil or self.storage.changeAlphaNext <= 0 then
            self.storage.nextGreedChanceDifference = difference
        else
            self.storage.nextGreedChanceDifference = self.storage.nextGreedChanceDifference + difference
        end

        self.storage.changeAlphaNext = 2.9  --传给显示下一层概率变化用
        self.storage.nextGreedChanceOld = self.storage.nextGreedChance  --存储上一帧 下一层概率
    end


    --计算当前层概率
    if Game():GetStateFlag(GameStateFlag.STATE_SUPERGREED_SPAWNED) == true and self.storage.currentGreedChance ~= 0 then
        self.storage.currentGreedChance = 0
    else

        if Game():GetStateFlag(GameStateFlag.STATE_SUPERGREED_SPAWNED) == true then
            self.storage.currentGreedChance = 0
        else
                --如果当前层见过小的
            if self.storage.meetSmallDungeon == Game():GetLevel():GetDungeonPlacementSeed() and self.storage.currentGreedChance ~= 0 then
                self.storage.currentGreedChance = 0
            end
            --复原见完小贪婪rewind
            if self.storage.beforeMeetSmallCurrentGreedChance > self.storage.currentGreedChance and self.storage.meetSmallDungeon ~= Game():GetLevel():GetDungeonPlacementSeed() then
                self.storage.currentGreedChance = self.storage.beforeMeetSmallCurrentGreedChance
            end
        end

    end

    -----------------------------------------------------------------------------------------------------------------
    --ui位置的变化，借鉴自星象房概率mod
    local updatePos = false  --判断是否需要更新位置，默认不需要
    local updateRib = false  --判断是否需要更新贪婪的肋骨状态

    local activePlayers = Game():GetNumPlayers()  --获取玩家数量

	for p = 1, activePlayers do
		local player = Isaac.GetPlayer(p - 1)
		if player.FrameCount == 0 or DidPlayerCharacterJustChange(player) or DidPlayerDualityCountJustChange(player) then
			updatePos = true
		end
        if DidPlayerRibCountJustChange(player) then
            updateRib = true
        end
	end

    --获取玩家数量变化
    if self.storage.numplayers ~= activePlayers then
		updatePos = true
		self.storage.numplayers = activePlayers
	end

    --获取设置中界面位置更新
    if self.storage.HUDOffset ~= Options.HUDOffset then
		updatePos = true
		self.storage.HUDOffset = Options.HUDOffset
	end

    --检测跑圈
    --Was a Victory Lap Completed, Runs completed on Normal Difficulty Will switch to HARD upon start of a Victory Lap
	if self.storage.VictoryLap ~= Game():GetVictoryLap() then
		updatePos = true
		self.storage.VictoryLap = Game():GetVictoryLap()
	end

    --检测种子导致的禁止成就标志
    --Certain Seed Effects block achievements
	if self.storage.NumSeedEffects ~= Game():GetSeeds():CountSeedEffects() then
		updatePos = true
		self.storage.NumSeedEffects = Game():GetSeeds():CountSeedEffects()
	end

    if updatePos then  --如果需要，调动位置更新函数
		self:updatePosition()
	end
    -----------------------------------------------------------------------------------------------------
    if updateRib then
        local ribShift = false  --有贪婪的肋骨id:98
        for i = 0, Game():GetNumPlayers() - 1 do  --遍历所有玩家
            local player = Isaac.GetPlayer(i)  --获取对应玩家
            local playerType = player:GetPlayerType()  --获取角色标签，用于判断当前是哪个角色
            --如果贪婪的肋骨
            if player:HasTrinket(TrinketType.TRINKET_RIB_OF_GREED) and not ribShift then
                ribShift = true
            end
        end
        self.storage.ribofGreed = ribShift
    end

    if self.storage.ribofGreed then
        self.storage.ribofGreedChance = 0
    else
        self.storage.ribofGreedChance = self.storage.currentGreedChance
    end

    --当前层概率有变化
    if self.storage.ribofGreedChance ~= self.storage.currentGreedChanceOld then
        local difference = self.storage.ribofGreedChance - self.storage.currentGreedChanceOld  --计算变化

        --判断当前是否有未显示完的变化,如果有，就合并
        if self.storage.changeAlphaCurrent == nil or self.storage.changeAlphaCurrent <= 0 then
            self.storage.currentGreedChanceDifference = difference
        else
            self.storage.currentGreedChanceDifference = self.storage.currentGreedChanceDifference + difference
        end

        self.storage.changeAlphaCurrent = 2.9  --传给显示当前层概率变化用
        self.storage.currentGreedChanceOld = self.storage.ribofGreedChance
    end
end

--更新位置。借鉴自星象房概率mod
function mod:updatePosition()
	local TrueCoopShift = false  --我理解的是：检测是否处于真合作模式
	local BombShift = false
	local PoopShift = false  --有里蓝人，大便计数器
	local RedHeartShift = false  --有里伯，红心计数器
	local SoulHeartShift = false  --有表伯，魂心计数器
	local DualityShift = false  --有二元性id:498，天使恶魔概率合为一体

	local ShiftCount = 0  --一共多几行
    if FontRenderSettings ~= nil then  --FontRenderSettings是忏悔+新增的类，检测这个类是否为空就能知道忏悔+是否开启
        self.initialVector = Vector(21, 181)  --真正的设定初始位置
    else
        self.initialVector = Vector(21, 179)  --忏悔版本ui会往上两个像素
    end


	for i = 0, Game():GetNumPlayers() - 1 do  --遍历所有玩家
		local player = Isaac.GetPlayer(i)  --获取对应玩家
		local playerType = player:GetPlayerType()  --获取角色标签，用于判断当前是哪个角色
        --只检测有效玩家，合作模式宝宝不算数
		if player:GetBabySkin() == -1 then
            --如果存在第二个人，并且没有父实体（说明不是合作模式宝宝），并且角色标签等于该角色的主玩家/主形态标签（是本体），说明是真合作模式
			if i > 0 and player.Parent == nil and playerType == player:GetMainTwin():GetPlayerType() and not TrueCoopShift then
				TrueCoopShift = true
			end
            --如果是里蓝人。这边放在真合作里面，是因为真合作的话，会同时显示炸弹计数器和大便计数器。可如果所有人都是里蓝人呢，会出错吗？待测试
			if playerType ~= PlayerType.PLAYER_BLUEBABY_B and not BombShift then -- Shift Stats because of Bomb Counter
				BombShift = true
			end
		end
        --如果是里蓝人，存在大便计数器
		if playerType == PlayerType.PLAYER_BLUEBABY_B and not PoopShift then -- Shift Stats because of Poop Spell Counter
			PoopShift = true
		end
        --如果是里伯，存在红心计数器
		if playerType == PlayerType.PLAYER_BETHANY_B and not RedHeartShift then -- Shifts Stats because of Red Heart Counter
			RedHeartShift = true
		end
        --如果是表伯，存在魂心计数器
		if playerType == PlayerType.PLAYER_BETHANY and not SoulHeartShift then -- Shifts Stats because of Soul Heart Counter
			SoulHeartShift = true
		end
        --如果有二元性，天使恶魔概率合为一体
		if player:HasCollectible(CollectibleType.COLLECTIBLE_DUALITY) and not DualityShift then -- Shifts Stats because of Duality
			DualityShift = true
		end
	end

	if BombShift then
		ShiftCount = ShiftCount + 1
	end
	if PoopShift then
		ShiftCount = ShiftCount + 1
	end
	if RedHeartShift then
		ShiftCount = ShiftCount + 1
	end
	if SoulHeartShift then
		ShiftCount = ShiftCount + 1
	end

    --炸弹和大便至少会有一个
	ShiftCount = ShiftCount - 1 -- There will always be 1 ShiftCount due to bombs and poop, so its safe to do this

    --一共多几行
	if ShiftCount > 0 then
		self.initialVector = self.initialVector + Vector(0, (11 * ShiftCount) - 2)
	end

    --确认雅各是一号位玩家。原因未知，For some reason并不知道是哪些reason
	--For some reason whether or not Jacob&Esau are 1st player or another player matters, so I have to check specifically if Jacob is player 1 here
	if Isaac.GetPlayer(0):GetPlayerType() == PlayerType.PLAYER_JACOB then
		self.initialVector = self.initialVector + Vector(0, 30)
	elseif TrueCoopShift then
		self.initialVector = self.initialVector + Vector(0, 16)
		if DualityShift then
			self.initialVector = self.initialVector + Vector(0, -2) -- I hate this(没搞懂，星象房概率mod作者为什么要加一句：我讨厌这个)
		end
	end

    --如果有二元性
	if DualityShift then
		self.initialVector = self.initialVector + Vector(0, -12)
	end

    --如果是困难/贪婪模式，或者因为种子/挑战导致有禁成就图标，或者DR有目的地标识（为什么会判断dr？）
	-- Checks if Hard Mode and Seeded/Challenge/Daily; Seeded/Challenge have no achievements logo, and Daily Challenge has destination logo.
	if Game().Difficulty == Difficulty.DIFFICULTY_HARD or Game():IsGreedMode() or not CanRunUnlockAchievements() then
		self.initialVector = self.initialVector + Vector(0, 16)
	end

    --根据设置中的界面位置，来更新位置
    self.initialVector = self.initialVector + (Options.HUDOffset * Vector(20, 12))
end

--每次游戏渲染后调用（每秒60次）
function mod:tellMe()
    if mod:shouldHide() then  --如果需要关闭显示概率，那就停止渲染
        return
    end
    mod:updateCheck()  --检查是否需要更新

    -------------------------------------------------------
    --控制位置----------------------------------------------
    local spriteVector  --初始化当前层概率坐标
    local spriteVectorShowNext  --初始化下一层概率坐标
    local isCurrentOn = self.storage.MCMCurrentChance  --当前层概率是否开启
    local isNextOn = self.storage.MCMNextChance  --下一层概率是否开启
    if PlanetariumChance or REPENTOGON then  --判断星象房概率mod是否开启
        --如果开了
        spriteVector = Vector(self.initialVector.X-21, self.initialVector.Y)
        if self.storage.MCMLocationDown then
            spriteVector.Y = self.initialVector.Y + 12
        end
        spriteVectorShowNext = Vector(self.initialVector.X-21, self.initialVector.Y)
        if isCurrentOn then
            spriteVectorShowNext.Y = self.initialVector.Y + 13
            if self.storage.MCMLocationDown then
                spriteVectorShowNext.Y = self.initialVector.Y + 25
            end
        else
            spriteVectorShowNext.Y = self.initialVector.Y + 1
            if self.storage.MCMLocationDown then
                spriteVectorShowNext.Y = self.initialVector.Y + 13
            end
        end
    else
        --如果没开
        spriteVector = Vector(self.initialVector.X-21, self.initialVector.Y-12)
        if self.storage.MCMLocationDown then
            spriteVector.Y = self.initialVector.Y
        end
        spriteVectorShowNext = Vector(self.initialVector.X-21, self.initialVector.Y-12)
        if isCurrentOn then
            spriteVectorShowNext.Y = self.initialVector.Y + 1
            if self.storage.MCMLocationDown then
                spriteVectorShowNext.Y = self.initialVector.Y + 13
            end
        else
            spriteVectorShowNext.Y = self.initialVector.Y - 11
            if self.storage.MCMLocationDown then
                spriteVectorShowNext.Y = self.initialVector.Y + 1
            end
        end
    end
    --控制位置----------------------------------------------
    -------------------------------------------------------

    --手动补色
    local myKColor = KColor(1, 1, 1, 0.5)  --默认颜色
    if self.storage.MCMColor then  --如果开启手动补色
        local level = Game():GetLevel():GetStage() --获取当前LevelStage
        local StageType = Game():GetLevel():GetStageType()  --获取当前StageType
        if level == 1 or level == 2 then
            if StageType == 2 then  --燃烧地下室 
                myKColor = KColor(0.8, 1, 1, 0.4)
            end
            if StageType == 4 then  --下水道
                myKColor = KColor(1, 1, 0.8, 0.4)
            end
            if StageType == 5 then  --污水井
                myKColor = KColor(1, 0.9, 1, 0.5)
            end
        end
        if level == 3 or level == 4 then
            if StageType == 2 then  --淹水洞穴
                myKColor = KColor(1, 1, 0.8, 0.5)
            end
            if StageType == 4 then  --矿洞
                myKColor = KColor(0.9, 0.9, 1, 0.4)
            end
            if StageType == 5 then  --灰坑
                myKColor = KColor(0.9, 0.9, 1, 0.4)
            end
        end
        if level == 5 or level == 6 then
            if StageType == 2 then  --阴湿深牢
                myKColor = KColor(1, 1, 0.8, 0.4)
            end
            if StageType == 4 then  --陵墓
                myKColor = KColor(0.9, 1, 0.9, 0.45)
            end
            if StageType == 5 then  --炼狱
                myKColor = KColor(0.7, 1, 1, 0.45)
            end
        end
        if level == 7 or level == 8 then
            if StageType == 4 then  --尸宫
                myKColor = KColor(1, 0.9, 1, 0.45)
            end
        end
    end

    --绘制图标
    if isCurrentOn then
        self.mySprite:Render(spriteVector, Vector(0,0), Vector(0,0))   --(横轴,纵轴)
    end
    if isNextOn then
        self.mySpriteShowNext:Render(spriteVectorShowNext, Vector(0,0), Vector(0,0))
    end
    --绘制文字
    local initialTextVector = self.initialVector + Game().ScreenShakeOffset --初始化文字坐标，.ScreenShakeOffset是屏幕偏移量，是在boos攻击或者某些震动特效的时候让文字一起动。加的1是为了让数字跟上一层的数字隔开11个像素点而不是10个
    local currentText --存储当前层概率需要输出的数字
    local currentTextVector = Vector(initialTextVector.X-5, spriteVector.Y+2)
    if self.storage.ribofGreedChance ~= nil then  --如果调用DrawString函数时 String 或 RenderColor 参数为 nil，游戏会崩溃.
        currentText = string.format("%.1f%%", self.storage.ribofGreedChance) --保留一位小数
        if isCurrentOn then
            self.myFont:DrawString(currentText, currentTextVector.X, currentTextVector.Y, myKColor, 0, true)
        end
        -- self.myFont:DrawString(currentText, currentTextVector.X, currentTextVector.Y, KColor(1, 1, 1, 0.5), 0, true)
    end
    local nextText  --存储下一层预测概率需要输出的数字
    local textVectorShowNext = Vector(initialTextVector.X-5, spriteVectorShowNext.Y+1)
    if self.storage.nextGreedChance ~= nil then
        nextText = string.format("%.1f%%", self.storage.nextGreedChance)
        if isNextOn then
            self.myFontShowNext:DrawString(nextText, textVectorShowNext.X, textVectorShowNext.Y, myKColor, 0, true)
        end
    end

    --显示当前 当前层概率的变化。借鉴自星象房概率mod
    if self.storage.changeAlphaCurrent and self.storage.changeAlphaCurrent > 0 then
        local alpha = self.storage.changeAlphaCurrent
        if self.storage.changeAlphaCurrent > 0.5 then
			alpha = 0.5
		end
		local difference = self.storage.currentGreedChanceDifference
		local differenceOutput = string.format("%.1f%%", difference)
		local slide = TextAcceleration((2.9 - self.storage.changeAlphaCurrent) / (2 * 0.01))
        if isCurrentOn then
            if difference > 0 then --positive difference
                self.myFont:DrawString("+" .. differenceOutput, currentTextVector.X + 30 + slide, currentTextVector.Y, KColor(0, 1, 0, alpha), 0, true)
            elseif difference < 0 then --negative difference
                self.myFont:DrawString(differenceOutput, currentTextVector.X + 30 + slide, currentTextVector.Y, KColor(1, 0, 0, alpha), 0, true)
            end
        end
		self.storage.changeAlphaCurrent = self.storage.changeAlphaCurrent - 0.01
    end

    --显示当前 下一层预测概率的变化。借鉴自星象房概率mod
    if self.storage.changeAlphaNext and self.storage.changeAlphaNext > 0 then
        local alpha = self.storage.changeAlphaNext
        if self.storage.changeAlphaNext > 0.5 then
			alpha = 0.5
		end
		local difference = self.storage.nextGreedChanceDifference
		local differenceOutput = string.format("%.1f%%", difference)
		local slide = TextAcceleration((2.9 - self.storage.changeAlphaNext) / (2 * 0.01))
        if isNextOn then
            if difference > 0 then --positive difference
                self.myFont:DrawString("+" .. differenceOutput, textVectorShowNext.X + 30 + slide, textVectorShowNext.Y, KColor(0, 1, 0, alpha), 0, true)
            elseif difference < 0 then --negative difference
                self.myFont:DrawString(differenceOutput, textVectorShowNext.X + 30 + slide, textVectorShowNext.Y, KColor(1, 0, 0, alpha), 0, true)
            end
        end
		self.storage.changeAlphaNext = self.storage.changeAlphaNext - 0.01
    end

    --测试代码
    -- --穿裤头
    local player = Isaac.GetPlayer(0)
    local renderpos = Isaac.WorldToRenderPosition(player.Position)
    -- self.testSprite:Render(Vector(renderpos.X - 8,renderpos.Y - 8), Vector(0,0), Vector(0,0))  --恶魔房标志
    if self.storage.MCMRainbowGlasses then      --戴眼镜并彩虹变色
        self.storage.hslH = (self.storage.hslH + 1) % 360  --括号里后面加的数字是变色的步长，越大越快
        local r, g, b = rainbow(self.storage.hslH)
        self.testSprite2.Color = Color(r, g, b, 0.5)
        self.testSprite2:Render(Vector(renderpos.X - 16,renderpos.Y - 25), Vector(0,0), Vector(0,0))  --两个眼镜
        self.testSprite2:Render(Vector(renderpos.X ,renderpos.Y - 25), Vector(0,0), Vector(0,0))
    end
    if self.storage.MCMShowNumber then  --显示当前层到底会不会出，以及哪里出
        local shopText
        local secretText
        local shopVector = Vector(initialTextVector.X-5, initialTextVector.Y+26)
        local secretVector = Vector(initialTextVector.X-5, initialTextVector.Y+38)
        if self.storage.shopGreedNumber ~= nil then
            shopText = string.format("%d", self.storage.shopGreedNumber)
            self.shopNumberFont:DrawString(shopText, shopVector.X, shopVector.Y, KColor(1, 1, 1, 0.5), 0, true)
        end
        if self.storage.secretGreedNumber ~= nil then
            secretText = string.format("%d", self.storage.secretGreedNumber)
            self.secretNumberFont:DrawString(secretText, secretVector.X, secretVector.Y, KColor(1, 1, 1, 0.5), 0, true)
        end
    end

    -- print(Game():GetLevel():GetStageType())
end

--进入对局的时候触发，为真表示继续，为假表示新对局
function mod:initialize(bool)

    if bool == true then
        if mod:HasData() then
            self.storage = json.decode(mod:LoadData())
        end
    else
        mod:initStore()
    end

    self:updatePosition()

end

--对局退出的时候运行
function mod:exit()
    --存储当前storage的数据
    local jsonString = json.encode(mod.storage)
    mod:SaveData(jsonString)

	if mod:shouldHide() then return end  --不知道干嘛的，星象房概率mod加了，我也加一手
end

--初始化各种数据
function mod:initStore()
	self.storage = {}

    self.storage.initialCurrentGreedChance = 0  --当前层初始出贪婪概率为0
    self.storage.currentGreedChance = 0  --当前层贪婪概率，初始化为0
    self.storage.currentGreedChanceOld = 0  --当前层贪婪概率的上一刻的值，初始化为0
    self.storage.currentGreedChanceDifference = 0  --当前层贪婪概率的变化，初始化为0
    self.storage.changeAlphaCurrent = 0  --当前层概率变化的判断，初始化为0

    self.storage.initialNextGreedChance = 0  --下一层初始出贪婪概率为0
    self.storage.nextGreedChance = 0  --下一层预测概率，初始为0
    self.storage.nextGreedChanceOld = 0  --下一层预测概率的上一刻的值，初始化为0
    self.storage.nextGreedChanceDifference = 0  --下一层预测概率的变化，初始化为0
    self.storage.changeAlphaNext = 0  --下一层概率变化的判断，初始化为0

    self.storage.lastCurrentGreedChance = 0  --上一层的当前层贪婪概率，用于防下层瞬间rewind，初始化为0
    self.storage.beforeMeetSmallCurrentGreedChance = 0  --当前层见过小贪婪之前的概率，用于防见过小贪婪之后立刻rewind，初始化为0
    self.storage.beforeMeetBigCurrentGreedChance = 0  --当前层见过大贪婪之前的概率，用于防见过大贪婪之后立刻rewind，初始化为0
    self.storage.lastDungeon = 1  --上一层的夹层种子，初始化为1
    self.storage.currentDungeon = 2  --当前层的夹层种子，初始化为2
    self.storage.donationBrokenDungeon = 0  --摧毁存款机的那一层的夹层种子，初始化为0
    self.storage.meetSmallDungeon = 0  --见过小贪婪的那一层的夹层种子，初始化为0

    self.storage.coinsDifferenceChance = 0  --身上的钱导致的概率的变化，初始化为0
    self.storage.donationBrokenDifferenceChance = 0  --摧毁存款机导致的概率的变化，初始化为0
    self.storage.shopkeeperKilledDifferenceChance = 0  --摧毁商店店主导致的概率的变化，初始化为0
    self.storage.donationDifferenceChance = 0  --捐款导致的概率的变化，初始化为0

    self.storage.preAscentGreedChance = 0  --提前单独存放预回溯的陵墓2的概率

    self.storage.donation = 0  --当前层捐了多少钱，初始化为0

    self.storage.ribofGreed = false  --是否有贪婪的肋骨的效果
    self.storage.ribofGreedChance = 0  --被贪婪的肋骨影响后的当前层真正概率

    --配置文件
    self.storage.MCMCurrentChance = true  --默认开启  当前层概率
    self.storage.MCMNextChance = true  --默认开启  下一层概率
    self.storage.MCMLocationDown = false  --默认关闭  概率显示往下挪一格
    self.storage.MCMShowNumber = false  --默认关闭  显示贪婪数量
    self.storage.MCMRainbowGlasses = false  --默认关闭  戴上彩虹眼镜
    self.storage.MCMColor = false  --默认关闭，手动补色


	self.initialVector = Vector(21, 197.5) + (Options.HUDOffset * Vector(20, 12)) --初始化坐标。真正影响全局的在updatePosition里

    self.mySprite = Sprite() --初始化当前层概率图标
    self.mySprite:Load("gfx/ui/greed_chance.anm2", true)
    self.mySprite.Color = Color(1, 1, 1, 0.5) --调色，数据来源星象房概率mod  红 绿 蓝 透明度
    self.mySprite:SetFrame("Idle", 10) --调用第十帧，即所绘代表贪婪的图标
    self.mySpriteShowNext = Sprite()  --初始化下一层预测概率图标
    self.mySpriteShowNext:Load("gfx/ui/greed_chance.anm2", true)
    self.mySpriteShowNext.Color = Color(1, 1, 1, 0.5) --调色，数据来源星象房概率mod  红 绿 蓝 透明度
    self.mySpriteShowNext:SetFrame("Idle", 16) --调用第十六帧，即所绘代表下一层预测贪婪的图标，会在当前层实时变化

    self.myFont = Font() --初始化文字
    self.myFont:Load("font/luaminioutlined.fnt") --调用原版的这个字库
    self.myFontShowNext = Font()
    self.myFontShowNext:Load("font/luaminioutlined.fnt")


    
    if (ModConfigMenu) and mod:HasData() then
        local jsonString = mod:LoadData()
        local fullData = json.decode(jsonString)
        if fullData.MCMCurrentChance ~= nil then
            self.storage.MCMCurrentChance = fullData.MCMCurrentChance
        end
        if fullData.MCMNextChance ~= nil then
            self.storage.MCMNextChance = fullData.MCMNextChance
        end
        if fullData.MCMShowNumber ~= nil then
            self.storage.MCMShowNumber = fullData.MCMShowNumber
        end
        if fullData.MCMRainbowGlasses ~= nil then
            self.storage.MCMRainbowGlasses = fullData.MCMRainbowGlasses
        end
        if fullData.MCMLocationDown then
            self.storage.MCMLocationDown = fullData.MCMLocationDown
        end
        if fullData.MCMColor then
            self.storage.MCMColor = fullData.MCMColor
        end
    end

    --测试玩
    self.testSprite = Sprite()
    self.testSprite:Load("gfx/ui/greed_chance.anm2", true)
    self.testSprite:SetFrame("Idle", 3)  --恶魔房标志
    self.testSprite2 = Sprite()
    self.testSprite2:Load("gfx/ui/greed_chance.anm2", true)
    self.testSprite2.Color = Color(1, 1, 1, 0.5)
    self.testSprite2:SetFrame("Idle", 10)  --眼镜
    self.storage.hslH = 0  --初始化HSL中的H，用于彩虹渐变
    self.storage.shopGreedNumber = 0  --初始化当前层的商店会不会出贪婪
    self.storage.secretGreedNumber = 0  --初始化当前层的隐藏会不会出贪婪，可能有不止一个，不确定
    self.shopNumberFont = Font()  --初始化文字,用来显示数量
    self.shopNumberFont:Load("font/luaminioutlined.fnt")    
    self.secretNumberFont = Font()
    self.secretNumberFont:Load("font/luaminioutlined.fnt")
    self.storage.test = 0
    self.storage.test2 = 0
    self.storage.test3 = 0
    self.storage.lastRibFrame = 0
end

mod:initStore()  --启动游戏加载模组的时候运行一次初始化

--检测身上贪婪的肋骨的变化
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
	local data = player:GetData()
	local currentRibCount = player:HasTrinket(TrinketType.TRINKET_RIB_OF_GREED)
	if data.greedChanceLastRibCount == nil then
		data.greedChanceLastRibCount = currentRibCount
	end
	data.greedChanceDidRibCountJustChange = false
	if data.greedChanceLastRibCount ~= currentRibCount then
		data.greedChanceDidRibCountJustChange = true
	end
	data.greedChanceLastRibCount = currentRibCount
end)

--检测身上二元性的变化。借鉴自星象房概率mod
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
	local data = player:GetData()
	local currentDualityCount = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_DUALITY)
	if not data.greedChanceLastDualityCount then
		data.greedChanceLastDualityCount = currentDualityCount
	end
	data.greedChanceDidDualityCountJustChange = false
	if data.greedChanceLastDualityCount ~= currentDualityCount then
		data.greedChanceDidDualityCountJustChange = true
	end
	data.greedChanceLastDualityCount = currentDualityCount
end)

--检测玩家的变化。借鉴自星象房概率mod
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
	local data = player:GetData()
	local playerType = player:GetPlayerType()
	if not data.greedChanceLastPlayerType then
		data.greedChanceLastPlayerType = playerType
	end
	data.greedChancePlayerTypeJustChanged = false
	if data.greedChanceLastPlayerType ~= playerType then
		data.greedChancePlayerTypeJustChanged = true
	end
	data.greedChanceLastPlayerType = playerType
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,mod.updateText) --完成一个新关卡或者进入新楼层触发
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.initialize) --新游戏开始时初始化
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.exit)  --退出游戏时触发，为什么要加这个不清楚，星象房概率mod加了，我也跟着加一下
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.tellMe) --每次游戏渲染后调用（每秒60次）