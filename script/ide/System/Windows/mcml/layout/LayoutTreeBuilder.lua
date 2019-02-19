--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTreeBuilder.lua");
local LayoutTreeBuilder = commonlib.gettable("System.Windows.mcml.layout.LayoutTreeBuilder");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutView.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutButton.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutInline.lua");
local LayoutInline = commonlib.gettable("System.Windows.mcml.layout.LayoutInline");
local LayoutButton = commonlib.gettable("System.Windows.mcml.layout.LayoutButton");
local LayoutObject = commonlib.gettable("System.Windows.mcml.layout.LayoutObject");
local LayoutView = commonlib.gettable("System.Windows.mcml.layout.LayoutView");
local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");

local LayoutTreeBuilder = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutTreeBuilder"));

function LayoutTreeBuilder:ctor()
	self.node = nil;
	self.style = nil;

	self.layout_object_parent = nil;

	self.parentNodeForRenderingAndStyle = nil;
end

-- @param node:	PageElement
-- @param style: ComputedStyle
function LayoutTreeBuilder:init(node)
	self.node = node;
	self.style = nil;
	self:initParentLayoutObject();

	self.parentNodeForRenderingAndStyle = self.node.parent;
	return self;
end

function LayoutTreeBuilder:ParentNodeForRenderingAndStyle()
	return self.parentNodeForRenderingAndStyle;
end

function LayoutTreeBuilder:initParentLayoutObject()
	self.layout_object_parent = nil;
	if(self.node.parent) then
		self.layout_object_parent = self.node.parent:GetLayoutObject();
	end
end

function LayoutTreeBuilder:ShouldCreateLayoutObject()
	if(not self.layout_object_parent) then
		return false;
	end
	if(not self.layout_object_parent:CanHaveChildren()) then
		return false;
	end
	self.style = self.style or self.node:StyleForLayoutObject();
	return self.node:LayoutObjectIsNeeded(self.style);
end

function LayoutTreeBuilder:NextLayoutObject()
    --ASSERT(self.node->renderer() or m_location ~= LocationUndetermined);
	local renderer = self.node:Renderer();
    if (renderer) then
        return renderer:NextSibling();
	end

--    if (m_parentFlowRenderer)
--        return m_parentFlowRenderer->nextRendererForNode(self.node);
--
--    if (m_phase == AttachContentForwarded) then
--        if (RenderObject* found = nextRendererOf(m_includer, self.node))
--            return found;
--        return NodeRenderingContext(m_includer).nextRenderer();
--    end

    -- Avoid an O(n^2) problem with this function by not checking for
    -- nextRenderer() when the parent element hasn't attached yet.
    if (self.node:ParentOrHostNode() and not self.node:ParentOrHostNode():Attached()) then
        return;
	end
	local node = self.node:NextSibling();
	while(node) do
		if (node:Renderer()) then
			if(node:Renderer():Style() and not node:Renderer():Style():FlowThread() == "") then
				--continue;
			else
				return node:Renderer();
			end
		end
	
		node = node:NextSibling();
	end
    return;
end

function LayoutTreeBuilder:PreviousLayoutObject()
    --ASSERT(self.node->renderer() or m_location ~= LocationUndetermined);
	local renderer = self.node:Renderer();
    if (renderer) then
        return renderer:PreviousSibling();
	end

--    if (m_parentFlowRenderer)
--        return m_parentFlowRenderer->previousRendererForNode(self.node);
--
--    if (m_phase == AttachContentForwarded) then
--        if (RenderObject* found = previousRendererOf(m_includer, self.node))
--            return found;
--        return NodeRenderingContext(m_includer).previousRenderer();
--    end

    -- FIXME: We should have the same O(N^2) avoidance as nextRenderer does
    -- however, when I tried adding it, several tests failed.
	
	local node = self.node:PreviousSibling();
	while(node) do
		if (node:Renderer()) then
			if(node:Renderer():Style() and not node:Renderer():Style():FlowThread() == "") then
				--continue;
			else
				return node:Renderer();
			end
		end
	
		node = node:PreviousSibling()
	end
	
    return;
end

function LayoutTreeBuilder:ParentLayoutObject()
	if(self.layout_object_parent) then
		return self.layout_object_parent;
	end
	local renderer = self.node:Renderer();
    if (renderer) then
        --ASSERT(m_location == LocationUndetermined);
        return renderer:Parent();
    end

--    if (m_parentFlowRenderer)
--        return m_parentFlowRenderer;

    --ASSERT(m_location ~= LocationUndetermined);
	if(self.parentNodeForRenderingAndStyle) then
		return self.parentNodeForRenderingAndStyle:Renderer();
	end
    return;
end

function LayoutTreeBuilder:CreateLayoutObjectIfNeeded()
	echo("LayoutTreeBuilder:CreateLayoutObjectIfNeeded")
	if(self:ShouldCreateLayoutObject()) then
		self.style = self.style or self.node:StyleForLayoutObject();

		local next_layout_object = self:NextLayoutObject();

		local layout_object = self:CreateLayoutObject();
		echo("LayoutTreeBuilder:CreateLayoutObjectIfNeeded")
		layout_object:PrintNodeInfo()
		local parent_layout_object = self:ParentLayoutObject();
		parent_layout_object:PrintNodeInfo()
		if(parent_layout_object and layout_object) then
			local child = parent_layout_object:FirstChild();
			
			parent_layout_object:AddChild(layout_object, next_layout_object);
		end

		return true;
	end
	return false;
end

function LayoutTreeBuilder:CreateLayoutObject()
	-- �����л���PageElement:CreateLayoutObject�����������LayoutObject����
	-- self.node:CreateLayoutObject(self.style)
	local node, style = self.node, self.style;
	local layout_object = node:GetLayoutObject();
	if(not layout_object) then
		layout_object = node:CreateLayoutObject(nil, style);
		node:SetLayoutObject(layout_object);
	end
	
	if(layout_object) then
		layout_object:SetAnimatableStyle(style);
	end



--    switch (style->display()) {
--        case NONE:
--            return 0;
--        case INLINE:
--            return new (arena) RenderInline(node);
--        case BLOCK:
--        case INLINE_BLOCK:
--        case RUN_IN:
--        case COMPACT:
--            // Only non-replaced block elements can become a region.
--            if (!style->regionThread().isEmpty() && doc->renderView())
--                return new (arena) RenderRegion(node, doc->renderView()->renderFlowThreadWithName(style->regionThread()));
--            return new (arena) RenderBlock(node);
--        case LIST_ITEM:
--            return new (arena) RenderListItem(node);
--        case TABLE:
--        case INLINE_TABLE:
--            return new (arena) RenderTable(node);
--        case TABLE_ROW_GROUP:
--        case TABLE_HEADER_GROUP:
--        case TABLE_FOOTER_GROUP:
--            return new (arena) RenderTableSection(node);
--        case TABLE_ROW:
--            return new (arena) RenderTableRow(node);
--        case TABLE_COLUMN_GROUP:
--        case TABLE_COLUMN:
--            return new (arena) RenderTableCol(node);
--        case TABLE_CELL:
--            return new (arena) RenderTableCell(node);
--        case TABLE_CAPTION:
--            return new (arena) RenderBlock(node);
--        case BOX:
--        case INLINE_BOX:
--            return new (arena) RenderDeprecatedFlexibleBox(node);
--#if ENABLE(CSS3_FLEXBOX)
--        case FLEXBOX:
--        case INLINE_FLEXBOX:
--            return new (arena) RenderFlexibleBox(node);
--#endif
--    }
--
	return layout_object;
end
