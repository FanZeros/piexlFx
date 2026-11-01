-- 闪电链美术层：整数像素轮廓、分级电弧、晶体目标和命中碎光。
local Art = {}
local floor, sin, cos, pi = math.floor, math.sin, math.cos, math.pi

Art.Palettes = {
    { dark = { 53, 43, 122 }, edge = { 73, 102, 252 }, body = { 65, 198, 255 }, light = { 154, 244, 255 }, core = { 242, 255, 255 } },
    { dark = { 75, 28, 108 }, edge = { 146, 67, 250 }, body = { 205, 131, 255 }, light = { 239, 202, 255 }, core = { 255, 246, 255 } },
    { dark = { 106, 44, 38 }, edge = { 239, 110, 49 }, body = { 255, 190, 70 }, light = { 255, 236, 155 }, core = { 255, 255, 235 } },
}

function Art.Noise(seed)
    local v = sin(seed * 12.9898 + 78.233) * 43758.5453
    return v - floor(v)
end

function Art.Color(vg, color, alpha)
    nvgFillColor(vg, nvgRGBA(color[1], color[2], color[3], floor(math.max(0, math.min(255, alpha)))))
end

function Art.Rect(vg, x, y, w, h, color, alpha)
    nvgBeginPath(vg)
    nvgRect(vg, floor(x), floor(y), math.max(1, floor(w)), math.max(1, floor(h)))
    Art.Color(vg, color, alpha or 255)
    nvgFill(vg)
end

function Art.Polygon(vg, points, color, alpha)
    nvgBeginPath(vg)
    for i, p in ipairs(points) do
        if i == 1 then nvgMoveTo(vg, floor(p.x), floor(p.y)) else nvgLineTo(vg, floor(p.x), floor(p.y)) end
    end
    nvgClosePath(vg)
    Art.Color(vg, color, alpha or 255)
    nvgFill(vg)
end

function Art.Glow(vg, x, y, radius, color, alpha)
    if alpha <= 0 or radius <= 0 then return end
    nvgBeginPath(vg)
    nvgRect(vg, x - radius, y - radius, radius * 2, radius * 2)
    nvgFillPaint(vg, nvgRadialGradient(vg, x, y, radius * 0.06, radius,
        nvgRGBA(color[1], color[2], color[3], floor(math.min(255, alpha))), nvgRGBA(color[1], color[2], color[3], 0)))
    nvgFill(vg)
end

-- 将线段栅格化，一层只提交一次路径，避免为每个像素单独绘制。
function Art.PixelLine(vg, a, b, width, color, alpha)
    local dx, dy = b.x - a.x, b.y - a.y
    local steps = math.max(1, math.ceil(math.max(math.abs(dx), math.abs(dy))))
    nvgBeginPath(vg)
    for j = 0, steps do
        local t = j / steps
        nvgRect(vg, floor(a.x + dx * t - width * 0.5), floor(a.y + dy * t - width * 0.5), width, width)
    end
    Art.Color(vg, color, alpha)
    nvgFill(vg)
end

function Art.Ring(vg, x, y, radius, squash, rotation, color, alpha, broken)
    nvgBeginPath(vg)
    local count = math.max(20, floor(radius * 2.8))
    for i = 0, count do
        if not broken or (i + floor(rotation * 10)) % 13 < 9 then
            local angle = i / count * pi * 2 + rotation
            nvgRect(vg, floor(x + cos(angle) * radius), floor(y + sin(angle) * radius * squash), 2, 2)
        end
    end
    Art.Color(vg, color, alpha)
    nvgFill(vg)
end

function Art.Star(vg, x, y, radius, rotation, color, alpha)
    local points = {}
    for i = 0, 7 do
        local angle = rotation + i * pi / 4
        local r = i % 2 == 0 and radius or radius * 0.16
        table.insert(points, { x = x + cos(angle) * r, y = y + sin(angle) * r })
    end
    Art.Polygon(vg, points, color, alpha)
end

-- 大折点决定轮廓，小折点补充毛刺；端点始终精确锚定，重绘不改变连接对象。
function Art.BuildPath(a, b, seed)
    local dx, dy = b.x - a.x, b.y - a.y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 0.1 then return { a, b } end
    local nx, ny = -dy / length, dx / length
    local count = math.max(4, math.ceil(length / 17))
    local major = { a }
    for i = 1, count - 1 do
        local t = i / count
        local offset = (Art.Noise(seed + i * 13) * 2 - 1) * math.min(24, length * 0.19) * sin(pi * t)
        table.insert(major, { x = a.x + dx * t + nx * offset, y = a.y + dy * t + ny * offset })
    end
    table.insert(major, b)
    local points = { a }
    for i = 2, #major do
        local p, q = major[i - 1], major[i]
        local offset = (Art.Noise(seed + i * 41) * 2 - 1) * math.min(5, length * 0.12)
        table.insert(points, { x = floor((p.x + q.x) * 0.5 + nx * offset), y = floor((p.y + q.y) * 0.5 + ny * offset) })
        table.insert(points, { x = floor(q.x), y = floor(q.y) })
    end
    return points
end

function Art.Bolt(vg, a, b, seed, strength, envelope, palette, reveal)
    local dx, dy = b.x - a.x, b.y - a.y
    local fullLength = math.sqrt(dx * dx + dy * dy)
    if fullLength < 1 or (reveal or 1) <= 0.01 then return end
    local fullPath = Art.BuildPath(a, b, seed)
    local points = { fullPath[1] }
    local cutoff = (reveal or 1) * (#fullPath - 1)
    for i = 2, #fullPath do
        if i - 1 <= cutoff then
            table.insert(points, fullPath[i])
        else
            local p, q = fullPath[i - 1], fullPath[i]
            local t = math.max(0, cutoff - (i - 2))
            table.insert(points, { x = p.x + (q.x - p.x) * t, y = p.y + (q.y - p.y) * t })
            break
        end
    end
    local width = (2.0 + 2.8 * envelope) * (0.62 + strength * 0.38)
    -- 先低亮辉光，再深边和高亮核心。主干白芯保留，衰减优先作用于宽度与外晕。
    for layer = 1, 5 do
        local color = ({ palette.edge, palette.dark, palette.body, palette.light, palette.core })[layer]
        local size = ({ width + 12, width + 5, width + 2, width, math.max(1, width * 0.42) })[layer]
        local opacity = ({ 18, 65, 145, 215, 250 })[layer] * strength
        nvgBeginPath(vg)
        for i = 2, #points do
            local p, q = points[i - 1], points[i]
            local dx, dy = q.x - p.x, q.y - p.y
            local steps = math.max(1, math.ceil(math.max(math.abs(dx), math.abs(dy)) / 1.4))
            local taper = 0.65 + Art.Noise(seed + i * 7) * 0.65
            local pixelWidth = math.max(1, floor(size * taper))
            for j = 0, steps do
                local t = j / steps
                nvgRect(vg, floor(p.x + dx * t - pixelWidth * 0.5), floor(p.y + dy * t - pixelWidth * 0.5), pixelWidth, pixelWidth)
            end
        end
        Art.Color(vg, color, opacity)
        nvgFill(vg)
    end
    -- 非对称分叉：长短不同，有二次折角，不与主干争夺亮度。
    local dx, dy = b.x - a.x, b.y - a.y
    local length = math.max(1, math.sqrt(dx * dx + dy * dy))
    local branchCount = math.min(3, math.floor(length * (reveal or 1) / 24))
    for branch = 1, branchCount do
        local index = math.max(2, math.min(#points - 1, floor(#points * (0.2 + branch * 0.17))))
        local p = points[index]
        local side = branch % 2 == 0 and -1 or 1
        local reach = 12 + Art.Noise(seed + branch * 73) * 18
        local tip = { x = p.x + dx / length * reach * 0.6 - dy / length * reach * side, y = p.y + dy / length * reach * 0.6 + dx / length * reach * side }
        local branchPoints = Art.BuildPath(p, tip, seed + branch * 233)
        for i = 2, #branchPoints do
            Art.PixelLine(vg, branchPoints[i - 1], branchPoints[i], i < #branchPoints and 2 or 1, palette.body, strength * 125)
        end
    end
end

function Art.Impact(vg, x, y, age, strength, seed, palette)
    if age < 0 or age > 0.9 then return end
    local flash = math.exp(-age * 14)
    local fade = math.max(0, 1 - age / 0.9)
    Art.Glow(vg, x, y, 22 + flash * 38, palette.edge, (25 * fade + 170 * flash) * strength)
    Art.Glow(vg, x, y, 10 + flash * 17, palette.body, 180 * flash * strength)
    if age < 0.32 then
        local r = 4 + age * 90
        Art.Ring(vg, x, y, r, 0.78, seed, palette.body, (1 - age / 0.32) * 190 * strength, true)
        Art.Star(vg, x, y, 6 + flash * 26, 0.15, palette.light, 235 * flash)
        Art.Star(vg, x, y, 4 + flash * 17, pi * 0.25, palette.core, 255 * flash)
    end
    for j = 1, 16 do
        local angle = Art.Noise(seed + j * 31) * pi * 2
        local velocity = 28 + Art.Noise(seed + j * 59) * 85
        local t = math.min(1, age * 2.7)
        local distance = velocity * (1 - (1 - t) ^ 3) * 0.65
        local px, py = x + cos(angle) * distance, y + sin(angle) * distance * 0.8
        local tail = (3 + Art.Noise(seed + j * 11) * 9) * fade
        Art.PixelLine(vg, { x = px, y = py }, { x = px - cos(angle) * tail, y = py - sin(angle) * tail }, j % 4 == 0 and 2 or 1, j % 3 == 0 and palette.light or palette.body, fade ^ 2 * 220 * strength)
        if j % 5 == 0 and age > 0.07 then Art.Rect(vg, px + 3, py - 2, 2, 2, palette.core, fade * 190) end
    end
    if age < 0.65 then
        local rotation = seed + floor(age * 12)
        Art.Ring(vg, x, y, 16 + sin(age * 20) * 2, 1, rotation, palette.body, (1 - age / 0.65) * 150, true)
    end
end

-- 悬浮晶体卫兵：分面、轮廓、镶金边和核心，不使用低细节方块占位。
function Art.Target(vg, x, y, time, flash, damage, palette)
    local angle = sin(time * 0.8) * 0.12
    Art.Glow(vg, x, y, 26, { 111, 58, 165 }, 32)
    Art.Ring(vg, x, y + 22, 17, 0.26, angle, { 83, 63, 111 }, 90, true)
    local outer = { {x=x,y=y-21},{x=x+13,y=y-3},{x=x+8,y=y+12},{x=x,y=y+20},{x=x-10,y=y+9},{x=x-13,y=y-4} }
    Art.Polygon(vg, outer, { 12, 14, 30 })
    Art.Polygon(vg, { {x=x,y=y-18},{x=x+10,y=y-2},{x=x,y=y+14},{x=x-10,y=y-2} }, { 96, 67, 135 })
    Art.Polygon(vg, { {x=x,y=y-18},{x=x+2,y=y-2},{x=x-10,y=y-2} }, { 162, 128, 184 })
    Art.Polygon(vg, { {x=x+2,y=y-2},{x=x+10,y=y-2},{x=x,y=y+14} }, { 54, 40, 91 })
    for side = -1, 1, 2 do
        Art.Polygon(vg, { {x=x+side*8,y=y-5},{x=x+side*22,y=y-12},{x=x+side*18,y=y+5},{x=x+side*11,y=y+9} }, { 25, 27, 48 })
        Art.PixelLine(vg, {x=x+side*9,y=y-5}, {x=x+side*20,y=y-10}, 1, { 164, 127, 112 }, 210)
    end
    Art.Star(vg, x, y-1, 7, pi*0.25, flash > 0.25 and palette.core or { 204, 139, 199 }, 255)
    if flash > 0 then
        Art.Polygon(vg, outer, palette.light, flash * 190)
        Art.PixelLine(vg, {x=x-8,y=y+9}, {x=x+6,y=y-11}, 2, palette.core, flash * 230)
    end
    Art.Rect(vg, x-13, y-29, 26, 2, { 31, 28, 47 })
    Art.Rect(vg, x-13, y-29, 26*(1-damage*0.6), 2, { 184, 90, 137 }, 210)
end

function Art.Caster(vg, x, y, age, time, palette)
    local charge = age < 0.58 and (age / 0.58) ^ 1.7 or math.exp(-(age - 0.58) * 7)
    local rotation = time * 0.65
    Art.Glow(vg, x, y, 48, palette.edge, 25 + charge*105)
    Art.Ring(vg, x, y+13, 29, 0.36, rotation, palette.edge, 100+charge*80, true)
    Art.Ring(vg, x, y+13, 22, 0.36, -rotation, palette.body, 80+charge*140, false)
    for i=1,6 do
        local angle = i*pi/3+rotation
        local px,py=x+cos(angle)*29,y+13+sin(angle)*10
        Art.Polygon(vg, {{x=px,y=py-3},{x=px+3,y=py},{x=px,y=py+3},{x=px-3,y=py}}, palette.light, 120+charge*100)
    end
    Art.Polygon(vg, {{x=x,y=y-23},{x=x+14,y=y-2},{x=x+9,y=y+13},{x=x-9,y=y+13},{x=x-14,y=y-2}}, {15,28,51})
    Art.Polygon(vg, {{x=x,y=y-19},{x=x+9,y=y-2},{x=x,y=y+9},{x=x-9,y=y-2}}, palette.edge)
    Art.Polygon(vg, {{x=x,y=y-19},{x=x+1,y=y-2},{x=x-9,y=y-2}}, palette.light)
    Art.Polygon(vg, {{x=x+1,y=y-2},{x=x+9,y=y-2},{x=x,y=y+9}}, palette.dark)
    for side=-1,1,2 do
        Art.Polygon(vg, {{x=x+side*10,y=y-6},{x=x+side*20,y=y-12},{x=x+side*24,y=y+9},{x=x+side*13,y=y+5}}, {23,43,68})
        Art.PixelLine(vg, {x=x+side*12,y=y-4}, {x=x+side*18,y=y+6}, 2, palette.body, 170)
    end
    local orbY=y-29
    Art.Glow(vg,x,orbY,12+charge*18,palette.body,90+charge*130)
    Art.Star(vg,x,orbY,4+charge*7,pi*0.25,palette.core,180+charge*75)
    if age < 0.58 then
        for j=1,14 do
            local phase=(age*1.4+j/14)%1
            local r=(1-phase)*42
            local a=j*2.399+time
            Art.Rect(vg,x+cos(a)*r,orbY+sin(a)*r*0.7,phase>0.7 and 2 or 1,2,palette.light,phase*210)
        end
    end
end

return Art
