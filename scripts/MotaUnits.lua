-- P0 单位与逐段电弧。所有函数使用局部画布坐标，原点由上层放置。
local P = require("MotaPrimitives")
local Units = {}
local pi, sin, cos = math.pi, math.sin, math.cos

function Units.Arc(vg, t, o, c)
    if t < 0 or t >= 0.35 then return end
    if (o.length or 48)<=0 then return end
    local length = P.Clamp(o.length or 48, 8, 144)
    local x, y = 18, 42
    local reveal = P.Clamp(t / 0.055, 0, 1)
    local fade = P.Clamp((0.155 - t) / 0.1, 0, 1)
    local seed = (o.seed or 17) + math.floor(math.max(0,t-0.055)*22)*19
    local points = {{x=x,y=y}}
    local count = math.max(4,math.ceil(length/8))
    for i=1,count do
        local q=i/count
        local jitter=(P.Noise(seed+i*37)*2-1)*7*sin(q*pi)
        points[#points+1]={x=x+length*q,y=y+jitter}
    end
    for layer=1,4 do
        local colors={c[2],c[3],c[4],c[6]}
        local widths={7,4,2,1}
        local alpha=({50,130,220,255})[layer]*fade
        for i=2,#points do
            local a,b=points[i-1],points[i]
            if (i-2)/count < reveal then
                local cut=P.Clamp(reveal*count-(i-2),0,1)
                P.Line(vg,a,{x=a.x+(b.x-a.x)*cut,y=a.y+(b.y-a.y)*cut},widths[layer],colors[layer],alpha)
            end
        end
    end
    if t>0.055 and t<0.19 then
        for i=1,2 do
            local a=points[math.max(2,math.floor(count*(0.25+i*0.2)))]
            local side=i==1 and -1 or 1
            P.Path(vg,{a,{x=a.x+6,y=a.y+side*10},{x=a.x+13,y=a.y+side*13}},1,c[4],fade*155)
        end
    end
    P.Flash(vg,x,y,t,c,10)
    P.Flash(vg,x+length,y,t-0.055,c,15)
    P.Sparks(vg,x+length,y,t-0.055,0.28,91,c,10,18,4)
end

function Units.ArcOrigin(vg,t,o,c)
    if t<0 or t>=0.28 then return end
    P.Flash(vg,48,48,t,c,22)
    P.Sparks(vg,48,48,t,0.28,38,c,14,28,0)
    P.Ring(vg,48,48,5+P.Out(t/0.28)*24,0.55,c[4],(1-t/0.28)*180)
end

function Units.Wheel(vg,t,o,c)
    local phase=(t/(o.period or 1.2))%1
    -- spin 必须为整周期数，任意小数按最近整数，确保循环首尾吻合。
    local spin=math.max(1,math.floor((o.spin or 2)+0.5))
    local direction=o.reverse and -1 or 1
    local a=o.rotation or (phase*pi*2*spin*direction)
    local x,y=24,24
    P.Ring(vg,24,44,18,0.12,c[1],150)
    for i=1,5 do
        local q=(phase+i/5)%1
        local dx=direction*(-10-q*10)
        P.Disc(vg,x+dx,43-q*5,1+q*2,c[2],(1-q)*90)
    end
    P.Disc(vg,x,y,17,c[1])
    P.Disc(vg,x,y,15,{66,76,94})
    P.Disc(vg,x-1,y-1,12,{107,123,141})
    P.Disc(vg,x+1,y+1,10,{39,46,65})
    for i=1,12 do
        local angle=a+i*pi/6
        local tx,ty=x+cos(angle)*16,y+sin(angle)*16
        local ex,ey=x+cos(angle+0.16)*20,y+sin(angle+0.16)*20
        P.Path(vg,{{x=tx,y=ty},{x=ex,y=ey},{x=x+cos(angle+0.3)*16,y=y+sin(angle+0.3)*16}},3,c[3],255)
        P.Rect(vg,ex,ey,2,2,c[5])
    end
    for i=1,4 do
        local angle=a+i*pi*0.5
        P.Line(vg,{x=x+cos(angle)*3,y=y+sin(angle)*3},{x=x+cos(angle)*12,y=y+sin(angle)*12},3,{144,153,159},255)
        P.Rect(vg,x+cos(angle)*9,y+sin(angle)*9-1,2,2,c[4])
    end
    P.Disc(vg,x,y,5,c[1]);P.Disc(vg,x,y,3,c[4]);P.Rect(vg,x-1,y-2,2,2,c[6])
    P.Line(vg,{x=12,y=41},{x=35,y=41},1,c[2],160)
    local spark=(phase*4)%1
    P.Line(vg,{x=24,y=42},{x=24-direction*9*spark,y=42-5*sin(spark*pi)},1,c[5],(1-spark)*210)
end

function Units.Crush(vg,t,o,c)
    if t<0 or t>=0.35 then return end
    local fade=(1-t/0.35)^1.3
    local x,y=48,66
    for i=1,4 do
        local dx=(i-2.5)*9
        P.Path(vg,{{x=x,y=y},{x=x+dx,y=y-3},{x=x+dx*1.3,y=y+3}},1,c[2],fade*220)
    end
    P.Ring(vg,x,y,4+P.Out(t/0.35)*36,0.16,c[3],fade*200)
    P.Flash(vg,x,y-3,t,c,17)
    for i=1,14 do
        local q=t/0.35
        local dx=(P.Noise(i*19)*2-1)*34*q
        local dy=-sin(q*pi)*(7+P.Noise(i*67)*24)
        P.Rect(vg,x+dx,y+dy, i%3==0 and 3 or 2,2,i%3==0 and c[5] or c[3],fade*240)
    end
    for i=1,5 do P.Disc(vg,x+(i-3)*9*(0.3+t*2),y-3-t*9,3+t*9,c[2],fade*70) end
end

-- 模块接缝：中心 (24,24)，四边端口 (0,24)/(48,24)/(24,0)/(24,48)。
-- 每条端口宽16px；边界截断后相邻格直接连续，不随呼吸改变端口宽度。
-- 本层仅画视觉，不做碰撞：拐角连接后方与前方，U形视为无效并退回直段。
local vectors={{1,0},{0,1},{-1,0},{0,-1}}

function Units.SnakePorts(part,o)
    local d=math.floor(o.dir or 0)%4
    local forward=vectors[d+1]
    local back=vectors[(d+2)%4+1]
    if part=="snake-body" and o.shape=="corner" then
        local incoming=math.floor(o.from or ((d+3)%4))%4
        if incoming~=d then back=vectors[incoming+1] end
    end
    return {x=24+back[1]*24,y=24+back[2]*24},{x=24+forward[1]*24,y=24+forward[2]*24}
end

local function SnakePath(part,o)
    local a,b=Units.SnakePorts(part,o)
    if part=="snake-head" then return {a,{x=24,y=24}} end
    if part=="snake-body" and o.shape=="corner" and a.x~=b.x and a.y~=b.y then
        -- 二次曲线在两端垂直穿过格边，外层不画封口或中心圆帽。
        local points={}
        for i=0,12 do
            local q=i/12
            points[#points+1]={x=(1-q)^2*a.x+2*(1-q)*q*24+q*q*b.x,y=(1-q)^2*a.y+2*(1-q)*q*24+q*q*b.y}
        end
        return points
    end
    return {a,{x=24,y=24},b}
end

function Units.Snake(vg,t,o,c,part)
    nvgSave(vg)
    nvgIntersectScissor(vg,0,0,48,48)
    local points=SnakePath(part,o)
    local phase=(t/2.8)%1*pi*2
    local d=math.floor(o.dir or 0)%4
    -- 尾巴顺前进方向渐粗，后方端口收尖；头/身体端口保持固定宽度。
    if part=="snake-tail" then
        local a,b=points[1],points[3]
        for layer=1,3 do
            local color=({c[1],c[3],c[4]})[layer]
            for i=0,12 do
                local q=i/12
                local bend=sin(q*pi)*sin(phase)*2
                local nx,ny=P.Turn(0,bend,d)
                local x=a.x+(b.x-a.x)*q+nx
                local y=a.y+(b.y-a.y)*q+ny
                P.Disc(vg,x,y,math.max(1,q*(layer==1 and 9 or (layer==2 and 7 or 4))),color)
            end
        end
    else
        P.Path(vg,points,18,c[1],255)
        P.Path(vg,points,14,c[3],255)
        P.Path(vg,points,8,c[4],255)
    end
    -- 鳞片跟随曲线路径；尾尖只保留靠连接端的鳞纹，避免悬空色块。
    for i=1,5 do
        local q=i/6
        local at=q*(#points-1)
        local index=math.min(#points-1,math.floor(at)+1)
        local f=at-(index-1)
        local a,b=points[index],points[index+1]
        local x=a.x+(b.x-a.x)*f
        local y=a.y+(b.y-a.y)*f+sin(phase+i)*0.6
        if (part~="snake-tail" or i>=4) and (part~="snake-head" or i<4) then
            P.Rect(vg,x-2,y-1,4,2,c[2],210)
            P.Rect(vg,x-1,y-1,2,1,c[5],130+sin(phase+i)*35)
        end
    end
    if part=="snake-head" then
        -- 眼睛在四向都保持朝屏幕的亮点，不旋转整张脸或附带角色剪影。
        local dx,dy=P.Turn(6,0,d)
        local hx,hy=24+dx,24+dy
        P.Disc(vg,hx,hy,10,c[1]);P.Disc(vg,hx,hy-1,8,c[3]);P.Disc(vg,hx-1,hy-2,5,c[4])
        for side=-1,1,2 do
            local ex,ey=P.Turn(7,side*5,d)
            P.Rect(vg,24+ex-2,24+ey-2,4,4,c[6])
            P.Rect(vg,24+ex,24+ey-1,2,3,c[1])
        end
        local tongue=math.max(0,sin(phase*2)-0.35)/0.65
        if tongue>0 then
            local function Pt(x,y) local rx,ry=P.Turn(x,y,d);return {x=24+rx,y=24+ry} end
            local endX=15+tongue*6
            P.Path(vg,{Pt(12,0),Pt(endX,0),Pt(endX+2,-2)},1,{241,97,135},255)
            P.Line(vg,Pt(endX,0),Pt(endX+2,2),1,{241,97,135},255)
        end
        -- 鼻孔和下颌，按方向定位但明暗保持屏幕上方受光。
        local nx,ny=P.Turn(12,0,d);P.Rect(vg,24+nx,24+ny,1,1,c[1])
    end
    nvgRestore(vg)
end

function Units.Eat(vg,t,o,c)
    if t<0 or t>=0.45 then return end
    local q=t/0.45
    P.Ring(vg,48,44,4+P.Out(q)*26,0.55,c[4],(1-q)*200)
    P.Flash(vg,48,39,t,c,15)
    P.Sparks(vg,48,40,t,0.45,73,c,12,27,-5)
    -- 新节从中心弹出，不画头部，供上层把成长脉冲沿身体逐节触发。
    local s=q<0.3 and P.Out(q/0.3) or 1
    P.Disc(vg,48,44,5*s,c[5],(1-q)*200)
end

function Units.Bite(vg,t,o,c)
    if t<0 or t>=0.38 then return end
    local q=t/0.38
    local gap=2+(1-P.Out(math.min(1,q*4)))*14+math.max(0,q-0.55)*12
    for side=-1,1,2 do
        for i=-1,1 do
            local x=48+i*7
            P.Path(vg,{{x=x-3,y=44+side*(gap+4)},{x=x,y=44+side*gap},{x=x+3,y=44+side*(gap+4)}},2,c[5],(1-q)*255)
        end
    end
    if t>0.07 then
        P.Flash(vg,48,44,t-0.07,c,17)
        P.Sparks(vg,48,44,t-0.07,0.3,151,c,12,30,8)
        for i=1,5 do P.Disc(vg,48+(i-3)*5*(1+q),44-q*10,2+q*4,c[2],(1-q)*70) end
    end
end

return Units
