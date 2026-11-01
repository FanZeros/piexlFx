local UI=require("urhox-libs/UI")
local M=require("MotaCatalog")
local P=require("MotaPrimitives")
local Demos=require("MotaDemos")
local Bench=UI.Widget:Extend("MotaBench")
local ran=false
function Bench:Render(vg)
 if ran then return end
 ran=true
 local worst=0
 local maxId=""
 local ids={}
 for id in pairs(M.definitions) do ids[#ids+1]=id end
 table.sort(ids)
 for _,id in ipairs(ids) do
  local d=M.definitions[id]
  local colors=P.Fit(nil,d.palette)
  local peak=0
  for _,q in ipairs({0,0.1,0.3,0.5,0.8}) do
   local function Draw()
    if d.draw then M.Draw(id,vg,q*d.duration,d.options,colors)
    else Demos.Draw(id,vg,q*d.duration,d.options,colors,true) end
   end
   for i=1,3 do Draw() end
   local values={}
   for round=1,3 do
    local start=os.clock()*1000
    for i=1,8 do Draw() end
    values[#values+1]=(os.clock()*1000-start)/8
   end
   table.sort(values)
   peak=math.max(peak,values[2])
  end
  print(string.format("[魔塔绘制基准] %s peak-batch-average=%.3fms",id,peak))
  if peak>worst then worst=peak;maxId=id end
 end
 print(string.format("[魔塔绘制基准] worst=%s %.3fms（3轮×8次批量中位数，不含GPU提交）",maxId,worst))
end
local ticks=0
SubscribeToEvent("Update",function(eventType,eventData)
 HandleUpdate(eventType,eventData);ticks=ticks+1
 if ticks==10 then UI.SetRoot(Bench {width="100%",height="100%"},true) end
end)
