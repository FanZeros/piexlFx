-- 基于 scaffold-2d.lua 的像素特效浏览器，使用 PixelForge 主题。
local UI = require("urhox-libs/UI")
local Catalog = require("GalleryCatalog")
local Battle = require("BattleCatalog")
local EffectCanvas = require("EffectCanvas")
local ChainLightning = require("ChainLightning")
local Mota = require("MotaCatalog")
local MotaCanvas = require("MotaCanvas")

---@class GalleryState : GalleryPlayback
---@field source string
---@field scrollY number
---@field battle boolean
---@field group string
---@field mota boolean
---@type GalleryState
local state = { source = "全部", scrollY = 0, paused = false, speed = 1.0, checker = false, time = 0, battle = true, group = "全部需求", mota = true }
---@type Panel?
local root = nil
---@type ScrollView?
local galleryScroll = nil
---@type Button?
local pauseButton = nil
---@type ChainLightning|MotaCanvas|nil
local detailLightning = nil
local filtered = {}
local rebuild = false
local restoreScroll = false
local lastWidth = 0
local lastHeight = 0

local function Label(text, size, color)
    return UI.Label { text = text, fontSize = size or 11, fontColor = color or "#F0F0F0", flexShrink = 1 }
end

local function SetSource(source)
    state.source = source
    state.scrollY = 0
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

local function CurrentEntries()
    return state.mota and Mota.entries or (state.battle and Battle.entries or Catalog.entries)
end

local function FilterEntries()
    filtered = {}
    local entries = CurrentEntries()
    for _, entry in ipairs(entries) do
        local matchesSource = state.source == "全部" or state.source == entry.source
        local matchesGroup = state.mota and (state.group == "全部需求" or state.group == entry.battleGroup)
            or (not state.mota and (not state.battle or state.group == "全部精选" or state.group == entry.battleGroup))
        if matchesSource and matchesGroup then
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

local function TogglePlayback()
    state.paused = not state.paused
    if pauseButton then pauseButton:SetText(state.paused and "继续播放" or "暂停播放") end
end

local function ReplayPlayback()
    state.time = 0
    if detailLightning then detailLightning:Replay() end
end

local function CreateCanvas(entry, height)
    if entry.procedural == "mota" then
        local canvas = MotaCanvas { width = "100%", height = height }
        canvas:SetEntry(entry, state)
        return canvas
    end
    if entry.procedural == "chain-lightning" then
        local canvas = ChainLightning { width = "100%", height = height }
        canvas:SetEntry(entry, state)
        return canvas
    end
    local canvas = EffectCanvas { width = "100%", height = height }
    canvas:SetEntry(entry, state)
    return canvas
end

local function ShowDetail(entry)
    if not root then return end
    local modal = UI.Modal {
        title = entry.title .. " / " .. entry.source,
        size = UI.GetWidth() < 720 and "fullscreen" or "lg",
        onClose = function(self)
            detailLightning = nil
            self:Destroy()
        end,
    }
    local canvasHeight = entry.procedural and math.min(420, UI.GetHeight() * 0.46) or math.min(420, UI.GetHeight() * 0.5)
    local canvas = CreateCanvas(entry, canvasHeight)
    local contentPanel = UI.Panel { gap = 12, children = { canvas } }
    if not entry.procedural then
        contentPanel:AddChild(UI.Label { text = entry.description or "原项目生成器导出的动画帧。", fontSize = 11, fontColor = "#A0A0C0", whiteSpace = "normal" })
        contentPanel:AddChild(Label(string.format("%d × %d  |  %d 帧  |  %s", entry.width, entry.height, entry.count, entry.license), 10, "#21BDAE"))
        contentPanel:AddChild(UI.Label { text = entry.origin, fontSize = 9, fontColor = "#A0A0C0", whiteSpace = "normal" })
    elseif entry.procedural == "mota" then
        local d = Mota.definitions[entry.effectId]
        contentPanel:AddChild(UI.Label { text = entry.description, fontSize = 10, fontColor = "#A0A0C0", whiteSpace = "normal" })
        contentPanel:AddChild(Label(string.format("%d×%dpx · 锚点(%d,%d) · %.2fs · %s", d.width,d.height,d.anchorX,d.anchorY,d.duration,d.loop and "循环" or "单次/间隔预览"),9,"#21BDAE"))
    else
        contentPanel:AddChild(UI.Label { text = "聚能 → 首击 → 五目标连锁 → 残电消散 · 0.14秒/跳 · 逐跳衰减18%", fontSize = 10, fontColor = "#A0A0C0", whiteSpace = "normal" })
    end
    modal:AddContent(contentPanel)
    if entry.procedural == "mota" then
        local effect = canvas --[[@as MotaCanvas]]
        detailLightning = effect
        local variant = Button(effect:GetVariantText(),function() end,false,112)
        variant.props.onClick = function() effect:ChangeVariant();variant:SetText(effect:GetVariantText()) end
        modal:AddContent(UI.Panel {flexDirection="row",gap=8,flexWrap="wrap",children={
            Button("原配色",function() effect:SetPalette(1) end,true,80),
            Button("橙红",function() effect:SetPalette(2) end,false,72),
            Button("紫色",function() effect:SetPalette(3) end,false,72),
            variant,
            Button("场景/纯特效",function() effect:ToggleClean() end,false,110),
        }})
    end
    if entry.procedural == "chain-lightning" then
        local lightning = canvas --[[@as ChainLightning]]
        detailLightning = lightning
        modal:AddContent(UI.Panel { flexDirection = "row", gap = 8, flexWrap = "wrap", children = {
            Button("冰蓝雷霆", function() lightning:SetPalette(1) end, true, 92),
            Button("紫电秘术", function() lightning:SetPalette(2) end, false, 92),
            Button("金色雷击", function() lightning:SetPalette(3) end, false, 92),
            Button("场景/纯特效", function() lightning:ToggleClean() end, false, 112),
        } })
    end
    modal:SetFooter(UI.Panel { flexDirection = "row", gap = 10, justifyContent = "flex-end", children = {
        Button("重播技能", function()
            if entry.procedural then
                if detailLightning then detailLightning:Replay() end
            else ReplayPlayback() end
        end, false, 110),
        Button("关闭预览", function() modal:Close() end, true, 120),
    } })
    root:AddChild(modal)
    modal:Open()
    print("[特效画廊] 放大：" .. entry.id)
end

local function CreateCard(entry, cardWidth, canvasHeight)
    local canvas = CreateCanvas(entry, canvasHeight)
    return UI.Card {
        id = entry.id,
        width = cardWidth, variant = "outlined", padding = 10, gap = 8, clickable = true,
        backgroundColor = "#16162F", borderColor = "#343459",
        onClick = function() ShowDetail(entry) end,
        children = {
            UI.Panel { flexDirection = "row", justifyContent = "space-between", alignItems = "center", children = {
                Label(entry.title, 12), Label(entry.license, 8, "#21BDAE"),
            } },
            canvas,
            UI.Panel { flexDirection = "row", justifyContent = "space-between", children = {
                Label(entry.battleGroup or entry.source, 9, "#21BDAE"),
                Label(entry.procedural and "程序化 · 点击放大" or (tostring(entry.count) .. " 帧 · 点击放大"), 8, "#74749B"),
            } },
            UI.Label { text = entry.usage or entry.source, fontSize = 9, fontColor = "#A0A0C0", whiteSpace = "normal", maxLines = 2 },
        },
    }
end

local function CreateUI()
    -- 根树重建前先退出overlay，避免窗口变化后留下已销毁弹窗的输入遮罩。
    local overlays=UI.GetOverlayStack()
    for i=#overlays,1,-1 do overlays[i]:Close() end
    detailLightning = nil
    pauseButton = nil
    FilterEntries()
    local width = UI.GetWidth()
    lastWidth = width
    lastHeight = UI.GetHeight()
    local wide = width >= 900
    local padding = width < 600 and 12 or 24
    local side = wide and 205 or 0
    local available = width - padding * 2 - side - (wide and 20 or 0)
    local cols = available >= 900 and 3 or (available >= 480 and 2 or 1)
    local cardWidth = math.floor((available - 16 - (cols - 1) * 14) / cols)
    local canvasHeight = state.battle and 200 or math.max(110, math.min(180, (UI.GetHeight() - 500) / 2))
    local cards = {}
    local gridRows = {}
    for _, entry in ipairs(filtered) do
        if entry.procedural == "chain-lightning" or (entry.effectId and entry.effectId:sub(1,5)=="demo/") then
            table.insert(gridRows, UI.Panel { width = "100%", children = {
                CreateCard(entry, available - 16, math.min(460, math.max(320, UI.GetHeight() * 0.52))),
            } })
        else
            table.insert(cards, CreateCard(entry, cardWidth, canvasHeight))
        end
    end
    for i = 1, #cards, cols do
        local rowCards = {}
        for j = i, math.min(i + cols - 1, #cards) do table.insert(rowCards, cards[j]) end
        table.insert(gridRows, UI.Panel { width = "100%", flexDirection = "row", gap = 14, children = rowCards })
    end
    local entries = CurrentEntries()
    local sourceButtons = {}
    table.insert(sourceButtons, Button("全部来源  /  " .. #entries, function() SetSource("全部") end, state.source == "全部", wide and "100%" or 155))
    for _, info in ipairs(Catalog.sources) do
        local n = 0
        for _, entry in ipairs(entries) do if entry.source == info.name then n = n + 1 end end
        if n > 0 then
            table.insert(sourceButtons, Button(info.name .. "  /  " .. n, function() SetSource(info.name) end, state.source == info.name, wide and "100%" or 155))
        end
    end
    if state.mota then
        local n=0
        for _,entry in ipairs(entries) do if entry.source=="魔塔实时" then n=n+1 end end
        table.insert(sourceButtons,Button("魔塔实时  /  "..n,function() SetSource("魔塔实时") end,state.source=="魔塔实时",wide and "100%" or 155))
    elseif state.battle then
        table.insert(sourceButtons, Button("实时技能  /  1", function() SetSource("实时技能") end, state.source == "实时技能", wide and "100%" or 155))
    end
    local selectedInfo = state.mota and "魔塔需求 · 纯Lua程序绘制，无新增图片。P0单段模块+编排演示，P1高频打击，P2轻量状态。" or (state.battle and "玩家在下方，攻击朝上。精选按用途分类；带地面效果、原版方向和适配限制见卡片详情。" or "来自真实项目源码的离线导出；点击卡片可放大。")
    if not state.mota and not state.battle then
        for _, info in ipairs(Catalog.sources) do
            if info.name == state.source then selectedInfo = info.note end
        end
    end
    local sidebar = UI.Panel {
        width = wide and side or "100%", flexDirection = wide and "column" or "row",
        flexWrap = "no-wrap", gap = 10,
        children = sourceButtons,
    }
    if wide then
        sidebar:AddChild(UI.Panel { height = 12 })
        sidebar:AddChild(Label("已下载源码", 10, "#21BDAE"))
        sidebar:AddChild(UI.Label { text = "4 个 GitHub 仓库\n25 个 Sprite Fusion 源码包", fontSize = 10, fontColor = "#A0A0C0", whiteSpace = "normal" })
        sidebar:AddChild(UI.Label { text = "原始文件保留在 vendor/，展示使用 assets/Effects/ 中的图集。", fontSize = 9, fontColor = "#74749B", whiteSpace = "normal" })
        sidebar:AddChild(UI.Label { text = "PixelSpace 为静态背景；其余按原生成器或原场景采样。", fontSize = 9, fontColor = "#74749B", whiteSpace = "normal" })
    end
    local sourceSelector = wide and sidebar or UI.ScrollView {
        width = "100%", height = 46, scrollX = true, scrollY = false, bounces = false,
        children = { sidebar },
    }
    local groupButtons = {}
    if state.mota or state.battle then
        for _, group in ipairs(state.mota and Mota.groups or Battle.groups) do
            table.insert(groupButtons, Button(group, function()
                state.group = group
                state.scrollY = 0
                rebuild = true
            end, state.group == group, 92))
        end
    end
    galleryScroll = UI.ScrollView {
        id = "gallery-scroll", flexGrow = 1, flexBasis = 0, minHeight = 0,
        scrollX = false, scrollY = true, showScrollbar = true,
        scrollbarInteractive = true, bounces = false,
        onScroll = function(_, _, y) state.scrollY = y end,
        children = {
            UI.Panel { width = "100%", gap = 14, paddingBottom = 8, children = gridRows },
        },
    }
    local content = UI.Panel { flexGrow = 1, flexBasis = 0, minWidth = 0, minHeight = 0, gap = 12, children = {
        UI.Panel { flexDirection = "row", alignItems = "center", gap = 12, children = {
            Label(state.mota and "魔塔需求特效" or (state.battle and "竖版战斗精选" or (state.source == "全部" and "特效总览" or state.source)), 16, "#F0F0F0"),
            Label(tostring(#filtered) .. " 组", 10, "#21BDAE"),
        } },
        UI.Label { text = selectedInfo, fontSize = 10, fontColor = "#A0A0C0", whiteSpace = "normal", maxLines = 2 },
        UI.ScrollView {
            width = "100%", height = state.battle and 44 or 0, visible = state.battle,
            scrollX = true, scrollY = false, bounces = false,
            children = { UI.Panel { flexDirection = "row", gap = 8, children = groupButtons } },
        },
        galleryScroll,
        Label("滚动浏览全部特效 · 点击卡片放大", 9, "#74749B"),
    } }
    pauseButton = Button(state.paused and "继续播放" or "暂停播放", TogglePlayback, false, 100)
    root = UI.Panel { width = "100%", height = "100%", backgroundColor = "#0F0F23", children = {
        UI.SafeAreaView { width = "100%", height = "100%", padding = padding, gap = width < 600 and 10 or 18, children = {
            UI.Panel { flexDirection = "row", alignItems = "center", justifyContent = "space-between", flexWrap = "wrap", gap = 12, children = {
                UI.Panel { gap = 4, children = {
                    Label("像素特效实验室", 23, "#F0F0F0"),
                    Label("PIXEL FX / OPEN SOURCE SHOWCASE", 9, "#21BDAE"),
                } },
                UI.Panel { flexDirection = "row", gap = 10, flexWrap = "wrap", children = {
                    Button(state.mota and "返回战斗精选" or "魔塔需求特效",function()
                        state.mota=not state.mota;state.battle=true;state.source="全部"
                        state.group=state.mota and "全部需求" or "全部精选";state.scrollY=0;rebuild=true
                    end,true,124),
                    Button(state.battle and "查看原始73组" or "竖版战斗精选", function()
                        state.mota = false
                        state.battle = not state.battle
                        state.source = "全部"
                        state.group = "全部精选"
                        state.scrollY = 0
                        rebuild = true
                    end, true, 124),
                    pauseButton,
                    Button(tostring(state.speed) .. "× 速度", function() state.speed = state.speed == 0.5 and 1 or (state.speed == 1 and 2 or 0.5); rebuild = true end, false, 96),
                    Button(state.checker and "棋盘背景" or "深色背景", function() state.checker = not state.checker; rebuild = true end, false, 100),
                    Button("重新播放", ReplayPlayback, true, 100),
                } },
            } },
            UI.Panel { height = 2, backgroundColor = "#343459" },
            UI.Panel { flexGrow = 1, flexBasis = 0, minHeight = 0, flexDirection = wide and "row" or "column", gap = wide and 20 or 8, children = { sourceSelector, content } },
            Label("鼠标滚轮 / 触摸拖动浏览 / SPACE 暂停 / 1–5 切换来源 / R 重播", 9, "#74749B"),
        } },
    } }
    UI.SetRoot(root, true)
    restoreScroll = true
    print(string.format("[特效画廊] 连续滚动列表，显示 %d 个，屏宽 %.0f", #filtered, width))
end

function Start()
    graphics.windowTitle = "像素特效实验室"
    input.mouseMode = MM_ABSOLUTE
    InitUI()
    CreateUI()
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    print("[特效画廊] 启动，原始素材 " .. #Catalog.entries .. " 组，魔塔需求 " .. #Mota.entries .. " 项")
end

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    if not state.paused then state.time = state.time + eventData:GetFloat("TimeStep") * state.speed end
    if math.abs(UI.GetWidth() - lastWidth) > 2 or math.abs(UI.GetHeight() - lastHeight) > 2 then rebuild = true end
    if rebuild then
        rebuild = false
        CreateUI()
    end
    if restoreScroll and galleryScroll then
        -- 重建布局后再恢复位置，切换播放控件时不跳回列表顶部。
        UI.Layout()
        galleryScroll:UpdateContentSize()
        galleryScroll:SetScroll(0, state.scrollY)
        restoreScroll = false
    end
end

---@param eventType string
---@param eventData KeyDownEventData
function HandleKeyDown(eventType, eventData)
    local key = eventData:GetInt("Key")
    if key == KEY_SPACE then TogglePlayback() end
    if key == KEY_R then ReplayPlayback() end
    local keys = { KEY_1, KEY_2, KEY_3, KEY_4, KEY_5 }
    for i, k in ipairs(keys) do if key == k and Catalog.sources[i] then SetSource(Catalog.sources[i].name) end end
end

function Stop()
    detailLightning = nil
    pauseButton = nil
    EffectCanvas.ReleaseImages()
    UI.Shutdown()
    root = nil
    galleryScroll = nil
end
