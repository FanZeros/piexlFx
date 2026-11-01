local UI=require("urhox-libs/UI")
local M=require("MotaCatalog")
local P=require("MotaPrimitives")
local Stress=UI.Widget:Extend("MotaStress")
local ids={"impacts/echo-strike","status/burning","status/poisoned","status/stunned","status/marked","status/buff-charge","moves/turret-fire","lightning/chain-arc"}
local colors={}
for _,id in ipairs(ids) do colors[id]=P.Fit(nil,M.definitions[id].palette) end
local frames=0
function Stress:Render(vg)
 for i=1,16 do
  local id=ids[(i-1)%#ids+1]
  local d=M.definitions[id]
  local t=0.11+(frames%16)/30
  if d.loop then t=t%d.duration else t=t%(d.duration+0.2) end
  nvgSave(vg);nvgTranslate(vg,20+(i-1)%4*160,40+math.floor((i-1)/4)*160)
  M.Draw(id,vg,t,d.options,colors[id])
  nvgRestore(vg)
 end
 frames=frames+1
 if frames==90 then print("[魔塔压力验收] 16个程序化效果同屏，90帧无运行错误；不等同目标设备帧率保证") end
end
local ticks=0
SubscribeToEvent("Update",function(eventType,eventData)
 HandleUpdate(eventType,eventData);ticks=ticks+1
 if ticks==10 then UI.SetRoot(Stress {width="100%",height="100%"},true) end
end)
