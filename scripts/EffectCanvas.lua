local UI = require("urhox-libs/UI")

---@class GalleryEntry
---@field id string
---@field source string
---@field title string
---@field description string
---@field origin string
---@field path string
---@field width number
---@field height number
---@field cols number
---@field rows number
---@field count number
---@field durations number[]
---@field license string
---@field battleGroup? string
---@field usage? string
---@field adaptation? string
---@field previewMotion? string
---@field previewRotation? number
---@field previewFrames? number
---@field procedural? string

---@class GalleryPlayback
---@field source string
---@field scrollY number
---@field time number
---@field paused boolean
---@field speed number
---@field checker boolean

---@class EffectCanvas : Widget
---@field entry_ GalleryEntry?
---@field playback_ GalleryPlayback?
local EffectCanvas = UI.Widget:Extend("EffectCanvas")
---@type table<string, integer>
local images = {}

function EffectCanvas:Init(props)
    UI.Widget.Init(self, props or {})
    self.entry_ = nil
    self.playback_ = nil
end

---@param entry GalleryEntry
---@param playback GalleryPlayback
function EffectCanvas:SetEntry(entry, playback)
    self.entry_ = entry
    self.playback_ = playback
end

local function Rect(vg, x, y, w, h, r, g, b)
    nvgBeginPath(vg)
    nvgRect(vg, x, y, w, h)
    nvgFillColor(vg, nvgRGB(r, g, b))
    nvgFill(vg)
end

---@param vg NVGContextWrapper
function EffectCanvas:Render(vg)
    local l = self:GetAbsoluteLayout()
    if l.w < 1 or l.h < 1 then return end
    nvgSave(vg)
    nvgIntersectScissor(vg, l.x, l.y, l.w, l.h)
    Rect(vg, l.x, l.y, l.w, l.h, 10, 10, 24)
    local state = self.playback_
    if state and state.checker then
        local tile = 16
        for y = 0, math.ceil(l.h / tile) do
            for x = 0, math.ceil(l.w / tile) do
                if (x + y) % 2 == 0 then Rect(vg, l.x + x * tile, l.y + y * tile, tile, tile, 26, 26, 48) end
            end
        end
    end
    local entry = self.entry_
    if entry and state then
        if not images[entry.path] then
            local handle = nvgCreateImage(vg, entry.path, NVG_IMAGE_NEAREST)
            if handle > 0 then
                images[entry.path] = handle
                print("[特效图集] 加载 " .. entry.path .. "，句柄 " .. handle)
            end
        end
        local image = images[entry.path]
        if image then
            local total = 0
            for _, duration in ipairs(entry.durations) do total = total + duration end
            local t = (state.time * 1000) % math.max(1, total)
            local index = 1
            for i, duration in ipairs(entry.durations) do
                index = i
                if t < duration then break end
                t = t - duration
            end
            local rotation = math.rad(entry.previewRotation or 0)
            local sin, cos = math.abs(math.sin(rotation)), math.abs(math.cos(rotation))
            local displayWidth = entry.width * cos + entry.height * sin
            local displayHeight = entry.width * sin + entry.height * cos
            local moving = entry.previewMotion == "up"
            local scale = math.min((l.w - 16) / displayWidth, (l.h - 16) / displayHeight)
            if moving then
                scale = math.min(scale, (l.w - 24) / displayWidth, l.h * 0.38 / displayHeight)
            end
            if scale >= 1 then scale = math.max(1, math.floor(scale)) end
            local w, h = entry.width * scale, entry.height * scale
            local centerX, centerY = l.x + l.w * 0.5, l.y + l.h * 0.5
            if moving then
                local halfHeight = displayHeight * scale * 0.5
                local bottom, top = l.y + l.h - halfHeight - 10, l.y + halfHeight + 10
                local travel = (state.time % 1.6) / 1.6
                centerY = bottom + (top - bottom) * travel
                Rect(vg, math.floor(centerX), top, 1, math.max(0, bottom - top), 35, 54, 66)
                nvgBeginPath(vg)
                nvgMoveTo(vg, centerX - 5, top + 6)
                nvgLineTo(vg, centerX, top)
                nvgLineTo(vg, centerX + 5, top + 6)
                nvgStrokeColor(vg, nvgRGB(33, 189, 174))
                nvgStrokeWidth(vg, 1)
                nvgStroke(vg)
            end
            local col, row = (index - 1) % entry.cols, math.floor((index - 1) / entry.cols)
            nvgSave(vg)
            nvgTranslate(vg, math.floor(centerX), math.floor(centerY))
            nvgRotate(vg, rotation)
            local x, y = -w * 0.5, -h * 0.5
            -- 在帧局部空间裁切，旋转的是单帧，而不是整张图集。
            nvgIntersectScissor(vg, x, y, w, h)
            nvgBeginPath(vg)
            nvgRect(vg, x, y, w, h)
            nvgFillPaint(vg, nvgImagePattern(vg, x - col * w, y - row * h, w * entry.cols, h * entry.rows, 0, image, 1))
            nvgFill(vg)
            nvgRestore(vg)
            Rect(vg, l.x, l.y + l.h - 2, l.w * index / entry.count, 2, 33, 189, 174)
        end
    end
    nvgRestore(vg)
end

function EffectCanvas.ReleaseImages()
    local vg = UI.GetNVGContext()
    for _, image in pairs(images) do nvgDeleteImage(vg, image) end
    images = {}
end

return EffectCanvas
