local UI = require("urhox-libs/UI")
local Chain = require("ChainLightning")
local ticks = 0
local function Find(widget, id)
    if widget.props.id == id then return widget end
    for _, child in ipairs(widget:GetChildren()) do
        local found = Find(child, id)
        if found then return found end
    end
end
local function Canvas(widget)
    if widget.playback_ then return widget end
    for _, child in ipairs(widget:GetChildren()) do
        local found = Canvas(child)
        if found then return found end
    end
end
local function CheckTargets()
    local origin = { x = 0, y = 0 }
    assert(#Chain.SelectTargets(origin, {}, 5, 3, 5) == 0)
    assert(#Chain.SelectTargets(origin, {{x=0,y=1}}, 5, 3, 5) == 0, "first strike went backwards")
    assert(#Chain.SelectTargets(origin, {{x=0,y=-1}}, 5, 3, 0) == 0)
    local chain = Chain.SelectTargets(origin, {
        {x=0,y=-2}, {x=0,y=-4}, {x=0,y=-6},
        {x=0,y=-8,alive=false}, {x=50,y=-8},
    }, 2, 2, 5)
    assert(#chain == 3 and chain[1] == 1 and chain[2] == 2 and chain[3] == 3, "range/dead/no-repeat selection failed")
    local tied = Chain.SelectTargets(origin, {{x=-1,y=-1},{x=1,y=-1}}, 5, 5, 1)
    assert(#tied == 1 and tied[1] == 1, "tie ordering failed")
    local overlap = Chain.SelectTargets(origin, {{x=0,y=-1},{x=0,y=-1}}, 2, 0, 5)
    assert(#overlap == 2, "overlapping targets failed")
    print("[闪电链验收] 空目标、前向、最大数量、半径边界、死亡过滤、超距、等距和不重复通过")
end
SubscribeToEvent("Update", function(eventType, eventData)
    HandleUpdate(eventType, eventData)
    ticks = ticks + 1
    if ticks == 10 then
        CheckTargets()
        local card = Find(UI.GetRoot(), "chain-lightning")
        assert(card, "chain lightning card missing")
        card:OnClick()
        assert(#UI.GetOverlayStack() > 0, "detail missing")
    elseif ticks == 22 then
        local stack = UI.GetOverlayStack()
        stack[#stack]:Close()
        local card = Find(UI.GetRoot(), "chain-lightning")
        local canvas = Canvas(card)
        canvas.playback_.paused = true
        canvas.playback_.time = 0.48
        print("[闪电链验收] 实时卡片与详情通过，固定在五目标连锁时刻")
    end
end)
