local UI=require("urhox-libs/UI")
local M=require("MotaCatalog")
local Canvas=require("MotaCanvas")
local ticks=0
local groups={
 {id="lightning/chain-arc",times={0,0.033,0.067,0.13,0.24,0.35}},
 {id="roller/rolling-wheel",times={0,0.1,0.2,0.3,1.1667,1.2}},
 {id="roller/wheel-crush",times={0,0.05,0.1,0.18,0.28,0.35}},
 {id="demo/snake-run",times={1.399,1.49,1.58,6.1,10.5,10.65}},
 {id="explosions/screen-nuke",times={0.03,0.15,0.3,0.5,0.75,0.9}},
 {id="pickups/collect-pull",times={0.03,0.15,0.3,0.39,0.45,0.5}},
 {id="shadow/devour",times={0.03,0.13,0.26,0.37,0.48,0.55}},
}
SubscribeToEvent("Update",function(eventType,eventData)
 HandleUpdate(eventType,eventData);ticks=ticks+1
 if ticks==20 then
  local rows={}
  for _,group in ipairs(groups) do
   local cards={}
   for _,t in ipairs(group.times) do
    local entry
    for _,e in ipairs(M.entries) do if e.effectId==group.id then entry=e end end
    local canvas=Canvas {width="100%",height=167}
    canvas:SetEntry(entry,{source="全部",scrollY=0,time=t,paused=true,speed=1,checker=false})
    canvas.clean_=true
    cards[#cards+1]=UI.Panel {width=286,height=205,padding=4,backgroundColor="#12172A",children={
     UI.Label {text=group.id.." · "..string.format("%.3fs",t),fontSize=9,fontColor="#BBD4E2"},canvas,
    }}
   end
   rows[#rows+1]=UI.Panel {flexDirection="row",gap=6,children=cards}
  end
  UI.SetRoot(UI.Panel {width="100%",height="100%",padding=8,gap=6,backgroundColor="#080C19",children=rows},true)
 end
end)
