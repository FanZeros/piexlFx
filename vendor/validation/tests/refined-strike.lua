local UI = require("urhox-libs/UI")
local Chain = require("ChainLightning")
local Art = require("LightningArt")
local ticks = 0
local function Find(widget, key, value)
    if widget.props[key] == value then return widget end
    for _, child in ipairs(widget:GetChildren()) do
        local result = Find(child, key, value)
        if result then return result end
    end
end
local function Canvas(widget)
    if widget.playback_ then return widget end
    for _, child in ipairs(widget:GetChildren()) do
        local result = Canvas(child)
        if result then return result end
    end
end
local function Click(text)
    local modal = UI.GetOverlayStack()[1]
    local result = Find(modal.contentContainer_, "text", text)
    assert(result, text)
    result.props.onClick(result)
end
local function CheckGeometry()
    for _, p in ipairs({{x=0,y=100},{x=100,y=0},{x=80,y=-60},{x=0.1,y=0.1},{x=0,y=0}}) do
        local path=Art.BuildPath({x=0,y=0},p,47)
        assert(path[1].x==0 and path[1].y==0)
        assert(math.abs(path[#path].x-p.x)<1 and math.abs(path[#path].y-p.y)<1)
        for _,point in ipairs(path) do assert(point.x==point.x and point.y==point.y) end
    end
    local elapsed=Chain.HopState(Chain.Config.castTime+Chain.Config.travelTime-0.001,1)
    assert(elapsed<Chain.Config.travelTime,"impact timing boundary")
end
SubscribeToEvent("Update",function(eventType,eventData)
    HandleUpdate(eventType,eventData)
    ticks=ticks+1
    if ticks==10 then
        CheckGeometry()
        local card=Find(UI.GetRoot(),"id","chain-lightning")
        local canvas=Canvas(card)
        local chain=canvas:GetChain(1.19)
        assert(#chain==5)
        local seen={}
        for _,index in ipairs(chain) do assert(not seen[index] and index~=6);seen[index]=true end
        card:OnClick()
    elseif ticks==25 then
        local stack=UI.GetOverlayStack()
        local canvas=Canvas(stack[1].contentContainer_)
        canvas.playback_.paused=true
        canvas.playback_.time=1.19
        Click("紫电秘术");assert(canvas.paletteIndex_==2)
        Click("金色雷击");assert(canvas.paletteIndex_==3)
        Click("冰蓝雷霆");assert(canvas.paletteIndex_==1)
        Click("场景/纯特效");assert(canvas.clean_)
        Click("场景/纯特效");assert(not canvas.clean_)
        canvas:Replay();assert(canvas.timeOffset_==1.19)
        canvas.timeOffset_=0
        canvas.playback_.time=0.67
        canvas:SetPalette(1)
        canvas.clean_=false
        print("[精修验收] 选敌、短距/零距电弧、接触时序、三配色、纯特效、重播通过")
    end
end)
