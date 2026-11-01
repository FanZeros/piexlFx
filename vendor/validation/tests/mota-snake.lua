local UI=require("urhox-libs/UI")
local Units=require("MotaUnits")
local P=require("MotaPrimitives")
local M=require("MotaCatalog")
local Canvas=require("MotaCanvas")
local ticks=0
local Test=UI.Widget:Extend("SnakeJoinTest")
function Test:Render(vg)
 local c=P.Fit(nil,"leaf")
 local l=self:GetAbsoluteLayout()
 nvgSave(vg);nvgTranslate(vg,l.x+10,l.y+10);nvgScale(vg,2,2)
 for group=0,3 do
  nvgSave(vg);nvgTranslate(vg,group%2*192+72,math.floor(group/2)*192+72)
  nvgRotate(vg,group*math.pi/2);nvgTranslate(vg,-72,-48)
  local cells={
   {x=0,y=48,part="snake-tail",dir=0},
   {x=48,y=48,part="snake-body",dir=0},
   {x=96,y=48,part="snake-body",dir=3,shape="corner",from=2},
   {x=96,y=0,part="snake-head",dir=3},
  }
  for _,cell in ipairs(cells) do
   nvgSave(vg);nvgTranslate(vg,cell.x,cell.y)
   Units.Snake(vg,0.35,{dir=cell.dir,shape=cell.shape,from=cell.from},c,cell.part)
   nvgRestore(vg)
  end
  nvgRestore(vg)
 end
 nvgRestore(vg)
end
SubscribeToEvent("Update",function(eventType,eventData)
 HandleUpdate(eventType,eventData);ticks=ticks+1
 if ticks==15 then
  local body
  for _,entry in ipairs(M.entries) do if entry.effectId=="critters/snake-body" then body=entry end end
  local canvas=Canvas {}
  canvas:SetEntry(body,{source="全部",scrollY=0,time=0,paused=true,speed=1,checker=false})
  local states={}
  for i=1,12 do canvas:ChangeVariant();local o=canvas.options_;states[o.dir..":"..o.shape..":"..o.from]=true end
  local count=0;for _ in pairs(states) do count=count+1 end;assert(count==12,"12 body variants")
  UI.SetRoot(Test {width="100%",height="100%"},true)
  print("[蛇模块验收] 12种方向/入口/形态状态可访问")
 end
end)
