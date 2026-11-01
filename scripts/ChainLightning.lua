-- 实时闪电链：选敌、施法时间轴和美术层分离，不依赖固定方向的图集。
local UI = require("urhox-libs/UI")
local Art = require("LightningArt")

---@class LightningPoint
---@field x number
---@field y number
---@field alive? boolean

---@class LightningConfig
---@field maxTargets integer
---@field firstRange number
---@field jumpRange number
---@field hopDelay number
---@field holdTime number
---@field cycleTime number
---@field attenuation number
---@field castTime number
---@field travelTime number

---@class ChainLightning : Widget
---@field entry_ GalleryEntry?
---@field playback_ GalleryPlayback?
---@field paletteIndex_ integer
---@field clean_ boolean
---@field timeOffset_ number
---@field cacheCycle_ integer
---@field chain_ integer[]
---@field targets_ LightningPoint[]
local ChainLightning = UI.Widget:Extend("ChainLightning")

---@type LightningConfig
ChainLightning.Config = {
    maxTargets = 5, firstRange = 0.65, jumpRange = 0.39,
    hopDelay = 0.14, holdTime = 0.78, cycleTime = 3.8,
    attenuation = 0.82, castTime = 0.58, travelTime = 0.065,
}

-- 点目标判定（非物理碰撞）：
--       ④ —— ③
--       |     |
--       ⑤     ②          · 超距目标不命中
--             |
--             ①
--             ↑ 首击只选施法者上方且在射程内的最近目标
--             P
-- 后续从上一命中点选最近未命中目标；等距保持输入顺序。
-- 边界：半径线上计入、死亡排除、零距离允许、不重复、无目标即结束。
---@param origin LightningPoint
---@param targets LightningPoint[]
---@param firstRange number
---@param jumpRange number
---@param maxTargets integer 包括首击在内的命中目标数
---@return integer[]
function ChainLightning.SelectTargets(origin, targets, firstRange, jumpRange, maxTargets)
    local chain, visited = {}, {}
    local current = origin
    for hop = 1, math.max(0, maxTargets) do
        local radius = hop == 1 and firstRange or jumpRange
        local best = 0
        local bestDistance = math.max(0, radius) ^ 2
        for i, target in ipairs(targets) do
            if target.alive ~= false and not visited[i] and (hop > 1 or target.y < origin.y) then
                local dx, dy = target.x - current.x, target.y - current.y
                local distance = dx * dx + dy * dy
                if distance <= bestDistance and (best == 0 or distance < bestDistance) then
                    best, bestDistance = i, distance
                end
            end
        end
        if best == 0 then break end
        visited[best] = true
        table.insert(chain, best)
        current = targets[best]
    end
    return chain
end

---@param index integer
---@param time number
---@return LightningPoint
function ChainLightning.TargetPosition(index, time)
    local positions = {
        { x = 210, y = 254 }, { x = 324, y = 209 }, { x = 290, y = 104 },
        { x = 132, y = 94 }, { x = 99, y = 201 }, { x = 378, y = 378 },
    }
    local point = positions[index]
    return { x = point.x + math.sin(time * 0.65 + index) * 4, y = point.y + math.cos(time * 0.55 + index) * 3 }
end

function ChainLightning:Init(props)
    UI.Widget.Init(self, props or {})
    self.entry_, self.playback_ = nil, nil
    self.paletteIndex_, self.clean_ = 1, false
    self.timeOffset_ = 0
    self.cacheCycle_ = -1
    self.chain_, self.targets_ = {}, {}
end

---@param entry GalleryEntry
---@param playback GalleryPlayback
function ChainLightning:SetEntry(entry, playback)
    self.entry_, self.playback_ = entry, playback
end

---@param index integer
function ChainLightning:SetPalette(index)
    self.paletteIndex_ = math.max(1, math.min(#Art.Palettes, index))
end

function ChainLightning:ToggleClean()
    self.clean_ = not self.clean_
end

function ChainLightning:Replay()
    self.timeOffset_ = self.playback_ and self.playback_.time or 0
    self.cacheCycle_ = -1
    print("[闪电链] 重播施法")
end

---@param time number
---@return integer[]
function ChainLightning:GetChain(time)
    local config = ChainLightning.Config
    local cycle = math.floor(time / config.cycleTime)
    if self.cacheCycle_ ~= cycle then
        local selectionTargets = {}
        for i = 1, 6 do selectionTargets[i] = ChainLightning.TargetPosition(i, cycle * config.cycleTime + config.castTime) end
        self.chain_ = ChainLightning.SelectTargets({x=210,y=344}, selectionTargets,
            config.firstRange * 420, config.jumpRange * 420, config.maxTargets)
        self.cacheCycle_ = cycle
    end
    return self.chain_
end

-- 时间驱动函数无累积积分，暂停/调速/重播与受控截图获得相同结果。
---@param age number
---@param hop integer
---@return number elapsed 从本跳电弧发出开始
---@return number strength
function ChainLightning.HopState(age, hop)
    local config = ChainLightning.Config
    local elapsed = age - config.castTime - (hop - 1) * config.hopDelay
    return elapsed, config.attenuation ^ (hop - 1)
end

local function Background(vg, age, palette)
    Art.Rect(vg, 0, 0, 420, 420, {8,11,24})
    Art.Glow(vg,210,215,240,{23,33,70},65)
    -- 极低对比石板，去掉工程网格；角部碎屑让空间有尺度但不抢技能。
    for row=0,8 do
        for col=0,8 do
            local n=Art.Noise(row*77+col*13)
            local x=col*52+(row%2)*26-26
            local y=row*50-10
            Art.Rect(vg,x,y,49,47,{13+math.floor(n*3),17+math.floor(n*4),31+math.floor(n*5)},170)
            if n>0.8 then Art.Rect(vg,x+8,y+11,3,1,{38,40,61},90) end
        end
    end
    Art.Ring(vg,210,210,176,1,-0.1,{32,38,63},80,true)
    Art.Ring(vg,210,210,169,1,0.4,{26,33,55},70,true)
    for i=1,26 do
        local x=Art.Noise(i*19)*400+10
        local y=Art.Noise(i*47)*400+10
        Art.Rect(vg,x,y,1,1,{58,72,99},60)
    end
    local flash=age>=0.58 and math.exp(-(age-0.58)*17) or 0
    Art.Rect(vg,0,0,420,420,palette.edge,flash*12)
end

local function Residual(vg, a, b, age, seed, strength, palette)
    if age<0 or age>0.65 then return end
    local fade=(1-age/0.65)^2
    local points=Art.BuildPath(a,b,seed)
    for i=2,#points do
        if Art.Noise(seed+i*29)>0.45 then
            Art.PixelLine(vg,points[i-1],points[i],1,palette.edge,fade*100*strength)
        end
    end
    for i=1,10 do
        local t=Art.Noise(seed+i*11)
        local drift=age*(Art.Noise(seed+i*17)-0.5)*28
        local x=a.x+(b.x-a.x)*t+drift
        local y=a.y+(b.y-a.y)*t-age*8
        Art.Rect(vg,x,y,i%3==0 and 2 or 1,1,palette.body,fade*200*strength)
    end
end

---@param vg NVGContextWrapper
function ChainLightning:Render(vg)
    local l=self:GetAbsoluteLayout()
    if l.w<1 or l.h<1 then return end
    local time=math.max(0,(self.playback_ and self.playback_.time or 0)-self.timeOffset_)
    local config=ChainLightning.Config
    local age,cycle=time%config.cycleTime,math.floor(time/config.cycleTime)
    local palette=Art.Palettes[self.paletteIndex_]
    local chain=self:GetChain(time)
    local hitOrder={}
    for hop,index in ipairs(chain) do hitOrder[index]=hop end
    for i=1,6 do self.targets_[i]=ChainLightning.TargetPosition(i,time) end
    nvgSave(vg)
    nvgIntersectScissor(vg,l.x,l.y,l.w,l.h)
    Art.Rect(vg,l.x,l.y,l.w,l.h,{7,9,20})
    local scale=math.min(l.w/420,l.h/420)
    -- 整倍数优先，避免像素网格在大幅展示时出现不均匀粗细。
    if scale>=1 then scale=math.max(1,math.floor(scale)) end
    nvgTranslate(vg,l.x+math.floor((l.w-420*scale)*0.5),l.y+math.floor((l.h-420*scale)*0.5))
    nvgScale(vg,scale,scale)
    if not self.clean_ then Background(vg,age,palette) end
    local muzzle={x=210,y=344}
    if not self.clean_ then
        Art.Caster(vg,210,373,age,time,palette)
        for i,p in ipairs(self.targets_) do
            local hop=hitOrder[i]
            local elapsed=hop and select(1,ChainLightning.HopState(age,hop)) or -1
            local hitAge=elapsed-config.travelTime
            local flash=hitAge>=0 and math.exp(-hitAge*13) or 0
            local damage=hitAge>=0 and config.attenuation^((hop or 1)-1) or 0
            Art.Target(vg,p.x,p.y,time+i,flash,damage,palette)
        end
    else
        -- 纯特效模式只显示施法核心和命中节点，不带角色/场景。
        local charge=age<config.castTime and age/config.castTime or math.exp(-(age-config.castTime)*8)
        Art.Glow(vg,muzzle.x,muzzle.y,22,palette.body,charge*160)
        Art.Star(vg,muzzle.x,muzzle.y,3+charge*7,math.pi*0.25,palette.core,charge*240)
    end
    ---@type LightningPoint
    local previous=muzzle
    for hop,index in ipairs(chain) do
        local endpoint=self.targets_[index]
        local elapsed,strength=ChainLightning.HopState(age,hop)
        local seed=cycle*101+hop*233
        if elapsed>=0 and elapsed<config.holdTime then
            local reveal=math.min(1,elapsed/config.travelTime)
            local attack=math.exp(-elapsed*10)
            local fade=math.min(1,(config.holdTime-elapsed)/0.25)
            local flicker=0.87+Art.Noise(math.floor(elapsed*24)+hop*37)*0.13
            -- 约14Hz轮廓重击、24Hz弱闪烁，避免每帧随机造成噪声抖动。
            local shapeSeed=seed+math.floor(math.max(0,elapsed-config.travelTime)*14)*47
            local visualStrength=0.45+strength*0.55
            Art.Bolt(vg,previous,endpoint,shapeSeed,visualStrength*fade*flicker,attack,palette,reveal)
            local packet=(elapsed*3.4)%1
            local px,py=previous.x+(endpoint.x-previous.x)*packet,previous.y+(endpoint.y-previous.y)*packet
            Art.Glow(vg,px,py,10,palette.body,60*fade*strength)
            Art.Star(vg,px,py,2+attack*2,0,palette.light,130*fade*strength)
        elseif elapsed>=config.holdTime then
            Residual(vg,previous,endpoint,elapsed-config.holdTime,seed+math.floor((config.holdTime-config.travelTime)*14)*47,strength,palette)
        end
        previous=endpoint
    end
    -- 接触爆闪置于主干上层，防止白芯压住命中形状。
    for hop,index in ipairs(chain) do
        local endpoint=self.targets_[index]
        local elapsed,strength=ChainLightning.HopState(age,hop)
        Art.Impact(vg,endpoint.x,endpoint.y,elapsed-config.travelTime,strength,cycle*101+hop*233,palette)
    end
    nvgRestore(vg)
end

return ChainLightning
