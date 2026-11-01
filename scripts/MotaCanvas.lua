local UI = require("urhox-libs/UI")
local Catalog = require("MotaCatalog")
local P = require("MotaPrimitives")
local Demos = require("MotaDemos")

---@class MotaCanvas : Widget
---@field entry_ GalleryEntry?
---@field playback_ GalleryPlayback?
---@field definition_ table
---@field options_ table
---@field colors_ table
---@field timeOffset_ number
---@field clean_ boolean
---@field paletteIndex_ integer
local Canvas = UI.Widget:Extend("MotaCanvas")

function Canvas:Init(props)
    UI.Widget.Init(self,props or {})
    self.entry_,self.playback_=nil,nil
    self.definition_,self.options_={},{}
    self.colors_=P.Fit(nil,"volt")
    self.timeOffset_=0
    self.clean_=false
    self.paletteIndex_=1
end

---@param entry GalleryEntry
---@param playback GalleryPlayback
function Canvas:SetEntry(entry,playback)
    self.entry_,self.playback_=entry,playback
    local definition=Catalog.definitions[entry.effectId or ""]
    assert(definition,"未知魔塔特效")
    self.definition_=definition
    self.options_={}
    for k,v in pairs(self.definition_.options) do self.options_[k]=v end
    self.colors_=P.Fit(nil,self.definition_.palette)
end

function Canvas:Replay()
    self.timeOffset_=self.playback_ and self.playback_.time or 0
end

function Canvas:ToggleClean() self.clean_=not self.clean_ end

function Canvas:SetPalette(index)
    self.paletteIndex_=index
    local names={self.definition_.palette,"fire","shadow"}
    self.colors_=P.Fit(nil,names[index] or self.definition_.palette)
end

function Canvas:ChangeVariant()
    local o=self.options_
    if o.length then o.length=o.length==48 and 96 or (o.length==96 and 144 or 48)
    elseif o.spin then o.reverse=not o.reverse
    elseif o.dir then
        local entry=self.entry_
        if entry and entry.effectId=="critters/snake-body" then
            local variant=(o.variant or 0)+1
            o.variant=variant%12
            o.dir=math.floor(o.variant/3)
            local form=o.variant%3
            o.shape=form==0 and "straight" or "corner"
            o.from=(o.dir+(form==1 and 1 or 3))%4
        else o.dir=(o.dir+1)%4 end
    elseif o.cells then o.cells=o.cells==2 and 3 or 2
    elseif o.level then o.level=o.level%5+1
    elseif o.area~=nil then o.area=not o.area end
end

function Canvas:GetVariantText()
    local o=self.options_
    if o.length then return "长度 "..o.length.."px" end
    if o.spin then return o.reverse and "滚动 ←" or "滚动 →" end
    if o.dir then
        local dirs={"右","下","左","上"}
        if o.shape=="corner" then return dirs[(o.from or 0)+1].."→"..dirs[o.dir+1] end
        return "朝向 "..dirs[o.dir+1]
    end
    if o.cells then return o.cells.."×"..o.cells.."范围" end
    if o.level then return "蓄能 "..o.level.."层" end
    if o.area~=nil then return o.area and "四周天罚" or "单格天罚" end
    return "固定形态"
end

function Canvas:Render(vg)
    local l=self:GetAbsoluteLayout()
    if l.w<1 or l.h<1 then return end
    local d=self.definition_
    if not d.id then return end
    local time=math.max(0,(self.playback_ and self.playback_.time or 0)-self.timeOffset_)
    -- one-shot 的重复是画廊编排，真实Draw在duration处严格清空。
    local period=d.loop and d.duration or d.duration+math.max(0.35,d.duration*0.4)
    local t=time%period
    nvgSave(vg)
    nvgIntersectScissor(vg,l.x,l.y,l.w,l.h)
    P.Rect(vg,l.x,l.y,l.w,l.h,{8,11,23})
    if self.playback_ and self.playback_.checker then
        for y=0,math.ceil(l.h/16) do for x=0,math.ceil(l.w/16) do
            if (x+y)%2==0 then P.Rect(vg,l.x+x*16,l.y+y*16,16,16,{22,27,43}) end
        end end
    end
    local scale=math.min((l.w-24)/d.width,(l.h-20)/d.height)
    if scale>=1 then scale=math.floor(scale) end
    nvgTranslate(vg,l.x+math.floor((l.w-d.width*scale)/2),l.y+math.floor((l.h-d.height*scale)/2))
    nvgScale(vg,scale,scale)
    nvgIntersectScissor(vg,0,0,d.width,d.height)
    if not self.clean_ then
        -- 极低对比舞台只用于看地面高度，不混入可复用特效函数。
        P.Line(vg,{x=4,y=d.anchorY},{x=d.width-4,y=d.anchorY},1,{29,36,48},90)
    end
    if d.draw then Catalog.Draw(d.id,vg,t,self.options_,self.colors_)
    elseif t<d.duration then Demos.Draw(d.id,vg,t,self.options_,self.colors_,self.clean_) end
    nvgRestore(vg)
end

return Canvas
