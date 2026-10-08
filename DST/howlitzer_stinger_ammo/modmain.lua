GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
env.STRINGS = GLOBAL.STRINGS

local modid = 'howlitzer_stinger_ammo'
AddPrefabPostInit("stinger", function(inst)
       inst:AddTag("blowpipeammo")
  	inst:AddTag("reloaditem_ammo") -- Action string.

       if not TheWorld.ismastersim then return end  --以下代码仅在服务端运行（这里其实不加这句判断也没事，客户端本就不会接触reloaditem组件。但是加了稳妥一点，不烧心）

       inst:AddComponent("reloaditem")
end)
