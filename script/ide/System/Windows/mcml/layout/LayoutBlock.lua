--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");
LayoutBlock:new():init();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlockLineLayout.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObjectChildList.lua");
local LayoutObjectChildList = commonlib.gettable("System.Windows.mcml.layout.LayoutObjectChildList");
local Size = commonlib.gettable("System.Windows.mcml.geometry.IntSize");
local Rect = commonlib.gettable("System.Windows.mcml.geometry.IntRect");
local Length = commonlib.gettable("System.Windows.mcml.geometry.Length");
local LayoutModel = commonlib.gettable("System.Windows.mcml.layout.LayoutModel");
local LayoutBlock = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBox"), commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"));

local MarginInfo = commonlib.inherit(nil,{});

function MarginInfo:ctor()
	self.atBeforeSideOfBlock = true;
    self.atAfterSideOfBlock = false;
    self.marginBeforeQuirk = false;
    self.marginAfterQuirk = false;
    self.determinedMarginBeforeQuirk = false;

	self.canCollapseWithChildren = nil;
	self.canCollapseMarginBeforeWithChildren = nil;
	self.canCollapseMarginAfterWithChildren = nil;
	self.quirkContainer = nil;
	self.positiveMargin = nil;
	self.negativeMargin = nil;
end
-- @param block: LayoutBlock object
-- @param beforeBorderPadding: length number
-- @param afterBorderPadding: length number
function MarginInfo:init(block, beforeBorderPadding, afterBorderPadding)
	-- Whether or not we can collapse our own margins with our children.  We don't do this
    -- if we had any border/padding (obviously), if we're the root or HTML elements, or if
    -- we're positioned, floating, a table cell.
    self.canCollapseWithChildren = not block:IsLayoutView() and not block:IsRoot() and not block:IsPositioned()
        and not block:IsFloating() and not block:IsTableCell() and not block:HasOverflowClip() and not block:IsInlineBlockOrInlineTable()
        and not block:IsWritingModeRoot() and block:Style():HasAutoColumnCount() and block:Style():HasAutoColumnWidth()
        and not block:Style():ColumnSpan();

    self.canCollapseMarginBeforeWithChildren = self.canCollapseWithChildren and (beforeBorderPadding == 0) and block:Style():MarginBeforeCollapse() ~= "MSEPARATE";

    -- If any height other than auto is specified in CSS, then we don't collapse our bottom
    -- margins with our children's margins.  To do otherwise would be to risk odd visual
    -- effects when the children overflow out of the parent block and yet still collapse
    -- with it.  We also don't collapse if we have any bottom border/padding.
    self.canCollapseMarginAfterWithChildren = self.canCollapseWithChildren and (afterBorderPadding == 0) and
        (Length.IsAuto(block:Style():LogicalHeight()) and block:Style():LogicalHeight() == 0) and block:Style():MarginAfterCollapse() ~= "MSEPARATE";
    
    self.quirkContainer = block:IsTableCell() or block:IsBody() or block:Style():MarginBeforeCollapse() == "MDISCARD" or block:Style():MarginAfterCollapse() == "MDISCARD";

    self.positiveMargin = if_else(self.canCollapseMarginBeforeWithChildren, block:MaxPositiveMarginBefore(), 0);
    self.negativeMargin = if_else(self.canCollapseMarginBeforeWithChildren, block:MaxNegativeMarginBefore(), 0);
	return self;
end

function MarginInfo:SetAtBeforeSideOfBlock(b)
	self.atBeforeSideOfBlock = b;
end

function MarginInfo:SetAtAfterSideOfBlock(b)
	self.atAfterSideOfBlock = b;
end

function MarginInfo:ClearMargin()
	self.positiveMargin = 0;
	self.negativeMargin = 0;
end

function MarginInfo:SetMarginBeforeQuirk(b)
	self.marginBeforeQuirk = b;
end

function MarginInfo:SetMarginAfterQuirk(b)
	self.marginAfterQuirk = b;
end

function MarginInfo:SetDeterminedMarginBeforeQuirk(b)
	self.determinedMarginBeforeQuirk = b;
end

function MarginInfo:SetPositiveMargin(p)
	self.positiveMargin = p;
end

function MarginInfo:SetNegativeMargin(n)
	self.negativeMargin = n;
end

function MarginInfo:SetPositiveMarginIfLarger(p)
	if (p > self.positiveMargin) then 
		self.positiveMargin = p;
	end
end

function MarginInfo:SetNegativeMarginIfLarger(n)
	if (n > self.negativeMargin) then
		self.negativeMargin = n;
	end
end

function MarginInfo:SetMargin(positive, negative)
	self.positiveMargin = positive; 
	self.negativeMargin = negative;
end

function MarginInfo:AtBeforeSideOfBlock()
	return self.atBeforeSideOfBlock;
end

function MarginInfo:CanCollapseWithMarginBefore()
	return self.atBeforeSideOfBlock and self.canCollapseMarginBeforeWithChildren;
end

function MarginInfo:CanCollapseWithMarginAfter()
	return self.atAfterSideOfBlock and self.canCollapseMarginAfterWithChildren;
end

function MarginInfo:CanCollapseMarginBeforeWithChildren()
	return self.canCollapseMarginBeforeWithChildren;
end

function MarginInfo:CanCollapseMarginAfterWithChildren()
	return self.canCollapseMarginAfterWithChildren;
end

function MarginInfo:QuirkContainer()
	return self.quirkContainer;
end

function MarginInfo:DeterminedMarginBeforeQuirk()
	return self.determinedMarginBeforeQuirk;
end

function MarginInfo:MarginBeforeQuirk()
	return self.marginBeforeQuirk;
end

function MarginInfo:MarginAfterQuirk()
	return self.marginAfterQuirk;
end

function MarginInfo:PositiveMargin()
	return self.positiveMargin;
end

function MarginInfo:NegativeMargin()
	return self.negativeMargin;
end

function MarginInfo:Margin()
	return self.positiveMargin - self.negativeMargin;
end

local MarginValues = commonlib.inherit(nil,{});

function MarginValues:ctor()
	self.positiveMarginBefore = nil;
	self.negativeMarginBefore = nil;
	self.positiveMarginAfter = nil;
	self.negativeMarginAfter = nil;
end

function MarginValues:init(beforePos, beforeNeg, afterPos, afterNeg)
	self.positiveMarginBefore = beforePos;
	self.negativeMarginBefore = beforeNeg;
	self.positiveMarginAfter = afterPos;
	self.negativeMarginAfter = afterNeg;

	return self;
end

function MarginValues:PositiveMarginBefore()
	return self.positiveMarginBefore;
end

function MarginValues:NegativeMarginBefore()
	return self.negativeMarginBefore;
end

function MarginValues:PositiveMarginAfter()
	return self.positiveMarginAfter;
end

function MarginValues:NegativeMarginAfter()
	return self.negativeMarginAfter;
end

function MarginValues:SetPositiveMarginBefore(pos)
	self.positiveMarginBefore = pos;
end

function MarginValues:SetNegativeMarginBefore(neg)
	self.negativeMarginBefore = neg;
end

function MarginValues:SetPositiveMarginAfter(pos)
	self.positiveMarginAfter = pos;
end

function MarginValues:SetNegativeMarginAfter(neg)
	self.negativeMarginAfter = neg;
end

function LayoutBlock:ctor()
	self.name = "LayoutBlock";

	-- LayoutObjectChildList object;
	self.children = LayoutObjectChildList:new();

	--self.lineBoxes = nil;

	self:SetChildrenInline(true);
end

function LayoutBlock:Children()
	return self.children;
end

-------------------------------------------------------------------------------------------------------------------------
---			html layout function
--
--
--
--
--

---------------------------------------------------------------------------------------------------
----------------	webkit/chromium	function

function LayoutBlock:IsLayoutBlock()
	return true;
end

function LayoutBlock:ComputeInlinePreferredLogicalWidths()
	--TODO: fixed this function
end

function LayoutBlock:ComputeBlockPreferredLogicalWidths()
	local nowrap = self:Style():WhiteSpace() == "nowrap";

    local child = self:FirstChild();
    local containingBlock = self:ContainingBlock();
    local floatLeftWidth floatRightWidth = 0, 0;
    while (child) do
        -- Positioned children don't affect the min/max width
        if (child:IsPositioned()) then
            child = child:NextSibling();
        else

--			if (child:IsFloating() or (child:IsBox() and child:AvoidsFloats())) then
--				local floatTotalWidth = floatLeftWidth + floatRightWidth;
--				if (child:Style()->clear() & CLEFT) {
--					m_maxPreferredLogicalWidth = max(floatTotalWidth, m_maxPreferredLogicalWidth);
--					floatLeftWidth = 0;
--				}
--				if (child->style()->clear() & CRIGHT) {
--					m_maxPreferredLogicalWidth = max(floatTotalWidth, m_maxPreferredLogicalWidth);
--					floatRightWidth = 0;
--				}
--			}

			-- A margin basically has three types: fixed, percentage, and auto (variable).
			-- Auto and percentage margins simply become 0 when computing min/max width.
			-- Fixed margins can be added in as is.
			local startMarginLength = child:Style():MarginStartUsing(self:Style());
			local endMarginLength = child:Style():MarginEndUsing(self:Style());
			local margin = 0;
			local marginStart = 0;
			local marginEnd = 0;
			if (Length.isFixed(startMarginLength)) then
				marginStart = marginStart + startMarginLength;
			end
			if (Length.isFixed(endMarginLength)) then
				marginEnd = marginEnd + endMarginLength;
			end
			margin = marginStart + marginEnd;

			local childMinPreferredLogicalWidth, childMaxPreferredLogicalWidth;
			if (child:IsBox() and child:IsHorizontalWritingMode() ~= self:IsHorizontalWritingMode()) then
				local childBox = child;
				local oldHeight = childBox:LogicalHeight();
				self:SetLogicalHeight(childBox:BorderAndPaddingLogicalHeight());
				childBox:ComputeLogicalHeight();
				childMinPreferredLogicalWidth = childBox:LogicalHeight();
				childMaxPreferredLogicalWidth = childMinPreferredLogicalWidth;
				childBox:SetLogicalHeight(oldHeight);
			else
				childMinPreferredLogicalWidth = child:MinPreferredLogicalWidth();
				childMaxPreferredLogicalWidth = child:MaxPreferredLogicalWidth();
			end

			local w = childMinPreferredLogicalWidth + margin;
			self.minPreferredLogicalWidth = math.max(w, self.minPreferredLogicalWidth);
        
			-- IE ignores tables for calculation of nowrap. Makes some sense.
			if (nowrap and not child:IsTable()) then
				self.maxPreferredLogicalWidth = math.max(w, self.maxPreferredLogicalWidth);
			end

			w = childMaxPreferredLogicalWidth + margin;

			if (not child:IsFloating()) then
				if (child:IsBox() and child:AvoidsFloats()) then
					-- Determine a left and right max value based off whether or not the floats can fit in the
					-- margins of the object.  For negative margins, we will attempt to overlap the float if the negative margin
					-- is smaller than the float width.
					local ltr = if_else(containingBlock, containingBlock:Style():IsLeftToRightDirection(), self:Style():IsLeftToRightDirection());
					local marginLogicalLeft = if_else("ltr", marginStart, marginEnd);
					local marginLogicalRight = if_else("ltr", marginEnd, marginStart);
					local maxLeft = if_else(marginLogicalLeft > 0, math.max(floatLeftWidth, marginLogicalLeft), floatLeftWidth + marginLogicalLeft);
					local maxRight = if_else(marginLogicalRight > 0, math.max(floatRightWidth, marginLogicalRight), floatRightWidth + marginLogicalRight);
					w = childMaxPreferredLogicalWidth + maxLeft + maxRight;
					w = math.max(w, floatLeftWidth + floatRightWidth);
				else
					self.maxPreferredLogicalWidth = math.max(floatLeftWidth + floatRightWidth, self.maxPreferredLogicalWidth);
				end
				floatLeftWidth, floatRightWidth = 0, 0;
			end
        
			if (child:IsFloating()) then
				if (self:Style():Floating() == "left") then
					floatLeftWidth = floatLeftWidth + w;
				else
					floatRightWidth = floatRightWidth + w;
				end
			else
				self.maxPreferredLogicalWidth = math.max(w, self.maxPreferredLogicalWidth);
			end

--			// A very specific WinIE quirk.
--			// Example:
--			/*
--			   <div style="position:absolute; width:100px; top:50px;">
--				  <div style="position:absolute;left:0px;top:50px;height:50px;background-color:green">
--					<table style="width:100%"><tr><td></table>
--				  </div>
--			   </div>
--			*/
--			// In the above example, the inner absolute positioned block should have a computed width
--			// of 100px because of the table.
--			// We can achieve this effect by making the maxwidth of blocks that contain tables
--			// with percentage widths be infinite (as long as they are not inside a table cell).
--			// FIXME: There is probably a bug here with orthogonal writing modes since we check logicalWidth only using the child's writing mode.
--			if (containingBlock && document()->inQuirksMode() && child->style()->logicalWidth().IsPercent()
--				&& !isTableCell() && child->isTable() && m_maxPreferredLogicalWidth < BLOCK_MAX_WIDTH) {
--				RenderBlock* cb = containingBlock;
--				while (!cb->isRenderView() && !cb->isTableCell())
--					cb = cb->containingBlock();
--				if (!cb->isTableCell())
--					m_maxPreferredLogicalWidth = BLOCK_MAX_WIDTH;
--			}
        
			child = child:NextSibling();
		end
    end

    -- Always make sure these values are non-negative.
    self.minPreferredLogicalWidth = math.max(0, self.minPreferredLogicalWidth);
    self.maxPreferredLogicalWidth = math.max(0, self.maxPreferredLogicalWidth);

    self.maxPreferredLogicalWidth = math.max(floatLeftWidth + floatRightWidth, self.maxPreferredLogicalWidth);
end

function LayoutBlock:ComputePreferredLogicalWidths()
	self:UpdateFirstLetter();

	if (not self:IsTableCell() and self:Style():LogicalWidth() ~= nil and self:Style():LogicalWidth() > 0) then
        self.minPreferredLogicalWidth = self:ComputeContentBoxLogicalWidth(self:Style():LogicalWidth());
		self.maxPreferredLogicalWidth = self.minPreferredLogicalWidth;
	else
        self.minPreferredLogicalWidth = 0;
        self.maxPreferredLogicalWidth = 0;

        if (self:ChildrenInline()) then
            self:ComputeInlinePreferredLogicalWidths();
        else
            self:ComputeBlockPreferredLogicalWidths();
		end
        self.maxPreferredLogicalWidth = math.max(self.minPreferredLogicalWidth, self.maxPreferredLogicalWidth);

        if (not self:Style():AutoWrap() and self:ChildrenInline()) then
            self.minPreferredLogicalWidth = self.maxPreferredLogicalWidth;
            
            -- A horizontal marquee with inline children has no minimum width.
--            if (layer() && layer()->marquee() && layer()->marquee()->isHorizontal())
--                m_minPreferredLogicalWidth = 0;
        end

        local scrollbarWidth = 0;
        if (self:HasOverflowClip() and self:Style():OverflowY() == "scroll") then
            --layer()->setHasVerticalScrollbar(true);
            scrollbarWidth = self:VerticalScrollbarWidth();
            self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + scrollbarWidth;
        end

--        if (self:IsTableCell()) then
--            local w = self:StyleOrColLogicalWidth();
--            if (w.isFixed() && w.value() > 0) {
--                m_maxPreferredLogicalWidth = max(m_minPreferredLogicalWidth, computeContentBoxLogicalWidth(w.value()));
--                scrollbarWidth = 0;
--            end
--        end
        
        self.minPreferredLogicalWidth = self.minPreferredLogicalWidth + scrollbarWidth;
    end
    
    if (Length.IsFixed(self:Style():LogicalMinWidth()) and self:Style():LogicalMinWidth() > 0) then
        self.maxPreferredLogicalWidth = math.max(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():LogicalMinWidth()));
        self.minPreferredLogicalWidth = math.max(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():LogicalMinWidth()));
    end
    
    if (Length.IsFixed(self:Style():LogicalMaxWidth())) then
        self.maxPreferredLogicalWidth = math.min(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():LogicalMaxWidth()));
        self.minPreferredLogicalWidth = math.min(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():LogicalMaxWidth()));
    end

    local borderAndPadding = self:BorderAndPaddingLogicalWidth();
    self.minPreferredLogicalWidth = self.minPreferredLogicalWidth + borderAndPadding;
    self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + borderAndPadding;

    self:SetPreferredLogicalWidthsDirty(false);
end

function LayoutBlock:LogicalWidthForChild(child)
	return if_else(self:IsHorizontalWritingMode(), child:Width(), child:Height());
end
function LayoutBlock:LogicalHeightForChild(child)
	return if_else(self:IsHorizontalWritingMode(), child:Height(), child:Width());
end
function LayoutBlock:LogicalTopForChild(child)
	return if_else(self:IsHorizontalWritingMode(), child:Y(), child:X());
end

function LayoutBlock:LogicalLeftForChild(child)
	return if_else(self:IsHorizontalWritingMode(), child:X(), child:Y());
end

-- Accessors for logical width/height and margins in the containing block's block-flow direction.
-- ApplyLayoutDeltaMode is enum, can be "ApplyLayoutDelta", "DoNotApplyLayoutDelta"
function LayoutBlock:SetLogicalLeftForChild(child, logicalLeft, ApplyLayoutDeltaMode)
	if (self:IsHorizontalWritingMode()) then
--        if (applyDelta == ApplyLayoutDelta)
--            view()->addLayoutDelta(LayoutSize(child->x() - logicalLeft, 0));
        child:SetX(logicalLeft);
    else
--        if (applyDelta == ApplyLayoutDelta)
--            view()->addLayoutDelta(LayoutSize(0, child->y() - logicalLeft));
        child:SetY(logicalLeft);
    end
end

function LayoutBlock:SetLogicalTopForChild(child, logicalTop, ApplyLayoutDeltaMode)
	if (self:IsHorizontalWritingMode()) then
--        if (applyDelta == ApplyLayoutDelta)
--            view()->addLayoutDelta(LayoutSize(0, child->y() - logicalTop));
        child:SetY(logicalTop);
    else
--        if (applyDelta == ApplyLayoutDelta)
--            view()->addLayoutDelta(LayoutSize(child->x() - logicalTop, 0));
        child:SetX(logicalTop);
    end
end

function LayoutBlock:MarginBeforeForChild(child)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		return child:MarginTop();
	elseif(write_mode ==  "BottomToTopWritingMode") then
		return child:MarginBottom();
	elseif(write_mode ==  "LeftToRightWritingMode") then
		return child:MarginLeft();
	elseif(write_mode ==  "RightToLeftWritingMode") then
		return child:MarginRight();
	end
	return child:MarginTop();
end

function LayoutBlock:MarginAfterForChild(child)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		return child:MarginBottom();
	elseif(write_mode ==  "BottomToTopWritingMode") then
		return child:MarginTop();
	elseif(write_mode ==  "LeftToRightWritingMode") then
		return child:MarginRight();
	elseif(write_mode ==  "RightToLeftWritingMode") then
		return child:MarginLeft();
	end
	return child:MarginBottom();
end
function LayoutBlock:MarginStartForChild(child)
	local start_;
	if(self:IsHorizontalWritingMode()) then
		start_ = if_else(self:Style():IsLeftToRightDirection(), child:MarginLeft(), child:MarginRight());
	else
		start_ = if_else(self:Style():IsLeftToRightDirection(), child:MarginTop(), child:MarginBottom());
	end
	return start_;
end

function LayoutBlock:MarginEndForChild(child)
	local end_;
	if(self:IsHorizontalWritingMode()) then
		end_ = if_else(self:Style():IsLeftToRightDirection(), child:MarginRight(), child:MarginLeft());
	else
		end_ = if_else(self:Style():IsLeftToRightDirection(), child:MarginBottom(), child:MarginTop());
	end
	return end_;
end

function LayoutBlock:MarginLogicalLeftForChild(child)
	if (self:IsHorizontalWritingMode()) then
        return child:MarginLeft();
	end
    return child:MarginTop();
end

function LayoutBlock:MarginLogicalRightForChild(child)
	if (self:IsHorizontalWritingMode()) then
        return child:MarginRight();
	end
    return child:MarginBottom();
end
function LayoutBlock:SetMarginStartForChild(child, margin)
	if (self:IsHorizontalWritingMode()) then
        if (self:Style():IsLeftToRightDirection()) then
            child:SetMarginLeft(margin);
        else
            child:SetMarginRight(margin);
		end
    else
        if (self:Style():IsLeftToRightDirection()) then
            child:SetMarginTop(margin);
        else
            child:SetMarginBottom(margin);
		end
    end
end

function LayoutBlock:SetMarginEndForChild(child, margin)
	if (self:IsHorizontalWritingMode()) then
        if (self:Style():IsLeftToRightDirection()) then
            child:SetMarginRight(margin);
        else
            child:SetMarginLeft(margin);
		end
    else
        if (self:Style():IsLeftToRightDirection()) then
            child:SetMarginBottom(margin);
        else
            child:SetMarginTop(margin);
		end
    end
end

function LayoutBlock:SetMarginBeforeForChild(child, margin)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		child:SetMarginTop(margin);
	elseif(write_mode ==  "BottomToTopWritingMode") then
		child:SetMarginBottom(margin);
	elseif(write_mode ==  "LeftToRightWritingMode") then
		child:SetMarginLeft(margin);
	elseif(write_mode ==  "RightToLeftWritingMode") then
		child:SetMarginRight(margin);
	end
end

function LayoutBlock:SetMarginAfterForChild(child, margin)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		child:SetMarginBottom(margin);
	elseif(write_mode ==  "BottomToTopWritingMode") then
		child:SetMarginTop(margin);
	elseif(write_mode ==  "LeftToRightWritingMode") then
		child:SetMarginRight(margin);
	elseif(write_mode ==  "RightToLeftWritingMode") then
		child:SetMarginLeft(margin);
	end
end
function LayoutBlock:CollapsedMarginBeforeForChild(child)
	--TODO: fixed this function
end
function LayoutBlock:CollapsedMarginAfterForChild(child)
	--TODO: fixed this function
end

function LayoutBlock:DesiredColumnWidth()
	--TODO: fixed this function
	return 0;
end

function LayoutBlock:AvailableLogicalWidthForLine(position, firstLine)
	--TODO: fixed this function
	return 0;
end

function LayoutBlock:AvailableLogicalWidth()
	if (self:HasColumns()) then
        return self:DesiredColumnWidth();
	end
    return LayoutBlock._super.AvailableLogicalWidth(self);
end

function LayoutBlock:IsInlineBlockOrInlineTable()
	return self:IsInline() and self:IsReplaced();
end

function LayoutBlock:UpdateFirstLetter()
	--TODO: fixed this function
end

function LayoutBlock:Layout()
	-- Update our first letter info now.
	self:UpdateFirstLetter();

	-- Table cells call layoutBlock directly, so don't add any logic here.  Put code into
    -- layoutBlock().
	self:LayoutBlock(false);

	if(self:HasControlClip() and self.overflow) then
		self:ClearLayoutOverflow();
	end
end

function LayoutBlock:ClearFloats(layoutPass)
	--TODO: fixed this function
end

function LayoutBlock:PositionedFloatsNeedRelayout()
	--TODO: fixed this function
	return false;
end

function LayoutBlock:LayoutBlock(relayoutChildren, pageLogicalHeight, layoutPass)
	if(not self:NeedsLayout()) then
		return;
	end

	if(self:IsInline() and not self:IsInlineBlockOrInlineTable()) then
		return;
	end

	if (not relayoutChildren and self:SimplifiedLayout()) then
        return;
	end

	local oldWidth = self:LogicalWidth();

	self:ComputeLogicalWidth();

	if(oldWidth ~= self:LogicalWidth()) then
		relayoutChildren = true;
	end

	local floatsLayoutPass = layoutPass;
    if (floatsLayoutPass == "NormalLayoutPass" and not relayoutChildren and not self:PositionedFloatsNeedRelayout()) then
        floatsLayoutPass = "PositionedFloatLayoutPass";
	end
	self:ClearFloats(layoutPass);

	local previousHeight = self:LogicalHeight();
    self:SetLogicalHeight(0);
    local hasSpecifiedPageLogicalHeight = false;
    local pageLogicalHeightChanged = false;
--    ColumnInfo* colInfo = columnInfo();
--    if (hasColumns()) {
--        if (!pageLogicalHeight) {
--            // We need to go ahead and set our explicit page height if one exists, so that we can
--            // avoid doing two layout passes.
--            computeLogicalHeight();
--            LayoutUnit columnHeight = contentLogicalHeight();
--            if (columnHeight > 0) {
--                pageLogicalHeight = columnHeight;
--                hasSpecifiedPageLogicalHeight = true;
--            }
--            setLogicalHeight(0);
--        }
--        if (colInfo->columnHeight() != pageLogicalHeight && m_everHadLayout) {
--            colInfo->setColumnHeight(pageLogicalHeight);
--            pageLogicalHeightChanged = true;
--        }
--        
--        if (!hasSpecifiedPageLogicalHeight && !pageLogicalHeight)
--            colInfo->clearForcedBreaks();
--    }

	-- For overflow:scroll blocks, ensure we have both scrollbars in place always.
--    if (self:ScrollsOverflow()) then
--        if (self:Style()->overflowX() == OSCROLL) then
--            layer()->setHasHorizontalScrollbar(true);
--		end
--        if (self:Style()->overflowY() == OSCROLL) then
--            layer()->setHasVerticalScrollbar(true);
--		end
--    end

	local repaintLogicalTop = 0;
    local repaintLogicalBottom = 0;
    local maxFloatLogicalBottom = 0;
    if (not self:FirstChild() and not self:IsAnonymousBlock()) then
        self:SetChildrenInline(true);
	end
    if (self:ChildrenInline()) then
        self:LayoutInlineChildren(relayoutChildren, repaintLogicalTop, repaintLogicalBottom);
    else
        self:LayoutBlockChildren(relayoutChildren, maxFloatLogicalBottom);
	end

	-- Expand our intrinsic height to encompass floats.
    local toAdd = self:BorderAfter() + self:PaddingAfter() + self:ScrollbarLogicalHeight();
--    if (lowestFloatLogicalBottom() > (logicalHeight() - toAdd) && expandsToEncloseOverhangingFloats())
--        setLogicalHeight(lowestFloatLogicalBottom() + toAdd);
--    
--    if (layoutColumns(hasSpecifiedPageLogicalHeight, pageLogicalHeight, statePusher))
--        return;

	-- Calculate our new height.
    local oldHeight = self:LogicalHeight();
    local oldClientAfterEdge = self:ClientLogicalBottom();
    self:ComputeLogicalHeight();
    local newHeight = self:LogicalHeight();
    if (oldHeight ~= newHeight) then
        if (oldHeight > newHeight and maxFloatLogicalBottom > newHeight and self:ChildrenInline()) then
            -- One of our children's floats may have become an overhanging float for us. We need to look for it.
--            for (RenderObject* child = firstChild(); child; child = child->nextSibling()) {
--                if (child->isBlockFlow() && !child->isFloatingOrPositioned()) {
--                    RenderBlock* block = toRenderBlock(child);
--                    if (block->lowestFloatLogicalBottomIncludingPositionedFloats() + block->logicalTop() > newHeight)
--                        addOverhangingFloats(block, false);
--                }
--            }
        end
    end


	if (previousHeight ~= newHeight) then
        relayoutChildren = true;
	end

    local needAnotherLayoutPass = self:LayoutPositionedObjects(relayoutChildren or self:IsRoot());

    if (self:InRenderFlowThread()) then
        --enclosingRenderFlowThread()->setRegionRangeForBox(this, offsetFromLogicalTopOfFirstPage());
	end

    -- Add overflow from children (unless we're multi-column, since in that case all our child overflow is clipped anyway).
    self:ComputeOverflow(oldClientAfterEdge);

	--statePusher.pop();

--    if (renderView->layoutState()->m_pageLogicalHeight)
--        setPageLogicalOffset(renderView->layoutState()->pageLogicalOffset(logicalTop()));

    self:UpdateLayerTransform();

    -- Update our scroll information if we're overflow:auto/scroll/hidden now that we know if
    -- we overflow or not.
    self:UpdateScrollInfoAfterLayout();

--	-- FIXME: This repaint logic should be moved into a separate helper function!
--    -- Repaint with our new bounds if they are different from our old bounds.
--    bool didFullRepaint = repainter.repaintAfterLayout();
--    if (!didFullRepaint && repaintLogicalTop != repaintLogicalBottom && (style()->visibility() == VISIBLE || enclosingLayer()->hasVisibleContent())) {
--        // FIXME: We could tighten up the left and right invalidation points if we let layoutInlineChildren fill them in based off the particular lines
--        // it had to lay out.  We wouldn't need the hasOverflowClip() hack in that case either.
--        LayoutUnit repaintLogicalLeft = logicalLeftVisualOverflow();
--        LayoutUnit repaintLogicalRight = logicalRightVisualOverflow();
--        if (hasOverflowClip()) {
--            // If we have clipped overflow, we should use layout overflow as well, since visual overflow from lines didn't propagate to our block's overflow.
--            // Note the old code did this as well but even for overflow:visible.  The addition of hasOverflowClip() at least tightens up the hack a bit.
--            // layoutInlineChildren should be patched to compute the entire repaint rect.
--            repaintLogicalLeft = min(repaintLogicalLeft, logicalLeftLayoutOverflow());
--            repaintLogicalRight = max(repaintLogicalRight, logicalRightLayoutOverflow());
--        }
--        
--        LayoutRect repaintRect;
--        if (isHorizontalWritingMode())
--            repaintRect = LayoutRect(repaintLogicalLeft, repaintLogicalTop, repaintLogicalRight - repaintLogicalLeft, repaintLogicalBottom - repaintLogicalTop);
--        else
--            repaintRect = LayoutRect(repaintLogicalTop, repaintLogicalLeft, repaintLogicalBottom - repaintLogicalTop, repaintLogicalRight - repaintLogicalLeft);
--
--        // The repaint rect may be split across columns, in which case adjustRectForColumns() will return the union.
--        adjustRectForColumns(repaintRect);
--
--        repaintRect.inflate(maximalOutlineSize(PaintPhaseOutline));
--        
--        if (hasOverflowClip()) {
--            // Adjust repaint rect for scroll offset
--            repaintRect.move(-layer()->scrolledContentOffset());
--
--            // Don't allow this rect to spill out of our overflow box.
--            repaintRect.intersect(LayoutRect(LayoutPoint(), size()));
--        }
--
--        // Make sure the rect is still non-empty after intersecting for overflow above
--        if (!repaintRect.isEmpty()) {
--            // FIXME: Might need rounding once we switch to float, see https://bugs.webkit.org/show_bug.cgi?id=64021
--            repaintRectangle(repaintRect); // We need to do a partial repaint of our content.
--            if (hasReflection())
--                repaintRectangle(reflectedRect(repaintRect));
--        }
--    }

	if (needAnotherLayoutPass and layoutPass == "NormalLayoutPass") then
        self:SetChildNeedsLayout(true, false);
        self:LayoutBlock(false, pageLogicalHeight, PositionedFloatLayoutPass);
    else
        self:SetNeedsLayout(false);
	end

end

function LayoutBlock:UpdateLayerTransform()
	--TODO: fixed this function
end

function LayoutBlock:HasLineIfEmpty()
	--TODO: fixed this function
	return false;
end

function LayoutBlock:CheckLinesForTextOverflow()
	--TODO: fixed this function
end

function LayoutBlock:LayoutBlockChildren(relayoutChildren, maxFloatLogicalBottom)
	--TODO: fixed this function
--	if (gPercentHeightDescendantsMap) {
--        if (HashSet<RenderBox*>* descendants = gPercentHeightDescendantsMap->get(this)) {
--            HashSet<RenderBox*>::iterator end = descendants->end();
--            for (HashSet<RenderBox*>::iterator it = descendants->begin(); it != end; ++it) {
--                RenderBox* box = *it;
--                while (box != this) {
--                    if (box->normalChildNeedsLayout())
--                        break;
--                    box->setChildNeedsLayout(true, false);
--                    box = box->containingBlock();
--                    ASSERT(box);
--                    if (!box)
--                        break;
--                }
--            }
--        }
--    }

    local beforeEdge = self:BorderBefore() + self:PaddingBefore();
    local afterEdge = self:BorderAfter() + self:PaddingAfter() + self:ScrollbarLogicalHeight();

    self:SetLogicalHeight(beforeEdge);

    -- The margin struct caches all our current margin collapsing state.  The compact struct caches state when we encounter compacts,
    local marginInfo = MarginInfo:new():init(self, beforeEdge, afterEdge);

    -- Fieldsets need to find their legend and position it inside the border of the object.
    -- The legend then gets skipped during normal layout.  The same is true for ruby text.
    -- It doesn't get included in the normal layout process but is instead skipped.
    --RenderObject* childToExclude = layoutSpecialExcludedChild(relayoutChildren);

    local previousFloatLogicalBottom = 0;
    maxFloatLogicalBottom = 0;

    local next = self:FirstChildBox();

    while (next) do
        local child = next;
        next = child:NextSiblingBox();

--        if (childToExclude == child)
--            continue; // Skip this child, since it will be positioned by the specialized subclass (fieldsets and ruby runs).

        -- Make sure we layout children if they need it.
        -- FIXME: Technically percentage height objects only need a relayout if their percentage isn't going to be turned into
        -- an auto value.  Add a method to determine this, so that we can avoid the relayout.
        if (relayoutChildren or ((Length.IsPercent(child:Style():LogicalHeight()) or Length.IsPercent(child:Style():LogicalMinHeight()) or Length.IsPercent(child:Style():LogicalMaxHeight())) and not self:IsLayoutView())) then
            child:SetChildNeedsLayout(true, false);
		end
        -- If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
        if (relayoutChildren and child:NeedsPreferredWidthsRecalculation()) then
            child:SetPreferredLogicalWidthsDirty(true, false);
		end

        -- Handle the four types of special elements first.  These include positioned content, floating content, compacts and
        -- run-ins.  When we encounter these four types of objects, we don't actually lay them out as normal flow blocks.
        if (not self:HandleSpecialChild(child, marginInfo)) then
			-- Lay out the child.
			self:LayoutBlockChild(child, marginInfo, previousFloatLogicalBottom, maxFloatLogicalBottom);	
		end
    end
    
    -- Now do the handling of the bottom of the block, adding in our bottom border/padding and
    -- determining the correct collapsed bottom margin information.
    self:HandleAfterSideOfBlock(beforeEdge, afterEdge, marginInfo);
end

function LayoutBlock:HandleSpecialChild(child, marginInfo)
	-- Handle in the given order
--    return handlePositionedChild(child, marginInfo)
--        || handleFloatingChild(child, marginInfo)
--        || handleRunInChild(child);
	return false;
end

function LayoutBlock:MaxPositiveMarginBefore()
	--return m_rareData ? m_rareData->m_margins.positiveMarginBefore() : RenderBlockRareData::positiveMarginBeforeDefault(this); 
	return math.max(self:MarginBefore(), 0);
end

function LayoutBlock:MaxNegativeMarginBefore()
	--return m_rareData ? m_rareData->m_margins.negativeMarginBefore() : RenderBlockRareData::negativeMarginBeforeDefault(this);
	return math.max(-self:MarginBefore(), 0);
end

function LayoutBlock:MaxPositiveMarginAfter()
	--return m_rareData ? m_rareData->m_margins.positiveMarginAfter() : RenderBlockRareData::positiveMarginAfterDefault(this);
	return math.max(self:MarginAfter(), 0);
end

function LayoutBlock:MaxNegativeMarginAfter()
	--return m_rareData ? m_rareData->m_margins.negativeMarginAfter() : RenderBlockRareData::negativeMarginAfterDefault(this);
	return math.max(-self:MarginAfter(), 0);
end

function LayoutBlock:CollapsedMarginBefore()
	return self:MaxPositiveMarginBefore() - self:MaxNegativeMarginBefore();
end

function LayoutBlock:CollapsedMarginAfter()
	return self:MaxPositiveMarginAfter() - self:MaxNegativeMarginAfter();
end

function LayoutBlock:CollapsedMarginBeforeForChild(child)
    -- If the child has the same directionality as we do, then we can just return its collapsed margin.
    if (not child:IsWritingModeRoot()) then
        return child:CollapsedMarginBefore();
    end
    -- The child has a different directionality.  If the child is parallel, then it's just
    -- flipped relative to us.  We can use the collapsed margin for the opposite edge.
    if (child:IsHorizontalWritingMode() == self:IsHorizontalWritingMode()) then
        return child:CollapsedMarginAfter();
    end
    -- The child is perpendicular to us, which means its margins don't collapse but are on the
    -- "logical left/right" sides of the child box.  We can just return the raw margin in this case.  
    return self:MarginBeforeForChild(child);
end

function LayoutBlock:ContainsFloats()
	--TODO: fixed this function
	return false;
end

function LayoutBlock:GetClearDelta(child, logicalTop)
	-- There is no need to compute clearance if we have no floats.
    if (not self:ContainsFloats()) then
        return 0;
    end
	--TODO: fixed this function
end

function LayoutBlock:EstimateLogicalTopPosition(child, marginInfo, estimateWithoutPagination)
	-- FIXME: We need to eliminate the estimation of vertical position, because when it's wrong we sometimes trigger a pathological
    -- relayout if there are intruding floats.
    local logicalTopEstimate = self:LogicalHeight();
    if (not marginInfo:CanCollapseWithMarginBefore()) then
        local childMarginBefore = if_else(child:SelfNeedsLayout(), self:MarginBeforeForChild(child), self:CollapsedMarginBeforeForChild(child));
        logicalTopEstimate = logicalTopEstimate + math.max(marginInfo:Margin(), childMarginBefore);
    end

    -- Adjust logicalTopEstimate down to the next page if the margins are so large that we don't fit on the current page.
--    LayoutState* layoutState = view()->layoutState();
--    if (layoutState->isPaginated() && layoutState->pageLogicalHeight() && logicalTopEstimate > logicalHeight()
--        && hasNextPage(logicalHeight()))
--        logicalTopEstimate = min(logicalTopEstimate, nextPageLogicalTop(logicalHeight()));

    logicalTopEstimate = logicalTopEstimate+ self:GetClearDelta(child, logicalTopEstimate);
    
    --estimateWithoutPagination = logicalTopEstimate;

--    if (layoutState->isPaginated()) {
--        // If the object has a page or column break value of "before", then we should shift to the top of the next page.
--        logicalTopEstimate = applyBeforeBreak(child, logicalTopEstimate);
--    
--        // For replaced elements and scrolled elements, we want to shift them to the next page if they don't fit on the current one.
--        logicalTopEstimate = adjustForUnsplittableChild(child, logicalTopEstimate);
--        
--        if (!child->selfNeedsLayout() && child->isRenderBlock())
--            logicalTopEstimate += toRenderBlock(child)->paginationStrut();
--    }

    return logicalTopEstimate;
end

function LayoutBlock:MarkAllDescendantsWithFloatsForLayout(floatToRemove, inLayout)
	--TODO: fixed this function
end

function LayoutBlock:MarkForPaginationRelayoutIfNeeded()
	
end

function LayoutBlock:ClearFloatsIfNeeded(child, marginInfo, oldTopPosMargin, oldTopNegMargin, yPos)
	local heightIncrease = self:GetClearDelta(child, yPos);
    if (heightIncrease == 0) then
        return yPos;
	end
	--TODO: fixed this function
end

function LayoutBlock:AddOverhangingFloats(child, makeChildPaintOtherFloats)
	--TODO: fixed this function
end

function LayoutBlock:LayoutBlockChild(child, marginInfo, previousFloatLogicalBottom, maxFloatLogicalBottom)
	local oldPosMarginBefore = self:MaxPositiveMarginBefore();
    local oldNegMarginBefore = self:MaxNegativeMarginBefore();

    -- The child is a normal flow object.  Compute the margins we will use for collapsing now.
    child:ComputeBlockDirectionMargins(self);

	-- Do not allow a collapse if the margin-before-collapse style is set to SEPARATE.
    if (child:Style():MarginBeforeCollapse() == "MSEPARATE") then
        marginInfo:SetAtBeforeSideOfBlock(false);
        marginInfo:ClearMargin();
    end

	-- Try to guess our correct logical top position.  In most cases this guess will
    -- be correct.  Only if we're wrong (when we compute the real logical top position)
    -- will we have to potentially relayout.
    local estimateWithoutPagination;
    local logicalTopEstimate = self:EstimateLogicalTopPosition(child, marginInfo, estimateWithoutPagination);

    -- Cache our old rect so that we can dirty the proper repaint rects if the child moves.
    local oldRect = Rect:new(child:X(), child:Y() , child:Width(), child:Height());
    local oldLogicalTop = self:LogicalTopForChild(child);

--#ifndef NDEBUG
--    LayoutSize oldLayoutDelta = view()->layoutDelta();
--#endif
    -- Go ahead and position the child as though it didn't collapse with the top.
    self:SetLogicalTopForChild(child, logicalTopEstimate, "ApplyLayoutDelta");

	local childRenderBlock = if_else(child:IsLayoutBlock(), child, nil);
    local markDescendantsWithFloats = false;
    if (logicalTopEstimate ~= oldLogicalTop and not child:AvoidsFloats() and childRenderBlock and childRenderBlock:ContainsFloats()) then
        markDescendantsWithFloats = true;
    elseif (not child:AvoidsFloats() or child:ShrinkToAvoidFloats()) then
        -- If an element might be affected by the presence of floats, then always mark it for layout.
--        local fb = max(previousFloatLogicalBottom, lowestFloatLogicalBottomIncludingPositionedFloats());
--        if (fb > logicalTopEstimate)
--            markDescendantsWithFloats = true;
--		end
    end

	if (childRenderBlock) then
        if (markDescendantsWithFloats) then
            childRenderBlock:MarkAllDescendantsWithFloatsForLayout();
		end
        if (not child:IsWritingModeRoot()) then
            --previousFloatLogicalBottom = max(previousFloatLogicalBottom, oldLogicalTop + childRenderBlock->lowestFloatLogicalBottomIncludingPositionedFloats());
		end
    end

	if (not child:NeedsLayout()) then
        child:MarkForPaginationRelayoutIfNeeded();
	end

	local childHadLayout = child.everHadLayout;
	local childNeededLayout = child:NeedsLayout();
    if (childNeededLayout) then
        child:Layout();
	end

	-- Cache if we are at the top of the block right now.
    local atBeforeSideOfBlock = marginInfo:AtBeforeSideOfBlock();

    -- Now determine the correct ypos based off examination of collapsing margin values.
    local logicalTopBeforeClear = self:CollapseMargins(child, marginInfo);

    -- Now check for clear.
    local logicalTopAfterClear = self:ClearFloatsIfNeeded(child, marginInfo, oldPosMarginBefore, oldNegMarginBefore, logicalTopBeforeClear);
    
--    bool paginated = view()->layoutState()->isPaginated();
--    if (paginated)
--        logicalTopAfterClear = adjustBlockChildForPagination(logicalTopAfterClear, estimateWithoutPagination, child,
--            atBeforeSideOfBlock && logicalTopBeforeClear == logicalTopAfterClear);
--
    self:SetLogicalTopForChild(child, logicalTopAfterClear, "ApplyLayoutDelta");


	-- Now we have a final top position.  See if it really does end up being different from our estimate.
    if (logicalTopAfterClear ~= logicalTopEstimate) then
        if (child:ShrinkToAvoidFloats()) then
            -- The child's width depends on the line width.
            -- When the child shifts to clear an item, its width can
            -- change (because it has more available line width).
            -- So go ahead and mark the item as dirty.
            child:SetChildNeedsLayout(true, false);
        end
        
        if (childRenderBlock) then
            if (not child:AvoidsFloats() and childRenderBlock:ContainsFloats()) then
                childRenderBlock:MarkAllDescendantsWithFloatsForLayout();
			end
            if (not child:NeedsLayout()) then
                child:MarkForPaginationRelayoutIfNeeded();
			end
        end

        -- Our guess was wrong. Make the child lay itself out again.
        child:LayoutIfNeeded();
    end

	-- We are no longer at the top of the block if we encounter a non-empty child.  
    -- This has to be done after checking for clear, so that margins can be reset if a clear occurred.
    if (marginInfo:AtBeforeSideOfBlock() and not child:IsSelfCollapsingBlock()) then
        marginInfo:SetAtBeforeSideOfBlock(false);
	end

    -- Now place the child in the correct left position
    self:DetermineLogicalLeftPositionForChild(child);

    -- Update our height now that the child has been placed in the correct position.
    self:SetLogicalHeight(self:LogicalHeight() + self:LogicalHeightForChild(child));
    if (child:Style():MarginAfterCollapse() == "MSEPARATE") then
        self:SetLogicalHeight(self:LogicalHeight() + self:MarginAfterForChild(child));
        marginInfo:ClearMargin();
    end
    -- If the child has overhanging floats that intrude into following siblings (or possibly out
    -- of this block), then the parent gets notified of the floats now.
    if (childRenderBlock and childRenderBlock:ContainsFloats()) then
        maxFloatLogicalBottom = math.max(maxFloatLogicalBottom, self:AddOverhangingFloats(child, not childNeededLayout));
	end

    local childOffset = Size:new(child:X() - oldRect:X(), child:Y() - oldRect:Y());
    if (childOffset:Width() ~= 0 and childOffset:Height() ~= 0) then
        --view()->addLayoutDelta(childOffset);

        -- If the child moved, we have to repaint it as well as any floating/positioned
        -- descendants.  An exception is if we need a layout.  In this case, we know we're going to
        -- repaint ourselves (and the child) anyway.
--        if (childHadLayout and not self:SelfNeedsLayout() and child:CheckForRepaintDuringLayout())
--            child->repaintDuringLayoutIfMoved(oldRect);
--		end
    end

    --if (not childHadLayout and child:CheckForRepaintDuringLayout()) {
	if (not childHadLayout) then
		child:OnAfterChildLayout(child);
        --child->repaint();
        --child->repaintOverhangingFloats(true);
    end

--    if (paginated) {
--        // Check for an after page/column break.
--        LayoutUnit newHeight = applyAfterBreak(child, logicalHeight(), marginInfo);
--        if (newHeight != height())
--            setLogicalHeight(newHeight);
--    }

--    // FIXME: Change to use roughlyEquals when we move to float.
--    // See https://bugs.webkit.org/show_bug.cgi?id=66148
--    ASSERT(oldLayoutDelta == view()->layoutDelta());
end

function LayoutBlock:MarginValuesForChild(child)
	local childBeforePositive = 0;
    local childBeforeNegative = 0;
    local childAfterPositive = 0;
    local childAfterNegative = 0;

    local beforeMargin = 0;
    local afterMargin = 0;

    local childRenderBlock = if_else(child:IsLayoutBlock(), child , nil);
    
    -- If the child has the same directionality as we do, then we can just return its margins in the same direction.
    if (not child:IsWritingModeRoot()) then
        if (childRenderBlock) then
            childBeforePositive = childRenderBlock:MaxPositiveMarginBefore();
            childBeforeNegative = childRenderBlock:MaxNegativeMarginBefore();
            childAfterPositive = childRenderBlock:MaxPositiveMarginAfter();
            childAfterNegative = childRenderBlock:MaxNegativeMarginAfter();
        else
            beforeMargin = child:MarginBefore();
            afterMargin = child:MarginAfter();
        end
    elseif (child:IsHorizontalWritingMode() == self:IsHorizontalWritingMode()) then
        -- The child has a different directionality.  If the child is parallel, then it's just
        -- flipped relative to us.  We can use the margins for the opposite edges.
        if (childRenderBlock) then
            childBeforePositive = childRenderBlock:MaxPositiveMarginAfter();
            childBeforeNegative = childRenderBlock:MaxNegativeMarginAfter();
            childAfterPositive = childRenderBlock:MaxPositiveMarginBefore();
            childAfterNegative = childRenderBlock:MaxNegativeMarginBefore();
        else
            beforeMargin = child:MarginAfter();
            afterMargin = child:MarginBefore();
        end
    else
        -- The child is perpendicular to us, which means its margins don't collapse but are on the
        -- "logical left/right" sides of the child box.  We can just return the raw margin in this case.
        beforeMargin = self:MarginBeforeForChild(child);
        afterMargin = self:MarginAfterForChild(child);
    end

    -- Resolve uncollapsing margins into their positive/negative buckets.
    if (beforeMargin) then
        if (beforeMargin > 0) then
            childBeforePositive = beforeMargin;
        else
            childBeforeNegative = -beforeMargin;
		end
    end
    if (afterMargin) then
        if (afterMargin > 0) then
            childAfterPositive = afterMargin;
        else
            childAfterNegative = -afterMargin;
		end
    end

    return MarginValues:new():init(childBeforePositive, childBeforeNegative, childAfterPositive, childAfterNegative);
end

function LayoutBlock:IsSelfCollapsingBlock()
	-- We are not self-collapsing if we
    -- (a) have a non-zero height according to layout (an optimization to avoid wasting time)
    -- (b) are a table,
    -- (c) have border/padding,
    -- (d) have a min-height
    -- (e) have specified that one of our margins can't collapse using a CSS extension
    if (self:LogicalHeight() > 0
        or self:IsTable() or self:BorderAndPaddingLogicalHeight() ~= 0
        or Length.IsPositive(self:Style():LogicalMinHeight())
        or self:Style():MarginBeforeCollapse() == "MSEPARATE" or self:Style():MarginAfterCollapse() == "MSEPARATE") then
			return false;
	end

    local logicalHeightLength = self:Style():LogicalHeight();
    local hasAutoHeight = Length.IsAuto(logicalHeightLength);
	--if (logicalHeightLength.isPercent() && !document()->inQuirksMode()) {
    if (Length.IsPercent(logicalHeightLength)) then
        hasAutoHeight = true;
		local cb = self:ContainingBlock();
		while(not cb:IsLayoutView()) do
			if (Length.IsFixed(cb:Style():LogicalHeight()) or cb:IsTableCell()) then
                hasAutoHeight = false;
			end
			cb = cb:ContainingBlock();
		end
    end

    -- If the height is 0 or auto, then whether or not we are a self-collapsing block depends
    -- on whether we have content that is all self-collapsing or not.
    if (hasAutoHeight or ((Length.IsFixed(logicalHeightLength) or Length.IsPercent(logicalHeightLength)) and Length.IsZero(logicalHeightLength))) then
        -- If the block has inline children, see if we generated any line boxes.  If we have any
        -- line boxes, then we can't be self-collapsing, since we have content.
        if (self:ChildrenInline()) then
            return not self:FirstLineBox();
		end
        
        -- Whether or not we collapse is dependent on whether all our normal flow children
        -- are also self-collapsing.
		local child = self:FirstChildBox();
		while(child) do
			if (not child:IsFloatingOrPositioned()) then
				if (not child:IsSelfCollapsingBlock()) then
					return false;
				end
			end
			child = child:NextSiblingBox();
		end
        return true;
    end
    return false;
end

function LayoutBlock:SetMaxMarginBeforeValues(pos, neg)

end

function LayoutBlock:SetMaxMarginAfterValues(pos, neg)

end

function LayoutBlock:CollapseMargins(child, marginInfo)
	-- Get the four margin values for the child and cache them.
    local childMargins = self:MarginValuesForChild(child);

    -- Get our max pos and neg top margins.
    local posTop = childMargins:PositiveMarginBefore();
    local negTop = childMargins:NegativeMarginBefore();

    -- For self-collapsing blocks, collapse our bottom margins into our top to get new posTop and negTop values.
    if (child:IsSelfCollapsingBlock()) then
        posTop = max(posTop, childMargins:PositiveMarginAfter());
        negTop = max(negTop, childMargins:NegativeMarginAfter());
    end
    
    -- See if the top margin is quirky. We only care if this child has
    -- margins that will collapse with us.
    local topQuirk = child:IsMarginBeforeQuirk() or self:Style():MarginBeforeCollapse() == "MDISCARD";

	if (marginInfo:CanCollapseWithMarginBefore()) then
        -- This child is collapsing with the top of the block.  If it has larger margin values, then we need to update
        -- our own maximal values.
        if (not marginInfo:QuirkContainer() or not topQuirk) then
            self:SetMaxMarginBeforeValues(math.max(posTop, self:MaxPositiveMarginBefore()), math.max(negTop, self:MaxNegativeMarginBefore()));
		end

        -- The minute any of the margins involved isn't a quirk, don't
        -- collapse it away, even if the margin is smaller (www.webreference.com
        -- has an example of this, a <dt> with 0.8em author-specified inside
        -- a <dl> inside a <td>.
        if (not marginInfo:DeterminedMarginBeforeQuirk() and not topQuirk and (posTop - negTop) ~= 0 ) then
            self:SetMarginBeforeQuirk(false);
            marginInfo:SetDeterminedMarginBeforeQuirk(true);
        end

        if (not marginInfo:DeterminedMarginBeforeQuirk() and topQuirk and not self:MarginBefore()) then
            -- We have no top margin and our top child has a quirky margin.
            -- We will pick up this quirky margin and pass it through.
            -- This deals with the <td><div><p> case.
            -- Don't do this for a block that split two inlines though.  You do
            -- still apply margins in this case.
            self:SetMarginBeforeQuirk(true);
		end
    end

	if (marginInfo:QuirkContainer() and marginInfo:AtBeforeSideOfBlock() and (posTop - negTop) ~= 0) then
        marginInfo:SetMarginBeforeQuirk(topQuirk);
	end

    local beforeCollapseLogicalTop = self:LogicalHeight();
    local logicalTop = beforeCollapseLogicalTop;

	if (child:IsSelfCollapsingBlock()) then
        -- This child has no height.  We need to compute our
        -- position before we collapse the child's margins together,
        -- so that we can get an accurate position for the zero-height block.
        local collapsedBeforePos = math.max(marginInfo:PositiveMargin(), childMargins:PositiveMarginBefore());
        local collapsedBeforeNeg = math.max(marginInfo:NegativeMargin(), childMargins:NegativeMarginBefore());
        marginInfo:SetMargin(collapsedBeforePos, collapsedBeforeNeg);
        
        -- Now collapse the child's margins together, which means examining our
        -- bottom margin values as well. 
        marginInfo:SetPositiveMarginIfLarger(childMargins:PositiveMarginAfter());
        marginInfo:SetNegativeMarginIfLarger(childMargins:NegativeMarginAfter());

        if (not marginInfo:CanCollapseWithMarginBefore()) then
            -- We need to make sure that the position of the self-collapsing block
            -- is correct, since it could have overflowing content
            -- that needs to be positioned correctly (e.g., a block that
            -- had a specified height of 0 but that actually had subcontent).
            logicalTop = self:LogicalHeight() + collapsedBeforePos - collapsedBeforeNeg;
		end
    else
        if (child:Style():MarginBeforeCollapse() == "MSEPARATE") then
            self:SetLogicalHeight(self:LogicalHeight() + marginInfo:Margin() + self:MarginBeforeForChild(child));
            logicalTop = self:LogicalHeight();
        elseif (not marginInfo:AtBeforeSideOfBlock() or
            (not marginInfo:CanCollapseMarginBeforeWithChildren()
             and (not marginInfo:QuirkContainer() or not marginInfo:MarginBeforeQuirk()))) then
            -- We're collapsing with a previous sibling's margins and not
            -- with the top of the block.
            self:SetLogicalHeight(self:LogicalHeight() + math.max(marginInfo:PositiveMargin(), posTop) - math.max(marginInfo:NegativeMargin(), negTop));
            logicalTop = self:LogicalHeight();
        end

        marginInfo:SetPositiveMargin(childMargins:PositiveMarginAfter());
        marginInfo:SetNegativeMargin(childMargins:NegativeMarginAfter());

        if (marginInfo:Margin()) then
            marginInfo:SetMarginAfterQuirk(child:IsMarginAfterQuirk() or self:Style():MarginAfterCollapse() == "MDISCARD");
		end
    end

	-- If margins would pull us past the top of the next page, then we need to pull back and pretend like the margins
    -- collapsed into the page edge.
--    LayoutState* layoutState = view()->layoutState();
--    if (layoutState->isPaginated() && layoutState->pageLogicalHeight() && logicalTop > beforeCollapseLogicalTop
--        && hasNextPage(beforeCollapseLogicalTop)) {
--        LayoutUnit oldLogicalTop = logicalTop;
--        logicalTop = min(logicalTop, nextPageLogicalTop(beforeCollapseLogicalTop));
--        setLogicalHeight(logicalHeight() + (logicalTop - oldLogicalTop));
--    }
    return logicalTop;
end

function LayoutBlock:DetermineLogicalLeftPositionForChild(child)
    local startPosition = self:BorderStart() + self:PaddingStart();
    local totalAvailableLogicalWidth = self:BorderAndPaddingLogicalWidth() + self:AvailableLogicalWidth();

    -- Add in our start margin.
    local childMarginStart = self:MarginStartForChild(child);
    local newPosition = startPosition + childMarginStart;
        
    -- Some objects (e.g., tables, horizontal rules, overflow:auto blocks) avoid floats.  They need
    -- to shift over as necessary to dodge any floats that might get in the way.
--    if (child:AvoidsFloats() and self:ContainsFloats() and not self:InRenderFlowThread()) then
--        newPosition += computeStartPositionDeltaForChildAvoidingFloats(child, marginStartForChild(child), logicalWidthForChild(child));
--	end

    self:SetLogicalLeftForChild(child, if_else(self:Style():IsLeftToRightDirection(), newPosition, totalAvailableLogicalWidth - newPosition - self:LogicalWidthForChild(child), "ApplyLayoutDelta"));
end

function LayoutBlock:HandleAfterSideOfBlock(beforeEdge, afterEdge, marginInfo)
	--TODO: fixed this function
end

function LayoutBlock:LayoutPositionedObjects(relayoutChildren)
	--TODO: fixed this function
	return false;
end

function LayoutBlock:ComputeOverflow(oldClientAfterEdge, recomputeFloats)
	--TODO: fixed this function
end

function LayoutBlock:UpdateScrollInfoAfterLayout()
	--TODO: fixed this function
end

function LayoutBlock:SimplifiedLayout()
	if ((not self:PosChildNeedsLayout() and not self:NeedsSimplifiedNormalFlowLayout()) or self:NormalChildNeedsLayout() or self:SelfNeedsLayout()) then
        return false;
	end
	if (self:NeedsPositionedMovementLayout() and not self:TryLayoutDoingPositionedMovementOnly()) then
        return false;
	end

	if(self:PosChildNeedsLayout() and self:LayoutPositionedObjects(false)) then
		return false;
	end

	--self.overflow:Clear();
	self:ComputeOverflow(self:ClientLogicalBottom(), true);

	self:UpdateLayerTransform();

	self:UpdateScrollInfoAfterLayout();

	self:SetNeedsLayout(false);

	return true;
end

--function LayoutBlock:AddChildBeforeDescendant(new_child, before_descendant)
--	if(before_descendant:Parent() ~= self) then
--		return;
--	end
--	--DCHECK_NE(before_descendant->Parent(), this);
--	local before_descendant_container = before_descendant:Parent();
--	while (before_descendant_container:Parent() ~= self) do
--		before_descendant_container = before_descendant_container:Parent();
--	end
--
--	--DCHECK(before_descendant_container);
--
--	-- We really can't go on if what we have found isn't anonymous. We're not
--	-- supposed to use some random non-anonymous object and put the child there.
--	-- That's a recipe for security issues.
--	if(before_descendant_container:IsAnonymous()) then
--		return;
--	end
--	--CHECK(before_descendant_container->IsAnonymous());
--
--	-- If the requested insertion point is not one of our children, then this is
--	-- because there is an anonymous container within this object that contains
--	-- the beforeDescendant.
--	if (before_descendant_container:IsAnonymousBlock() or before_descendant_container:IsLayoutFullScreen() or before_descendant_container:IsLayoutFullScreenPlaceholder()) then
--		-- Full screen layoutObjects and full screen placeholders act as anonymous
--		-- blocks, not tables:
--		-- Insert the child into the anonymous block box instead of here.
--	if (new_child:IsInline() or (new_child:IsFloatingOrOutOfFlowPositioned() and not self:IsFlexibleBox() and not self:IsLayoutGrid()) or before_descendant:Parent():SlowFirstChild() ~= before_descendant) then
--			before_descendant_container:AddChild(new_child, before_descendant);
--		else
--			self:AddChild(new_child, before_descendant:Parent());
--		end
--		return;
--	end
--
--	--DCHECK(before_descendant_container->IsTable());
--	if(before_descendant_container:IsTable()) then
--		return;
--	end
--	if (new_child:IsTablePart()) then
--		-- Insert into the anonymous table.
--		before_descendant_container:AddChild(new_child, before_descendant);
--		return;
--	end
--
--	LayoutObject* before_child =
--		SplitAnonymousBoxesAroundChild(before_descendant);
--
--	DCHECK_EQ(before_child->Parent(), this);
--	if (before_child->Parent() != this) {
--	// We should never reach here. If we do, we need to use the
--	// safe fallback to use the topmost beforeChild container.
--	before_child = before_descendant_container;
--	}
--
--	AddChild(new_child, before_child);
--end
--
--function LayoutBlock:AddChild(new_child, before_child)
--	if (before_child and before_child:Parent() ~= self) then
--		self:AddChildBeforeDescendant(new_child, before_child);
--		return;
--	end
--
--  -- Only LayoutBlockFlow should have inline children, and then we shouldn't be
--  -- here.
--	if(not self:ChildrenInline()) then
--	return;
--	end
--	--DCHECK(!ChildrenInline());
--
--	if (new_child:IsInline() or (new_child:IsFloatingOrOutOfFlowPositioned() and not self:IsFlexibleBox() and not self:IsLayoutGrid())) then
--		-- If we're inserting an inline child but all of our children are blocks,
--		-- then we have to make sure it is put into an anomyous block box. We try to
--		-- use an existing anonymous box if possible, otherwise a new one is created
--		-- and inserted into our list of children in the appropriate position.
--		local after_child = if_else(before_child, before_child:PreviousSibling(), self:LastChild());
--
--		if (after_child and after_child:IsAnonymousBlock()) then
--			after_child:AddChild(new_child);
--			return;
--		end
--
--		if (new_child:IsInline()) then
--			-- No suitable existing anonymous box - create a new one.
--			local new_box = CreateAnonymousBlock();
--			LayoutBlock._super.AddChild(self, new_box, before_child);
--			new_box:AddChild(new_child);
--			return;
--		end
--	end
--
--	LayoutBlock._super.AddChild(new_child, before_child);
--end

-- virtual function
function LayoutBlock:DirtyLinesFromChangedChild(child)
	--TODO: fixed this function
end

function LayoutBlock:AddChild(newChild, beforeChild)
	if (self:Continuation() and not self:IsAnonymousBlock()) then
        return self:AddChildToContinuation(newChild, beforeChild);
	end
    return self:AddChildIgnoringContinuation(newChild, beforeChild);
end

function LayoutBlock:AddChildToContinuation(newChild, beforeChild)

end

function LayoutBlock:AddChildIgnoringContinuation(newChild, beforeChild)
	if (not self:IsAnonymousBlock() and self:FirstChild() and (self:FirstChild():IsAnonymousColumnsBlock() and self:FirstChild():IsAnonymousColumnSpanBlock())) then
        return self:AddChildToAnonymousColumnBlocks(newChild, beforeChild);
	end
    return self:AddChildIgnoringAnonymousColumnBlocks(newChild, beforeChild);
end

function LayoutBlock:AddChildToAnonymousColumnBlocks(newChild, beforeChild)
	--TODO: fixed this function
end

function LayoutBlock:VirtualChildren()
	return self:Children();
end

function LayoutBlock:ColumnsBlockForSpanningElement(newChild)
	local columnsBlockAncestor = nil;
--    if (not newChild:IsText() and newChild->style()->columnSpan() && !newChild->isFloatingOrPositioned()
--        && !newChild->isInline() && !isAnonymousColumnSpanBlock()) {
--        if (style()->specifiesColumns())
--            columnsBlockAncestor = this;
--        else if (!isInline() && parent() && parent()->isRenderBlock()) {
--            columnsBlockAncestor = toRenderBlock(parent())->containingColumnsBlock(false);
--            
--            if (columnsBlockAncestor) {
--                // Make sure that none of the parent ancestors have a continuation.
--                // If yes, we do not want split the block into continuations.
--                RenderObject* curr = this;
--                while (curr && curr != columnsBlockAncestor) {
--                    if (curr->isRenderBlock() && toRenderBlock(curr)->continuation()) {
--                        columnsBlockAncestor = 0;
--                        break;
--                    }
--                    curr = curr->parent();
--                }
--            }
--        }
--    }
    return columnsBlockAncestor;
end

function LayoutBlock:MakeChildrenNonInline(insertionPoint)
	-- makeChildrenNonInline takes a block whose children are *all* inline and it
    -- makes sure that inline children are coalesced under anonymous
    -- blocks.  If |insertionPoint| is defined, then it represents the insertion point for
    -- the new block child that is causing us to have to wrap all the inlines.  This
    -- means that we cannot coalesce inlines before |insertionPoint| with inlines following
    -- |insertionPoint|, because the new child is going to be inserted in between the inlines,
    -- splitting them.
--    if(self:IsInlineBlockOrInlineTable() or not self:IsInline()) then
--		return;
--	end
--  if(not insertionPoint or insertionPoint:Parent() == self) then
--		return;
--	end
    self:SetChildrenInline(false);

    local child = self:FirstChild();
    if (not child) then
        return;
	end
--    deleteLineBoxTree();
--
--    while (child) {
--        RenderObject *inlineRunStart, *inlineRunEnd;
--        getInlineRun(child, insertionPoint, inlineRunStart, inlineRunEnd);
--
--        if (!inlineRunStart)
--            break;
--
--        child = inlineRunEnd->nextSibling();
--
--        RenderBlock* block = createAnonymousBlock();
--        children()->insertChildNode(this, block, inlineRunStart);
--        moveChildrenTo(block, inlineRunStart, child);
--    }
--
--#ifndef NDEBUG
--    for (RenderObject *c = firstChild(); c; c = c->nextSibling())
--        ASSERT(!c->isInline());
--#endif
--
--    repaint();
end


function LayoutBlock:AddChildIgnoringAnonymousColumnBlocks(newChild, beforeChild)
	-- Make sure we don't append things after :after-generated content if we have it.
    if (not beforeChild) then
        beforeChild = self:FindAfterContentRenderer();
	end

    -- If the requested beforeChild is not one of our children, then this is because
    -- there is an anonymous container within this object that contains the beforeChild.
    if (beforeChild and beforeChild:Parent() ~= self) then
--        RenderObject* beforeChildAnonymousContainer = anonymousContainer(beforeChild);
--        ASSERT(beforeChildAnonymousContainer);
--        ASSERT(beforeChildAnonymousContainer->isAnonymous());
--
--        if (beforeChildAnonymousContainer->isAnonymousBlock()) {
--            // Insert the child into the anonymous block box instead of here.
--            if (newChild->isInline() || beforeChild->parent()->firstChild() != beforeChild)
--                beforeChild->parent()->addChild(newChild, beforeChild);
--            else
--                addChild(newChild, beforeChild->parent());
--            return;
--        }
--
--        ASSERT(beforeChildAnonymousContainer->isTable());
--        if ((newChild->isTableCol() && newChild->style()->display() == TABLE_COLUMN_GROUP)
--                || (newChild->isRenderBlock() && newChild->style()->display() == TABLE_CAPTION)
--                || newChild->isTableSection()
--                || newChild->isTableRow()
--                || newChild->isTableCell()) {
--            // Insert into the anonymous table.
--            beforeChildAnonymousContainer->addChild(newChild, beforeChild);
--            return;
--        }
--
--        // Go on to insert before the anonymous table.
--        beforeChild = beforeChildAnonymousContainer;
    end

    -- Check for a spanning element in columns.
    local columnsBlockAncestor = self:ColumnsBlockForSpanningElement(newChild);
    if (columnsBlockAncestor) then
--        // We are placing a column-span element inside a block. 
--        RenderBlock* newBox = createAnonymousColumnSpanBlock();
--        
--        if (columnsBlockAncestor != this) {
--            // We are nested inside a multi-column element and are being split by the span.  We have to break up
--            // our block into continuations.
--            RenderBoxModelObject* oldContinuation = continuation();
--            setContinuation(newBox);
--
--            // Someone may have put a <p> inside a <q>, causing a split.  When this happens, the :after content
--            // has to move into the inline continuation.  Call updateBeforeAfterContent to ensure that our :after
--            // content gets properly destroyed.
--            bool isLastChild = (beforeChild == lastChild());
--            if (document()->usesBeforeAfterRules())
--                children()->updateBeforeAfterContent(this, AFTER);
--            if (isLastChild && beforeChild != lastChild())
--                beforeChild = 0; // We destroyed the last child, so now we need to update our insertion
--                                 // point to be 0.  It's just a straight append now.
--
--            splitFlow(beforeChild, newBox, newChild, oldContinuation);
--            return;
--        }
--
--        // We have to perform a split of this block's children.  This involves creating an anonymous block box to hold
--        // the column-spanning |newChild|.  We take all of the children from before |newChild| and put them into
--        // one anonymous columns block, and all of the children after |newChild| go into another anonymous block.
--        makeChildrenAnonymousColumnBlocks(beforeChild, newBox, newChild);
--        return;
    end

    local madeBoxesNonInline = false;

    -- A block has to either have all of its children inline, or all of its children as blocks.
    -- So, if our children are currently inline and a block child has to be inserted, we move all our
    -- inline children into anonymous block boxes.
    if (self:ChildrenInline() and not newChild:IsInline() and not newChild:IsFloatingOrPositioned()) then
        -- This is a block with inline content. Wrap the inline content in anonymous blocks.
        self:MakeChildrenNonInline(beforeChild);
        madeBoxesNonInline = true;

        if (beforeChild and beforeChild:Parent() ~= self) then
            beforeChild = beforeChild:Parent();
            if(beforeChild:IsAnonymousBlock()) then
				return;
			end
            if(beforeChild:Parent() == self) then
				return;
			end
        end
--    elseif(!childrenInline() && (newChild->isFloatingOrPositioned() || newChild->isInline())) then
--        -- If we're inserting an inline child but all of our children are blocks, then we have to make sure
--        -- it is put into an anomyous block box. We try to use an existing anonymous box if possible, otherwise
--        -- a new one is created and inserted into our list of children in the appropriate position.
--        RenderObject* afterChild = beforeChild ? beforeChild->previousSibling() : lastChild();
--
--        if (afterChild && afterChild->isAnonymousBlock()) {
--            afterChild->addChild(newChild);
--            return;
--        }
--
--        if (newChild->isInline()) {
--            -- No suitable existing anonymous box - create a new one.
--            RenderBlock* newBox = createAnonymousBlock();
--            RenderBox::addChild(newBox, beforeChild);
--            newBox->addChild(newChild);
--            return;
--        }
    end

    LayoutBlock._super.AddChild(self, newChild, beforeChild);

    if (madeBoxesNonInline and self:Parent() and self:IsAnonymousBlock() and self:Parent():IsLayoutBlock()) then
       self:Parent():RemoveLeftoverAnonymousBlock(self);
	end
    -- this object may be dead here
end

function LayoutBlock:RemoveLeftoverAnonymousBlock(child)
	--TODO: fixed this function
end

function LayoutBlock:FirstLineBox()
	return;
end

function LayoutBlock:LastLineBox()
	return;
end