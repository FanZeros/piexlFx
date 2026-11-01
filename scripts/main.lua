-- 基于 scaffold-2d.lua 的像素特效浏览器，使用 PixelForge 主题。
local UI = require("urhox-libs/UI")
local Catalog = require("GalleryCatalog")
local EffectCanvas = require("EffectCanvas")

---@class GalleryState : GalleryPlayback
---@field source string
---@field page number
---@type GalleryState
local state = { source = "全部", page = 1, paused = false, speed = 1.0, checker = false, time = 0 }
---@type Panel?
local root = nil
local filtered = {}
local pageSize = 6
local rebuild = false
local lastWidth = 0

local function Label(text, size, color)
    return UI.Label { text = text, fontSize = size or 11, fontColor = color or "#F0F0F0", flexShrink = 1 }
end

local function SetSource(source)
    state.source = source
    state.page = 1
    rebuild = true
    print("[特效画廊] 切换来源：" .. source)
end

local function InitUI()
    local shadow = {
        { x = 3, y = 3, blur = 0, color = { 10, 10, 26, 204 } },
        { x = -1, y = -1, blur = 0, color = { 255, 255, 255, 48 } },
    }
    local theme = UI.Theme.ExtendTheme(UI.Theme.defaultTheme, {
        fonts = {
            { family = "sans", weights = {
                normal = "Fonts/FusionPixel-12px-Prop-zh_hans.ttf",
                bold = "Fonts/FusionPixel-12px-Prop-zh_hans-Bold.ttf",
            } },
            { family = "mono", weights = { normal = "Fonts/FusionPixel-12px-Mono-zh_hans.ttf" } },
        },
        colors = {
            primary = { 33, 189, 174, 255 }, primaryHover = { 61, 208, 193, 255 }, primaryPressed = { 25, 168, 153, 255 },
            secondary = { 108, 92, 231, 255 }, secondaryHover = { 133, 119, 237, 255 }, secondaryPressed = { 90, 75, 214, 255 },
            background = { 15, 15, 35, 255 }, surface = { 27, 27, 58, 255 }, surfaceHover = { 37, 37, 80, 255 },
            text = { 240, 240, 240, 255 }, textSecondary = { 160, 160, 192, 255 }, border = { 58, 58, 106, 255 },
            disabled = { 42, 42, 74, 255 }, disabledText = { 80, 80, 112, 255 },
        },
        componentDefaults = { borderRadius = 0 },
        components = {
            Button = { borderRadius = 0, borderWidth = 2, boxShadow = shadow },
            Card = { borderRadius = 0, borderWidth = 2, boxShadow = { { x = 4, y = 4, blur = 0, color = { 10, 10, 26, 204 } } } },
        },
    })
    UI.Init({ theme = theme, scale = UI.Scale.DEFAULT })
end

local function FilterEntries()
    filtered = {}
    for _, entry in ipairs(Catalog.entries) do
        if state.source == "全部" or state.source == entry.source then
            table.insert(filtered, entry)
        end
    end
end

local function Button(text, fn, active, width)
    return UI.Button {
        text = text, height = 36, width = width, fontSize = 10,
        variant = active and "primary" or "secondary",
        backgroundColor = active and "#168A80" or "#252550",
        onClick = fn,
    }
end

local function ShowDetail(entry)
    if not root then return end
    local modal = UI.Modal { title = entry.title .. " / " .. entry.source, size = "lg" }
    local canvas = EffectCanvas { width = "100%", height = math.min(420, UI.GetHeight() * 0.5) }
    canvas:SetEntry(entry, state)
    modal:AddContent(UI.Panel { gap = 12, children = {
        canvas,
        Label(entry.description or "原项目生成器导出的动画帧。", 11, "#A0A0C0"),
        Label(string.format("%d × %d  |  %d 帧  |  %s", entry.width, entry.height, entry.count, entry.license), 10, "#21BDAE"),
        UI.Label { text = entry.origin, fontSize = 9, fontColor = "#A0A0C0", whiteSpace = "normal" },
    } })
    modal:SetFooter(UI.Panel { flexDirection = "row", justifyContent = "flex-end", children = {
        Button("关闭预览", function() modal:Close() end, true, 120),
    } })
    modal.props.onClose = function() modal:Destroy() end
    root:AddChild(modal)
    modal:Open()
    print("[特效画廊] 放大：" .. entry.id)
end

local function CreateCard(entry, cardWidth, canvasHeight)
    local canvas = EffectCanvas { width = "100%", height = canvasHeight }
    canvas:SetEntry(entry, state)
    return UI.Card {
        width = cardWidth, variant = "outlined", padding = 10, gap = 8, clickable = true,
        backgroundColor = "#16162F", borderColor = "#343459",
        onClick = function() ShowDetail(entry) end,
        children = {
            UI.Panel { flexDirection = "row", justifyContent = "space-between", alignItems = "center", children = {
                Label(entry.title, 12), Label(entry.license, 8, "#21BDAE"),
            } },
            canvas,
            UI.Panel { flexDirection = "row", justifyContent = "space-between", children = {
                Label(entry.source, 9, "#A0A0C0"),
                Label(tostring(entry.count) .. " 帧 · 点击放大", 8, "#74749B"),
            } },
        },
    }
end

local function CreateUI()
    FilterEntries()
    local width = UI.GetWidth()
    lastWidth = width
    local wide = width >= 900
    local side = wide and 205 or 0
    local available = width - 48 - side - (wide and 20 or 0)
    local cols = available >= 900 and 3 or (available >= 480 and 2 or 1)
    pageSize = cols * 2
    local pages = math.max(1, math.ceil(#filtered / pageSize))
    state.page = math.max(1, math.min(state.page, pages))
    local cardWidth = math.floor((available - 16 - (cols - 1) * 14) / cols)
    local canvasHeight = math.max(110, math.min(180, (UI.GetHeight() - 500) / 2))
    local cards = {}
    for i = (state.page - 1) * pageSize + 1, math.min(state.page * pageSize, #filtered) do
        table.insert(cards, CreateCard(filtered[i], cardWidth, canvasHeight))
    end
    local gridRows = {}
    for i = 1, #cards, cols do
        local rowCards = {}
        for j = i, math.min(i + cols - 1, #cards) do table.insert(rowCards, cards[j]) end
        table.insert(gridRows, UI.Panel { width = "100%", flexDirection = "row", gap = 14, children = rowCards })
    end
    local sourceButtons = {}
    table.insert(sourceButtons, Button("全部特效  /  " .. #Catalog.entries, function() SetSource("全部") end, state.source == "全部", wide and "100%" or 155))
    for _, info in ipairs(Catalog.sources) do
        local n = 0
        for _, entry in ipairs(Catalog.entries) do if entry.source == info.name then n = n + 1 end end
        table.insert(sourceButtons, Button(info.name .. "  /  " .. n, function() SetSource(info.name) end, state.source == info.name, wide and "100%" or 155))
    end
    local selectedInfo = "来自真实项目源码的离线导出；点击卡片可放大。"
    for _, info in ipairs(Catalog.sources) do
        if info.name == state.source then selectedInfo = info.note end
    end
    local sidebar = UI.Panel {
        width = wide and side or "100%", flexDirection = wide and "column" or "row",
        flexWrap = wide and "no-wrap" or "wrap", gap = 10,
        children = sourceButtons,
    }
    if wide then
        sidebar:AddChild(UI.Panel { height = 12 })
        sidebar:AddChild(Label("已下载源码", 10, "#21BDAE"))
        sidebar:AddChild(UI.Label { text = "4 个 GitHub 仓库\n25 个 Sprite Fusion 源码包", fontSize = 10, fontColor = "#A0A0C0", whiteSpace = "normal" })
        sidebar:AddChild(UI.Label { text = "原始文件保留在 vendor/，展示使用 assets/Effects/ 中的图集。", fontSize = 9, fontColor = "#74749B", whiteSpace = "normal" })
        sidebar:AddChild(UI.Label { text = "PixelSpace 为静态背景；其余按原生成器或原场景采样。", fontSize = 9, fontColor = "#74749B", whiteSpace = "normal" })
    end
    local content = UI.Panel { flexGrow = 1, flexBasis = 0, minWidth = 0, gap = 12, children = {
        UI.Panel { flexDirection = "row", alignItems = "center", gap = 12, children = {
            Label(state.source == "全部" and "特效总览" or state.source, 16, "#F0F0F0"),
            Label(tostring(#filtered) .. " 组", 10, "#21BDAE"),
        } },
        UI.Label { text = selectedInfo, fontSize = 10, fontColor = "#A0A0C0", whiteSpace = "normal" },
        UI.ScrollView { flexGrow = 1, flexBasis = 0, children = {
            UI.Panel { width = "100%", gap = 14, paddingBottom = 8, children = gridRows },
        } },
        UI.Panel { height = 42, flexDirection = "row", justifyContent = "space-between", alignItems = "center", children = {
            Label(string.format("%02d / %02d 页", state.page, pages), 10, "#A0A0C0"),
            UI.Panel { flexDirection = "row", gap = 10, children = {
                Button("上一页", function() state.page = state.page > 1 and state.page - 1 or pages; rebuild = true end, false, 96),
                Button("下一页", function() state.page = state.page < pages and state.page + 1 or 1; rebuild = true end, true, 96),
            } },
        } },
    } }
    root = UI.Panel { width = "100%", height = "100%", backgroundColor = "#0F0F23", children = {
        UI.SafeAreaView { width = "100%", height = "100%", padding = 24, gap = 18, children = {
            UI.Panel { flexDirection = "row", alignItems = "center", justifyContent = "space-between", flexWrap = "wrap", gap = 12, children = {
                UI.Panel { gap = 4, children = {
                    Label("像素特效实验室", 23, "#F0F0F0"),
                    Label("PIXEL FX / OPEN SOURCE SHOWCASE", 9, "#21BDAE"),
                } },
                UI.Panel { flexDirection = "row", gap = 10, flexWrap = "wrap", children = {
                    Button(state.paused and "继续播放" or "暂停播放", function() state.paused = not state.paused; rebuild = true end, false, 100),
                    Button(tostring(state.speed) .. "× 速度", function() state.speed = state.speed == 0.5 and 1 or (state.speed == 1 and 2 or 0.5); rebuild = true end, false, 96),
                    Button(state.checker and "棋盘背景" or "深色背景", function() state.checker = not state.checker; rebuild = true end, false, 100),
                    Button("重新播放", function() state.time = 0 end, true, 100),
                } },
            } },
            UI.Panel { height = 2, backgroundColor = "#343459" },
            UI.Panel { flexGrow = 1, flexBasis = 0, minHeight = 0, flexDirection = wide and "row" or "column", gap = 20, children = { sidebar, content } },
            Label("SPACE 暂停 / 方向键翻页 / 1–5 切换来源 / R 重播", 9, "#74749B"),
        } },
    } }
    UI.SetRoot(root, true)
    print(string.format("[特效画廊] 当前页 %d/%d，显示 %d 个，屏宽 %.0f", state.page, pages, #cards, width))
end

function Start()
    graphics.windowTitle = "像素特效实验室"
    input.mouseMode = MM_ABSOLUTE
    InitUI()
    CreateUI()
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    print("[特效画廊] 启动，已载入 " .. #Catalog.entries .. " 组真实来源素材")
end

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    if not state.paused then state.time = state.time + eventData:GetFloat("TimeStep") * state.speed end
    if math.abs(UI.GetWidth() - lastWidth) > 2 then rebuild = true end
    if rebuild then rebuild = false; CreateUI() end
end

---@param eventType string
---@param eventData KeyDownEventData
function HandleKeyDown(eventType, eventData)
    local key = eventData:GetInt("Key")
    if key == KEY_SPACE then state.paused = not state.paused; rebuild = true end
    if key == KEY_R then state.time = 0 end
    if key == KEY_RIGHT then state.page = state.page + 1; rebuild = true end
    if key == KEY_LEFT then state.page = math.max(1, state.page - 1); rebuild = true end
    local keys = { KEY_1, KEY_2, KEY_3, KEY_4, KEY_5 }
    for i, k in ipairs(keys) do if key == k and Catalog.sources[i] then SetSource(Catalog.sources[i].name) end end
end

function Stop()
    EffectCanvas.ReleaseImages()
    UI.Shutdown()
    root = nil
end
