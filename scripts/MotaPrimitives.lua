-- 魔塔特效共用绘制：纯时间函数，不使用随机状态或外部图片。
local Art = require("LightningArt")
local P = {}
P.Rect, P.Glow, P.Star = Art.Rect, Art.Glow, Art.Star

-- 每个像素行/列只提交一个矩形，避免粗线按长度重复覆盖同一批像素。
function P.Line(vg,a,b,width,color,alpha)
    if alpha<1 then return end
    local dx,dy=b.x-a.x,b.y-a.y
    local xMajor=math.abs(dx)>=math.abs(dy)
    local span=xMajor and dx or dy
    local extent=math.abs(span)
    local steps=math.max(1,math.ceil(extent+width))
    local start=math.min(xMajor and a.x or a.y,xMajor and b.x or b.y)-width*0.5
    nvgBeginPath(vg)
    for i=0,steps-1 do
        local axis=math.floor(start+i)
        local q=extent<0.001 and 0 or math.max(0,math.min(1,(axis-(xMajor and a.x or a.y))/span))
        local x=xMajor and axis or math.floor(a.x+dx*q-width*0.5)
        local y=xMajor and math.floor(a.y+dy*q-width*0.5) or axis
        nvgRect(vg,x,y,xMajor and 1 or width,xMajor and width or 1)
    end
    Art.Color(vg,color,alpha)
    nvgFill(vg)
end
P.Noise = Art.Noise
P.Palettes = {
    volt = {{29,24,64},{72,61,151},{89,118,239},{66,199,255},{169,241,255},{248,255,255}},
    fire = {{49,24,39},{123,45,44},{226,79,38},{255,154,49},{255,224,126},{255,255,230}},
    leaf = {{16,37,37},{29,79,59},{52,137,73},{101,193,86},{181,235,121},{246,255,205}},
    gold = {{53,29,48},{107,62,78},{189,115,66},{244,182,75},{255,232,149},{255,255,232}},
    poison = {{28,25,49},{64,40,96},{101,79,157},{138,193,75},{204,241,114},{246,255,211}},
    shadow = {{22,19,38},{55,33,79},{104,56,143},{169,92,205},{230,167,244},{255,234,255}},
}

function P.Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
function P.Out(t) return 1 - (1 - P.Clamp(t, 0, 1)) ^ 3 end

-- 接受短色板，插值扩展到六阶；空色板退回原配色。
function P.Fit(colors, fallback)
    local input = colors and #colors > 0 and colors or P.Palettes[fallback or "volt"]
    local result = {}
    for i = 1, 6 do
        local at = (i - 1) / 5 * (#input - 1) + 1
        local a, b = input[math.floor(at)], input[math.min(#input, math.floor(at) + 1)]
        local t = at - math.floor(at)
        result[i] = { math.floor(a[1] + (b[1] - a[1]) * t), math.floor(a[2] + (b[2] - a[2]) * t), math.floor(a[3] + (b[3] - a[3]) * t) }
    end
    return result
end

-- 逐扫描线圆盘，保持硬边像素轮廓，无平滑圆形贴图。
local discSpans={}
function P.Disc(vg, x, y, r, color, alpha)
    if r < 0.5 or (alpha or 255) < 1 then return end
    local radius = math.floor(r)
    local spans=discSpans[radius]
    if not spans then
        spans={}
        for row=-radius,radius do
            local half=math.floor(math.sqrt(math.max(0,radius*radius-row*row)))
            local last=spans[#spans]
            if last and last.half==half then last.height=last.height+1
            else spans[#spans+1]={half=half,row=row,height=1} end
        end
        discSpans[radius]=spans
    end
    nvgBeginPath(vg)
    for _,span in ipairs(spans) do
        nvgRect(vg,math.floor(x)-span.half,math.floor(y)+span.row,span.half*2+1,span.height)
    end
    Art.Color(vg, color, alpha or 255)
    nvgFill(vg)
end

function P.Ring(vg, x, y, r, squash, color, alpha, phase)
    if r < 1 or alpha < 1 then return end
    nvgBeginPath(vg)
    local count = math.min(120, math.max(16, math.ceil(r * 3)))
    for i = 0, count - 1 do
        local a = i / count * math.pi * 2
        if not phase or (i + math.floor(phase)) % 9 < 6 then
            nvgRect(vg, math.floor(x + math.cos(a) * r), math.floor(y + math.sin(a) * r * squash), 1, 1)
        end
    end
    Art.Color(vg, color, alpha)
    nvgFill(vg)
end

function P.Sparks(vg, x, y, t, life, seed, colors, count, reach, gravity)
    if t < 0 or t >= life then return end
    local q = t / life
    local fade = (1 - q) ^ 1.5
    for i = 1, count do
        local a = P.Noise(seed + i * 31) * math.pi * 2
        local speed = reach * (0.35 + P.Noise(seed + i * 71) * 0.65)
        local dx, dy = math.cos(a) * speed, math.sin(a) * speed
        local px = x + dx * P.Out(q)
        local py = y + dy * P.Out(q) + (gravity or 0) * q * q
        P.Line(vg, {x=px,y=py}, {x=px-dx*0.08*(1-q),y=py-dy*0.08*(1-q)}, i%5==0 and 2 or 1, colors[i%3+3], fade*230)
    end
end

function P.Flash(vg, x, y, t, colors, radius)
    if t < 0 or t > 0.25 then return end
    local f = math.exp(-t * 23)
    P.Glow(vg,x,y,radius*1.7,colors[4],f*160)
    P.Star(vg,x,y,2+radius*f,0,colors[5],f*245)
    P.Star(vg,x,y,2+radius*0.65*f,math.pi*0.25,colors[6],f*255)
end

function P.Path(vg, points, width, color, alpha)
    for i=2,#points do P.Line(vg,points[i-1],points[i],width,color,alpha) end
end

-- 0右 / 1下 / 2左 / 3上；像素坐标旋转不依赖引擎整幅旋转。
function P.Turn(x, y, direction)
    local d = math.floor(direction or 0) % 4
    if d == 1 then return -y, x end
    if d == 2 then return -x, -y end
    if d == 3 then return y, -x end
    return x, y
end

return P
