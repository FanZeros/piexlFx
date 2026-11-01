local UI = require("urhox-libs/UI")
local visited = 0
local function Find(widget, text)
    if widget.props.text == text then return widget end
    for _, child in ipairs(widget:GetChildren()) do
        local result = Find(child, text)
        if result then return result end
    end
end
local sources = {"Sprite Fusion  /  25", "Pixel FX Forge  /  12", "PixelPlanets  /  12", "PixelSpace  /  4"}
local ticks = 0
SubscribeToEvent("Update", function(eventType, eventData)
    HandleUpdate(eventType, eventData)
    ticks = ticks + 1
    if ticks == 15 or ticks == 30 or ticks == 45 or ticks == 60 then
        visited = visited + 1
        local button = Find(UI.GetRoot(), sources[visited])
        assert(button, "source button missing")
        button.props.onClick(button)
        print("[自动验收] 切换来源 " .. sources[visited])
    end
    if ticks == 75 then
        local button = Find(UI.GetRoot(), "Sprite Fusion  /  25")
        button.props.onClick(button)
    end
    if ticks == 90 then
        local root = UI.GetRoot()
        local function FindCard(widget)
            if widget.props.clickable then return widget end
            for _, child in ipairs(widget:GetChildren()) do
                local result = FindCard(child)
                if result then return result end
            end
        end
        local card = FindCard(root)
        assert(card, "card missing")
        card:OnClick()
        assert(#UI.GetOverlayStack() > 0, "detail modal missing")
        print("[自动验收] 点击放大通过")
    end
    if ticks == 105 then
        local stack = UI.GetOverlayStack()
        if #stack > 0 then stack[#stack]:Close() end
        local nextPage = Find(UI.GetRoot(), "下一页")
        nextPage.props.onClick(nextPage)
        print("[自动验收] 翻页通过")
    end
end)
