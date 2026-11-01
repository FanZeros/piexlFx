-- 竖版战斗用途索引；引用原图集，不覆盖原始素材或模拟重力。
local Catalog = require("GalleryCatalog")

local Battle = {
    groups = { "全部精选", "发射弹道", "命中反馈", "范围技能", "防御增益" },
    entries = {},
}
local originals = {}
for _, entry in ipairs(Catalog.entries) do originals[entry.id] = entry end

local function Add(id, title, group, usage, adaptation, options)
    local original = assert(originals[id], "缺少战斗素材：" .. id)
    local entry = {}
    for key, value in pairs(original) do entry[key] = value end
    entry.title = title
    entry.battleGroup = group
    entry.usage = usage
    entry.adaptation = adaptation
    entry.description = usage .. "\n" .. adaptation
    if options then
        for key, value in pairs(options) do entry[key] = value end
    end
    if entry.previewFrames then
        entry.count = math.min(entry.count, entry.previewFrames)
        entry.durations = {}
        for i = 1, entry.count do entry.durations[i] = original.durations[i] end
    end
    table.insert(Battle.entries, entry)
end

Add("pb-fireball-fx", "向上火球", "发射弹道", "推荐 · 玩家下方发射，火球向上移动。", "展示旋转朝上；飞行由外层位移演示，原图不变。", { previewMotion = "up", previewRotation = -90 })
Add("sf-energy", "能量球弹体候选", "发射弹道", "待适配 · 球体可挂到向上移动的弹丸。", "外层上移仅作预览；原图后段含向下接地电弧，正式弹道需重导。", { previewMotion = "up" })
Add("sf-muzzle-flash", "枪口火光", "发射弹道", "待适配 · 挂在武器发射点，不是飞行子弹。", "原图保留侧向火光与弹壳；正式朝上建议重导出。", { previewFrames = 12 })

Add("sf-impact", "弹丸命中火花", "命中反馈", "推荐 · 在上方敌人受击点播放一次。", "已有火花及碎屑轨迹；不代表无重力。", { previewFrames = 20 })
Add("pb-slash-hit-fx", "斩击命中", "命中反馈", "推荐 · 近战击中或剑气碰撞反馈。", "是弧线加命中闪光，不作为直线弹道。")
Add("sf-slash", "弧形刀光", "命中反馈", "推荐 · 放在玩家前方或敌人受击位置。", "原版为斜向挥砍；不是从下向上的飞行轨迹。", { previewFrames = 22 })
Add("pb-explosion-fluid", "小型爆破", "命中反馈", "推荐 · 火球、炮弹击中后的局部爆炸。", "在命中点播放；烟火仍沿原图轨迹扩散。")

Add("pb-vortex-fx", "漩涡核心", "范围技能", "推荐 · 上方目标区域的聚能、吸引视觉。", "旋涡留在目标点；吸引和伤害需要游戏逻辑。")
Add("forge-burst-storm", "雷电爆发", "范围技能", "推荐 · 目标点雷暴、连锁攻击的爆发反馈。", "径向爆发图集；不是向上贯穿光束。")
Add("forge-burst-frost", "冰霜符印爆发", "范围技能", "推荐 · 目标点冰系爆发或冻结标记。", "保留符印动画；冻结范围另行定义。")
Add("sf-ice", "冰霜新星", "范围技能", "有地面 · 敌人脚下的冻结范围技能。", "含贴地冰环、冰刺；俯视悬空战斗需重新生成。")
Add("sf-poison", "毒雾区域", "范围技能", "有地面 · 上方战区的持续伤害提示。", "现图含贴地形态；并非向上飞行的毒弹。")
Add("sf-explosion", "大型爆炸", "范围技能", "有地面 · 敌群爆破、地面范围攻击。", "有焦痕、地环、落地碎片；失重场景需改生成器。")
Add("forge-burst-fire", "火焰爆发", "范围技能", "有方向 · 目标区域的火焰技能反馈。", "原配方含下落流向；不直接充当向上弹体。")
Add("sf-holy-light", "圣光区域", "范围技能", "有地面 · 目标区域的圣光打击或治疗。", "画面是光柱与底环，不是逐段向上飞行的激光。")

Add("pb-shield-fx", "环形护盾", "防御增益", "推荐 · 跟随下方玩家的受击保护。", "中心环形视觉；阻挡弹丸需要游戏逻辑。")
Add("forge-barrier-arcane", "奥术护盾", "防御增益", "推荐 · 玩家周围的保护结界。", "跟随角色中心播放，不需要改变攻击朝向。")
Add("forge-barrier-frost", "冰霜护盾", "防御增益", "推荐 · 冰系护盾、格挡状态提示。", "居中符印；碰撞范围不能直接按亮边判定。")
Add("sf-heal", "治疗光点", "防御增益", "推荐 · 下方玩家的回复、吸血反馈。", "保留原版上升光点与底环。")
Add("pb-healing-circle-fx", "治疗法阵", "防御增益", "有地面 · 玩家脚下的治疗区域。", "原图为透视椭圆法阵；严格俯视需改成圆形。")
Add("forge-aura-holy", "圣光光环", "防御增益", "推荐 · 跟随玩家的强化状态。", "原地循环，不作为命中或弹道动画。")
Add("forge-aura-nature", "自然光环", "防御增益", "推荐 · 自然系持续增益状态。", "按原图循环；其中粒子流向保持原样。")
Add("sf-power-up", "强化爆发", "防御增益", "有角色 · 升级、觉醒、临时强化。", "原图带人形轮廓；更换角色时建议重新导出。")
Add("sf-shield", "半球护盾", "防御增益", "有地面 · 地面守点、半球防护罩。", "不是完整俯视圆罩；悬空战斗建议用环形护盾。")

table.insert(Battle.entries, {
    id = "chain-lightning", source = "实时技能", title = "闪电链 · 连锁电击",
    battleGroup = "范围技能", procedural = "chain-lightning",
    usage = "实时 · 下方施法，首击向上，再跳跃到附近敌人。",
    adaptation = "最多命中5个目标，跳跃间隔0.14秒，逐跳衰减18%；超距停止且不重复命中。",
    description = "精修实时像素电弧：聚能符环、多层分叉、逐跳接触爆闪、电屑与残电消散。支持冰蓝、紫电、金雷与纯特效模式；目标与血条为演示，未接入正式伤害。",
    origin = "本项目 Lua 程序化技能演示 · scripts/ChainLightning.lua",
    path = "", width = 420, height = 420, cols = 1, rows = 1, count = 1,
    durations = { 3800 }, license = "项目自制",
})
-- 将新技能放在精选第一项，原始73组目录保持不变。
local chainEntry = table.remove(Battle.entries)
table.insert(Battle.entries, 1, chainEntry)

return Battle
