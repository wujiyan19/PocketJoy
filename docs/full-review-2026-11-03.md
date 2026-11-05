# 玩趣盒 LittleGames — 全量审查报告

> 审查日期：2026-11-03 · 版本：v1.0.0（versionCode 1000000）· API 26 / 最低 API 24
> 范围：构建配置、ArkTS 规范、模型层、视图层、持久化、网络、资源/主题/i18n、无障碍、测试、仓库治理

---

## 1. 摘要

**这是一个工程质量明显高于同类个人项目的代码库**：无第三方运行时依赖、无 `console.log`、无废弃全局 API、无 ArkTS 禁用语法、资源引用零缺失、深浅色与三语完全对齐、模型层有 1400 条自测。**但它有 7 个会真实伤害用户的问题，16 个明显的性能/交互缺陷，以及一批"做完一半就留在仓库里"的债务。**

| 级别 | 数量 | 性质 |
|---|---:|---|
| **P0** | 7 | 数据静默丢失、核心操作失效、构建期白屏、主线程 ANR |
| **P1** | 16 | 帧率、布局、死局、可访问性、国际化、死控件 |
| **P2** | 20+ | 死代码、测试裁剪、文档失真、仓库膨胀、配置泄漏 |

三条结论值得单独记住：

1. 俄罗斯方块**贴底后完全无法旋转** —— 最常用的操作之一失效了。
2. 自定义随机数生成器**数值上已损坏**（乘法溢出 2^53），约 1.5% 的种子会让布局周期化。
3. 回归测试 **1400/1400 全绿是裁剪出来的** —— 两个失败的 LAN 套件被排除，且其中两条测试结构上不可能失败。

---

## 2. 审查方法与可复现证据

| 手段 | 结果 |
|---|---|
| 通读源码 | 168 个 `.ets`；完整读 50+ 个核心文件，其余按层抽读 + 全量机械校验 |
| 真实编译 | `node scripts/build-hap.cjs` → **BUILD SUCCESSFUL**（16.5s），附 **21 条 ArkTS 告警** |
| 项目自带回归 | `node scripts/run-regressions.cjs` → **32 套 / 1400 检查全通过**（排除 2 个 LAN 套件后） |
| 真实执行目录 | 用项目自己的 TS fixture 反编译并执行 `getAllGames()` → **64 入口、6 分类 16/24/5/4/4/11**，与 README 逐项吻合 |
| SDK 契约核对 | 查 `@ohos.net.socket.d.ts`、`@ohos.net.connection.d.ts`、`@ohos.app.form.formProvider.d.ts` 的 `@permission` / `@throws` / `@deprecated` |
| 资源一致性 | 脚本比对 968×3 语言包、149 浅/深色、全部 `$r()` 引用 |
| 数值复现 | 在 Node 中复现 `RandomSource` 的 LCG 循环与浮点溢出 |

日志产物：`.audit/build.log`、`.audit/regressions.log`（建议审查结束后删除或加入 `.gitignore`）。

---

## 3. P0：必须修

### P0-1 恢复持久化时 11 处 `getSync` 未捕获 → 一个坏键让全量战绩本次运行永不落盘

- **位置**：`model/GameData.ets:233, 237, 241, 247, 251, 255, 260, 271, 279, 689`
- **证据**：这些 `store.getSync(...)` 全部在 `try` 之外，而 `restore()` 被 `init()` 的单个 try 包裹。任一处抛错 → `catch` → `store = null` → 之后所有最高分/时长只在内存增长，退出即丢，用户只看到一条 hilog。
- **反讽**：文件里专门写了注释 "A damaged new record cannot erase the original score maps"，真正会毁数据的恰是这些未保护的读取。
- **旁证**：编译器已点名这 11 处 —— `Function may throw exceptions. Special handling is required.`
- **修法**：每个 key 单独 `try/catch` 并回退默认值，让坏键只损坏自己。

### P0-2 俄罗斯方块贴底后无法旋转

- **位置**：`model/game/TetrisModel.ets:104-114`
- **证据**：`const offsets = [0, -1, 1, -2, 2]` 只改 `piece.x`，`piece.y` 永远是原值；而 `canPlace` 对 `ny >= this.rows` 直接 `return false`。注释写"带回踢"，实际没有纵向踢墙。
- **影响**：只要方块已落地、且下一朝向比当前高一行（T/L/J/S/Z 都存在 2↔3 行循环），5 个候选全部失败，旋转被静默拒绝。SRS 在此会把方块上推一格。这是"贴底补位"这一最常用操作的直接失效。
- **修法**：换真正的 SRS 踢墙表（含 `(0,-1)`/`(0,-2)` 与 I 型专用表）。

### P0-3 `RandomSource` 数值上已损坏（乘法溢出 2^53）

- **位置**：`model/game/RandomSource.ets:26`
- **证据**：`this.seed = (this.seed * 1103515245 + 12345) % 2147483648;`，`seed` 可达 2³¹，乘后约 **2.37e18** ≫ `MAX_SAFE_INTEGER`（9.0e15），低位被 double 舍入吃掉 —— 而低位正是 LCG 的全部价值。
- **实测复现**（完全相同的表达式）：

  | 种子 | 结果 |
  |---|---|
  | 58381 | 第 60 抽后进入 **10 值循环** |
  | 298 | 第 11 抽后进入 **61 值循环** |
  | 1 / 3 / 55464 / 42 | 2000 抽内未退化 |
  | `2147483647 * 1103515245` | `2369780942852698600` > 2⁵³ ✅ 已溢出 |

- **影响面**：`SudokuModel.fallbackPuzzle` 用固定种子 1/3（实测安全）；真正中招的是**按日期派生种子**的玩具场景 —— `ToyLevelRules` 用 `1…999999` 派生 Blackhole/Drift 种子，约 1.5% 的种子退化，对应某些日期的布局周期性重复。
- **定性**：算法层面确定错误（P0 级代码缺陷），用户可见频率约每几十天一次（P2 级现象）。
- **修法**：`(Math.imul(seed, 1103515245) + 12345) >>> 0`，或换 mulberry32 / xorshift32。

### P0-4 `build()` 内无保护索引 `state.pieces[0]` → 白屏

- **位置**：`pages/collection/ExpansionWorldBoard.ets:20`、`:136`、`ExpansionPage.ets:274`、`ExpansionCardBoard.ets:21,58-59`、`ExpansionExtras.ets:14,54`、`ExpansionLifeBoard.ets:30,103`
- **证据**：`Math.max(0, this.vm.state.pieces[0].x - 160)` 在 ArkUI 渲染期求值。`pieces` 为空 → `TypeError` → 整页白屏，重进仍复现。
- **矛盾点**：同文件其他位置用了 `?.`，说明是遗漏而非风格选择。
- **修法**：VM 暴露 `player(): ExpansionPiece | undefined`，渲染处判空。

### P0-5 AI 同步跑在 UI 线程，最多 500 回合/次点击

- **位置**：`model/game/ExpansionPoker.ets:264-268`（`for (let guard = 0; guard < 500 && needsComputerTurn; guard++)`），由 `viewmodel/ExpansionViewModel.ets:219-224` 的 `setTimeout` 直接调用；`ExpansionChess.hardMove()` 同样同步搜索。
- **证据**：全仓库只有数独用了 `taskpool`（`viewmodel/SudokuViewModel.ets:89`），其余 AI 全在主线程。
- **影响**：低端机上一次"出牌"可阻塞数百毫秒 → 掉帧、输入假死、有 ANR 风险。
- **修法**：套用已有的 `SudokuTask` + `taskpool` 模式，并给循环加时间预算。

### P0-6 切后台时记忆翻牌仍在推进对局

- **位置**：`viewmodel/MemoryCardViewModel.ets:170-172`
- **证据**：`onAppHidden()` 只 `gameSound.stop()`，500/800ms 的 `flipTimer`（`:116`、`:258`）继续跑 `resolvePending()`，在后台改 `cards`/`matchedCount`/`status`。玩家回来发现棋盘已变。
- **陷阱**：**不能只 `clearTimer()`** —— 那样 `locked` 永远为 `true` 且 `flippedIdxs.length === 2`，`:96` 会永久拒绝点击 = 死锁。正确做法是先结算再停表。

### P0-7 推荐卡：未判空 + 把 `Resource` 塞进 FormBindingData

- **位置**：`widgets/GameCardData.ets:24-29`
- **证据**：`const game: GameInfo = daily.recommendations[0];` 未判空，空目录时 `game.id` 立刻 `TypeError`；`data.gameIcon = game.icon;` 把一个 `Resource` 对象塞进会被**序列化成字符串**的 `FormBindingData`（SDK 明确说明），而图片必须走 `formImages`/fd。`DailyGameCard.ets:16` 的默认值永不生效，因为 key 已存在。
- **影响**：`onAddForm` 同步抛错 → 添加卡片失败；"今日推荐"图标大概率空白/破损（需真机确认）。
- **修法**：只传 `gameId`，在卡片侧 `$r` 解析；或用 `formImages`。

---

## 4. P1：性能与交互

| # | 问题 | 位置 | 影响 |
|---|---|---|---|
| P1-1 | **30Hz 全量深拷贝**：每次 `sync()` 做 `JSON.parse(JSON.stringify(state))` 并整体替换 `@Trace` 根 | `viewmodel/ExpansionViewModel.ets:80` + `:178-184` | 60 款实时玩法每秒 30 次"字符串化+解析+整棵子树失效"，`@Trace` 细粒度更新被架空 |
| P1-2 | **每格同步查资源**：`GameArtTile` 在 `build()` 里 `getStringSync` 拼无障碍文案 | `components/GameArtTile.ets:39`、`common/I18nUtils.ets:22` | 6×10 棋盘 × 30fps ≈ **1800 次同步资源查询/秒** |
| P1-3 | 布局属性落在 `.animation()` 作用域内（违反 AGENTS.md §3） | `pages/classic/Game2048Page.ets:335-342`、`BrickBreakerPage.ets:138-151` | 旋转/分屏/折叠时对 16~40 个方块做几何动画 → 每帧重排版 |
| P1-4 | `ForEach` 用**值**当 key，重复值丢节点 | `ExpansionBrainBoard.ets:146`、`ExpansionExtras.ets:99-102`、`ExpansionWorldBoard.ets:176-189` | 棋盘出现相同拼块时 ArkUI 报重复 key，渲染少于模型 |
| P1-5 | 全仓库仅剩 1 处硬编码中文 UI 文案 | `pages/classic/SnakeGamePage.ets:134` | 英文用户看到中文，且这是该游戏唯一启动提示 |
| P1-6 | 死控件：`ControlPad` 中央按钮是真实可聚焦 Button，回调为空函数 | `SnakeGamePage.ets:152`、`KlotskiPage.ets:150`、`components/ControlPad.ets:94` | 点击有震动却毫无作用；读屏念出"能按但没用"的按钮 |
| P1-7 | 安全区 `@Local` 快照永不更新 | 13 个页面 `@Local safeBottom = SafeAreaInsets.bottom`，而后者是普通 static | 手势/三键导航切换、旋转后继续用旧内边距 |
| P1-8 | 每次切 Tab/回首页都**同步刷盘全量数据** | `pages/Index.ets:155` → `GameLifecycleBus.ets:166-169` → `flushNow()` | 10 组 map + 64 条记录的 `putSync`+`flushSync` 跑在 UI 线程 |
| P1-9 | 120 个泡泡节点常驻 + 每帧重建漂移赛道多边形 | `ExpansionPage.ets:443-447`、`ToyDriftStage.ets:13-36` | 空盘也解码 120 张图；漂移时每帧分配 ~1700 个数值 |
| P1-10 | 可访问性缺口：俄罗斯方块 3 个纯图标按钮无标签、蛇/方块 400/200 个格子无任何语义 | `TetrisGamePage.ets:154-171`、`:131-145`、`SnakeGamePage.ets:113-128` | 读屏用户无法玩这两款游戏 |
| P1-11 | **两张卡片 `designWidth` 不一致**（320 vs 640），但都是 2 列宽 | `resources/base/profile/game_forms.json:9` vs `:23` | `autoDesignWidth` 按比例缩放 → 继续卡片文字/图标只有另一张的一半 |
| P1-12 | **英文启动器名称仍是中文**：`AppScope/resources/en_US/element/string.json` 的 `app_name = 玩趣盒`，与 zh_CN 逐字节相同 | 作用于 `AppScope/app.json5:8` 与 `module.json5:24` | 英文设备桌面图标名、卡片名都是中文 |
| P1-13 | 打地鼠**难度不再影响回合时长** | `model/game/WhackMoleModel.ets:21-23` 忽略参数恒返回 30；`WhackMoleViewModel.ets:54` 仍保留 40/30/20 | HARD 反而比旧版 HARD 更轻松，难度只剩出怪频率 |
| P1-14 | 打砖块**行分非单调**，与自带注释矛盾 | `model/game/BrickBreakerModel.ets:102` `[50,40,30,20,10,50,40,30]` | 第 3 关起最底行 50 分 = 顶行、比第 4 行高 5 倍 |
| P1-15 | 巴士配色**可能死局**：托盘满且无同色车 → 永久卡住，`outcome` 永不置位 | `model/game/ExpansionSorting.ets:38-46` | 既不能赢也不能输，只能退出 |
| P1-16 | 连连看**无死局检测**：只在发牌时保证有一对，消除后不再检查 | `model/game/ExpansionMatching.ets:103-113` | 无解时永久冻结（`action()` 有重排但无人触发） |

小项：`GuessNumberPage` 的 `List` 嵌在 `Scroll` 里且带 `layoutWeight(1)`（短窗口可能塌成 0 高）；`GameResultDialog` 分享失败后的 toast 无销毁保护（`Index.ets:100-104` 已有正确写法）。

---

## 5. P2：架构、规范与工程债务

### 5.1 网络层：一整套"已撤下但没删"的局域网功能

`LanTransport`(270) + `LanProtocol`(63) + `LanFraming`(44) + `LanGameSession`(195) + `LanRoomPanel`(123) ≈ **700 行死代码**：

- **无人引用**：全仓库没有任何页面 import `LanRoomPanel`；
- **无实现**：`LanGameAdapter` 零实现者，且 7 款 LAN 游戏全部在 `GameAvailability.ets:4-11` 的撤下名单；
- **权限缺失**：`module.json5` 只声明 `VIBRATE`，而 `LanTransport.ets:179` 的 `connection.getAllNets()` 在 SDK 里标了 `@permission ohos.permission.GET_NETWORK_INFO @throws 201`，`bind/listen/connect/send` 需要 `ohos.permission.INTERNET`。一旦接回 UI，房主第一步就吃 201；
- **错误码被吞**：`LanGameSession.ets:187` 把 `permission/listen/connect/send/timeout` 全折叠成 `network`，用户被提示"检查是否在同一 Wi-Fi"；
- **文档失真**：`docs/lan-multiplayer.md` 仍宣称可用、贴出 `node scripts/test-lan-multiplayer.cjs`、声称 22/22；实测 **1/22 通过**；
- **96 条 `lan_*` 字符串**（32×3 语言）仍随包发布。

**决断**：要么删干净（5 个源文件 + 字符串 + 文档 + 失败测试），要么作为一次完整特性交付（权限、adapter、接线、错误透传、双机实测）。

### 5.2 测试与验证：绿色是裁剪出来的

- `scripts/run-regressions.cjs:6-7` 用 **2026-10-12 的历史快照**当套件清单，且硬编码追加 11 个套件名；该快照自称 "89-game scope"，而现在是 64 入口；`report.scope` 也硬编码 `'64-entry …'`；
- 该快照的 `excludedSuites` 明确排除了两个 LAN 套件 —— 所以 1400/1400 全绿是排除失败套件后的结果；
- `entry/src/test/` 下 14 个 Hypium `.test.ets`（125 个 `it`）**没有任何 runner 入口**（无 `src/ohosTest`、无 npm script），CI 里等于不存在；
- **两条测试结构上不可能失败**：`ViewModelClassic.test.ets:61`（测"反向转向被忽略"，断言 `x > length-1`，即使反向被接受也成立）、`ViewModelPuzzle.test.ets:69-75`（用例名写 `shuffles_to_solvable_board`，却从未调用 `isSolvable`）；
- **两处测试把 bug 固化了**：`WhackMoleModel.test.ets:45-49`、`ViewModelClassic.test.ets:167-172` 断言三种难度都等于 30，正好锁死 P1-13；
- **覆盖空洞**：打砖块（唯一零测试的上架经典款）、整个 Expansion 族（承载 60 款玩法）、`KlotskiRules.deal`（真正被调用的生成器）、`RandomSource` 除"同种子两次相同"以外的性质、数独 NORMAL/HARD 与 fallback、`GameData` 持久化/设置/清空路径。

### 5.3 工程与配置

| 项 | 证据 | 建议 |
|---|---|---|
| **签名口令进了被跟踪文件** | `build-profile.json5:8-14` 含 `certpath/keyPassword/storePassword`，且处于未提交修改；`.gitignore` 只挡 `*.p12/*.p7b`，README 却写"口令保留本地" | signingConfigs 留空，用本机忽略文件注入 |
| 仓库 86% 是文档 | 跟踪 6764 文件，`docs/` **5301 个 / 559 MB**，`.git` 320 MB | 证据外置到 LFS / Release |
| 126 个一次性脚本 | `scripts/` 命名 `device-*`/`three-*`/`final-*` 混叠 | 归档，只留 6~8 个入口 |
| `package.json` 被 ignore 却声明依赖 | `.gitignore` + `package.json`（`hypium-driver`） | 干净 clone 无法复现测试环境 |
| **`AGENTS.md` 被 ignore** | `.gitignore` | 强制规范不随仓库分发，贡献者与 CI 看不到 |
| 扩充页是上帝组件 | `ExpansionPage.ets` 472 行承载 60 款玩法，`gameId` 字符串分发 + emoji 当美术 | 按家族拆子组件 |
| 15 个游戏页模板复制 | 每页手写 attach/detach/restore/requestExit/@Monitor + 双弹窗（约 450~600 行重复），已出现结算弹窗条件分歧 | 抽 `GamePageShell` + `GamePageController` |
| 路由表重复 | `GameRouteRegistry.ets:7-21` 的 `PATHS` 与 `:42-43` 的硬编码 id 数组双份维护；`getAllGameRoutes()` 无调用者 | 由 `PATHS` 派生 |
| 首页硬编码"新游"名单 | `Index.ets:139-140` 8 个 id 中 5 个已撤下/合并 → 实际只渲染 3 张卡 | 移入目录元数据 |
| 帧循环可"复活" | `DisplayFrameLoop.ets:25-37` 在 `dispose()` 后仍能新建循环；`ExpansionViewModel.ets:201` 未置 `frame = null`（其他 VM 都置了） | 加 `disposed` 守卫 |
| 生命周期总线单槽覆盖 | `GameLifecycleBus.ets:54-63` 新观察者静默覆盖旧观察者 → 旧 VM 的 interval/帧源永不释放 | 覆盖时记警告并 `onAppHidden()` |
| 销毁期改状态 + `animateTo` | `ExpansionFeedback.ets:17-22`、`ExpansionChessBoard.ets:48-58` | 拆出无动画的 `cancelImmediate()` |
| 21 条编译告警长期存在 | 17 条"可能抛异常" + 4 条 `audio`/`media` syscap 告警 | 修 P0-1 可清大半；syscap 需能力检测降级 |
| 死资源/死资产 | 968 字符串中 35 个无引用；5 条 `a11y_*` 全语言就绪但没用；`jumpjump` 已撤下仍注册路由，页面/VM/3 图/2 音随包；16 个基础媒体无暗色版（`toy_car_0..5`、`toy_drift_car`、`toy_plate_0..4`、`toy_screw`、`toy_slot`） | 例行清理 |
| 启动窗口配置双份来源 | `module.json5:36-38` 同时有 `startWindow` profile 与遗留 `startWindowIcon/Background` | 删遗留项 |

---

## 6. 分层结论速查

| 层 | 结论 |
|---|---|
| **构建** | ✅ 可编译、可签名出包；⚠️ 21 条告警、签名配置入库 |
| **配置/权限** | ⚠️ 只声明 `VIBRATE`（够用），但 LAN 代码需要 `INTERNET` + `GET_NETWORK_INFO` |
| **模型层** | ⚠️ 2048 / 扫雷 / 数独 / 滑动拼图 / 华容道 / Match3 / 贪吃蛇 / 黑洞口 均正确；❌ 俄罗斯方块旋转、随机数生成器 |
| **视图层** | ⚠️ 30Hz 深拷贝、每格查资源、布局入动画、重复 key、无保护索引 |
| **持久化** | ❌ P0-1；其余（防抖、上下限校验、损坏回退）设计良好 |
| **网络** | ❌ 整层死代码 + 文档失真 |
| **资源/i18n/主题** | ✅ 引用零缺失、深色 149=149、三语 968×3 对齐；⚠️ 英文 `app_name` 是中文、16 个暗色媒体缺失 |
| **无障碍** | ⚠️ 俄罗斯方块按钮无标签、蛇/方块棋盘无摘要、纸牌空格读作"○" |
| **测试** | ⚠️ 自测量足，但绿是裁剪来的、两条测试不可能失败、Hypium 未接线 |
| **仓库** | ⚠️ 559MB 文档、126 脚本、口令入库、`AGENTS.md` 被忽略 |

---

## 7. 已核实"没问题"的部分（避免误伤）

- **资源引用零缺失**：92 个 color、107 个 float、933 个 string、467 个 media 引用全部可解析（`app_icon`/`brand_start_icon` 在 AppScope，属正常）。
- **深色主题完整**：base 149 色 = dark 149 色，无缺失无重复。
- **三语键集合对齐**：base / en_US / zh_CN 各 968 键，集合相同。
- **目录数字诚实**：实跑 `getAllGames()` = 64，分类 16/24/5/4/4/11，与 README 表格逐项吻合；路由 64 条且唯一。
- **模型算法正确**：2048 每次移动只合并一次、扫雷首点 3×3 安全且抽样无偏、数独逐步挖洞并校验唯一解、滑动拼图奇偶性正确、华容道 BFS 确认可解（EASY 570 / NORMAL 55,795 / HARD 10,769,776 状态）、Match3 发牌无初始三连且死局重发、贪吃蛇尾格让位判定正确、黑洞关卡不越界。
- **无 ArkTS 违规**：`any`/`unknown`、解构、`for..in`、`var`、`as const`、索引签名、非空断言、`Symbol()`、`require`、`globalThis` 全部 0 命中。
- **无废弃 API、无 `console.log`**：`animateTo`/`getRouter`/`px2vp`/`promptAction` 全部走 `this.getUIContext()`；日志统一 40 处 `hilog`。
- **无硬编码十六进制颜色**：仅 `Color.Transparent` 与 `CollectionPage.ets:285` 一处 `Color.White`（黑白棋）。
- **生命周期纪律**：15/15 游戏页 `attach`↔`detach`+`dispose` 成对；除 P0-6 外所有定时器都有清理路径；数独异步任务有代次校验。
- **接续实现严谨**：`AppContinuation.ets` 的字段白名单、路径形状校验、20KB 上限、版本号都到位。
- **隐私**：无网络权限、无遥测、无 PII 上报，成绩只在本机。

---

## 8. 修复路线图

### 第一批（阻断级，约 1 天）

1. P0-1 持久化 `getSync` 加保护
2. P0-2 俄罗斯方块 SRS 踢墙表
3. P0-3 `RandomSource` 改 `Math.imul`
4. P0-4 `pieces[0]` 逐处判空
5. P0-6 记忆翻牌：先结算再停表（注意别写成死锁）
6. P0-7 推荐卡判空 + 卡片侧解析图标

### 第二批（体验级，约 2 天）

7. P0-5 AI 下 `taskpool`（复用数独模式）
8. P1-1 + P1-2 + P1-3 同文件三连改（深拷贝、每格查资源、布局入动画）
9. P1-11 两张卡片 `designWidth` 统一
10. P1-12 英文 `app_name`
11. P1-13 / P1-14 数值修正（并同步改掉锁定 bug 的两条测试）
12. P1-15 / P1-16 两个死局兜底
13. P1-4 ~ P1-7、P1-10 批量修

### 第三批（治理，可并行）

14. 网络层做决断：删干净，或一次性做完
15. 测试清单去快照化、给 Hypium 接线、补两条"不可能失败"的断言
16. 签名配置移出仓库、`docs` 外置、脚本归档、`AGENTS.md` 解除忽略

### 验收方式

每批改完执行：

```powershell
node scripts/build-hap.cjs
node scripts/run-regressions.cjs
```

并新增/修正断言：`SlidePuzzleRules.isSolvable`、贪吃蛇反向（`x === hx + 1`）、`WhackMole getGameTime` 三档不同值、`BrickBreaker ROW_SCORES` 单调。

---

## 9. 覆盖边界（未做的事）

- **未在真机/模拟器运行**：所有运行时行为结论来自 SDK 契约、编译告警与代码推演。
- **未做性能实测**：P1-1/2/3/8/9 为静态推断，量级可信但绝对值需 Trace/Profiler。
- **模型层是重点抽检**：未逐行读 `ExpansionCards/Poker/Brain`、`CollectionModel`、`DailyInspirationCatalog`。
- **P1-15 / P1-16 是"从生成器与守卫逻辑推得的无解状态"**，未做穷举状态搜索，请按"缺少兜底"而非"必然复现"理解。
- **卡片图标破损**有 SDK 文档支撑，但仍建议真机放一张卡确认。
- 未执行 Hypium 套件。
