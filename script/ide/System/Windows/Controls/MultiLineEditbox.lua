--[[
Title: MultiLineEditbox
Author(s): LiPeng
Date: 2017/10/3
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/MultiLineEditbox.lua");
local MultiLineEditbox = commonlib.gettable("System.Windows.Controls.MultiLineEditbox");
------------------------------------------------------------

test
------------------------------------------------------------
NPL.load("(gl)script/ide/test/test_multiline_editbox.lua");
test.test_multiline_generalV2();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/ScrollAreaBase.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/TextControl.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local TextControl = commonlib.gettable("System.Windows.Controls.TextControl");
local Point = commonlib.gettable("mathlib.Point");
local Rect = commonlib.gettable("mathlib.Rect");
local UniString = commonlib.gettable("System.Core.UniString");
local Application = commonlib.gettable("System.Windows.Application");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");

local MultiLineEditbox = commonlib.inherit(commonlib.gettable("System.Windows.Controls.Primitives.ScrollAreaBase"), commonlib.gettable("System.Windows.Controls.MultiLineEditbox"));
MultiLineEditbox:Property("Name", "MultiLineEditbox");

MultiLineEditbox:Property({"Background", "", auto=true});
MultiLineEditbox:Property({"BackgroundColor", "#cccccc", auto=true});
MultiLineEditbox:Property({"LineNumberBackground", "", auto=true});
MultiLineEditbox:Property({"LineNumberBackgroundColor", "#eeeeee80", auto=true});
MultiLineEditbox:Property({"LineNumberColor", "#808080", auto=true});
MultiLineEditbox:Property({"showLineNumber", false, nil, "ShowLineNumber", auto=true})
MultiLineEditbox:Property({"Color", "#000000", })
MultiLineEditbox:Property({"CursorColor", "#33333388"})
MultiLineEditbox:Property({"SelectedBackgroundColor", "#99c9ef", auto=true})
MultiLineEditbox:Property({"CurLineBackgroundColor", "#e5ebf1e0", auto=true})
MultiLineEditbox:Property({"AlwaysShowCurLineBackground", true, "isAlwaysShowCurLineBackground", "SetAlwaysShowCurLineBackground"})
MultiLineEditbox:Property({"m_cursor", nil, "cursorPosition", "setCursorPosition"})
MultiLineEditbox:Property({"cursorVisible", false, "isCursorVisible", "setCursorVisible"})
MultiLineEditbox:Property({"m_cursorWidth", 2,})
MultiLineEditbox:Property({"m_blinkPeriod", 0, "getCursorBlinkPeriod", "setCursorBlinkPeriod"})
--MultiLineEditbox:Property({"m_readOnly", false, "isReadOnly", "setReadOnly", auto=true})
MultiLineEditbox:Property({"m_echoMode", "Normal", "echoMode", "setEchoMode"})
MultiLineEditbox:Property({"Font", "System;14;norm", auto=true})
MultiLineEditbox:Property({"Scale", nil, "GetScale", "SetScale", auto=true})
MultiLineEditbox:Property({"horizontalMargin", 0});
MultiLineEditbox:Property({"leftTextMargin", 2});
MultiLineEditbox:Property({"topTextMargin", 2});
MultiLineEditbox:Property({"rightTextMargin", 2});
MultiLineEditbox:Property({"bottomTextMargin", 2});
-- TODO: for lipeng 2017.12.6, text to show when text is empty. such as "click to enter text..."
MultiLineEditbox:Property({"EmptyText", nil, "GetEmptyText", "SetEmptyText", auto=true})
MultiLineEditbox:Property({"m_readOnly", false, "isReadOnly", "setReadOnly"})
--MultiLineEditbox:Property({"m_readOnly", false, "  ", "setReadOnly"})
--MultiLineEditbox:Property({"m_maxLength", 65535, "getMaxLength", "setMaxLength", auto=true})
--MultiLineEditbox:Property({"rows", nil, "GetRows", "SetRows"})
MultiLineEditbox:Property({"lineWrap", nil, "GetLineWrap", "SetLineWrap", auto=true})
MultiLineEditbox:Property({"ItemHeight",20, auto=true, "GetItemHeight", "SetItemHeight"})
-- if nil, its value depends on whether self.InputMethodEnabled is true.
MultiLineEditbox:Property({"isAlwaysShowIMEButton", nil})

--MultiLineEditbox:Property({"vSliderWidth", 20, auto=true});
--MultiLineEditbox:Property({"hSliderHeight", 20, auto=true});
--MultiLineEditbox:Property({"vSliderWidth", nil, auto=true});
--MultiLineEditbox:Property({"hSliderHeight", nil, auto=true});

--MultiLineEditbox:Signal("resetInputContext");
MultiLineEditbox:Signal("selectionChanged");
MultiLineEditbox:Signal("cursorPositionChanged", function(oldLine, newLine, oldPos, newPos) end);
MultiLineEditbox:Signal("textChanged");
--MultiLineEditbox:Signal("accepted");
--MultiLineEditbox:Signal("editingFinished");
--MultiLineEditbox:Signal("updateNeeded");

local OverflowEnum = ComputedStyleConstants.OverflowEnum;

function MultiLineEditbox:ctor()
--	self:setFocusPolicy(FocusPolicy.StrongFocus);
--	self:setAttribute("WA_InputMethodEnabled");
--	self:setMouseTracking(true);
	self.clip = self.showLineNumber;
end

function MultiLineEditbox:init(parent)
	MultiLineEditbox._super.init(self, parent);
	return self;
end

function MultiLineEditbox:ShowIMEButton(bShow)
	if(bShow) then
		if(not self.imeButton) then
			self.imeButton = Button:new():init(self);
			self.imeButton:setRect(self.leftTextMargin,self.topTextMargin,16,16);
			self.imeButton:SetBackground("Texture/whitedot.png");
			self.imeButton:SetTooltip("If English Only");
			self.imeButton:Connect("clicked", self, self.OnClickToggleIME);
			self:UpdateIMEButton();
		end
		if(self.isAlwaysShowIMEButton == nil) then
			self.isAlwaysShowIMEButton = true;
		end
		self.imeButton:show();
	else
		if(self.imeButton) then
			self.imeButton:hide();
		end
	end
end

function MultiLineEditbox:OnClickToggleIME()
	self:SetInputMethodEnabled(not self:IsInputMethodEnabled());
	self:UpdateIMEButton();
end

function MultiLineEditbox:UpdateIMEButton()
	if(self.imeButton) then
		if(self:IsInputMethodEnabled()) then
			self.imeButton:SetText(L"On");
			self.imeButton:SetBackgroundColor("#33333360");
			self.imeButton:SetColor("#ffffff60");
		else
			self.imeButton:SetText(L"En");
			self.imeButton:SetBackgroundColor("#3333ff60");
			self.imeButton:SetColor("#ffffff60");
		end
	end
end

function MultiLineEditbox:initViewport()
	self.viewport = TextControl:new():init(self);
	self.viewport:SetClip(true);
end

function MultiLineEditbox:ShowLineNumber(value)
	self.showLineNumber = value;
	self.clip = value;
end
function MultiLineEditbox:SetColor(color)
	if(self.viewport) then
		self.viewport:SetColor(color);
	end
end

function MultiLineEditbox:SetFont(font)
	if(self.viewport) then
		return self.viewport:SetFont(font);
	end
end

function MultiLineEditbox:SetScale(scale)
	if(self.viewport) then
		return self.viewport:SetScale(scale);
	end
end

function MultiLineEditbox:GetColor()
	if(self.viewport) then
		return self.viewport:GetColor();
	end
end

function MultiLineEditbox:SetCursorColor(color)
	if(self.viewport) then
		self.viewport:SetCursorColor(color);
	end
end

function MultiLineEditbox:GetCursorColor()
	if(self.viewport) then
		return self.viewport:GetCursorColor();
	end
end

function MultiLineEditbox:SetCurLineBackgroundColor(color)
	if(self.viewport) then
		self.viewport:SetCurLineBackgroundColor(color);
	end
end

function MultiLineEditbox:GetCurLineBackgroundColor()
	if(self.viewport) then
		return self.viewport:GetCurLineBackgroundColor();
	end
end

function MultiLineEditbox:SetAlwaysShowCurLineBackground(isShow)
	if(self.viewport) then
		self.viewport:SetAlwaysShowCurLineBackground(isShow);
	end
end

function MultiLineEditbox:isAlwaysShowCurLineBackground()
	if(self.viewport) then
		return self.viewport:isAlwaysShowCurLineBackground();
	end
end

function MultiLineEditbox:setLinePosColor(line, begin_pos, end_pos, font, color, scale)
	if(self.viewport) then
		self.viewport:setLinePosColor(line, begin_pos, end_pos, font, color, scale)
	end
end

function MultiLineEditbox:SetSelectedBackgroundColor(color)
	if(self.viewport) then
		self.viewport:SetSelectedBackgroundColor(color);
	end
end

function MultiLineEditbox:GetSelectedBackgroundColor()
	if(self.viewport) then
		return self.viewport:GetSelectedBackgroundColor();
	end
end

function MultiLineEditbox:isReadOnly()
	if(self.viewport) then
		return self.viewport:isReadOnly();
	end
end

function MultiLineEditbox:setReadOnly(bReadonly)
	if(self.viewport) then
		self.viewport:setReadOnly(bReadonly);
	end
end

function MultiLineEditbox:echoMode()
    return self.m_echoMode;
end

function MultiLineEditbox:SetEmptyText(text)
	self.viewport:SetEmptyText(text)
end

function MultiLineEditbox:SetLanguage(language)
	self.viewport:SetLanguage(language)
end

function MultiLineEditbox:setEchoMode(mode)
	if(self.m_echoMode == mode) then
		return;
	end
    self.m_echoMode = mode;
	self:Update();
end

function MultiLineEditbox:reset()

end

--function MultiLineEditbox:SetRows(value)
--	self.rows = value;
--	--local height = self.rows * self.itemHeight + leftTextMargin;
--	local height = self.rows * self.itemHeight;
--	self:resize(self:width(), height);
--end

function MultiLineEditbox:GetRows()
	return math.floor(self:ViewPort():height()/self.ItemHeight);
end

function MultiLineEditbox:ViewPort()
	return self.viewport;
end

function MultiLineEditbox:setReadOnly(bReadOnly)
	--self.m_readOnly = bReadOnly;
	if(self.viewport) then
		self.viewport:setReadOnly(bReadOnly);
	end
end

function MultiLineEditbox:isReadOnly()
	if(self.viewport) then
		self.viewport:isReadOnly();
	end
end

function MultiLineEditbox:SetText(text)
	self.viewport:SetText(text);
end

function MultiLineEditbox:GetText()
	return self.viewport:GetText();
end

function MultiLineEditbox:AddItem(text)
	self.viewport:AddItem(text);
end

function MultiLineEditbox:RemoveItem(index)
	self.viewport:RemoveItem(index);
end

function MultiLineEditbox:contains(x,y)
	return self:rect():contains(x,y);
end

function MultiLineEditbox:updateViewportPos()
	self.viewport:updatePos(self.hscroll, self.vscroll);
end

function MultiLineEditbox:GetRow()
	return math.floor(self:ViewRegion():height()/self.viewport:GetLineHeight());
end

function MultiLineEditbox:UpdateScrollbarValue()
	if(not self.scrollbarValueDirty) then
		return;
	end

	if(not self.hbar:isHidden()) then
		self.hscroll = self.viewport:hValue();
		self.hbar:SetValue(self.hscroll);
	end

	if(not self.vbar:isHidden()) then
		self.vscroll = self.viewport:vValue();
		self.vbar:SetValue(self.vscroll);
	end

	self.scrollbarValueDirty = false;
end

-- text region. 
function MultiLineEditbox:ViewRegion()
	local x = self.leftTextMargin;
	local y = self.topTextMargin;
	local w = self:width() - self.leftTextMargin - self.rightTextMargin;
	local h = self:height() - self.topTextMargin - self.bottomTextMargin;

	if(self.hbar and not self.hbar:isHidden()) then
		h = h - self.SliderSize;
	end

	if(self.vbar and not self.vbar:isHidden()) then
		w = w - self.SliderSize;
	end

	if(self.showLineNumber) then
		x = x + self:LineNumberWidth();
		w = w - self:LineNumberWidth();
	end
	return Rect:new_from_pool(x,y,w,h);
end

function MultiLineEditbox:ViewRegionOffsetX()
	local offset_x = self.leftTextMargin;
	if(self.showLineNumber) then
		offset_x = offset_x + self:LineNumberWidth();
	end
	return offset_x;
end

function MultiLineEditbox:ViewRegionOffsetY()
	local offset_y = self.topTextMargin;
	return offset_y;
end

local overflowMap = {
	[OverflowEnum.OSCROLL] = "AlwaysOn",
	[OverflowEnum.OHIDDEN] = "AlwaysOff",
	[OverflowEnum.OAUTO] = "Auto",
}

function MultiLineEditbox:ApplyCss(css)
	MultiLineEditbox._super.ApplyCss(self, css);
	self:SetItemHeight(css:ComputedLineHeight());
	if(self.viewport) then
		self.viewport:ApplyCss(css);
	end

	local overflow_x = css:OverflowX();
	local overflow_y = css:OverflowY();
	if(overflow_x == OverflowEnum.OVISIBLE and overflow_x == OverflowEnum.OVISIBLE) then
		--self:setHorizontalScrollBarPolicy()
	else
		self:setHorizontalScrollBarPolicy(overflowMap[overflow_x])
		self:setVerticalScrollBarPolicy(overflowMap[overflow_y])
	end
end

function MultiLineEditbox:LineNumberWidth()
	if(not self.lineNumberWidth) then
		self.lineNumberWidth = self.viewport:WordWidth() + self.leftTextMargin;
	end
	return self.lineNumberWidth;
end

function MultiLineEditbox:GetLineNumberAlignment()
	-- default to right,top and no clipping.
	return 2+256;
end

function MultiLineEditbox:SetItemHeight(value)
	self.ItemHeight = value;
	if(self.viewport) then
		self.viewport:SetLineHeight(value);
	end
end

function MultiLineEditbox:GetItemHeight()
	return self.ItemHeight;
end

function MultiLineEditbox:paintEvent(painter)
	MultiLineEditbox._super.paintEvent(self, painter);

	--self:updateScrollGeometry();
	painter:SetPen(self:GetBackgroundColor());
	painter:DrawRectTexture(self:x(), self:y(), self:width(), self:height(), self:GetBackground());

	if(self.showLineNumber) then
		painter:SetPen(self:GetLineNumberBackgroundColor());
		painter:DrawRectTexture(self:x(), self:y() + self.topTextMargin, self:LineNumberWidth(), self:height()- self.topTextMargin - self.bottomTextMargin, self:GetLineNumberBackground());

		local lineHeight = self.viewport:GetLineHeight();

		local bShowIME;
		if(self.viewport and self.viewport.cursorVisible and self.viewport:hasFocus() and not self.viewport:isReadOnly()) then
			-- draw the cursor line bg
			painter:SetPen(self.viewport:GetCurLineBackgroundColor());
			painter:DrawRect(self:x(), self:y() + self.topTextMargin + lineHeight * (self.viewport.cursorLine-self.viewport.from_line), self:LineNumberWidth(), lineHeight);

			-- draw input method tip
			if(self:GetWindow() and not self:GetWindow():IsInputMethodEnabled()) then
				bShowIME = true;
			else
				bShowIME = self.isAlwaysShowIMEButton;
			end
		end
		self:ShowIMEButton(bShowIME);

		painter:SetPen(self:GetLineNumberColor());
		painter:SetFont(self:GetFont());
		local scale = self:GetScale();
		local lineNumWidth = self:LineNumberWidth()-5; -- add some padding
		for i = 0, self.viewport.to_line - self.viewport.from_line do
			painter:DrawTextScaledEx(self:x(), self:y() + lineHeight * i + self.topTextMargin, lineNumWidth, lineHeight, tostring(self.viewport.from_line + i), self:GetLineNumberAlignment(), scale);
		end
	end
end

function MultiLineEditbox:SetTextMargin(left, top, right, bottom)
	self.leftTextMargin = left or self.leftTextMargin;
	self.topTextMargin = top or self.topTextMargin;
	self.rightTextMargin = right or self.rightTextMargin;
	self.bottomTextMargin = bottom or self.bottomTextMargin;
end