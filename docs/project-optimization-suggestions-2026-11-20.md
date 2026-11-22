# LittleGames（玩趣盒）项目全面审查与优化建议

> 整理日期：2026-11-20
> 适用范围：基于仓库当前主工程源码（`entry/src/main/`）、资源目录（`entry/src/main/resources/`）、构建测试脚本（`scripts/`）及文档资产目录现状分析。

---

## 2026 年 11 月 22 日复核与处理

复核对象为玩趣盒 v1.1.0 和提交 `a5c48cf` 上的当前应用。公开目录为 **60 个入口、65 种玩法、6 个分类**。以下结论对应实际代码、模型回归、同模式 HAP 对照和 API 26 模拟器。后面的 11 月 20 日原文保留作对照，其中的源码链接指向当时的仓库快照。

### 功能与运行时

| 原报告项目 | 复核与实施 |
| --- | --- |
| 一.1 首页新增精选 | 8 个 ID 中 5 个已撤下，筛选后确实只剩 3 个。替换为 8 款在架游戏，测试同时核对数量、唯一性及可用路由。此前用户实际受到的影响是推荐少了五款，末行卡片数取决于所在窗口的列数。 |
| 一.2 合并模式 | 数学和节奏的设置页此前已按当前模式展示规则，三键跳跃也已使用节拍游标。仍有实际问题的是切换规则后继续使用父入口音效。现在五种数学、两种节奏模式分别激活自己的反馈音，四轨和三键的说明各自独立。 |
| 一.3、三.4 「我的」列表 | 最近游玩和常玩排行原先没有点击导航。现在逐行可打开相应游戏，已补可访问标签，排名的开局次数由父页提供。华容道中空的上下文检查一并移除。 |
| 一.4、5 结算反馈 | 成功震动原先无条件触发。现在只有庆祝结算使用成功触感，失败、平局使用轻触，并共用棋类和局判定。数独、华容道、滑动拼图、记忆翻牌、猜数字的结算均补了返回操作。 |
| 一.6、二.3 分类与搜索 | 5 类原来共用同一个图标。现在六类分别使用本机 SDK 中的不同符号。搜索名称、说明与分类计数在取得目录时建立，输入时直接筛选。同一份中文或英文目录的 60 款只需 120 次字符串读取，后续多次搜索额外读取为 0。 |
| 二.1 快照及进度 | 两个 ViewModel 的同步热路径确实使用 JSON 往返。改用分离的类型化快照，复用未变化的数组和实体，保留接续边界的 JSON。实际局面仍与初始快照对照，撤销回初始局面不会误报有进度。覆盖 87 个现行及归档模型的三档对照共 261 组。 |
| 二.2 32 ms 节流 | 有显示帧回调又按 32 ms 二次同步属实，现已取消。对 60 次间隔 16 ms 的钩索模型回调，视图发布由 30 次变为 60 次，物理步数均为 120；同步及进度查询的 JSON 编码由 90 次变为 0，解码由 30 次变为 0。该实验核对发布频率，实际显示帧率、耗电及 GC 停顿尚无设备测量。 |
| 二.4 贪吃蛇 | 旧页面每次更新遍历 20×20 格。现在背景棋盘独立绘制，前景仅更新蛇身、蛇头和食物。开局蛇长 3 时，一次移动的格子类型与方向读取各由 400 次降至 3 次，前景为 3 段蛇和 1 个食物。 |

[首页与搜索](../entry/src/main/ets/pages/home/HomeCatalog.ets) · [结算页](../entry/src/main/ets/components/GameResultDialog.ets) · [扩展游戏状态](../entry/src/main/ets/viewmodel/ExpansionViewModel.ets) · [桌面性能回归](../scripts/test-performance.cjs)

### 架构、资源与构建

| 原报告项目 | 复核与实施 |
| --- | --- |
| 三.1 数据管理 | 将 13 个基础目录条目移入 `ClassicCatalog`，把 Preferences 单键读取保护、防抖、异步刷盘及生命周期同步刷盘移入 `GamePreferences`。保留 `GameDataManager` 对外接口、原存储键、旧成绩及存档格式。 |
| 三.2 撤下界面与 LAN | 独立的 LAN 通讯/房间组件和跳一跳页面、3D 素材移入应用模块外的归档。9 个共享游戏页面/组件去除不可达的专属控件。历史记录、规则模型、35 项路由阻断和 LAN 传输独立回归继续保留。 |
| 三.3 状态编码 | 棋类和局、升变、吃过路兵、半回合数以及动作/运动中常用实体类型已用具名枚举，在模型、UI 和美术映射中按同一编码读取。原来序列化的整数值不变。不同游戏独有的字段仍由各自模型解释。 |
| 四.1 声音 | 当前有 **24 个**已撤但有专属音效的游戏，共 48 个 WAV，而非原报告的 20 个。包内音效从 182 个减为 134 个，子模式的 10 个 WAV 正常使用。退出玩法的音色、算法和种子仍可从项目源文件重建。 |
| 四.2 三维模型 | 退出游戏的两个 GLB 不再打包。在架的黑洞和滚球继续提供独立浅/深材质，GLB 内共用重复的几何字节。原/新文件的 420 段访问数据逐项相同，Khronos 校验均为零错误、零警告。原文中把整个深色文件长度当作可节省量的算法高估了收益。 |
| 四.3 图片 | 实包移出 16 个离线美术源的两套图，并让 35 份字节相同的深色图回退到基础资源。合计减少 67 个 SVG。仍被现行静态资源映射引用的图按其实际依赖保留。 |
| 五.1、2 构建及测试 | Debug 默认增量，Release 和明确指定 `--clean` 时全量重编。回归的默认日志改到 `.local-tools/regressions/`，套件分进程隔离、最多默认 4 个并行，缓存以实际源码和编译器内容标识。可用 `LITTLEGAMES_REGRESSION_JOBS=1` 串行复现。 |
| 五.3 脚本目录 | 当前整理前是 134 个顶层文件。已将 25 个成组的历史设备验收脚本移入 `scripts/device/`，顶层降至 109 个。保留现行构建、测试、目录验收及公共 fixture 的调用入口。 |
| 五.4 仓库及本机资产 | 源码目录下的 `docs/` 复核前约 906.71 MiB，Git 当前快照中的文档约 606.22 MiB，`.git/` 约 239.62 MiB。历史截图已有文档引用和验收用途；新增原始截图、原始布局进入忽略规则，现有证据、标签和 Git 历史保留。`.local-tools/` 约 19.48 GiB，包含独立 API 26 工具链 7.50 GiB、模拟器实例 5.14 GiB 和镜像 4.50 GiB，无法把总量视为无用缓存。此前 6 份技能文件均与已安装内容完全一致，已单独提交为 `3a6dfff`。 |

[数据目录](../entry/src/main/ets/model/ClassicCatalog.ets) · [Preferences 边界](../entry/src/main/ets/model/GamePreferences.ets) · [归档说明](../archive/README.md) · [持久化编码](../entry/src/main/ets/model/game/ExpansionStateCodes.ets) · [音效清单](game-sounds.md) · [构建入口](../scripts/build-hap.cjs) · [回归入口](../scripts/run-regressions.cjs)

### 实包与验证

同为 `debug=false` 的未签名 Release HAP。基线是已公开的 v1.1.0，复核包仍使用 1.1.0 / 1001000。比较实际 ZIP 条目及文件总长度，避免把工作树磁盘量误当作下载量。

| 项目 | 公开 v1.1.0 | 复核包 | 减少 |
| --- | ---: | ---: | ---: |
| WAV 音效载荷 | 3,695,650 B | 2,736,568 B | 959,082 B |
| GLB 三维载荷 | 2,627,968 B | 1,207,288 B | 1,420,680 B |
| SVG 载荷 | 1,273,332 B | 1,229,198 B | 44,134 B |
| **HAP 总长度** | **10,650,714 B** | **8,029,359 B** | **2,621,355 B（24.61%）** |

三类资源合计减少 2,423,896 B，其余来自字节码、资源索引和容器开销。本机先后两次 Debug 构建为 25.748 s 和 2.043 s，第二次有 19 项复用；Release 全量构建为 23.658 s。39 套桌面回归 **1,482/1,482 通过**。相同套件在本机暖缓存下，单进程串行调度约 26.1 s，4 进程约 12.3 s，具体耗时随机器和负载变化。[HAP 条目、字节数与 SHA-256 对照](optimization-2026-11-22/hap-size.json)

API 26 模拟器覆盖安装本轮签名包。新增精选区实见 8 款，分类页搜索随筛选即时更新，「我的」两类条目均可打开对应游戏。3×3 滑块实走 22 步通关后点击「返回」，直接回到分类；合并的算式比较与三键节拍模式显示各自规则。贪吃蛇触控后蛇头移动而食物位置不变。黑洞、滚球的浅深两套 3D 均渲染并响应输入。该轮未测真机帧率或物理振动。[两款 3D 实测画面](optimization-2026-11-22/native-scenes.jpg) · [分类图标实测](optimization-2026-11-22/category-symbols.png)

---

## 11 月 20 日原始审核

## 项目现状概览

`LittleGames`（玩趣盒）是一个基于 **HarmonyOS API 26（最低兼容 API 24）**、使用 **ArkTS 严格模式 + ArkUI `@ComponentV2`** 构建的原生单人小游戏合集，当前公开 **64 个独立入口 / 69 个原有玩法 / 6 大分类**，无第三方运行时依赖。

### 现有工程亮点
- **架构清晰、状态响应规范**：首页已从单一壳文件拆分为 [Index.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/Index.ets)、[FeaturedTab.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/FeaturedTab.ets)、[CategoryTab.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/CategoryTab.ets)、[ProfileTab.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/ProfileTab.ets) 与路由表 [GameRoutes.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/router/GameRoutes.ets)；全工程遵循 `@ComponentV2` + `@ObservedV2` / `@Trace` / `@Local` / `@Param` 响应式规范。
- **生命周期与接续闭环完整**：通过 [GameLifecycleBus.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/GameLifecycleBus.ets) 统一解决 `NavDestination` 无 `onPageShow`/`onPageHide` 的问题，统一接管前后台切换自动暂停、精确游玩时长统计、设置半模态遮挡暂停与侧滑返回确认；通过 [AppContinuation.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/AppContinuation.ets) 实现显式版本化状态接续。
- **设备适配与系统融合扎实**：[ScreenUtils.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/ScreenUtils.ets) 与 [SafeAreaInsets.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/SafeAreaInsets.ets) 动态响应窗口宽度与手势导航避让区；集成桌面卡片（[GameFormAbility.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/widgets/GameFormAbility.ets)）、系统分享/碰一碰分享（[GameResultDialog.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/components/GameResultDialog.ets)）以及原生 ArkGraphics 3D（[ToySceneController.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/ToySceneController.ets)）。
- **容错与数据保护意识强**：[GameData.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/model/GameData.ets) 通过 `unreadKeys` 防止读取失败时以缺省值覆盖磁盘记录，并保留已下架/合并玩法的旧战绩不丢失。

在此基础上，从 **功能缺陷与交互细节、运行时性能与渲染、架构与可维护性、包体积与资源瘦身、构建测试与仓库治理** 五个维度整理优化建议如下。

---

## 一、 功能缺陷与交互细节优化（P0 / P1）

### 1. 首页「新增精选」包含 5 款已下架游戏，导致栅格缺列（P0）
- **位置**：[Index.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/Index.ets#L139-L140)、[GameAvailability.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/GameAvailability.ets#L4-L11)
- **现状问题**：`Index.loadAll()` 中 `this.newGames` 硬编码过滤 `['fruitslice', 'backpack', 'billiards', 'guandan', 'xiangqi', 'linerescue', 'melody', 'farm']` 共 8 个 ID，但其中 `backpack`、`billiards`、`guandan`、`linerescue`、`farm` 5 款已在 `RETIRED_GAME_IDS` 中下架。最终首页「新增精选」只渲染出 **3 张卡片**（`fruitslice`、`xiangqi`、`melody`），在平板/折叠屏 4 列栅格下末行缺列，手机 2 列栅格下末行落单。
- **优化建议**：将 `newGames` 过滤列表更新为当前在架的 8 款代表性新增玩法（如补充 `screwout`、`blackhole`、`drift`、`buscolor`、`picturepuzzle` 等），并增加回归断言保证 `newGames.length` 与期望卡片数一致。

### 2. 合并子模式（`beatjump` 等）在状态栏、规则说明与音效中误按父入口 `gameId` 判断（P1）
- **位置**：
  - [ExpansionPage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/collection/ExpansionPage.ets#L262-L290)
  - [CollectionPage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/collection/CollectionPage.ets#L117)
  - [GameHeader.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/components/GameHeader.ets#L113) 与 [GameSettingsPanel.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/components/GameSettingsPanel.ets#L150)
  - [ExpansionViewModel.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/viewmodel/ExpansionViewModel.ets#L92-L101)
- **现状问题**：
  - 当用户进入 `rhythm` 并切换至合并子模式 `beatjump` 时，`Page` 层的 `this.gameId` 仍为 `'rhythm'`，而 `this.vm.modeId` 为 `'beatjump'`。
  - `ExpansionPage.Status()` 第 262 行使用 `this.gameId` 判断 `BRAIN_IDS.includes(this.gameId)`，导致第 263 行中原本为 `beatjump` 编写的 `this.vm.state.cursor` 分支不可达，实际落入第 289 行的 `'rhythm'` 分支，错误显示为 `this.vm.state.moves / goal`（仅命中次数而非真实推进节拍数，参见 [ExpansionBrain.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/model/game/ExpansionBrain.ets#L89-L93)）。
  - `ExpansionPage` 与 `CollectionPage` 向 `GameHeader` 传入的是父级 `gameId`，用户在设置面板点击「玩法说明」时，[GameSettingsPanel.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/components/GameSettingsPanel.ets#L150) 总是调用 `gameRules(this.gameId)`，无法随当前激活的子模式（如 `compare` / `sequence` / `binary` / `targetsum` / `beatjump`）展示对应规则。
- **优化建议**：在 `ExpansionPage.Status()`、`GameHeader` / `GameSettingsPanel` 规则展示以及音效路由中，统一以当前生效的 `modeId` 为准。

### 3. 「我的」页面中的「最近玩过」与「常玩排行」条目不支持点击跳转（P1）
- **位置**：[ProfileTab.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/ProfileTab.ets#L130-L160)、[ProfileTab.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/ProfileTab.ets#L203-L255)
- **现状问题**：「精选」页的「最近玩过」支持点击卡片立即开局，但「我的」页中的「最近玩过」与「常玩排行」均为纯展示容器，未绑定 `onClick` 事件和交互无障碍描述。
- **优化建议**：为 `ProfileTab` 添加 `@Param onGameClick: (game: GameInfo) => void = () => {}`，由 [Index.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/Index.ets#L264-L272) 传入 `navigateToGame`，让用户在统计页也能一键重开常玩/最近游戏。

### 4. 结算弹窗出现时无条件触发成功震动（P1）
- **位置**：[GameResultDialog.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/components/GameResultDialog.ets#L73-L75)
- **现状问题**：`aboutToAppear()` 无条件调用 `Haptics.success()`，导致扫雷踩雷失败、打砖块生命耗尽或对弈负于电脑弹出失败结算框时，依然产生“成功”触感反馈。
- **优化建议**：依据 `this.celebrate` 参数区分触感（或由调用方传入震动语义类型），仅胜利/通关庆祝时调用 `Haptics.success()`，失败或平局改用轻触或提示震动。

### 5. 数独与华容道通关弹窗缺少「返回」次按钮（P1）
- **位置**：[SudokuPage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/puzzle/SudokuPage.ets#L273-L282)、[KlotskiPage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/puzzle/KlotskiPage.ets#L151-L163)
- **现状问题**：其余游戏页的 `GameResultDialog` 均提供「再来一局 / 新游戏」与「返回」双按钮，唯独数独和华容道未配置 `showSecondary: true`，通关后若想回到首页必须先点弹窗外部或物理返回（且 `GameResultDialog` 拦截点击）。
- **优化建议**：为两处 `GameResultDialog` 补齐 `showSecondary: true`、`secondaryText: $r('app.string.action_back')` 与 `onSecondary: () => { this.pathStack.pop(); }`。

### 6. 分类筛选 Chip 图标重复，视觉辨识度不足（P2）
- **位置**：[CategoryTab.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/CategoryTab.ets#L56-L60)
- **现状问题**：`getCategorySymbol(index)` 除 `-1`（全部）与 `0`（街机休闲）外，其余 5 个分类全部返回相同的 `$r('sys.symbol.square_grid_2x2')`。
- **优化建议**：在确认 API 26 `sys.symbol` 可用性的前提下，为逻辑解谜、棋盘对弈、数字训练、记忆专注、反应节奏匹配不同语义图标。

---

## 二、 运行时性能与渲染优化（P1）

### 1. 消除实时游戏与状态同步中的 `JSON.parse(JSON.stringify(...))` 深拷贝与比对（P1）
- **位置**：
  - [ExpansionViewModel.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/viewmodel/ExpansionViewModel.ets#L80)（`sync()`）与 [L210](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/viewmodel/ExpansionViewModel.ets#L210)（`hasProgress()`）
  - [CollectionViewModel.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/viewmodel/CollectionViewModel.ets#L73)（`sync()`）与 [L160](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/viewmodel/CollectionViewModel.ets#L160)（`hasProgress()`）
- **现状问题**：
  - 每次 `sync()` 都对整个状态对象执行 `JSON.parse(JSON.stringify(this.model.state))`（包含 `board`、`pieces`、`piles`、`target`、`tray`、`data` 等全部数组与子对象）。在 20 余款实时物理/动作游戏中，每 32ms 帧刷新及 `onTouch` 触发 `aim()` 时都会频繁触发全量序列化/反序列化，产生大量临时对象与 GC 压力。
  - 每次打开设置面板评估 `hasProgress()` 时，再次全量 `JSON.stringify(this.state)` 并做字符串对比。
- **优化建议**：
  - 为 `ExpansionState` / `CollectionState` 实现轻量的结构化 `clone()` 方法（仅复制当前游戏用到的数组/元素），或将频繁变化的渲染属性拆分为细粒度 `@ObservedV2` / `@Trace` 字段（类似 `Game2048Page` 的 `TileData` 与 `ExpansionRenderPiece`）。
  - 用操作计数或布尔标记 `hasInteracted` 替代 `JSON.stringify` 字符串比对来判定 `hasProgress()`。

### 2. 解除扩展实时游戏 32ms（~30 FPS）的二次渲染节流（P1）
- **位置**：[ExpansionViewModel.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/viewmodel/ExpansionViewModel.ets#L182-L188)、[DisplayFrameLoop.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/DisplayFrameLoop.ets#L31)
- **现状问题**：`DisplayFrameLoop` 已通过 `setExpectedFrameRateRange({ min: 30, max: 60, expected: 60 })` 以 60fps 驱动帧回调，但 `ExpansionViewModel.advance()` 内部保留了 `if (this.renderElapsed >= 32)` 的判断才触发 `this.sync()`，导致所有扩展实时游戏（包含 `ToyBlackholeStage`、`ToyRollingStage` 3D 场景与 `ToyDriftStage`）的画面输出帧率被限制在 **~30 FPS**。
- **优化建议**：在移除上述 `JSON.parse(JSON.stringify(...))` 序列化瓶颈后，取消 `32ms` 二次节流，每帧直接同步轻量状态与 3D `renderer.draw()`，释放 60 FPS 流畅度。

### 3. 分类页搜索索引与分类计数预计算（P1）
- **位置**：[CategoryTab.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/CategoryTab.ets#L32-L54)、[L237](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/CategoryTab.ets#L237)
- **现状问题**：
  - `@Computed get categoryGames()` 在每次搜索词变化时，都会遍历全量游戏调用 `resolveString(g.name, context)` 与 `resolveString(g.description, context)`（每次按键产生上百次资源字符串同步解析）。
  - `CategoryChip` 构建时内联执行 `this.allGames.filter(...)` 统计分类数量。
- **优化建议**：在 `allGames` 变化时一次性构建包含 `{ game, nameLower, descLower }` 的搜索索引以及各分类计数表，输入过滤时直接做纯内存子串匹配。

### 4. 贪吃蛇 20×20 棋盘动态节点渲染优化（P2）
- **位置**：[SnakeGamePage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/classic/SnakeGamePage.ets#L113-L128)
- **现状问题**：棋盘采用 20×20 = 400 个 `Stack` 嵌套条件分支逐格渲染，每次蛇移动一格时 UI 层需为 400 个格子重新执行 `isSnakeCell`、`getSnakeImage`、`getSnakeRotation`、`isFood`、`getCellColor` 等判断。
- **优化建议**：参考 [Game2048Page.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/classic/Game2048Page.ets) 的静态底格 + 独立 `translate` 动态层方案，将 400 格背景收口为静态层并开启 `renderGroup(true)`，仅对蛇身与食物节点做增量定位更新。

---

## 三、 架构设计与代码可维护性（P1 / P2）

### 1. 拆分职责过重的 `GameDataManager`（P1）
- **位置**：[GameData.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/model/GameData.ets)（743 行）
- **现状问题**：单一静态类同时承担了：① 13 款经典游戏静态目录配置、② `Preferences` 同步/异步防抖落盘引擎、③ 战绩/开局次数/时长/历史排序查询、④ 全局偏好设置、⑤ 2048 与数独本地存档快照管理。
- **优化建议**：
  - 抽离经典游戏目录至 `model/ClassicCatalog.ets`（与 `CollectionCatalog.ets`、`ExpansionCatalog.ets` 保持架构对称）；
  - 抽离底层 `Preferences` 读写、防抖定时器及 `unreadKeys` 保护逻辑为独立的 `PreferencesStore` 持久化基础设施。

### 2. 隔离或归档未启用的局域网模块与已下架游戏 UI 代码（P2）
- **现状问题**：
  - 局域网联机已撤下（[module.json5](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/module.json5) 未申请网络权限），但仍保留完整的传输与房间 UI 实现：[LanTransport.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/LanTransport.ets)（270 行）、[LanGameSession.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/LanGameSession.ets)（217 行）、[LanRoomPanel.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/components/LanRoomPanel.ets)（129 行）以及 `LanProtocol.ets`、`LanFraming.ets`。
  - 已下架的跳一跳完整页面体系（[JumpJumpPage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/classic/JumpJumpPage.ets) 260 行、[ToyJumpStage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/components/ToyJumpStage.ets) 95 行及对应 ViewModel/Model）和 30 款已下架合集/扩展游戏分支，仍耦合在 [ExpansionPage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/collection/ExpansionPage.ets)、[ExpansionWorldBoard.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/collection/ExpansionWorldBoard.ets)、[ExpansionCardBoard.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/collection/ExpansionCardBoard.ets)、[ExpansionBrainBoard.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/collection/ExpansionBrainBoard.ets) 等共享组件内。
- **优化建议**：将暂不恢复上架的已下架 UI 与 LAN 代码移至独立的归档目录或条件模块，减轻主页面组件的分支复杂度与阅读负担（仅保留用于历史战绩兼容的轻量元数据即可）。

### 3. 消除 `ExpansionState` / `CollectionState` 魔数下标与类型编码（P2）
- **位置**：[ExpansionState.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/model/game/ExpansionState.ets)、[ExpansionPage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/collection/ExpansionPage.ets)、[ExpansionWorldBoard.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/collection/ExpansionWorldBoard.ets)
- **现状问题**：状态中广泛使用通用字段与魔数编码，如 `data[0..9]`、`piece.kind`（0~58）、`state.phase`、`state.cursor` 在不同游戏间承担完全不同的语义（例如 `data[8] === 1` 代表象棋和棋、`data[9]` 代表兵升变、`piece.kind === 32` 代表滚球），View 与 Model 强依赖隐式约定，修改极易出错。
- **优化建议**：为 `piece.kind` 及高频 `data` 索引定义具名枚举或常量表（如 `PieceKind.ROLLING_BALL`、`ChessDataIndex.DRAW_FLAG`），提高可读性与重构安全性。

### 4. 清理局部代码异味（P2）
- [KlotskiPage.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/puzzle/KlotskiPage.ets#L44-L46)：`aboutToAppear()` 内残留无意义的空 `if (ctx) {}` 代码块，应予以移除。
- [ProfileTab.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/ProfileTab.ets#L1)、[L237](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/pages/home/ProfileTab.ets#L237)：组件头部注释声明为“纯展示组件”，但第 1 行直接引入了 `GameDataManager` 并在 `ForEach` 内调用 `GameDataManager.getPlayCount(game.id)`；建议由父组件在组装数据时一并传入开局次数，恢复纯展示边界。

---

## 四、 包体积与资源瘦身优化（P2）

当前 `entry/src/main/resources/` 统计含大量冗余或已下架玩法的静态资产，存在较大的直接瘦身空间：

| 资源目录 | 当前规模（实测） | 存在的问题 | 优化方案与可节省空间 |
| --- | --- | --- | --- |
| `rawfile/sounds/` | **182 个文件，3,609 KB** | ① 包含 **20 个已下架游戏** 对应的 **40 个 `.wav`**（`781.2 KB`）；<br>② 包含 **5 个合并子模式** 的 **10 个 `.wav`**（`194.2 KB`），但 [GameSoundPlayer.ets](https://github.com/wujiyan19/PocketJoy/blob/b868301/entry/src/main/ets/common/GameSoundPlayer.ets#L59-L60) 按入口 `gameId` 加载，子模式音效从未被加载。 | ① 打包时按 `isGameAvailable` 剔除已下架游戏音效，可立减 **781.2 KB**；<br>② 合并子模式按 `modeId` 加载各自音效（或清理未用音频）。 |
| `rawfile/toy/` | **6 个 `.glb`，2,566.4 KB** | ① `jump.glb`（398.1 KB）+ `jump_dark.glb`（398.1 KB）仅服务于已下架的 `jumpjump`；<br>② `blackhole_dark.glb`（513.5 KB）与 `rolling_dark.glb`（371.7 KB）复制了完整几何体以适配深色主题。 | ① 移出下架的 `jump*.glb` 可减 **796.2 KB**；<br>② 合并浅/深色模型或运行时通过材质/背景色切换，可再减 **885.2 KB**；合计减少 **1,681.4 KB（约 1.64 MB）**。 |
| `base/media/` & `dark/media/` | **945 个文件，1,394.4 KB** | 保留了大量已下架玩法的专属棋盘/道具图标（如 `exp_board_farm`、`exp_board_decorate`、`exp_pack_slot` 等）。 | 在资源生成脚本中按在架目录裁剪未引用图片，进一步缩减 HAP 包体积。 |

---

## 五、 构建、测试与仓库工程化治理（P2）

### 1. 优化 `scripts/build-hap.cjs` 日常编译速度
- **位置**：[build-hap.cjs](https://github.com/wujiyan19/PocketJoy/blob/b868301/scripts/build-hap.cjs#L29-L31)
- **现状问题**：当前命令行固定传入 `'--no-daemon', '--no-incremental'`，使所有 Debug 编译也强制走无缓存全量构建，单次编译耗时偏高。
- **优化建议**：仅在 `release` 模式或显式传入 `--clean` 参数时禁用增量编译，默认 `debug` 构建开启增量编译以提升日常迭代效率。

### 2. 修复 `scripts/run-regressions.cjs` 默认输出路径与加速执行
- **位置**：[run-regressions.cjs](https://github.com/wujiyan19/PocketJoy/blob/b868301/scripts/run-regressions.cjs#L8-L23)
- **现状问题**：
  - 当未设置 `LITTLEGAMES_REGRESSION_OUTPUT` 环境变量时，默认输出目录指向 `entry/build/iteration-20261013/regressions`，与 [AGENTS.md](https://github.com/wujiyan19/PocketJoy/blob/b868301/AGENTS.md) 中“长期验证证据不要放在 `entry/build` 下，Hvigor 清理任务可能删除该目录”的规范相违背。
  - 34 套回归脚本采用 `cp.spawnSync` 串行逐个启动子进程，且每个进程重复用 TypeScript 转译同一批 `.ets` 源码。
- **优化建议**：将默认输出路径改为 `.local-tools/regressions`；抽取前置共享转译缓存并采用受控并发（Worker Pool）执行各测试套，缩短全量回归时间。

### 3. 整理 `scripts/` 目录下平铺的 128 个脚本
- **现状问题**：`scripts/` 下共平铺 128 个文件（含 59 个阶段性 `device-*` 脚本、35 个 `test-*` 脚本、9 个 `generate-*` 脚本、6 个 `preview-*` 脚本等），根目录入口与一次性历史验收脚本混杂。
- **优化建议**：按职能建立子目录分层（如 `scripts/tests/`、`scripts/generators/`、`scripts/device/`、`scripts/archive/`），根目录仅保留核心入口（如 `build-hap.cjs`、`run-regressions.cjs`）。

### 4. 仓库体积、磁盘占用与工作区治理
- **`docs/` 体积过大（磁盘占用 906.2 MB，Git 已跟踪 561.7 MB，`.git` 达 322.7 MB）**：`docs/device-acceptance/`（754.9 MB）与 `docs/screenshots/`（127.9 MB）中留存大量历史原始截图。建议将原始过程截图纳入 `.gitignore` 并清理 Git 跟踪历史（或迁移至 Git LFS），仅保留文档报告引用的关键拼图与汇总数据。
- **本地工具链磁盘占用（`.local-tools/` 占用 19,855 MB / 约 19.4 GB）**：本机已安装图形版 DevEco Studio `26.0.0.851` 且 [build-hap.cjs](https://github.com/wujiyan19/PocketJoy/blob/b868301/scripts/build-hap.cjs#L6-L10) 默认已指向 IDE 内置工具链；如无离线命令行构建需求，清理冗余本地工具链与缓存可释放接近 **20 GB** 磁盘空间。
- **清理工作区未提交修改**：`git status` 显示 `docs/skills/harmonyos-app-development/` 下存在 6 个已修改文件，建议核对后及时提交或还原，保持工作区洁净。

---

## 建议实施路线图

| 优先级 | 建议事项 | 核心收益 |
| --- | --- | --- |
| **P0** | 修复 `Index.newGames` 过滤列表中的 5 个下架 ID | 消除首页「新增精选」缺列/落单视觉缺陷 |
| **P1** | 修复合并子模式（`beatjump` 等）进度/规则/音效 ID 绑定 | 恢复子模式正确的局内进度显示与玩法说明 |
| **P1** | 消除 `ExpansionViewModel` / `CollectionViewModel` 每帧 JSON 深拷贝并解除 32ms 节流 | 降低 GC 卡顿，使实时 3D 与动作游戏达到 60 FPS |
| **P1** | `ProfileTab` 列表支持点击跳转、`GameResultDialog` 区分胜负震动、数独/华容道弹窗补全返回按钮、分类搜索预建索引 | 补齐关键交互一致性并消除搜索输入卡顿 |
| **P2** | 裁剪 `rawfile/sounds` 与 `rawfile/toy` 冗余资源；拆分 `GameDataManager` 与隔离下架/LAN 代码 | 仅音频与 3D 模型即可减重 **2,462.6 KB（约 2.4 MB）** 以上，大幅降低后续维护成本 |
| **P2** | 修复 `run-regressions.cjs` 默认输出路径、优化 `build-hap.cjs` 增量构建、整理 `scripts/` 与 `docs/` 体积 | 提升日常研发效率，显著降低仓库与本地存储负担 |
