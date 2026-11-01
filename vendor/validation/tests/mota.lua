local UI=require("urhox-libs/UI")
local M=require("MotaCatalog")
local Canvas=require("MotaCanvas")
local P=require("MotaPrimitives")
local Units=require("MotaUnits")
local Demos=require("MotaDemos")
local ticks=0
local function Find(w,key,value)
    if w.props[key]==value then return w end
    for _,child in ipairs(w:GetChildren()) do local r=Find(child,key,value);if r then return r end end
end
local function FirstCanvas(w)
    if w.playback_ then return w end
    for _,child in ipairs(w:GetChildren()) do local r=FirstCanvas(child);if r then return r end end
end
local function Click(text)
    local w=Find(UI.GetRoot(),"text",text);assert(w,"button missing "..text);w.props.onClick(w)
end
local function Checks()
    local vg=UI.GetNVGContext()
    local short=P.Fit({{10,20,30},{50,90,130},{150,190,210},{250,250,255}})
    assert(#short==6 and short[6][1]==250)
    assert(#M.entries==30)
    local original=nvgBeginPath
    local calls=0
    nvgBeginPath=function(ctx) calls=calls+1;original(ctx) end
    for id,d in pairs(M.definitions) do
        assert(d.anchorX>=0 and d.anchorX<d.width and d.anchorY>=0 and d.anchorY<d.height,id.." anchor")
        if not d.loop and d.draw then
            calls=0;M.Draw(id,vg,d.duration,d.options,short)
            assert(calls==0,id.." must be empty at end")
            M.Draw(id,vg,-0.01,d.options,short);assert(calls==0,id.." negative time")
        end
    end
    nvgBeginPath=original
    for dir=0,3 do
        local a,b=Units.SnakePorts("snake-body",{dir=dir,shape="straight"})
        assert((a.x+b.x)==48 and (a.y+b.y)==48,"straight opposing ports")
        for from=0,3 do
            if from~=dir then
                local p,q=Units.SnakePorts("snake-body",{dir=dir,shape="corner",from=from})
                assert(p.x>=0 and p.y>=0 and q.x<=48 and q.y<=48,"port bounds")
            end
        end
    end
    for _,distance in ipairs({-1,0,47.99,48,239.99,240,767.99,768}) do
        local p=Demos.SnakePoint(distance);assert(p.x==p.x and p.y==p.y,"snake sample finite")
        local q=Demos.SnakePoint(distance+768)
        assert(math.abs(p.x-q.x)<0.001 and math.abs(p.y-q.y)<0.001,"route loop")
    end
    print("[魔塔验收] 30条目、短色板、锚点、单次收尾、蛇端口和闭合路径通过")
end
SubscribeToEvent("Update",function(eventType,eventData)
    HandleUpdate(eventType,eventData);ticks=ticks+1
    if ticks==12 then
        Checks()
        local card=UI.GetRoot():FindById("mota-lightning/chain-arc");assert(card);card:OnClick()
    elseif ticks==22 then
        local modal=UI.GetOverlayStack()[1];assert(modal)
        local canvas=FirstCanvas(modal.contentContainer_)
        canvas.playback_.time=10;canvas:Replay();assert(canvas.timeOffset_==10)
        HandleKeyDown("KeyDown",{GetInt=function() return KEY_R end})
        assert(canvas.timeOffset_==0 and canvas.playback_.time==0)
        local length=Find(modal.contentContainer_,"text","长度 48px");assert(length)
        length.props.onClick(length);assert(canvas.options_.length==96)
        local orange=Find(modal.contentContainer_,"text","橙红");orange.props.onClick(orange)
        local clean=Find(modal.contentContainer_,"text","场景/纯特效");clean.props.onClick(clean)
        HandleKeyDown("KeyDown",{GetInt=function() return KEY_SPACE end})
    elseif ticks==23 then
        local modal=UI.GetOverlayStack()[1];assert(modal,"pause must retain modal")
        local canvas=FirstCanvas(modal.contentContainer_)
        assert(canvas.clean_ and canvas.paletteIndex_==2 and canvas.options_.length==96,"retain detail state")
        modal:Close()
        Click("返回战斗精选")
    elseif ticks==35 then
        assert(UI.GetRoot():FindById("chain-lightning"),"old chain retained")
        Click("查看原始73组")
    elseif ticks==45 then
        assert(UI.GetRoot():FindById("pb-fireball-fx"),"originals retained")
        Click("魔塔需求特效")
    elseif ticks==55 then
        Click("P0 核心")
    elseif ticks==65 then
        assert(UI.GetRoot():FindById("mota-demo/snake-run"))
        assert(not UI.GetRoot():FindById("mota-impacts/echo-strike"),"P0 filter")
        local scroll=UI.GetRoot():FindById("gallery-scroll");scroll:OnWheel(0,-8)
        local _,y=scroll:GetScroll();assert(y>0,"scroll")
        Click("P1 高频")
    elseif ticks==75 then
        assert(UI.GetRoot():FindById("mota-explosions/screen-nuke"),"P1 filter")
        Click("P2 状态")
    elseif ticks==85 then
        assert(UI.GetRoot():FindById("mota-status/burning"),"P2 filter")
        print("[魔塔验收] 新页签、筛选、滚动、详情参数/配色/纯特效、暂停重播及旧目录保留通过")
    end
end)
