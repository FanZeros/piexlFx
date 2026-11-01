-- 交付索引：程序化效果定义与画廊条目共用，不触碰原始素材目录。
local Units = require("MotaUnits")
local Fx = require("MotaMechanics")
local Catalog = require("GalleryCatalog")
local P = require("MotaPrimitives")
---@class MotaDefinition
---@field id string
---@field width number
---@field height number
---@field anchorX number
---@field anchorY number
---@field duration number
---@field loop boolean
---@field palette string
---@field draw? function
---@field options table
---@class MotaCatalog
---@field entries GalleryEntry[]
---@field definitions table<string, MotaDefinition>
---@field groups string[]
---@field Draw fun(id:string,vg:NVGContextWrapper,t:number,options:table,colors:table)
---@type MotaCatalog
local M = { entries = {}, definitions = {}, groups = {"全部需求","P0 核心","P1 高频","P2 状态","复用素材"} }

local function Add(id,title,group,w,h,ox,oy,duration,loop,palette,draw,usage,options)
    local definition={id=id,width=w,height=h,anchorX=ox,anchorY=oy,duration=duration,loop=loop,palette=palette,draw=draw,options=options or {}}
    M.definitions[id]=definition
    table.insert(M.entries,{
        id="mota-"..id,source="魔塔实时",title=title,battleGroup=group,procedural="mota",
        effectId=id,path="",width=w,height=h,cols=1,rows=1,count=1,durations={duration*1000},license="项目自制",
        usage=usage,description=usage,adaptation="纯程序绘制；不加载图片、不附带人形。单位px，原点为素材左上，锚点见详情。",
        origin="scripts/MotaUnits.lua / MotaMechanics.lua",
    })
end

Add("lightning/chain-arc","单段闪电 · 可伸缩","P0 核心",192,84,18,42,0.35,false,"volt",Units.Arc,"0.35秒；起点锚定；默认向右，length=48（8–144）；朝向由上层旋转。",{length=48,seed=17})
Add("lightning/arc-origin","闪电起点爆发","P0 核心",96,96,48,48,0.28,false,"volt",Units.ArcOrigin,"0.28秒起点电芒；可用橙红色板组合烈焰闪电。")
Add("demo/chain-five","五段连跳 · 300ms间隔","P0 核心",336,192,48,132,1.8,false,"volt",nil,"单段模块的五跳编排；固定目标端点，非原大型闪电链。")
Add("roller/rolling-wheel","死亡滚轮 · 循环单位","P0 核心",48,48,24,44,1.2,true,"gold",Units.Wheel,"锯齿与辐条相位旋转；spin=2圈/周期；默认向右，reverse反向。",{spin=2})
Add("roller/wheel-crush","滚轮碾压 · 火花碎屑","P0 核心",96,96,48,66,0.35,false,"gold",Units.Crush,"0.35秒；地面锚定，碎屑、裂纹、薄尘与冲击环。")
Add("demo/roller-run","死亡滚轮 · 往返碾压","P0 核心",336,144,168,116,4.8,true,"gold",nil,"往返滚动与接触碾压编排；展示位移与旋转方向同步，不是整体贴图翻转。")
for _,part in ipairs({"head","body","tail"}) do
    local names={head="蛇头 · 四向吐信",body="蛇身 · 直段与拐角",tail="蛇尾 · 渐细收尾"}
    Add("critters/snake-"..part,names[part],"P0 核心",48,48,24,44,2.8,true,"leaf",
        function(vg,t,o,c) Units.Snake(vg,t,o,c,"snake-"..part) end,
        "48px模块；锚点(24,44)，躯体中心(24,24)；dir=0右/1下/2左/3上。",{dir=0,shape="straight",from=3})
end
Add("critters/snake-eat","蛇蛇进食 · 成长脉冲","P0 核心",96,88,48,44,0.45,false,"leaf",Units.Eat,"0.45秒；高光可沿蛇节延迟触发，新节从中心弹出。")
Add("critters/snake-bite","蛇蛇自噬 · 咬合断烟","P0 核心",96,88,48,44,0.38,false,"leaf",Units.Bite,"0.38秒；双排獠牙咬合、碎光和短烟；不包含真实自噬判定。")
Add("demo/snake-run","贪吃蛇 · 转弯进食成长","P0 核心",336,240,168,210,11.2,true,"leaf",nil,"8节蛇沿格子路径逐格移动，身体保持连续转角；每0.7秒一格，含进食和新尾节生长。")
Add("impacts/echo-strike","二次打击 · 轻量回响","P1 高频",96,88,48,44,0.3,false,"volt",Fx.Echo,"延迟0.1秒的小型重影火花；适合0.2秒高频触发。")
Add("sky/heaven-smite","天罚 · 单格/四周","P1 高频",160,160,80,124,0.6,false,"gold",Fx.Smite,"预警光环后落下光柱与十字灼痕；area=true加入四周反馈。",{area=false})
Add("impacts/row-sweep","行列溅射 · 扫掠冲击","P1 高频",288,88,18,44,0.5,false,"volt",Fx.Sweep,"向右扫过五个接触点；整幅转向可做列溅射；锁定起播位置。")
Add("impacts/zone-strike","区域锁定 · 延迟重击","P1 高频",160,176,80,90,0.5,false,"fire",Fx.Zone,"0.15秒锁定框后重击；cells=2或3，控制2×2/3×3范围。",{cells=2})
Add("explosions/screen-nuke","核弹 · 冲击蘑菇云","P1 高频",352,352,176,258,0.9,false,"fire",Fx.Nuke,"屏幕中心演出；局部闪白、冲击环、火云帽与烟柱。不可按0.2秒频率叠播。")
Add("moves/turret-fire","炮台枪口 · 极短火光","P1 高频",72,64,16,32,0.15,false,"fire",Fx.Muzzle,"0.15秒向右枪口火光；不画炮台/角色，弹道由上层单独触发。")
Add("projectiles/snipe-shot","狙击弹道 · 穿孔闪光","P1 高频",192,80,18,40,0.3,false,"gold",Fx.Snipe,"当前画廊无bullet-tracer，新增高速细弹道；默认朝右，终点穿孔。")
Add("ui/match-three","三消 · 消除爆发","P1 高频",96,88,48,44,0.4,false,"shadow",Fx.Match,"只做单格消除爆发和下坠碎屑，三格连线由上层编排。")
for _,kind in ipairs({"burning","poisoned","stunned","marked","buff-charge"}) do
    local names={burning="燃烧 · 贴身余焰",poisoned="中毒 · 轻薄毒泡",stunned="麻痹 · 环绕星点",marked="死亡标记 · 低亮脚印",["buff-charge"]="蓄能 · 叠层光环"}
    local palettes={burning="fire",poisoned="poison",stunned="gold",marked="shadow",["buff-charge"]="fire"}
    Add("status/"..kind,names[kind],"P2 状态",96,88,48,59,2.4,true,palettes[kind],
        function(vg,t,o,c) Fx.Status(vg,t,o,c,kind) end,
        kind=="buff-charge" and "贴地叠层光环，level=1–5；不画角色或血条。" or "小范围循环，中心留空；不画角色或血条。",kind=="buff-charge" and {level=3} or {})
end
Add("pickups/collect-pull","收集者 · 吸引轨迹","P2 状态",160,160,80,80,0.5,false,"gold",Fx.Pull,"像素光点从四周弯聚到中心；只演示轨迹，不移动真实道具。")
Add("shadow/devour","吞噬 · 内卷裂隙","P2 状态",128,128,64,64,0.55,false,"shadow",Fx.Devour,"目标点内卷吸入、暗核闭合；离间计可在两个目标间交替触发。")

-- 原素材中可直接复用的治疗/复生/升级候选，明确限制，不冒充pixelfx原ID。
local reuse={
    {"sf-heal","治愈之光 · 复用光点","治疗光点/底环；zoom按角色调整，无额外剪影。"},
    {"forge-aura-holy","复生圣光 · 复用光环","可作复生过程光效，复活逻辑另接；不是复生专用动画。"},
    {"forge-aura-nature","升级气场 · 复用自然光环","可作升级后的持续气场；不使用带人形的sf-power-up。"},
}
for _,info in ipairs(reuse) do
    for _,original in ipairs(Catalog.entries) do
        if original.id==info[1] then
            ---@type GalleryEntry
            local entry={
                id="mota-reuse-"..original.id,source=original.source,title=info[2],
                battleGroup="复用素材",usage=info[3],description=info[3],origin=original.origin,
                path=original.path,width=original.width,height=original.height,
                cols=original.cols,rows=original.rows,count=original.count,
                durations=original.durations,license=original.license,
            }
            table.insert(M.entries,entry)
        end
    end
end

function M.Draw(id,vg,t,options,colors)
    local d=M.definitions[id]
    if not d or not d.draw or t<0 or (not d.loop and t>=d.duration) then return end
    d.draw(vg,d.loop and t%d.duration or t,options or d.options,colors and #colors==6 and colors or P.Fit(colors,d.palette))
end

return M
