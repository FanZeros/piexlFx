-- 编排演示与实际素材分离：不把整场景当成单段素材交付。
local P = require("MotaPrimitives")
local Units = require("MotaUnits")
local M = {}
local pi=math.pi

local function Place(vg,x,y,fn)
    nvgSave(vg);nvgTranslate(vg,x,y);fn();nvgRestore(vg)
end

function M.Chain(vg,t,o,c,clean)
    local points={{x=48,y=132},{x=96,y=132},{x=144,y=84},{x=192,y=84},{x=240,y=132},{x=288,y=84}}
    for hop=1,5 do
        local a,b=points[hop],points[hop+1]
        local dx,dy=b.x-a.x,b.y-a.y
        local length=math.sqrt(dx*dx+dy*dy)
        local age=t-(hop-1)*0.3
        if not clean then
            P.Disc(vg,b.x,b.y,6,c[1],255)
            P.Disc(vg,b.x,b.y,3,c[3],180)
        end
        nvgSave(vg);nvgTranslate(vg,a.x,a.y);nvgRotate(vg,math.atan(dy,dx));nvgTranslate(vg,-18,-42)
        Units.Arc(vg,age,{length=length,seed=hop*47},c)
        nvgRestore(vg)
    end
end

function M.Roller(vg,t,o,c,clean)
    local cycle=t%4.8
    local forward=cycle<2.4
    local u=forward and cycle/2.4 or (cycle-2.4)/2.4
    local x=forward and 44+u*248 or 292-u*248
    if not clean then
        P.Line(vg,{x=18,y=117},{x=318,y=117},1,{50,49,66},220)
        for i=1,5 do P.Rect(vg,42+i*46,119,14,2,c[1],120) end
    end
    for i=1,5 do
        local at=i*0.39
        local age=(cycle%2.4)-at
        local contact=forward and 44+at/2.4*248 or 292-at/2.4*248
        Place(vg,contact-48,116-66,function() Units.Crush(vg,age,{},c) end)
    end
    Place(vg,x-24,116-44,function() Units.Wheel(vg,cycle,{reverse=not forward,spin=2,period=1.2,rotation=(x-44)/20},c) end)
end

-- 闭合格子路径，16条边，每边48px。插值采用弧长，转弯也沿格子边而非抄近路。
local route={
    {x=216,y=144},{x=264,y=144},{x=312,y=144},{x=312,y=96},{x=312,y=48},
    {x=264,y=48},{x=216,y=48},{x=168,y=48},{x=168,y=96},{x=168,y=144},
    {x=120,y=144},{x=72,y=144},{x=72,y=192},{x=120,y=192},{x=168,y=192},{x=168,y=144},
}

function M.SnakePoint(distance)
    local q=(distance/48)%#route
    local index=math.floor(q)+1
    local a,b=route[index],route[index%#route+1]
    local f=q-math.floor(q)
    local direction=b.x>a.x and 0 or (b.y>a.y and 1 or (b.x<a.x and 2 or 3))
    return {x=a.x+(b.x-a.x)*f,y=a.y+(b.y-a.y)*f,dir=direction}
end

function M.SnakeState(t)
    local age=t%11.2
    local length=96
    for i=1,5 do length=length+48*P.Out((age-i*1.4)/0.18) end
    local cut=P.Out((age-10.5)/0.22)
    length=length+(96-length)*cut
    return age,length,age>=10.5
end

function M.Snake(vg,t,o,c,clean)
    local headDistance=t/0.7*48
    local age,length,cutting=M.SnakeState(t)
    local count=math.floor(length/48)+1
    local tailDistance=headDistance-length
    local bodyStart=tailDistance+32
    local head=M.SnakePoint(headDistance)
    local points={M.SnakePoint(bodyStart)}
    for d=(math.floor(bodyStart/48)+1)*48,headDistance,48 do points[#points+1]=M.SnakePoint(d) end
    points[#points+1]=head
    if not clean then
        for _,p in ipairs(route) do P.Rect(vg,p.x-21,p.y-21,42,42,{22,29,36},120) end
        local food=M.SnakePoint((math.floor(headDistance/96)+1)*96)
        P.Star(vg,food.x,food.y,5,pi/4,{250,195,86},220)
        P.Rect(vg,food.x,food.y-2,1,1,{255,255,210})
    end
    -- 路径躯干以同一宽度过角；层级由暗轮廓到鳞片高光，保证转角不留洞。
    for layer=1,3 do
        local width=({18,14,8})[layer]
        local color=({c[1],c[3],c[4]})[layer]
        P.Path(vg,points,width,color,255)
        for i=2,#points-1 do P.Disc(vg,points[i].x,points[i].y,width*0.5,color) end
    end
    for d=bodyStart+5,headDistance-12,8 do
        local p=M.SnakePoint(d)
        P.Rect(vg,p.x-2,p.y-2,4,3,c[2],240)
        P.Rect(vg,p.x-1,p.y-2,2,1,c[5],160)
    end
    -- 尾部沿历史路径连续渐细；只有尖端一像素，前接身体，不叠第二个完整蛇节。
    for layer=1,3 do
        local color=({c[1],c[3],c[4]})[layer]
        local radius=({9,7,4})[layer]
        for step=0,16 do
            local q=step/16
            local point=M.SnakePoint(tailDistance+q*32)
            P.Disc(vg,point.x,point.y,math.max(1,q*radius),color)
        end
    end
    Place(vg,head.x-24,head.y-24,function() Units.Snake(vg,t%2.8,{dir=head.dir},c,"snake-head") end)
    local phase=age%1.4
    if age>=1.4 and age<7.5 and not cutting then
        for segment=0,count-1 do
            local pulseAge=phase-segment*0.045
            if pulseAge>=0 and pulseAge<0.32 then
                local p=M.SnakePoint(headDistance-segment*48)
                P.Ring(vg,p.x,p.y,9,1,c[5],(1-pulseAge/0.32)*155)
            end
        end
        Place(vg,head.x-48,head.y-44,function() Units.Eat(vg,phase,{},c) end)
    end
    if cutting then
        -- 路线在第9/15节点自交：(168,144)。头到达旧身体后才开始截短。
        Place(vg,168-48,144-44,function() Units.Bite(vg,age-10.5,{},c) end)
    end
end

function M.Draw(id,vg,t,o,c,clean)
    if id=="demo/chain-five" then M.Chain(vg,t,o,c,clean)
    elseif id=="demo/roller-run" then M.Roller(vg,t,o,c,clean)
    elseif id=="demo/snake-run" then M.Snake(vg,t,o,c,clean) end
end

return M
