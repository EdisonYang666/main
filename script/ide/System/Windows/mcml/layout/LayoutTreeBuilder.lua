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
NPL.load("(gl)script/ide/System/Windows/mcml/render/LayoutInline.lua");
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
end

-- @param node:	PageElement
-- @param style: ComputedStyle
function LayoutTreeBuilder:init(node, style)
	self.node = node;
	self.style = style;
	self:initParentLayoutObject();
	return self;
end

function LayoutTreeBuilder:ParentLayoutObject()
	return self.layout_object_parent;
end

function LayoutTreeBuilder:initParentLayoutObject()
	self.layout_object_parent = nil;
	if(self.node.parent) then
		self.layout_object_parent = self.node.parent:GetLayoutObject();
	end
end

function LayoutTreeBuilder:ShouldCreateLayoutObject()
	if(self.node.name == "pe:mcml") then
		return true;
	end
	if(not self.layout_object_parent) then
		return false;
	end
	if(not self.layout_object_parent:CanHaveChildren()) then
		return false;
	end

	return self.node:LayoutObjectIsNeeded(style);
end

function LayoutTreeBuilder:CreateLayoutObjectIfNeeded()
	if(self:ShouldCreateLayoutObject()) then
		self:CreateLayoutObject();
	end
end

function LayoutTreeBuilder:CreateLayoutObjectWithDisplay()
	local node = self.node;
	local display = self.style:Display();
	if(display == "block" or display == "inline-block") then
		return LayoutBlock:new():init(node);
	elseif(display == "inline") then
		return LayoutInline:new():init(node);
	end
end

function LayoutTreeBuilder:CreateLayoutObject()
	echo("LayoutTreeBuilder:CreateLayoutObject");
	echo(self.node.name);
	echo(self.node.attr.name);
	-- �����л���PageElement:CreateLayoutObject�����������LayoutObject����
	-- self.node:CreateLayoutObject(self.style)
	local node, style = self.node, self.style;

	local layout_object = node:GetLayoutObject();
	if(not layout_object) then
		layout_object = self:CreateLayoutObjectWithDisplay();
		node:SetLayoutObject(layout_object);
	end
	

	layout_object:SetStyle(style);

	local parent_layout_object = self:ParentLayoutObject();
--	echo("LayoutTreeBuilder:CreateLayoutObject");
--	echo(node.name);
--	echo(node.attr.name);
	if(parent_layout_object) then
--		echo(parent_layout_object.name);
		parent_layout_object:AddChild(layout_object);
--	else
--		echo("no parent_layout_object")
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
end
