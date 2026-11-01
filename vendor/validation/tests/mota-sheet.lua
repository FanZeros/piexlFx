local UI=require("urhox-libs/UI")
local M=require("MotaCatalog")
local Canvas=require("MotaCanvas")
local ticks=0
local times={
 ["lightning/chain-arc"]=0.08,["lightning/arc-origin"]=0.05,["demo/chain-five"]=0.96,
 ["roller/rolling-wheel"]=0.34,["roller/wheel-crush"]=0.12,["demo/roller-run"]=0.9,
 ["critters/snake-head"]=0.4,["critters/snake-body"]=0.4,["critters/snake-tail"]=0.4,
 ["critters/snake-eat"]=0.12,["critters/snake-bite"]=0.12,["demo/snake-run"]=6.1,
 ["impacts/echo-strike"]=0.13,["sky/heaven-smite"]=0.2,["impacts/row-sweep"]=0.15,
 ["impacts/zone-strike"]=0.19,["explosions/screen-nuke"]=0.38,["moves/turret-fire"]=0.03,
 ["projectiles/snipe-shot"]=0.11,["ui/match-three"]=0.1,
}
SubscribeToEvent("Update",function(eventType,eventData)
 HandleUpdate(eventType,eventData);ticks=ticks+1
 if ticks==20 then
  local rows={}
  local cards={}
  for _,entry in ipairs(M.entries) do
   if entry.procedural then
    local canvas=Canvas {width="100%",height=180}
    local playback={source="全部",scrollY=0,time=times[entry.effectId] or 0.71,paused=true,speed=1,checker=false}
    canvas:SetEntry(entry,playback)
    if entry.effectId=="critters/snake-body" then canvas.options_.shape="corner" end
    cards[#cards+1]=UI.Panel {width=286,height=226,padding=6,backgroundColor="#12172A",children={
     UI.Label {text=entry.title,fontSize=11,fontColor="#D9E7EF"},canvas,
     UI.Label {text=entry.effectId,fontSize=8,fontColor="#7D9EB2"},
    }}
   end
  end
  for i=1,#cards,6 do
   local row={};for j=i,math.min(#cards,i+5) do row[#row+1]=cards[j] end
   rows[#rows+1]=UI.Panel {flexDirection="row",gap=6,children=row}
  end
  UI.SetRoot(UI.Panel {width="100%",height="100%",padding=8,gap=6,backgroundColor="#080C19",children=rows},true)
 end
end)
