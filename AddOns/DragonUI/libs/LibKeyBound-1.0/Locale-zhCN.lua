--[[
	KeyBound localization file
		Chinese Simplified by ondh - http://www.ondh.cn
--]]

if (GetLocale() ~= "zhCN") then
	return
end

local REVISION = 90000 + tonumber(("$Revision: 92 $"):match("%d+"))
if (LibKeyBoundLocale10 and REVISION <= LibKeyBoundLocale10.REVISION) then
	return
end

local escapeKey = "Esc"

LibKeyBoundLocale10 = {
	REVISION = REVISION;
	BindingMode = "按键绑定模式";
	Enabled = "按键绑定模式已启用";
	Disabled = "按键绑定模式已禁用";
	ClearTip = format("按 %s 清除所有绑定", escapeKey);
	NoKeysBoundTip = "当前没有绑定按键";
	ClearedBindings = "从 %s 移除按键绑定";
	BoundKey = "设置 %s 到 %s";
	UnboundKey = "取消绑定 %s 从 %s";
	CannotBindInCombat = "不能在战斗状态绑定按键";
	CombatBindingsEnabled = "离开战斗状态, 按键绑定模式已启用";
	CombatBindingsDisabled = "进入战斗状态, 按键绑定模式已禁用";
	BindingsHelp = "将鼠标停留在按钮上, 然后按下要指定的快捷键即可完成绑定。要清除当前按钮的按键绑定, 请按 %s。";
	ResetKeybinds = "重置按键绑定";
	ResetKeybindsConfirm = "是否将所有按键绑定重置为默认设置？";
	CannotResetInCombat = "战斗中无法重置按键绑定。";
	AllKeybindsReset = "所有按键绑定已重置为默认设置。";

	-- This is the short display version you see on the Button
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "DA",
	["Left Arrow"] = "LA",
	["Right Arrow"] = "RA",
	["Up Arrow"] = "UA",
}
setmetatable(LibKeyBoundLocale10, {__index = LibKeyBoundBaseLocale10})
