local UI = require("urhox-libs/UI")
local Battle = require("BattleCatalog")
local ticks = 0
local function Find(widget, text)
    if widget.props.text == text then return widget end
    for _, child in ipairs(widget:GetChildren()) do
        local found = Find(child, text)
        if found then return found end
    end
end
local function Click(text)
    local button = Find(UI.GetRoot(), text)
    assert(button, "button missing: " .. text)
    button.props.onClick(button)
end
local function CountCards(widget)
    local count = widget.props.clickable and 1 or 0
    for _, child in ipairs(widget:GetChildren()) do count = count + CountCards(child) end
    return count
end
local function Scroll()
    local view = UI.GetRoot():FindById("gallery-scroll") --[[@as ScrollView?]]
    assert(view)
    return view
end
local function Canvas(widget)
    if widget.entry_ then return widget end
    for _, child in ipairs(widget:GetChildren()) do
        local found = Canvas(child)
        if found then return found end
    end
end
local savedY = 0
SubscribeToEvent("Update", function(eventType, eventData)
    HandleUpdate(eventType, eventData)
    ticks = ticks + 1
    if ticks == 12 then
        assert(#Battle.entries == 25)
        assert(CountCards(UI.GetRoot()) == 25, "default battle list failed")
        assert(not Find(UI.GetRoot(), "下一页"), "pagination remains")
        local height = Scroll():GetLayout().h
        assert(height > 100, "portrait scroll viewport too small")
        Scroll():OnWheel(0, -8)
        local _, y = Scroll():GetScroll()
        assert(y > 0, "wheel failed")
        savedY = y
        Click("暂停播放")
    elseif ticks == 20 then
        local _, y = Scroll():GetScroll()
        assert(math.abs(y - savedY) < 1, "playback reset scroll")
        Click("发射弹道")
    elseif ticks == 28 then
        assert(CountCards(UI.GetRoot()) == 3, "projectile filter failed")
        local fireball = UI.GetRoot():FindById("pb-fireball-fx")
        local canvas = Canvas(fireball)
        assert(canvas.entry_.previewRotation == -90 and canvas.entry_.previewMotion == "up")
        fireball:OnClick()
        assert(#UI.GetOverlayStack() > 0, "detail missing")
    elseif ticks == 36 then
        local stack = UI.GetOverlayStack()
        stack[#stack]:Close()
        Click("命中反馈")
    elseif ticks == 44 then
        assert(CountCards(UI.GetRoot()) == 4, "impact filter failed")
        Click("范围技能")
    elseif ticks == 52 then
        assert(CountCards(UI.GetRoot()) == 9, "area filter failed")
        Click("防御增益")
    elseif ticks == 60 then
        assert(CountCards(UI.GetRoot()) == 9, "buff filter failed")
        Click("全部精选")
        Click("Sprite Fusion  /  11")
    elseif ticks == 68 then
        assert(CountCards(UI.GetRoot()) == 11, "source filter failed")
        Click("查看原始73组")
    elseif ticks == 76 then
        assert(CountCards(UI.GetRoot()) == 73, "original list missing")
        local canvas = Canvas(UI.GetRoot():FindById("pb-fireball-fx"))
        assert(not canvas.entry_.previewRotation and not canvas.entry_.previewMotion, "original modified")
        Click("竖版战斗精选")
    elseif ticks == 85 then
        assert(CountCards(UI.GetRoot()) == 25)
        local canvas = Canvas(UI.GetRoot():FindById("pb-fireball-fx"))
        canvas.playback_.paused = true
        canvas.playback_.time = 0.2
        Scroll():ScrollToTop()
        print("[战斗验收] 默认精选25组、四类筛选、来源筛选、原版73组、滚动、放大全部通过")
    end
end)
