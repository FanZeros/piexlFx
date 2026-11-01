-- 绘制调用级确定性/范围/循环审计，不伪装成浏览器Canvas check。
local P=require("MotaPrimitives")
local M=require("MotaCatalog")
local Units=require("MotaUnits")
local ran=false
local function Audit()
 local originals={}
 for _,name in ipairs({"nvgBeginPath","nvgRect","nvgFillColor","nvgFill","nvgFillPaint","nvgRadialGradient","nvgMoveTo","nvgLineTo","nvgClosePath","nvgSave","nvgRestore","nvgIntersectScissor"}) do originals[name]=_G[name] end
 local signature={}
 local samples={}
 local opacity=255
 local function Add(x,y,w,h)
  signature[#signature+1]=string.format("%.2f,%.2f,%.2f,%.2f",x,y,w,h)
  samples[#samples+1]={x=x,y=y,w=w,h=h}
 end
 nvgBeginPath=function() end;nvgRect=function(_,x,y,w,h) Add(x,y,w,h) end
 nvgFillColor=function(_,color) end;nvgFill=function() end;nvgFillPaint=function() end
 nvgRadialGradient=function() return 0 end
 nvgSave=function() end;nvgRestore=function() end;nvgIntersectScissor=function() end
 nvgMoveTo=function(_,x,y) Add(x,y,0,0) end;nvgLineTo=nvgMoveTo;nvgClosePath=function() end
 local function Render(id,t,o)
  signature={};samples={}
  local d=M.definitions[id]
  M.Draw(id,{},t,o or d.options,{{10,20,30},{50,90,130},{150,190,210},{250,250,255}})
  return table.concat(signature,"|"),samples
 end
 local spills={}
 for id,d in pairs(M.definitions) do
  if d.draw then
   for frame=0,math.ceil(d.duration*30) do
    local t=math.min(d.duration,frame/30)
    local renderOptions={d.options}
    if id=="lightning/chain-arc" then renderOptions={{length=8},{length=48},{length=96},{length=144}} end
    if id=="sky/heaven-smite" then renderOptions={{area=false},{area=true}} end
    if id=="impacts/zone-strike" then renderOptions={{cells=2},{cells=3}} end
    if id=="roller/rolling-wheel" then renderOptions={{spin=1},{spin=2,reverse=true},{spin=5}} end
    if id=="status/buff-charge" then renderOptions={{level=1},{level=5}} end
    for _,option in ipairs(renderOptions) do
    local a,rects=Render(id,t,option)
    local b=Render(id,t,option)
    assert(a==b,id.." deterministic")
    if not id:find("critters/snake%-") then
     for _,r in ipairs(rects) do
      if r.x<0 or r.y<0 or r.x+r.w>d.width or r.y+r.h>d.height then
       if not spills[id] then print(string.format("[边界样本] %s t=%.3f rect=%.1f,%.1f,%.1f,%.1f canvas=%d,%d",id,t,r.x,r.y,r.w,r.h,d.width,d.height)) end
       spills[id]=true;break
      end
     end
    end
    end
   end
   if d.loop then
    local a=Render(id,0);local b=Render(id,d.duration)
    assert(a==b,id.." exact periodic seam")
   else assert(Render(id,d.duration)=="",id.." empty end") end
  end
 end
 assert(Render("lightning/chain-arc",0.1,{length=0})=="","zero length arc")
 for name,fn in pairs(originals) do _G[name]=fn end
 local count=0
 for id in pairs(spills) do count=count+1;print("[魔塔范围审计] spill "..id) end
 print("[魔塔范围审计] 完成，越界条目="..count)
 assert(count==0,"effect canvas bounds")
end
SubscribeToEvent("Update",function(eventType,eventData)
 HandleUpdate(eventType,eventData)
 if not ran then ran=true;Audit() end
end)
