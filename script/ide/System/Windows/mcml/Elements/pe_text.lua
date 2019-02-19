--[[
Title: text element
Author(s): LiXizhi
Date: 2015/4/28
Desc: it handles plain text node, or HTML tags of <span>
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_text.lua");
System.Windows.mcml.Elements.pe_text:RegisterAs("text");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Label.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutText.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
local UniString = commonlib.gettable("System.Core.UniString");
local LayoutText = commonlib.gettable("System.Windows.mcml.layout.LayoutText");
local mcml = commonlib.gettable("System.Windows.mcml");
local Label = commonlib.gettable("System.Windows.Controls.Label");
local UIElement = commonlib.gettable("System.Windows.UIElement")
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");

local pe_text = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_text"));
pe_text:Property({"class_name", "pe:text"});
pe_text.Property({"value", nil, "GetValue", "SetValue"})


local StyleChangeEnum = PageElement.StyleChangeEnum;

function pe_text:ctor()
end

-- public:
function pe_text:createFromString(str)
	return self:new({name="text", value = str});
end

function pe_text:GetTextTrimmed()
	echo("pe_text:GetTextTrimmed")
	echo(self.value)
	local value = self.value or self:GetAttributeWithCode("value", nil, true);
	echo(value)
	if(value) then
		value = string.gsub(value, "nbsp;", "");
		value = string.gsub(value, "^[%s]+", "");
		value = string.gsub(value, "[%s]+$", "");
	end
	return value;
end

function pe_text:LoadComponent(parentElem, parentLayout, style)
	--local css = self:CreateStyle(nil, style);
	--css["text-align"] = css["text-align"] or "left";

	local value = self:GetTextTrimmed();
	self.value = value;
--	if(not value or value=="") then
--		return true;
--	end
	--self:EnableSelfPaint(parentElem);
end

function pe_text:TranslateMe(langTable, transName)
	self.value = langTable(self.value);
end

function pe_text:ReplaceVariables(variables)
	local value = self.value;
	-- REPLACE
	local k;
	for k=1, #variables do
		local variable = variables[k];
		local var_value = value:match(variable.match_exp)
		if(var_value) then
			value = value:gsub(variable.gsub_exp, variable.func(var_value) or var_value); 
		end
	end

	self.value = value;
end

--function pe_text:LoadComponent(parentElem, parentLayout, style)
--	local css = self:CreateStyle(nil, style);
--
--	local value = self:GetTextTrimmed();
--	self.value = value;
--	if(not value or value=="") then
--		return true;
--	end
--	self:EnableSelfPaint(parentElem);
--
--	css.float = true;
--	local font, font_size, scale = css:GetFontSettings();
--	local line_padding = 2;
--	
--	if(css["line-height"]) then
--		local line_height = css["line-height"];
--		local line_height_percent = line_height:match("(%d+)%%");
--		if(line_height_percent) then
--			line_height_percent = tonumber(line_height_percent);
--			line_padding = math.ceil((line_height_percent*font_size*0.01-font_size)*0.5);
--		else
--			line_height = line_height:match("(%d+)");
--			line_height = tonumber(line_height);
--			if(line_height) then
--				line_padding = math.ceil((line_height-font_size)*0.5);
--			end
--		end
--	end
--	self.font = font;
--	self.font_size = font_size;
--	self.scale = scale;
--	self.line_padding = line_padding;
--	self.textflow = css.textflow;
--end

-- this function is called automatically after page component is loaded and whenever the window resize. 
function pe_text:UpdateLayout(parentLayout)
	self.value = self:GetTextTrimmed();
	self:CalculateTextLayout(self:GetValue(), parentLayout);
end

-- static function: calculate text. 
function pe_text:CalculateTextLayout(labelText, parentLayout)
	self.labels = commonlib.Array:new();
	self:CalculateTextLayout_helper(labelText, parentLayout, self:GetStyle());
end

-- private function: recursively calculate
function pe_text:CalculateTextLayout_helper(labelText, parentLayout, css)
	if(not labelText or labelText=="") then
		return
	end
	-- font-family: Arial; font-size: 14pt;font-weight: bold; 
	local left, top, width, height;
	local scale = self.scale;
	local textflow = self.textflow;
	local font_size = self.font_size;
	local line_padding = self.line_padding or 2;
	
		
	local labelWidth = _guihelper.GetTextWidth(labelText, self.font);
		
	-- labelWidth = labelWidth + 3;
	if(labelWidth>0) then
		width = parentLayout:GetPreferredSize();
		if(width == 0) then
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
			width = parentLayout:GetPreferredSize();
		end
		local remaining_text_func;
		if(labelWidth>width and width>0) then
			if(css and css["display"] == "block") then
					
			else
				-- for inline block, we will display recursively in multiple line
				local trim_text, remaining_text = _guihelper.TrimUtf8TextByWidth(labelText,width,self.font)

				if(trim_text and trim_text~="" and remaining_text and remaining_text~="") then
					remaining_text_func = function()
						parentLayout:NewLine();
						local left, top, width, height = parentLayout:GetPreferredRect();
						self:CalculateTextLayout_helper(remaining_text, parentLayout, css);
					end
					labelText = trim_text;
					labelWidth = _guihelper.GetTextWidth(labelText, font);
					if(labelWidth<=0) then
						return;
					end
				end
			end
			--width = parentLayout:GetMaxSize();
			--if(labelWidth>width) then
				--labelWidth = width
			--end
		end
		left, top = parentLayout:GetAvailablePos();
		height = font_size;
		width = labelWidth;
			
		if(scale) then
			width = width * scale;
			height = height * scale;
		end	

		height = height + line_padding + line_padding;

		local _this = Label:new():init();
		_this:SetText(labelText);
		_this:setGeometry(left, top, width, height);
		self.labels:add(_this);

		if(css) then
			if(css["text-align"]) then
				local aval_left, aval_top, aval_width, aval_height = parentLayout:GetPreferredRect();
				if(css["text-align"] == "right") then
					_this:setX(aval_width-width);
					width = aval_width; -- tricky: it will assume all width
				elseif(css["text-align"] == "center") then
					local shift_x = (aval_width - aval_left - width)/2
					_this:setX(aval_left + shift_x);
					width = width + shift_x; -- tricky: it will assume addition width
				end
			end
			if(css["text-shadow"]) then
				if(css["shadow-quality"]) then
					-- _this:GetAttributeObject():SetField("TextShadowQuality", tonumber(css["shadow-quality"]) or 0);
				end
				if(css["shadow-color"]) then
					-- _this:GetAttributeObject():SetField("TextShadowColor", _guihelper.ColorStr_TO_DWORD(css["shadow-color"]));
				end
			end	
		end
			
		-- this fixed an bug that text overrun the preferred rect.
		-- however, multiple lines of scaled font may still appear wrong, but will not affect parent layout after the fix.
		local max_width = parentLayout:GetPreferredSize();
		if(width>max_width) then
			width = max_width;
		end
		parentLayout:AddObject(width, height);

		if(remaining_text_func) then
			remaining_text_func();
		end
	end
end

-- virtual function: 
-- after child node layout is updated
function pe_text:OnAfterChildLayout(layout, left, top, right, bottom)
end

-- get value: it is usually one of the editor tag, such as <input>
function pe_text:GetValue()
	return self.value;
end

-- set value: it is usually one of the editor tag, such as <input>
function pe_text:SetValue(value)
	self.value = tostring(value);
end

-- virtual function: 
function pe_text:paintEvent(painter)
	if(self.labels) then
		local css = self:Renderer():Style();
		painter:SetFont(css:Font():ToTable());
		painter:SetPen(css:Color():ToDWORD());
		for i = 1, #self.labels do
			local label = self.labels[i];
			if(label) then
				local x = label.crect:x();
				local y = label.crect:y()+self.line_padding;
				local w = label.crect:width();
				local h = label.crect:height()-self.line_padding-self.line_padding;
				local text = label:GetText();

				if(be_shadow) then
					painter:SetPen(shadow_color);
					painter:DrawTextScaledEx(x + shadow_offset_x, y + shadow_offset_y, w, h, text, textAlignment, self.scale);
					painter:SetPen(css.color or "#000000");
				end

				painter:DrawTextScaledEx(x, y, w, h, text, textAlignment, self.scale);
			end
		end
	end
end

function pe_text:CreateLayoutObject(arena, style)
	local text = self:GetTextTrimmed();
	return LayoutText:new():init(self, text);
end

function pe_text:RecalcTextStyle(change)
	if(change ~= StyleChangeEnum.NoChange and self:ParentNode() and self:ParentNode():Renderer()) then
		if (self:Renderer()) then
			self:Renderer():SetStyle(self:ParentNode():Renderer():Style());
		end
	end

	if(self:NeedsStyleRecalc()) then
		if(self:ParentNode() and self:ParentNode():Renderer()) then
			if (self:Renderer()) then
				if (self:Renderer():IsText()) then
					self:Renderer():ToRenderText():SetText(self:GetValue());
				end
			else
				self:reattachLayoutTree();
			end
		end
	end

	self:ClearNeedsStyleRecalc();
end

function pe_text:Data()
	return self.value;
end

--void CharacterData::setData(const String& data, ExceptionCode&)
function pe_text:SetData(data)
	echo("pe_text:SetData")
    if (self:Data() == data) then
        return;
	end

    local oldLength = UniString:new(self.value):length();
	local newLength = UniString:new(data):length();

    self:SetDataAndUpdate(data, 1, oldLength, newLength);
    --document()->textRemoved(this, 0, oldLength);
end

--void CharacterData::appendData(const String& data, ExceptionCode&)
function pe_text:AppendData(data)
    local newStr = self.value;
    newStr = newStr..data;

	local oldLength = UniString:new(self.value):length();
	local newLength = UniString:new(data):length();

    self:SetDataAndUpdate(newStr, oldLength, 0, newLength);
end

--void CharacterData::updateRenderer(unsigned offsetOfReplacedData, unsigned lengthOfReplacedData)
function pe_text:UpdateRenderer(offsetOfReplacedData, lengthOfReplacedData)
	echo("pe_text:UpdateRenderer")
	echo(self.value)
	echo(self:Attached())
	if(self:Renderer()) then
		self:Renderer():PrintNodeInfo();
	end
    if ((not self:Renderer() or not self:RendererIsNeeded(self:Renderer():Style())) and self:Attached()) then
        self:reattachLayoutTree();
    elseif (self:Renderer()) then
        self:Renderer():ToRenderText():SetTextWithOffset(self.value, offsetOfReplacedData, lengthOfReplacedData);
	end
end

--void CharacterData::setDataAndUpdate(PassRefPtr<StringImpl> newData, unsigned offsetOfReplacedData, unsigned oldLength, unsigned newLength)
function pe_text:SetDataAndUpdate(newData, offsetOfReplacedData, oldLength, newLength)
--    if (document()->frame())
--        document()->frame()->selection()->textWillBeReplaced(this, offsetOfReplacedData, oldLength, newLength);
    --RefPtr<StringImpl> oldData = m_data;
    self.value = newData;
    self:UpdateRenderer(offsetOfReplacedData, oldLength);
    --dispatchModifiedEvent(oldData.get());
end

function pe_text:IsTextNode()
	return true;
end

function pe_text:GetAllChildWithNameIDClass(name, id, class, output)
	return output;
end

function pe_text:GetAllChildWithName(name, output)
	return output;
end

function pe_text:GetAllChildWithAttribute(attrName, attrValue, output)
	return output;
end

function pe_text:GetInnerText()
	return self.value;
end

function pe_text:print()
	log(self.value);
end