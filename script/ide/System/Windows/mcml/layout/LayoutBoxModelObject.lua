--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBoxModelObject.lua");
local LayoutBoxModelObject = commonlib.gettable("System.Windows.mcml.layout.LayoutBoxModelObject");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutLayer.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
local IntSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local LayoutLayer = commonlib.gettable("System.Windows.mcml.layout.LayoutLayer");
local LayoutBoxModelObject = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutBoxModelObject"));

local LayoutSize = IntSize;

local PositionEnum = ComputedStyleConstants.PositionEnum;

-- Used to store state between styleWillChange and styleDidChange
local s_wasFloating = false;
local s_hadLayer = false;
local s_layerWasSelfPainting = false;

function LayoutBoxModelObject:ctor()
	self.name = "LayoutBoxModelObject";
	--RenderLayer* m_layer;
	self.layer = nil;
--	self.border = nil;
--	self.content = nil;
--
--
--		-- the next available renderable position 
--	self.availableX = 0;
--	self.availableY = 0;
--	-- the next new line position
--	self.newlineX = 0;
--	self.newlineY = 0;
--	-- the current preferred size of the container control. It may be enlarged by child controls. 
--	self.width = 0;
--	self.height = 0;
--	-- the min region in the container control which is occupied by its child controls
--	self.usedWidth = 0;
--	self.usedHeight = 0;
--	-- the real region in the container control which is occupied by its child controls
--	self.realWidth = 0;
--	self.realHeight = 0;
--
end

function LayoutBoxModelObject:init(node)
	LayoutBoxModelObject._super.init(self, node);

	return self;
end

----param new_child: a LayoutObject
--function LayoutBoxModelObject:AddChild(new_child)
--	
--end

function LayoutBoxModelObject:BorderTop()
	return self:Style():BorderTopWidth();
end

function LayoutBoxModelObject:BorderBottom()
	return self:Style():BorderBottomWidth();
end

function LayoutBoxModelObject:BorderLeft()
	return self:Style():BorderLeftWidth();
end

function LayoutBoxModelObject:BorderRight()
	return self:Style():BorderRightWidth();
end

function LayoutBoxModelObject:BorderBefore()
	return self:Style():BorderBeforeWidth();
end

function LayoutBoxModelObject:BorderAfter()
	return self:Style():BorderAfterWidth();
end

function LayoutBoxModelObject:BorderStart()
	return self:Style():BorderStartWidth();
end

function LayoutBoxModelObject:BorderEnd()
	return self:Style():BorderEndWidth();
end

function LayoutBoxModelObject:BorderAndPaddingHeight()
	return self:BorderTop() + self:BorderBottom() + self:PaddingTop() + self:PaddingBottom();
end

function LayoutBoxModelObject:BorderAndPaddingWidth()
	return self:BorderLeft() + self:BorderRight() + self:PaddingLeft() + self:PaddingRight();
end

function LayoutBoxModelObject:BorderAndPaddingLogicalHeight()
	return self:BorderBefore() + self:BorderAfter() + self:PaddingBefore() + self:PaddingAfter();
end

function LayoutBoxModelObject:BorderAndPaddingLogicalWidth()
	return self:BorderStart() + self:BorderEnd() + self:PaddingStart() + self:PaddingEnd();
end

function LayoutBoxModelObject:BorderAndPaddingLogicalLeft()
	local left = self:BorderLeft() + self:PaddingLeft();
	if(not self:Style():IsHorizontalWritingMode()) then
		left = self:BorderTop() + self:PaddingTop();
	end
	return left;
	--return self:Style():IsHorizontalWritingMode() ? self:BorderLeft() + self:PaddingLeft() : self:BorderTop() + self:PaddingTop();
end

function LayoutBoxModelObject:BorderAndPaddingStart()
	return self:BorderStart() + self:PaddingStart();
end

function LayoutBoxModelObject:BorderLogicalLeft()
	local left = self:BorderLeft();
	if(not self:Style():IsHorizontalWritingMode()) then
		left = self:BorderTop();
	end
	return left;
	--return self:Style():IsHorizontalWritingMode() ? self:BorderLeft() : self:BorderTop();
end

function LayoutBoxModelObject:BorderLogicalRight()
	local right = self:BorderRight();
	if(not self:Style():IsHorizontalWritingMode()) then
		right = self:BorderBottom();
	end
	return right;
	--return self:Style():IsHorizontalWritingMode() ? self:BorderRight() : self:BorderBottom();
end

function LayoutBoxModelObject:PaddingLeft()
	local padding = self:Style():PaddingLeft();
	local w = 0;
	if (padding:IsPercent()) then
        w = self:ContainingBlock():AvailableLogicalWidth();
	end
	return padding:CalcMinValue(w);
end

function LayoutBoxModelObject:PaddingTop()
	local padding = self:Style():PaddingTop();
	local w = 0;
	if (padding:IsPercent()) then
        w = self:ContainingBlock():AvailableLogicalWidth();
	end
	return padding:CalcMinValue(w);
end

function LayoutBoxModelObject:PaddingRight()
	local padding = self:Style():PaddingRight();
	local w = 0;
	if (padding:IsPercent()) then
        w = self:ContainingBlock():AvailableLogicalWidth();
	end
	return padding:CalcMinValue(w);
end

function LayoutBoxModelObject:PaddingBottom()
	local padding = self:Style():PaddingBottom();
	local w = 0;
	if (padding:IsPercent()) then
        w = self:ContainingBlock():AvailableLogicalWidth();
	end
	return padding:CalcMinValue(w);
end

function LayoutBoxModelObject:PaddingBefore(includeIntrinsicPadding)
	local padding = self:Style():PaddingBefore();
	local w = 0;
	if (padding:IsPercent()) then
        w = self:ContainingBlock():AvailableLogicalWidth();
	end
	return padding:CalcMinValue(w);
end

function LayoutBoxModelObject:PaddingAfter(includeIntrinsicPadding)
	local padding = self:Style():PaddingAfter();
	local w = 0;
	if (padding:IsPercent()) then
        w = self:ContainingBlock():AvailableLogicalWidth();
	end
	return padding:CalcMinValue(w);
end

function LayoutBoxModelObject:PaddingStart(includeIntrinsicPadding)
	local padding = self:Style():PaddingStart();
	local w = 0;
	if (padding:IsPercent()) then
        w = self:ContainingBlock():AvailableLogicalWidth();
	end
	return padding:CalcMinValue(w);
end

function LayoutBoxModelObject:PaddingEnd(includeIntrinsicPadding)
	local padding = self:Style():PaddingEnd();
	local w = 0;
	if (padding:IsPercent()) then
        w = self:ContainingBlock():AvailableLogicalWidth();
	end
	return padding:CalcMinValue(w);
end


function LayoutBoxModelObject:MarginLeft()
	
end

function LayoutBoxModelObject:MarginTop()
	
end

function LayoutBoxModelObject:MarginRight()
	
end

function LayoutBoxModelObject:MarginBottom()
	
end

function LayoutBoxModelObject:Float()
	return self:Style():Float();
end

function LayoutBoxModelObject:Left()
	return self:Style():Left();
end

function LayoutBoxModelObject:Top()
	return self:Style():Top();
end

function LayoutBoxModelObject:Right()
	return self:Style():Right();
end

function LayoutBoxModelObject:Bottom()
	return self:Style():Bottom();
end

-- virtual function
function LayoutBoxModelObject:BorderBoundingBox()
	
end

-- The HashMap for storing continuation pointers.
-- An inline can be split with blocks occuring in between the inline content.
-- When this occurs we need a pointer to the next object. We can basically be
-- split into a sequence of inlines and blocks. The continuation will either be
-- an anonymous block (that houses other blocks) or it will be an inline flow.
-- <b><i><p>Hello</p></i></b>. In this example the <i> will have a block as
-- its continuation but the <b> will just have an inline as its continuation.
local continuationMap = nil;

function LayoutBoxModelObject:Continuation()
	if(not continuationMap) then
		return;
	end
	return continuationMap[self];
end

function LayoutBoxModelObject:SetContinuation(continuation)
    if (continuation) then
        if (not continuationMap) then
            continuationMap = {};
		end
        continuationMap[this] = continuation;
    else
        if (continuationMap) then
            continuationMap[this] = nil;
		end
    end
end

function LayoutBoxModelObject:StyleDidChange(diff, oldStyle)
	LayoutBoxModelObject._super.StyleDidChange(self, diff, oldStyle);
	self:UpdateBoxModelInfoFromStyle();

	if (self:RequiresLayer()) then
        if (not self:Layer()) then
            if (s_wasFloating and self:IsFloating()) then
                self:SetChildNeedsLayout(true);
			end
            self.layer = LayoutLayer:new():init(self);
            self:SetHasLayer(true);
            self.layer:InsertOnlyThisLayer();
            if (self:Parent() and not self:NeedsLayout() and self:ContainingBlock()) then
                self.layer:SetNeedsFullRepaint();
                -- There is only one layer to update, it is not worth using |cachedOffset| since
                -- we are not sure the value will be used.
                self.layer:UpdateLayerPositions(0);
            end
        end
    elseif (self:Layer() and self:Layer():Parent()) then
        self:SetHasTransform(false); -- Either a transform wasn't specified or the object doesn't support transforms, so just null out the bit.
        self:SetHasReflection(false);
        self.layer:RemoveOnlyThisLayer(); -- calls destroyLayer() which clears m_layer
        if (s_wasFloating and self:IsFloating()) then
            self:SetChildNeedsLayout(true);
		end
    end

    if (self:Layer()) then
        self:Layer():StyleChanged(diff, oldStyle);
        if (s_hadLayer and self:Layer():IsSelfPaintingLayer() ~= s_layerWasSelfPainting) then
            self:SetChildNeedsLayout(true);
		end
    end
end

function LayoutBoxModelObject:UpdateBoxModelInfoFromStyle()
	-- Set the appropriate bits for a box model object.  Since all bits are cleared in styleWillChange,
    -- we only check for bits that could possibly be set to true.
    --setHasBoxDecorations(hasBackground() || style()->hasBorder() || style()->hasAppearance() || style()->boxShadow());
    self:SetInline(self:Style():IsDisplayInlineType());
    self:SetRelPositioned(self:Style():Position() == PositionEnum.RelativePosition);
    self:SetHorizontalWritingMode(self:Style():IsHorizontalWritingMode());
end

function LayoutBoxModelObject:HasInlineDirectionBordersPaddingOrMargin()
	return self:HasInlineDirectionBordersOrPadding() or self:MarginStart() ~= 0 or self:MarginEnd() ~= 0;
end

function LayoutBoxModelObject:HasInlineDirectionBordersOrPadding()
	return self:BorderStart() ~= 0 or self:BorderEnd() ~= 0 or self:PaddingStart() ~= 0 or self:PaddingEnd() ~= 0;
end

-- Overridden by subclasses to determine line height and baseline position.
--virtual LayoutUnit lineHeight(bool firstLine, LineDirectionMode, LinePositionMode = PositionOnContainingLine)
function LayoutBoxModelObject:LineHeight(firstLine, direction, linePositionMode)

end

--virtual LayoutUnit baselinePosition(FontBaseline, bool firstLine, LineDirectionMode, LinePositionMode = PositionOnContainingLine) const = 0;
function LayoutBoxModelObject:BaselinePosition(baselineType, firstLine, direction, linePositionMode)

end

function LayoutBoxModelObject:Layer()
	return self.layer;
end

function LayoutBoxModelObject:RequiresLayer()
	return self:IsRoot() or self:IsPositioned() or self:IsRelPositioned() or self:IsTransparent() or self:HasOverflowClip() or self:HasTransform() or self:HasMask() or self:HasReflection() or self:Style():SpecifiesColumns();
end

--bool RenderBoxModelObject::hasSelfPaintingLayer() const
function LayoutBoxModelObject:HasSelfPaintingLayer()
	--return false;
    return self.layer ~= nil and self.layer:IsSelfPaintingLayer();
end

--LayoutSize relativePositionOffset() const { return LayoutSize(relativePositionOffsetX(), relativePositionOffsetY()); }
function LayoutBoxModelObject:RelativePositionOffset()
	return LayoutSize:new(self:RelativePositionOffsetX(), self:RelativePositionOffsetY());
end

function LayoutBoxModelObject:RelativePositionOffsetX()
	-- Objects that shrink to avoid floats normally use available line width when computing containing block width.  However
    -- in the case of relative positioning using percentages, we can't do this.  The offset should always be resolved using the
    -- available width of the containing block.  Therefore we don't use containingBlockLogicalWidthForContent() here, but instead explicitly
    -- call availableWidth on our containing block.
    if (not self:Style():Left():IsAuto()) then
        local cb = self:ContainingBlock();
        if (not self:Style():Right():IsAuto() and not cb:Style():IsLeftToRightDirection()) then
            return -(self:Style():Right():CalcValue(cb:AvailableWidth()));
		end
        return self:Style():Left():CalcValue(cb:AvailableWidth());
    end
    if (not self:Style():Right():IsAuto()) then
        local cb = self:ContainingBlock();
        return -(self:Style():Right():CalcValue(cb:AvailableWidth()));
    end
    return 0;
end

function LayoutBoxModelObject:RelativePositionOffsetY()
	local containingBlock = self:ContainingBlock();

    -- If the containing block of a relatively positioned element does not
    -- specify a height, a percentage top or bottom offset should be resolved as
    -- auto. An exception to this is if the containing block has the WinIE quirk
    -- where <html> and <body> assume the size of the viewport. In this case,
    -- calculate the percent offset based on this height.
    -- See <https://bugs.webkit.org/show_bug.cgi?id=26396>.
    if (not self:Style():Top():IsAuto()
        and (not containingBlock:Style():Height():IsAuto()
            or not self:Style():Top():IsPercent()
            or containingBlock:StretchesToViewport())) then
        return self:Style():Top():CalcValue(containingBlock:AvailableHeight());
	end

    if (not self:Style():Bottom():IsAuto()
        and (not containingBlock:Style():Height():IsAuto()
            or not self:Style():Bottom():IsPercent()
            or containingBlock:StretchesToViewport())) then
        return -(self:Style():Bottom():CalcValue(containingBlock:AvailableHeight()));
	end
    return 0;
end