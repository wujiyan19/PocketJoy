# 构建验收与来源

## 构建

先读取目标项目配置、构建脚本与 `AGENTS.md`，分别确认 compile、target、compatible SDK。2026-11-12 核对 LittleGames 为 compile/target=`26.0.0`、compatible=`6.1.1(24)`；本机默认 DevEco Studio `26.0.0.851`，根目录没有 hvigorw，使用项目入口：

```powershell
node scripts/build-hap.cjs
node scripts/build-hap.cjs release
```

按所需模式选择一条，在仓库根目录执行。入口默认使用 `C:/Program Files/Huawei/DevEco Studio/` 内的 Node/Hvigor/SDK/JBR；支持 `LITTLEGAMES_TOOLCHAIN_ROOT` 指向独立 command-line-tools、`JAVA_HOME` 指向兼容 JDK，环境仅传给构建子进程。本机保留的独立工具链是 `.local-tools/harmonyos-26.0.0.851/command-line-tools/`；JBR 25.0.2 的历史成功不替代当前构建验证。

产物在 `entry/build/default/outputs/default/`。长期日志、备份、候选包回执和工具不能放在 `entry/build` 下，Hvigor 迁移/清理可能删除该目录。其他工程沿用实际 wrapper/CI/脚本，不强制 LittleGames 路径、版本或环境变量；Git Bash 传给 Node 的 Windows 绝对路径使用 `C:/...` 等实际路径格式。

签名使用已有合法配置；LittleGames 共享 `build-profile.json5` 不含个人签名，本机配置由 `hvigorfile.ts` 从忽略文件 `signing.local.json` 读取并注入内存。不要输出该文件内容，也不要把证书、私钥、口令或个人签名路径复制到技能和共享配置。Release 是编译模式，不代表发行签名、可安装或可上架；按实际产物区分 unsigned、本地签名与发行条件。

## 按变更选择验证

LittleGames 当前套件及排除原因以 `scripts/regression-suites.json` 为准，统一入口是 `node scripts/run-regressions.cjs`。仅在变更范围确实需要时执行全套；长期保留结果时设置 `LITTLEGAMES_REGRESSION_OUTPUT` 到构建目录之外。以下是按职责选取的入口，使用前确认仍在当前清单中：

| 变更范围 | 相关现有入口（`node scripts/<name>.cjs`） |
| --- | --- |
| 原游戏规则、性能/偏好 | `test-performance`、`test-generation-logic`、对应规则审计 |
| 设置与游玩记录/时长 | `test-game-settings`、`test-play-history`、`test-play-time` |
| 经典合集与扩充玩法 | `test-collection`、`test-expansion`、`test-expansion-completion` |
| 窗口计算与接续 | `test-window-sizing`、`test-continuation` |
| 存档与读取失败 | `test-local-game-saves`、`test-data-recovery`、`test-review-fixes` |
| 历史传输层 | `test-lan-transport`；旧 `test-lan-multiplayer` 因适配器撤下而排除，不作为现有联机功能验收 |
| 电脑对手 | `test-computer-opponents`、`test-poker-ai`、`test-chess-ai`、`test-card-ai` |
| 素材与互动反馈 | `test-expansion-art`；必要时运行对应素材渲染检查 |

桌面运行器转换 `.ets`，替代部分原生服务与时钟。它能验证业务不变量，不能证明 ArkTS 编译、原生 Socket 行为、设备画面或性能。使用仓库配置的 Node 与 TypeScript 模块；必要时按项目说明配置 `ARKTS_TYPESCRIPT_PATH`。

新增测试仅在行为或风险值得验证时编写；验证非法输入、规则边界、完整流程、竞态或协议不变量，避免仅匹配实现文本。低影响样式或文档改动不需要镜像测试。

`.ets` 修改执行原生构建。完成后检查本次 diff 及 `git diff --check`，保留已有未提交工作。旧测试/构建报告不能当成本次结果；若已有改动导致失败，说明证据与影响范围，不随意回退用户工作。

审查先跟踪实际生产入口、调用者、状态构造和参数范围，再确定缺陷与严重度；仅有历史源码、循环上限、资源设计宽度或可疑写法不能证明白屏、ANR、缩放错误或性能故障。记录可复现步骤和反例；未复现的疑点保留为待证，不先增加防护层。测试失败先确认断言、fixture 和实际业务语义，不为通过测试削弱已有规则。

## 设备与后端验收

- 页面/组件：浅色与深色、长文本与大字号、实际触区、状态提示、原生返回、筛选/滚动位置、弹层快速双击与取消。
- 适配：本次支持设备的竖/横屏、窗口变小、分屏/悬浮窗；棋盘同时受宽高约束，底部操作和浮栏留白可用。
- 生命周期：按业务验证进入、暂停、后台/前台、结束和恢复等实际路径。游戏自动恢复不能解除手动暂停；倒计时等功能单独核对跨后台与锁屏语义。
- 接续：区分序列化规则测试与真实跨设备迁移；检查路径恢复、未就绪接收、无效版本、恢复失败及实时场景先暂停。
- LAN：两台真实设备在适用 Wi-Fi/热点下握手、双方操作、重开、失联、后台断线；受控桌面传输不能替代此项。
- 云端：真实契约成功与错误、非法/缺失字段、权限、超时、重复提交、取消/旧请求、冲突和分页；记录服务环境与是否为 mock。
- 性能：只有实际测量后才报告帧率、内存、耗电等；截图只能说明采样帧的视觉状态。
- 升级/发布：记录包版本、Debug/Release、签名状态与 SHA-256，区分实际安装包和公开发布包。升级优先覆盖安装，验证记录、偏好及存档重启后仍保留；不因安装失败擅自卸载或清数据。需要更改签名或身份时先说明数据影响并按已有授权处理。

只验证任务涉及的关键范围，网络、接续和发布条目仅在实际功能或任务需要时适用。设备不可用时交付可完成的构建和回归，列明尚未实测项；不从未验证状态推断所有机型与功能通过。设备验收记录包身份、场景与截图/日志来源，测试后恢复临时修改的用户设置。构建成功仍需说明与交付有关的告警；系统或驱动 E 级日志不自动等于应用崩溃，按应用进程、故障栈与操作时序判断。

## 来源与维护

此 skill 初次提炼于 2026-10-09，本轮更新于 2026-11-12。项目规范、现行源码和资源是实现依据；历史文档与截图只支持相应包及场景。以下路径相对 LittleGames 根目录，在其他工程中不要求存在，不作为运行依赖。

| 提炼内容 | 项目依据 |
| --- | --- |
| ArkTS 严格约束与 SDK 构建 | `AGENTS.md`、`build-profile.json5`、`entry/oh-package.json5`、`entry/src/main/module.json5`、`scripts/build-hap.cjs` |
| API 26 迁移与兼容 | `docs/api26-upgrade-implementation-2026-10-18.md`、`entry/src/main/ets/common/ImmersiveLight.ets` |
| 系统语义色与设计令牌 | `entry/src/main/ets/common/DesignTokens.ets`、`entry/src/main/resources/base/element`、`entry/src/main/resources/dark/element` |
| 当前页面层级和尺寸 | `docs/ui-polish-plan-2026-10-07.md`、`docs/device-acceptance/ui-polish-2026-10-08/REPORT.md`、`entry/src/main/ets/components/HomeHeader.ets` / `GameCard.ets`、`entry/src/main/ets/pages/home/FeaturedTab.ets` |
| 截图与素材复核 | `docs/device-acceptance/ui-polish-2026-10-07/light-featured.jpeg`、`docs/art/legacy-gameplay-2026-10-08/dark.png` |
| 原生动效与防穿透 | `entry/src/main/ets/common/HarmonyMotion.ets`、`entry/src/main/ets/components/GameResultDialog.ets`、`docs/harmony-native-motion-2026-10-03.md` |
| 导航/状态/窗口 | `entry/src/main/ets/pages/Index.ets`、`entry/src/main/ets/router`、`entry/src/main/ets/viewmodel/SudokuViewModel.ets`、`entry/src/main/ets/common/ScreenUtils.ets` |
| 本地数据/生命周期/安全区 | `entry/src/main/ets/model/GameData.ets`、`entry/src/main/ets/common/GameLifecycleBus.ets` / `SafeAreaInsets.ets`、`entry/src/main/ets/model/game/RandomSource.ets` |
| 接续 | `entry/src/main/ets/common/AppContinuation.ets` / `GameSessionTransfer.ets`、`docs/harmonyos-continuation-immersive-light.md` |
| LAN 历史经验与撤下状态 | `entry/src/main/ets/common/LanProtocol.ets` / `LanFraming.ets` / `LanTransport.ets`、`docs/lan-multiplayer.md`、`scripts/regression-suites.json` |
| 统一素材 | `docs/art/unified-icons.md`、`docs/art/legacy-gameplay-2026-10-08/README.md`、`scripts/game-art-palette.cjs` |
| 审查纠错、数据保护、存档兼容 | `docs/review-fixes-2026-11-04.md`、`docs/game-retention-implementation-2026-10-27.md` |
| 本地签名与升级验收 | `hvigorfile.ts`、`.gitignore`、`docs/release/v1.0.1.md` |

以上来源记录提炼依据，不维护“当前所有功能已通过/未通过”的全局结论。仓库与已安装的技能副本需要同步更新时，先验证仓库副本，再同步本技能对应文件；不改其他技能或用户配置，不把“允许自动选择”写成每轮必然加载的保证。

## 官方资料入口

以下是官方资料入口；每次新增/更换能力仍按目标版本核实。部分网页依赖动态加载，保存入口不等于已核实具体 API 签名。

- [ArkTS 官方说明](https://developer.huawei.com/consumer/en/arkts/)：语言定位与静态检查；具体约束继续核对目标编译器与 TypeScript 转 ArkTS 文档。
- [MVVM V2 官方指南（版本化资料）](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V14/arkts-mvvm-v2-V14)：Model/View/ViewModel 与 V2 状态管理；该页面不是目标 SDK 的全量参考。
- [数据存储方案选择](https://developer.huawei.com/consumer/cn/doc/doccenter-dev-faq/faqs-local-database-management-38)：按数据类型与访问需求选择存储。
- [Preferences 指南入口](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-preferences)：查当前偏好存储文档，并核对本地 SDK 的 preferences 声明。
- [Network Kit 数据传输能力目录](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/network-kit-data-transmission-V5)：从目录进入 HTTP、WebSocket 或 Socket 文档，选择目标 API 版本。
- [UI Design Kit 目录](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/ui-design-arkts)：核对 HDS 组件与材质定义。
- [应用接续最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-application-continue-progess)：已有工程接续路线的官方参考，具体回调与参数需再核实。

本机官方 SDK 可从 `C:/Program Files/Huawei/DevEco Studio/sdk` 定位，示例路径仅作本机查找提示；先确认目标安装位置。网页不完整时同时查本地声明和原生构建，仍不确定的能力不要猜造。
