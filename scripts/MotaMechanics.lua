-- 高频机制与状态：有限色阶、定量粒子、无累积状态，one-shot 在时长处直接归零。
local P = require("MotaPrimitives")
local Fx = {}
local pi,sin,cos=math.pi,math.sin,math.cos

function Fx.Echo(vg,t,o,c)
    if t<0.1 or t>=0.3 then return end
    local age=t-0.1
    local q=age/0.2
    P.Star(vg,48+q*3,44-q*2,13*(1-q),0.3,c[3],(1-q)*85)
    P.Flash(vg,48,44,age,c,10)
    P.Sparks(vg,48,44,age,0.2,72,c,7,18,4)
end

function Fx.Smite(vg,t,o,c)
    if t<0 or t>=0.6 then return end
    local x,y=80,124
    local q=t/0.6
    local radius=o.area and 56 or 25
    if t<0.15 then
        P.Ring(vg,x,y,radius*(1-t/0.15*0.35),0.3,c[4],t/0.15*170)
        P.Star(vg,x,22,8+sin(t*25)*3,0,c[5],200)
    else
        local age=t-0.15
        local flash=math.exp(-age*13)
        P.Glow(vg,x,y-32,65,c[4],flash*160)
        for layer=1,4 do
            local width=({21,11,5,2})[layer]*(0.25+flash*0.75)
            P.Rect(vg,x-width/2,14,width,y-14,c[layer+2],flash*({65,125,210,255})[layer])
        end
        local fade=(1-q)^1.2
        P.Line(vg,{x=x-radius,y=y},{x=x+radius,y=y},2,c[3],fade*180)
        P.Line(vg,{x=x,y=y-10},{x=x,y=y+10},2,c[4],fade*180)
        P.Ring(vg,x,y,5+P.Out(age/0.45)*radius,0.3,c[4],fade*220)
        P.Flash(vg,x,y,age,c,20)
        P.Sparks(vg,x,y-4,age,0.45,42,c,18,math.min(radius,44),4)
        if o.area then
            for i=0,3 do
                local a=i*pi/2
                P.Flash(vg,x+cos(a)*42,y+sin(a)*16,age-0.07,c,10)
            end
        end
    end
end

function Fx.Sweep(vg,t,o,c)
    if t<0 or t>=0.5 then return end
    local x=18+P.Out(t/0.38)*250
    local y=44
    local fade=P.Clamp((0.5-t)/0.15,0,1)
    P.Line(vg,{x=18,y=y},{x=x,y=y},9,c[2],fade*45)
    P.Line(vg,{x=math.max(18,x-65),y=y},{x=x,y=y},3,c[4],fade*180)
    P.Line(vg,{x=math.max(18,x-18),y=y},{x=x,y=y},1,c[6],fade*255)
    P.Path(vg,{{x=x-8,y=y-17},{x=x+2,y=y},{x=x-8,y=y+17}},2,c[5],fade*240)
    for i=1,5 do
        local at=0.38*(1-(1-i*46/250)^(1/3))
        P.Sparks(vg,18+i*46,y,t-at,0.16,70+i,c,5,11,0)
    end
end

function Fx.Zone(vg,t,o,c)
    if t<0 or t>=0.5 then return end
    local n=o.cells==3 and 3 or 2
    local r=n==3 and 58 or 39
    local x,y=80,90
    if t<0.15 then
        local a=(0.5+t/0.15*0.5)*220
        for sx=-1,1,2 do for sy=-1,1,2 do
            P.Path(vg,{{x=x+sx*(r-9),y=y+sy*r},{x=x+sx*r,y=y+sy*r},{x=x+sx*r,y=y+sy*(r-9)}},2,c[4],a)
        end end
        P.Rect(vg,x-2,y-2,5,5,c[5],170)
    else
        local age=t-0.15
        local q=age/0.35
        P.Rect(vg,x-7,y-r-12+P.Out(math.min(1,age/0.065))*r,14,r,c[3],math.exp(-age*25)*150)
        P.Flash(vg,x,y,age,c,27)
        P.Ring(vg,x,y,4+P.Out(q)*r,0.65,c[4],(1-q)*200)
        P.Sparks(vg,x,y,age,0.35,28,c,20,r,9)
    end
end

function Fx.Nuke(vg,t,o,c)
    if t<0 or t>=0.9 then return end
    local x,y=176,258
    local fade=P.Clamp((0.9-t)/0.26,0,1)
    if t<0.11 then
        P.Glow(vg,x,y-82,170,c[5],(1-t/0.11)*180)
        P.Star(vg,x,y,88*(1-t/0.11),0,c[6],(1-t/0.11)*255)
    end
    P.Ring(vg,x,y,8+P.Out(t/0.9)*157,0.35,c[4],(1-t/0.9)*230)
    -- 蘑菇云先长茎再铺开帽沿，暗底/火沿/内核三层扫描圆盘。
    local grow=P.Out(t/0.5)
    local top=y-120*grow
    for layer=1,3 do
        local colors={c[1],c[3],c[4]}
        local radius=({23,17,9})[layer]
        for i=0,5 do
            P.Disc(vg,x+sin(i*1.7)*5,y-i*16*grow,radius*(0.5+grow*0.5),colors[layer],fade*({220,170,160})[layer])
        end
        for i=-3,3 do
            local dx=i*22*grow
            P.Disc(vg,x+dx,top+math.abs(i)*5,((layer==1 and 29 or 22)-(layer-1)*4)*grow,colors[layer],fade*({235,180,160})[layer])
        end
    end
    P.Sparks(vg,x,y-10,t,0.9,48,c,25,85,8)
    for i=1,8 do
        local q=P.Clamp((t-0.2)/0.7,0,1)
        P.Disc(vg,x+(i-4.5)*27*grow,top-5-q*24,10+q*9,c[2],fade*q*85)
    end
end

function Fx.Muzzle(vg,t,o,c)
    if t<0 or t>=0.15 then return end
    local q=t/0.15
    P.Glow(vg,22,32,21,c[4],(1-q)*120)
    P.Path(vg,{{x=16,y=32},{x=30,y=24},{x=47-q*20,y=32},{x=29,y=39},{x=16,y=32}},3,c[3],(1-q)*230)
    P.Line(vg,{x=16,y=32},{x=42-q*15,y=32},3,c[6],(1-q)*255)
    P.Sparks(vg,28,32,t,0.15,39,c,6,15,2)
end

function Fx.Snipe(vg,t,o,c)
    if t<0 or t>=0.3 then return end
    local x=18+P.Out(t/0.09)*148
    local fade=P.Clamp((0.22-t)/0.1,0,1)
    P.Line(vg,{x=math.max(18,x-90),y=40},{x=x,y=40},3,c[3],fade*100)
    P.Line(vg,{x=math.max(18,x-37),y=40},{x=x,y=40},1,c[6],fade*230)
    P.Flash(vg,166,40,t-0.09,c,12)
    P.Ring(vg,166,40,3+P.Clamp((t-0.09)*70,0,14),1,c[2],t>0.09 and (1-t/0.3)*170 or 0)
end

function Fx.Match(vg,t,o,c)
    if t<0 or t>=0.4 then return end
    local q=t/0.4
    local r=math.max(0,12*(1-P.Out(q*2)))
    P.Disc(vg,48,44,r,c[4],220)
    P.Flash(vg,48,44,t,c,18)
    P.Ring(vg,48,44,5+P.Out(q)*28,0.8,c[3],(1-q)*150)
    for i=1,9 do
        local a=i*2.4
        local dx=cos(a)*(8+P.Noise(i)*18)*q
        local dy=sin(a)*(8+P.Noise(i*29)*18)*q+q*q*14
        P.Rect(vg,48+dx,44+dy,2,2,c[i%3+3],(1-q)*255)
    end
end

function Fx.Status(vg,t,o,c,kind)
    local phase=t/2.4*pi*2
    local x,y=48,51
    if kind=="burning" then
        for i=1,7 do
            local q=(t/2.4+i/7)%1
            local px=x+(P.Noise(i*23)*2-1)*15
            P.Disc(vg,px,y-q*22,2+(1-q)*2,c[3],sin(q*pi)*170)
            P.Rect(vg,px,y-q*22,2,3,c[5],sin(q*pi)*180)
        end
    elseif kind=="poisoned" then
        P.Ring(vg,x,y+8,17,0.3,c[3],100)
        for i=1,5 do
            local q=(t/2.4+i/5)%1
            P.Ring(vg,x+sin(i*3)*15,y-q*24,2+q*2,1,c[4],sin(q*pi)*180)
        end
    elseif kind=="stunned" then
        for i=1,3 do
            local a=phase+i*pi*2/3
            P.Star(vg,x+cos(a)*18,y-28+sin(a)*4,3,0,c[5],210)
        end
    elseif kind=="marked" then
        P.Ring(vg,x,y+8,19,0.32,c[3],85+sin(phase)*20,0)
        for i=0,3 do
            local a=i*pi/2
            P.Star(vg,x+cos(a)*17,y+8+sin(a)*5,3,pi/4,c[4],130)
        end
        P.Path(vg,{{x=x-4,y=y+7},{x=x,y=y+10},{x=x+4,y=y+7}},1,c[5],160)
    elseif kind=="buff-charge" then
        local level=P.Clamp(o.level or 3,1,5)
        for ring=1,level do P.Ring(vg,x,y+9,9+ring*3,0.35,c[3+ring%2],40+level*15,math.floor((t/2.4)%1*9)+ring) end
        for i=1,8 do
            local q=(t/2.4+i/8)%1
            P.Rect(vg,x+cos(i*2.4)*19,y+8-q*37,1,3,c[5],sin(q*pi)*(90+level*22))
        end
    end
end

function Fx.Pull(vg,t,o,c)
    if t<0 or t>=0.5 then return end
    local q=P.Out(t/0.5)
    for i=1,9 do
        local a=i*2.399
        local r=(1-q)*(22+P.Noise(i*47)*41)
        local x,y=80+cos(a)*r,80+sin(a)*r*0.65
        P.Line(vg,{x=x,y=y},{x=x+cos(a)*7*(1-q),y=y+sin(a)*7*(1-q)},1,c[4],sin(t/0.5*pi)*210)
        P.Rect(vg,x,y,2,2,c[5],sin(t/0.5*pi)*230)
    end
    P.Flash(vg,80,80,t-0.37,c,14)
end

function Fx.Devour(vg,t,o,c)
    if t<0 or t>=0.55 then return end
    local q=t/0.55
    P.Glow(vg,64,64,36,c[3],sin(q*pi)*90)
    for i=1,24 do
        local a=i*2.399+q*3
        local r=(1-q)*(10+P.Noise(i*11)*39)
        P.Rect(vg,64+cos(a)*r,64+sin(a)*r*0.6,2,2,c[i%3+2],sin(q*pi)*230)
    end
    local r=sin(q*pi)*18
    P.Disc(vg,64,64,r,c[1],235)
    P.Ring(vg,64,64,r,0.65,c[4],sin(q*pi)*200)
    if q>0.6 then P.Flash(vg,64,64,t-0.33,c,12) end
end

return Fx
