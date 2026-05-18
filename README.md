# 熊猫插件整合包

> 基于 `DragonUI` 深度改造与整合的《魔兽世界》3.3.5a 插件集合，目标是把常用界面、美化、团队、任务、资料与实用插件统一到一套开箱可用的包里。

![Interface Version](https://img.shields.io/badge/Interface-30300-blue)
![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-orange)
![Release](https://img.shields.io/badge/Release-Tag-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

<img width="1917" height="1054" alt="熊猫插件整合包界面预览" src="https://github.com/user-attachments/assets/dd45ed01-a35e-45fb-8426-897d29d35917" />

<details>
<summary><strong>更多界面截图（点击展开）</strong></summary>
<img width="1918" height="1054" alt="界面截图 1" src="https://github.com/user-attachments/assets/d29e956a-4831-4a99-b1f3-4f3208a337e2" />
<img width="1917" height="1054" alt="界面截图 2" src="https://github.com/user-attachments/assets/761d0315-ac4c-4aff-8e60-75beea91fdb1" />
<img width="1076" height="745" alt="配置界面截图" src="https://github.com/user-attachments/assets/47a14b2f-f7ec-46ab-af35-e938d52d0e09" />
</details>

## 项目简介

这不是单一插件，而是一套围绕 `DragonUI` 构建的 3.3.5a 整合方案。

当前整合包包含：

- `DragonUI` 核心界面系统
- `DragonUI_Options` 自定义配置面板
- 任务辅助、资料查询、团队治疗、团队提醒、PvP 提示、战斗统计、邮件与垃圾处理等常用插件
- 针对整合场景做过的兼容与统一配置处理

目前的目标不是“把插件都堆进来”，而是：

1. 保持主界面风格统一
2. 让常用插件都能从一个入口管理
3. 尽量减少重复功能和互相冲突
4. 为 3.3.5a 私服 / 非官方环境保留足够的兼容弹性

## 当前整合亮点

### 1. 统一界面基础

- 基于 `DragonUI` 的动作条、单位框体、施法条、小地图、聊天、背包、微型菜单与经验/声望条
- 支持深色模式、发光效果、零件缩放、框体移动与布局微调
- 内置编辑模式与按键绑定模式
- 支持配置导入、导出、预设保存和配置文件切换

### 2. 统一插件管理入口

游戏内提供“插件管理”页面，可直接：

- 查看当前整合插件的启用状态
- 按分类管理插件
- 打开大部分插件自己的设置界面
- 通过同一套界面控制整合内容

### 3. 已做的重点整合

- `Questie-335`
  - 已接入整合包
  - 强制关闭 Questie 自带任务追踪器，统一使用 `DragonUI` 的任务追踪样式
  - 修复了 3.3.5 环境下追踪头部宽度相关报错
  - 对私服常见的“Questie 数据库缺失任务”红字做了定向静音处理

- `EventAlert`
  - 已移植接入
  - 可用于法术触发、增益与目标减益提醒

- `RaidAlerter`
  - 已接入整合包
  - 适合团队环境下的警报、误导、驱散、团队检查与提示场景

- 小地图与菜单入口
  - 统一增加整合包入口按钮
  - 配置面板左上角、ESC 菜单按钮、小地图按钮提示统一使用“熊猫插件整合包”品牌名称

## 已整合插件一览

下面是当前仓库中已经纳入整合包的主要插件方向。

### 首领战斗 / 副本提醒

- `DBM-Core`
- `DBM-GUI`
- `DBM` 各资料片与副本模块

### 团队 / 治疗 / 团长工具

- `Grid2`
- `Grid2Options`
- `Grid2StatusRaidDebuffs`
- `Grid2StatusRaidDebuffsOptions`
- `Clique`
- `Decursive`
- `oRA3`
- `RaidAlerter`

### PvP

- `GladiatorlosSA`

### 任务 / 地图 / 资料

- `Questie-335`
- `Atlas`
- `AtlasLoot`
- `Mapster`
- `GatherMate`
- `GatherMate_Data`
- `TradeskillInfo`
- `TradeskillInfoUI`
- `Mendeleev`
- `RatingBuster`

### 界面增强 / 实用工具

- `Kui_Nameplates`
- `Kui_Nameplates_Auras`
- `EventAlert`
- `Postal`
- `WhisperPop`
- `SellJunk`

### 战斗统计

- `Skada`

## 安装方式

### 方式一：使用发布包

发布包命名规则为：

```text
熊猫插件整合-版本.zip
```

压缩包内只包含：

```text
AddOns/
```

安装步骤：

1. 下载发布包并解压
2. 打开解压后的 `AddOns` 目录
3. 将其中所有插件文件夹复制到：

```text
World of Warcraft/Interface/AddOns/
```

4. 进入游戏，在插件列表里确认相关插件已启用
5. 使用 `/dui` 或 `/dragonui` 打开配置界面

### 方式二：直接使用仓库内容

如果你是自己打包或手动同步：

1. 直接使用仓库中的 `AddOns` 目录
2. 将 `AddOns` 下所有子目录复制到客户端的 `Interface/AddOns/`
3. 覆盖旧文件后重载游戏

## 更新建议

从旧版本升级时，建议：

- 先备份 `WTF` 目录里的相关配置
- 如果出现界面错位、旧配置残留或插件行为异常，再考虑清理对应的 `SavedVariables`
- 大版本整合变动后，优先使用新配置重新测试

## 常用命令

### 主界面 / 配置

- `/dragonui`
- `/dui`
- `/pi`

作用：打开整合包主配置面板。

### 编辑模式 / 绑定模式

- `/dragonui edit`：切换编辑模式
- `/dragonui kb`：切换按键绑定模式

### 兼容与诊断

- `/duicomp`：打开兼容诊断与状态检查
- `/dragonui debug on`
- `/dragonui debug off`
- `/dragonui debug status`

### 背包与整理

- `/sort`：整理背包
- `/sortbank`：整理银行
- `/sortlock`：锁定当前鼠标指向物品/格子

### 聊天与快捷功能

- `/tt <内容>`：密语当前目标
- `/rl`：重载界面

## 当前整合说明

### Questie 相关

- 当前整合策略是：保留 Questie 的地图标记、任务搜索、鼠标提示等能力
- 关闭 Questie 自带追踪器，统一使用 `DragonUI` 的任务追踪界面
- 对私服常见自定义任务 ID 导致的红字提示做了整合层处理，避免无意义刷屏

### 配置入口

当前可以从以下位置打开或进入整合包配置：

- 聊天命令 `/dragonui`、`/dui`、`/pi`
- 小地图整合按钮
- ESC 菜单中的“熊猫插件整合包”按钮

### 配置面板品牌

当前配置面板已统一展示为：

```text
熊猫插件整合包
```

不再沿用原始的 `DragonUI 2.5` 标题展示。

## 已知说明

- 本整合包面向 `WoW 3.3.5a`
- 部分外部插件本身存在年代较久、私服环境差异较大的情况，遇到兼容问题时需要单独处理
- 如果第三方服务器修改了法术、任务、地图或团队 API，个别插件可能仍需进一步适配

## 仓库结构

```text
AddOns/                 游戏实际使用的插件目录
LICENSES/               第三方许可证
THIRD_PARTY_NOTICES.md  第三方组件说明
```

如果你要做发布或同步，最核心的就是 `AddOns/`。

## 致谢

本整合包建立在以下项目和作者的工作基础之上：

- `DragonUI`
- `Questie`
- `DBM`
- `Grid2`
- `oRA3`
- `Atlas / AtlasLoot`
- `Mapster`
- `GatherMate`
- `TradeskillInfo`
- `Skada`
- 以及仓库中所有被整合进来的第三方插件作者

## 许可证与声明

- `DragonUI` 自身代码遵循 [MIT License](LICENSE)
- 仓库中整合的第三方插件与资源，仍分别遵循其各自许可证
- 详细说明见：
  - [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
  - `LICENSES/`

本项目为玩家整理与整合用途，不隶属于也不代表暴雪娱乐。
