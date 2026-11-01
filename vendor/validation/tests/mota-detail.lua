local UI=require("urhox-libs/UI")
local ticks=0
local function Find(w,text)
 if w.props.text==text then return w end
 for _,child in ipairs(w:GetChildren()) do local r=Find(child,text);if r then return r end end
end
SubscribeToEvent("Update",function(eventType,eventData)
 HandleUpdate(eventType,eventData);ticks=ticks+1
 if ticks==10 then
  UI.GetRoot():FindById("mota-roller/rolling-wheel"):OnClick()
 elseif ticks==20 then
  local modal=UI.GetOverlayStack()[1];assert(modal)
  local button=Find(modal.contentContainer_,"滚动 →");button.props.onClick(button)
  local root=UI.GetRoot()
  Find(root,"1.0× 速度").props.onClick()
 elseif ticks==21 then
  assert(#UI.GetOverlayStack()==0,"rebuild closes and removes old overlay")
  UI.GetRoot():FindById("mota-critters/snake-body"):OnClick()
 elseif ticks==30 then
  local modal=UI.GetOverlayStack()[1];assert(modal)
  for _,w in ipairs(modal.contentContainer_:GetChildren()) do
   if w.playback_ then w.playback_.paused=true;w.playback_.time=0.4 end
   for _,child in ipairs(w:GetChildren()) do
    if child.playback_ then child.playback_.paused=true;child.playback_.time=0.4;child.options_.shape="corner" end
   end
  end
  print("[魔塔详情验收] 重建前清空overlay，详情重新打开可用")
 end
end)
