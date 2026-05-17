local L = LibStub("AceLocale-3.0"):NewLocale("KuiNameplatesAuras", "zhCN", false)
if not L then return end

L["Show my auras"] = "显示我的光环"
L["Auras"] = "光环"
L["Display auras cast by you on the current target's nameplate"] = "在当前目标的姓名板上显示你施放的光环"
L["Show on trivial units"] = "在小型单位上显示"
L["Show auras on trivial (half-size, lower maximum health) nameplates."] = "在小型单位（半尺寸、最大生命值较低）的姓名板上显示光环。"
L["Behaviour"] = "行为"
L["Use whitelist"] = "使用白名单"
L["Only display spells which your class needs to keep track of for PVP or an effective DPS rotation. Most passive effects are excluded."] = "只显示你的职业在 PvP 或有效 DPS 循环中需要关注的法术，大多数被动效果会被排除。"
L["Show on secondary targets"] = "显示在次要目标上"
L["Attempt to show and refresh auras on secondary targets - i.e. nameplates which do not have a visible unit frame on the default UI. Particularly useful when tanking."] = "尝试在次要目标上显示并刷新光环，也就是那些在默认界面里没有可见单位框体的姓名板。坦克时特别有用。"
L["Display"] = "显示"
L["Pulsate auras"] = "光环闪动"
L["Pulsate aura icons when they have less than 5 seconds remaining.\nSlightly increases memory usage."] = "当光环剩余时间少于 5 秒时，让其图标闪动。\n会略微增加内存占用。"
L["Show decimal places"] = "显示小数"
L["Show decimal places (.9 to .0) when an aura has less than one second remaining, rather than just showing 0."] = "当光环剩余时间少于 1 秒时，显示小数（0.9 到 0.0），而不是只显示 0。"
L["Sort auras by time remaining"] = "按剩余时间排序光环"
L["Increases memory usage."] = "会增加内存占用。"
L["Timer threshold (s)"] = "计时显示阈值（秒）"
L["Timer text will be displayed on auras when their remaining length is less than or equal to this value. -1 to always display timer."] = "当光环剩余时间小于或等于此值时，会显示计时文字。设为 -1 则始终显示计时。"
L["Effect length minimum (s)"] = "效果最短时长（秒）"
L["Auras with a total duration of less than this value will never be displayed. 0 to disable."] = "总持续时间低于此值的光环将不会显示。设为 0 可禁用。"
L["Effect length maximum (s)"] = "效果最长时长（秒）"
L["Auras with a total duration greater than this value will never be displayed. -1 to disable."] = "总持续时间高于此值的光环将不会显示。设为 -1 可禁用。"
L["Size"] = "大小"
L["Aura icon size on normal frames"] = "普通框体上的光环图标大小"
L["Size (trivial)"] = "大小（小型）"
L["Aura icon size on trivial frames"] = "小型框体上的光环图标大小"
L["Squareness"] = "方正度"
L["Where 1 is completely square and .5 is completely rectangular"] = "1 为完全正方形，0.5 为完全长方形"
L["Icons"] = "图标"
L["Global"] = "全局"

L["Edit spell list"] = "编辑法术列表"
L["Kui |cff9966ffSpell List|r"] = "Kui |cff9966ff法术列表|r"
L["Verbatim"] = "原样"
L["ADD_DESC "] = [[
将该名称解析为你法术书中的法术 ID，并加入追踪列表。
当输入框文字为 |cff88ff88绿色|r 时，这是默认行为。
]]
L["VERBATIM_DESC"] = [[
不尝试把这个法术解析为其 ID，直接按输入的名称加入。
换句话说，就是追踪所有与该名称匹配的光环。
当输入框文字为 |cffff0088红色|r 时，这是默认行为。
按住 Shift 再按回车也会强制使用这种方式。
]]

L["HELP_TEXT"] = [[
输入要追踪的技能 |cffffff00名称|r 或 |cffffff00法术 ID|r，然后按回车。
|cffffff00右键点击|r 法术可将其移除或忽略。

只有当前专精法术书里可见且可用的技能，才会按名称被识别。你也可以使用斜杠命令 |cffffff00/kslc dump|r，在把光环施加到目标后查找它们的法术 ID。

把鼠标移到“添加”和“原样”按钮上，可以查看更多说明。
]]
