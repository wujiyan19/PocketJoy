# LittleGames 64 款游戏去留审核

> **审核后已执行**　按用户决定，毛线收卷、迷你餐厅、房间塔防和射击守城已从公开目录撤下。执行后有 60 个公开入口、65 种可玩规则。下表保留撤下前的初评和复核建议，射击守城最终按用户决定撤下。[当前游戏清单](../README.md)

> **后续整改**　对仍在目录的候选逐项复核后，已完成 16 款的游戏规则、成绩或提示修正，以及另外 3 款的对外名称调整。下文中的旧名称、问题和模型数据记录审核时的版本。[动作验证](../scripts/test-action-physics.cjs) · [益智与成绩验证](../scripts/test-puzzle-records-and-feedback.cjs) · [群消、鱼群和残局验证](../scripts/test-expansion-puzzle-balance.cjs) · [推箱子关卡来源](art/warehouse-box-level-origins.md)

<details>
<summary>查看 19 款已落地的整改</summary>

| 涉及游戏 | 新版本行为 |
| --- | --- |
| 钩索摆荡、切水果、空气曲棍球 | 松开已挂上的钩索才会弹射。有效滑动才会切果。冰球按球槌碰撞时的实际运动反弹。 |
| 爬坡越野、自动攻击生存、大鱼吃小鱼 | 新开普通、困难坡道需要控速。简单生存档会有从侧面逼近的耐力敌人。鱼群随玩家成长补充猎物与捕食者，红色虚线环标出危险鱼。 |
| 点击群消、数学挑战 | 群消新局按颜色数量校准三档目标分，旧局沿用原目标。算式比较先选关系，再生成符合难度的算式。 |
| 麻将接龙、倒水排序、数独 | 无法重排或没有合法倒水操作时给出明确提示，并展示可用的恢复操作。填满但有冲突的数独会标出重复数字。 |
| 记忆翻牌、滑动拼图、信号反应 | 配对次数、数字滑块步数按档记最佳，旧总分单列。滑块简介改为排列数字。反应测试统一读取最佳毫秒数，兼容原有分档成绩。 |
| 纵向战机、休闲钓鱼 | 战机规则写明有生命撑过敌群即可获胜。钓鱼栏显示本局已钓获的种数。 |
| 宝石三消、彩泡弹射、推箱子 | 前两款采用新的中文展示名。推箱子英文名为 Warehouse Box Pusher，12 关均有候选布局或局部改稿的来源记录。 |

新版普通、困难爬坡局使用新地形格式。原有存档可在新版继续，新地形跨设备接续需要接收端支持新格式。

</details>

**2026 年 11 月 22 日。** 反重力中的 **Orchestrator Gemini 4 Neon Extra High** 收到了每款游戏的实际规则，分三批给出了 64 条建议。审核时的工作树有 64 个公开入口、69 个可玩规则 ID。数学挑战占一个入口、含五种题型，节奏落键占一个入口、含两种模式。另有 31 个已归档玩法。[Gemini 三批逐字回复](game-retention-gemini-2026-11-22-original.md)

| 如何处理当前独立入口 | Gemini 初评 | 结合项目与商店证据的建议 |
| --- | ---: | ---: |
| 保留 | 9 | **11** |
| 整改后保留 | 36 | **36** |
| 并入其他入口 | 4 | **5** |
| 当前版退出独立入口 | 15 | **11** |
| 因权利风险暂缓公开 | 0 | **1** |
| 合计 | **64** | **64** |

**最有把握原样保留的九款**是贪吃蛇、2048、猜数字、拆螺丝、黑洞吞噬、乘客上车、单键漂移、中国象棋和国际象棋。它们在两轮判断中一致。拆螺丝在拆板和暂存容量之间取舍，乘客上车要预判队首颜色和泊位，单键漂移则靠换向时机应对重新生成的弯道。三个玩法各自有值得重开一局的理由。

**复核后建议退出独立入口的十一款**是打地鼠、汉诺塔、跳子独留、跑酷闯关、房间塔防、节奏落键、迷你餐厅、毛线收卷、横版跳跃闯关、挡板对战和图片拼图。优先处理毛线收卷、迷你餐厅和房间塔防，三款都有固定操作绕过原本核心取舍的可复现证据。其余八款的判断主要依据当前内容量、与合集其他入口的重叠或继续投入的成本。退出独立入口是产品建议，实施时仍可留档或收为专题模式。

**五款合并到三个位置**。数字寻序并入信号反应，组成「专注与反应训练」。数字顺序记忆和旋律记忆并入记忆翻牌，组成「记忆挑战」。箭头清除和停车场挪车并入乘客上车，分别保留方向解障、车辆离场和按颜色接客。合并只收拢入口，不同的输入方式、胜负条件与历史成绩仍各自有意义。

**最先核对的公开名称**是俄罗斯方块 / Tetris 和消消乐。前者还需要把棋井、方块、配色与预览的整体呈现纳入评估，建议在出具授权或完成整体设计复核前暂缓公开。后者已有直接涉及游戏名称的国内判例，建议改为「宝石三消」等描述性名称。打地鼠的英文名、推箱子的英文名、泡泡龙和雷电战机的中文名也应按目标市场核查。数独、Memory Cards 的名称问题都有地区和商品范围差异，各自条目列出出处。[美国下落方块判例][T] · [北京知识产权法院判决全文][X]

## 改变 Gemini 初评的五项

| 游戏 | Gemini 初评 → 复核建议 | 影响判断的证据 |
| --- | --- | --- |
| 俄罗斯方块 | 整改 → 暂缓公开 | 产品耐玩，但名称和整套视觉的授权问题会影响对外分发。 |
| 十字熄灯 | 退出 → 保留 | 新题改变需要按下的格子组合，当前合集没有第二款提供同样的推理。其价值来自玩法差异，直接商店样本体量较小。 |
| 箭头清除 | 退出 → 合并 | 可离场的箭头只会减少阻挡，独立入口的深度有限。直接竞品累计 1 亿+，另一样本查询日在美国免费益智榜排第 28，值得保留为方向解障模式。 |
| 坦克对战 | 退出 → 保留 | 掩体会挡住双方炮弹，三处掩体的位置逐局变化。利用掩体改变射线是自动攻击生存没有的决策。 |
| 射击守城 | 退出 → 整改 | 每秒发一炮时，困难档盲扫五点 0/100 胜，按敌人位置瞄准 92/100 胜。将间隔缩短至 0.32 秒，固定扫射三档全胜。值得修的是高频输入绕过瞄准。 |

## 五款游戏的复玩验证

每项策略在简单、普通、困难三档各跑 100 个固定种子的模型局。测试通过现有游戏模型输入，结果衡量这些策略在这批局面中的效果。无需真机或网络即可从项目根目录复跑。[复现脚本](game-retention-gemini-2026-11-22-probe.cjs)

| 游戏 | 控制策略 | 胜局数（简单 / 普通 / 困难） |
| --- | --- | --- |
| 毛线收卷 | 只看各柱顶同色段，凑满八段，始终用第一根卷轴 | 100 / 100 / 100 |
| 迷你餐厅 | 每游戏秒依次做三种菜，再依次点击在场顾客，全程不读订单和库存 | 100 / 100 / 100 |
| 房间塔防 | 每游戏秒依次点六个炮位，全程不看敌情或修门 | 100 / 100 / 100。完全不建塔为 0 / 0 / 0 |
| 射击守城 | 每秒一炮，固定横扫五点。对照组按首个在场敌人位置瞄准。两组都按相同节奏尝试升级 | 盲扫 93 / 40 / 0。瞄准 100 / 100 / 92 |
| 色块归一 | 每一步从不同于当前区域的三种颜色中随机选择 | 42 / 23 / 14 |

房间塔防和射击守城在不同批次的 Gemini 回复里互被视为替代品。这组对照给出了分别处理它们的理由。色块归一也显示了随机点击随着难度上升明显失效，调难度时值得保留已有的选色决策。

## Google Play 同类热度

69 个规则 ID 均已配到可打开的官方详情页。按代表样本的核心输入和目标，51 项直接匹配，18 项为邻近品类。20 项另核了第二款样本。逐项列出累计下载档位，下表补充 2026 年 11 月 22 日美国区能核到的分类榜位。

| 玩法 | 美国区同日榜位 | 对标时需要注意什么 |
| --- | --- | --- |
| 方块拼填 | 免费益智第 6，Lite 版第 2 | 都是把备选块放入棋盘清行列，本版为 6×6 并设目标分。[Block Blast!](https://play.google.com/store/apps/details?id=com.block.juggle&hl=en&gl=US) · [Block Blast Lite](https://play.google.com/store/apps/details?id=com.blockblast.lite&hl=en&gl=US) |
| 拆螺丝 | 免费益智第 9 | Bolt Out 同样以颜色匹配拆件，本项目另有三颗回收、拆板和暂存上限。[Bolt Out](https://play.google.com/store/apps/details?id=com.gl.unbolt&hl=en&gl=US) |
| 乘客上车 | 免费休闲第 2 | 证据对应同色乘客上车。停车场挪车有自己的竞品样本。[Bus Fever Party!](https://play.google.com/store/apps/details?id=gridplus.busjam.carpuzzle&hl=en&gl=US) |
| 麻将接龙 | 免费桌游第 1 | Vita Mahjong 的核心也是配对移走自由麻将牌。[Vita Mahjong](https://play.google.com/store/apps/details?id=com.vitastudio.mahjong&hl=en&gl=US) |
| 国际象棋 | 免费桌游第 2 | Chess.com 同时覆盖联网对弈。离线人机样本在逐款条目中另列。[Chess.com](https://play.google.com/store/apps/details?id=com.chess&hl=en&gl=US) |
| 消消乐 | 畅销益智第 2 | 畅销榜反映商业表现，免费益智榜同日第 63。IP、长线运营及内购均影响对照。[Royal Match](https://play.google.com/store/apps/details?id=com.dreamgames.royalmatch&hl=en&gl=US) · [免费益智榜](https://www.appbrain.com/stats/google-play-rankings/top_free/puzzle/us) |
| 绳结解开、箭头清除 | 免费益智第 18、第 28 | 第三方转录的同日分类榜，分别对应 Line Tangle 与 Arrow Puzzle。可用于补充累计下载观察。[免费益智榜](https://www.appbrain.com/stats/google-play-rankings/top_free/puzzle/us) |

## 经典街机与合并

### 1. 贪吃蛇 · 保留

滑动或按键转向，吃食物让蛇变长并得分，撞墙或撞到自己结束。食物位置随机，路径随蛇身增长而收窄，三档移动速度提供可练习的操作差异。

- **去留**　随机食物和增长的蛇身让玩家每局重新安排路线，离线短局本身就成立。Gemini 初评为保留。
- **权利**　低／自绘蛇身、食物和图标，名称用普通玩法描述。
- **Google Play**　直接同类，都是格子中吃食物增长的经典蛇。 [Snake '97: retro phone classic · 1000 万+](https://play.google.com/store/apps/details?id=com.dsd164.snake97&hl=en&gl=US)。

### 2. 俄罗斯方块 · 暂缓公开

移动、旋转下落的四格块，填满横行消除得分，堆到顶部结束。方块随机抽取，能预览下一块，堆叠高度与多行消除构成长线决策。

- **去留**　消行和预判下一块很耐玩，但现名与棋井、七种形状、配色及预览同时近似知名作品。公开分发前应确认授权，或重新设计并核查整体呈现。Gemini 初评为整改。
- **权利**　高／中英文现名、10×20 井、七种经典形状、分色与下一块预览同时出现。公开分发前核授权或整体重做。[美国判例][T]
- **Google Play**　直接同类，方块旋转下落并清行，竞品为官方品牌产品。 [Tetris® · 5000 万+](https://play.google.com/store/apps/details?id=com.n3twork.tetris&hl=en&gl=US)。

### 3. 2048 · 保留

滑动整盘合并相同数字，挑战较大数字和累计得分，无合法移动时结束。每次有效移动补新块，三种规则分别以 5%、10%、20% 的概率出现 4，成绩按规则保存。

- **去留**　空格管理、边角布局和新块概率支持长期追分。查明代码来源后按实际使用情况履行许可即可。Gemini 初评为保留。
- **权利**　关注／核查实现是否使用原作代码。复制原版代码或实质部分时须附 MIT 许可与版权声明。界面和第三方素材需分别核对。[上游许可][M]
- **Google Play**　直接同类，滑动相同数字合并，朝 2048 目标前进。 [2048 · 1000 万+](https://play.google.com/store/apps/details?id=com.androbaby.game2048&hl=en&gl=US)。

### 4. 打地鼠 · 退出

在 30 秒内点中随机冒头的地鼠得分，点空洞扣分。每轮限时相同，三档改变出现间隔，每次可能出现一只或两只，成绩可比较。

- **去留**　列入退出独立入口的候选。30 秒局只变化出洞位置和速度，策略空间窄。两个直接样本分别为 1 万+、5 千+，英文用名还需处理。若仍需经典反应挑战，可作练习模式。Gemini 初评为退出。
- **权利**　较高／英文 Whack-a-Mole 与 Mattel 的 Whac-A-Mole 接近。改描述性英文名，同时更新帮助和续接文案。[Mattel][W]
- **Google Play**　直接同类，地鼠出现后限时点击。 [Whack A Mole - Mobile · 1 万+](https://play.google.com/store/apps/details?id=com.onisac.whackamole&hl=en&gl=US)。另见[Mega Mole - Whack A Mole · 5 千+](https://play.google.com/store/apps/details?id=com.hsiangyu.megamole&hl=en&gl=US)（机制相近）。

### 5. 打砖块 · 整改

拖动挡板接球，用反弹击碎这一关所有砖块，再进入下一关，生命耗尽结束。每关沿用八列矩形砖阵，行数从五行逐步增到八行，球速随关卡增加并设上限。

- **去留**　反弹落点能练，但满铺矩形砖只是从五行升到八行。先补能改变击球角度或球路选择的砖阵，比单纯继续加速更有复玩价值。Gemini 初评为整改。
- **权利**　低／中文名描述玩法。复核砖阵、声音和挡板图，避免引入商业街机原素材。
- **Google Play**　直接同类，左右移动挡板，反弹球击碎砖块。 [Bricks DEMOLITION · 1000 万+](https://play.google.com/store/apps/details?id=com.daf.archanoide&hl=en&gl=US)。

### 6. 消消乐 · 整改

交换相邻宝石排成三颗以上同色直线，在 30 步内靠消除和连锁得分。 8×8 随机棋盘与补牌会带来不同机会，无法消除的交换不占用步数。

- **去留**　三十步内的交换与连锁追分成立。优先把公开名称换成描述性名称，例如「宝石三消」，再比较目标变化能否改善复玩。竞品的十亿级下载不能证明本版留存。Gemini 初评为整改。
- **权利**　较高／北京知识产权法院（2022）京73民终77号案记载独立文字商标「消消乐」涉及游戏软件及在线游戏，认定涉案近似游戏名称侵权。本项目宜改描述性中文名，并按最新登记查证权利状态。[判决全文][X]
- **Google Play**　直接同类，交换相邻格凑三消。品牌内容及关卡运营不等同。同类 Royal Match 当日美国畅销益智第 2。 [Candy Crush Saga · 10 亿+](https://play.google.com/store/apps/details?id=com.king.candycrushsaga&hl=en&gl=US)。

## 数字、记忆与反应

### 7. 扫雷 · 整改

依据已开格旁的地雷数推断雷区，可插旗，翻开所有安全格获胜。首次点击后布雷，雷数随档变化。局面持续变化，但没有逐局无猜可解保证。

- **去留**　保留数字推断和随机雷区。核对三档棋面规模及雷密度，优先让困难档产生更多推理空间。扫雷不宜宣称每局都无需猜测。Gemini 初评为整改。
- **权利**　低／使用自绘标记、数字和结算图，避免复刻特定操作系统的原图标。
- **Google Play**　直接同类，根据数字推断雷位。 [Minesweeper for Android · 500 万+](https://play.google.com/store/apps/details?id=com.panu&hl=en&gl=US)。另见[Minesweeper - The Clean One · 100 万+](https://play.google.com/store/apps/details?id=ee.dustland.android.minesweeper&hl=en&gl=US)（机制相近）。

### 8. 数独 · 整改

在九宫格填入 1 至 9，使每行、每列和每个宫内数字各出现一次。可生成新题，按唯一解、提示量与显性或隐性唯一数等解题技法筛题。

- **去留**　值得保留为逻辑主力。题库能生成不同难度的唯一解，优先核对困难题在手机上记录候选数与纠错的体验。日本用名需单独处理。Gemini 初评为整改。
- **权利**　地区相关／题目由项目生成。面向日本时，Nikoli 对「数独 / SUDOKU」应用名有授权要求，应核名称许可。[Nikoli 公告][N]
- **Google Play**　直接同类，经典九宫格数字约束。 [Sudoku.com - Sudoku Puzzle · 1 亿+](https://play.google.com/store/apps/details?id=com.easybrain.sudoku.android&hl=en&gl=US)。

### 9. 猜数字 · 保留

在限定次数内猜出不含重复数字的密码，用位置正确和仅数字正确的反馈排除候选。每局随机密码，三档分别是 3、4、5 位。每次新反馈会改变后续猜法。

- **去留**　玩家根据每次 A/B 反馈缩小候选集合，随机密码与限定次数让下一盘仍有新决策。Gemini 初评为保留。
- **权利**　低／A/B 数字反馈采用通用表示。保留自己的名称、规则说明和界面。
- **Google Play**　直接同类，猜互不重复的数字串，根据 A/B 命中情况排除。项目长度随难度变化。 [Bulls and cows - Mastermind · 1 万+](https://play.google.com/store/apps/details?id=com.vist.bullscows&hl=en&gl=US)。

### 10. 记忆翻牌 · 整改

每次翻两张牌并记住图案位置，用尽量少的尝试找齐相同的牌对。 6、8、12 对牌的位置打乱，同一规则既能比翻牌次数，也会产生新布局。

- **去留**　以图案位置配对作为记忆类主入口，可承接顺序记忆。优先核英文用名及分档成绩，翻牌次数与顺序回忆成绩分别记录。Gemini 初评为整改。
- **权利**　地区相关／英文现名 Memory Cards。Ravensburger 在德国和加拿大有 MEMORY 卡牌商品注册，欧盟旧统一文字标另有无效终审。本手机游戏要按地区、商品范围与用法核定。[德国登记][DE] · [加拿大登记][CA] · [欧盟裁判][EU]
- **Google Play**　直接同类，翻两张卡，记位置找相同图案。 [Memory game: Card Matching · 100 万+](https://play.google.com/store/apps/details?id=com.brandedbrothers.memogame&hl=en&gl=US)。另见[Memory Match Cards · 1 万+](https://play.google.com/store/apps/details?id=com.jcrawley.memorycardgame&hl=en&gl=US)（机制相近）。

### 11. 数字绘格 · 整改

依据行列提示的连续填色格数，填格或标空，使全盘符合所有线索。 4×4 至 6×6 随机小题，用行列逻辑筛选，必要时回退到可推解题面。

- **去留**　保留自生成、逻辑筛题的底座。4×4 至 6×6 很适合入门，可优先加入有来源的图案谜底，让解完一题有可辨认的成果。Gemini 初评为整改。
- **权利**　低／自生成、筛题和自命名 Run Grid。具象谜底图案如有引入，应逐幅核源。
- **Google Play**　直接同类，用行列数字推断涂格。 [Nonogram.com - Puzzle Games · 5000 万+](https://play.google.com/store/apps/details?id=com.easybrain.nonogram&hl=en&gl=US)。

### 12. 数学挑战 · 整改

从心算、比大小、数列、二进制和补数组题中选一项，连续答十题，按正确题数计分。心算含加减乘。比较两式大小。数列猜下一项（等差或翻倍）。二进制转十进制。补数找缺失加数。各模式单独记分，十题选择的流程相同。

- **去留**　保留十题制共用入口，优先让五种模式各有明确角色。Gemini 建议留心算、扩数列、强化比较、移出二进制、把补数并入心算。二进制是否退出取决于是否保留专项学习用途。Gemini 初评为整改。
- **权利**　低／复核题目由程序生成，题干与答案文案自行编写。
- **Google Play**　邻近同类，含加减、乘除、限时心算和训练模式。其它四种子模式需分别看样本。 [Math Workout: Brain Training · 500 万+](https://play.google.com/store/apps/details?id=com.akbur.mathsworkout&hl=en&gl=US)。另见[Math Games for the Brain · 1000 万+](https://play.google.com/store/apps/details?id=de.softan.brainstorm&hl=en&gl=US)（邻近，混合数学和脑力训练）。

### 13. 数字寻序 · 合并

在打乱的数字表里从 1 起依次点到最后一个数，争取更短用时和更少误点。 3×3、4×4、5×5 随机排布，分档最佳用时给重复练习明确反馈。

- **去留**　并入以信号反应为主入口的「专注与反应训练」。保留随机数字表和分档最佳用时，和反应毫秒分开记录。Gemini 初评为合并。
- **权利**　低／自排数字矩阵，避免引入现成训练产品的题包或品牌用语。
- **Google Play**　直接同类，按序点数字，训练注意力和视觉搜索。 [Schulte table · 10 万+](https://play.google.com/store/apps/details?id=com.requestfordinner.schulte&hl=en&gl=US)。另见[Schulte Table - Attention Trai · 5 千+](https://play.google.com/store/apps/details?id=com.wu.schulte.table&hl=en&gl=US)（机制相近）。

### 14. 顺序记忆 · 合并

先记一串数字，自行点选隐藏，再按原顺序输入，全部复现即完成。每局随机 4、6 或 8 个数字，可重复，观察时间由玩家掌握，顺序输错即结束。

- **去留**　并入以记忆翻牌为主入口的「记忆挑战」，保留数字顺序模式。与翻牌的位置配对分别记分。Gemini 初评为合并。
- **权利**　低／数字序列、按键和反馈自制。
- **Google Play**　直接同类，记住刚展示的数字序列并按原顺序复现。 [Digit Span Test · 5 千+](https://play.google.com/store/apps/details?id=com.mastersofmemory.flashnumbers&hl=en&gl=US)。另见[Number Memory Test · 1 千+](https://play.google.com/store/apps/details?id=com.numbermemorytest&hl=en&gl=US)（机制相近）。

### 15. 信号反应 · 整改

等信号出现再点击，以毫秒计反应时间，提前点击本次失败。约 1.5 至 4 秒随机等待，每局只测一次刺激，挑战来自个人成绩改善。

- **去留**　单次刺激只有一个毫秒结果。若保留为训练主入口，建议与数字寻序组合，并允许连续数次看个人表现。单次测试仍可保留。Gemini 初评为整改。
- **权利**　低／反馈文字和信号图标使用自有资源。
- **Google Play**　直接同类，看信号变色后点击，测反应时长。 [Reaction Time Test · 1 万+](https://play.google.com/store/apps/details?id=com.efifi.reaction_speed_meter.reaction_speed_meter&hl=en&gl=US)。另见[Reaction Time Test · 1 千+](https://play.google.com/store/apps/details?id=com.tapboost.reactiontime&hl=en&gl=US)（机制相近）。

### 16. 旋律记忆 · 合并

听、看四个音高的顺序并依次按键复现，成功后序列加长，完成五轮获胜。随机四音序列从三个增加到七个，可重听，错误三次结束，使用统一规则。

- **去留**　作为「记忆挑战」中的听觉顺序模式，与数字顺序和位置翻牌并列。保留重听、五轮递进及三次失误记录。它不要求在节拍窗口按键。Gemini 初评为合并。
- **权利**　低／当前使用四个合成音高，应保留音源和序列生成记录。[音效记录][A]
- **Google Play**　直接同类，四个带音高的按钮、记住声光顺序并重复。项目以琴键呈现。 [Memory Sound · 10 万+](https://play.google.com/store/apps/details?id=com.RMSoftwares.JWMemorySound&hl=en&gl=US)。另见[Neon Simon – Memory Game · 1 千+](https://play.google.com/store/apps/details?id=com.simonpro.game&hl=en&gl=US)（机制相近）。

## 棋盘与空间解谜

### 17. 滑动拼图 · 整改

点空格旁的数字块滑入空格，按从小到大的行序复原全盘。可解洗牌，3×3、4×4、5×5 三种尺度。空格约束让换位次序影响步数。

- **去留**　将首页简介改成按序排列数字，入口可称「数字滑块」。3×3、4×4、5×5 的步数应能分别比较。它与任意交换两块的图片拼图有不同约束。Gemini 初评为整改。
- **权利**　低／数字块自排，棋面与界面文案可核对本地资源。
- **Google Play**　直接同类，同为借一个空位逐块移动，将数字还原为原顺序。 [15 Puzzle -Sliding Puzzle Game · 10 万+](https://play.google.com/store/apps/details?id=com.zeeron.puzzle15&hl=en&gl=US)。

### 18. 华容道 · 整改

移动大小不同的方块让路，把占四格的曹操块移到底部出口。三种基础布局经随机合法移动产生新局。棋子种类和出口固定，题量来自局面变化。

- **去留**　保留大小块让路的独立解谜。现有三种基本布局经合法移动打乱，长期吸引力取决于是否还能遇到不同堵点，优先补有来源的精选题。Gemini 初评为整改。
- **权利**　关注／核具体起局、曹操图像与目标市场用名。一件美国游戏软件 KLOTSKI 申请已于 1993 年放弃，单靠这件申请不能认定现名侵权。[USPTO 记录][K]
- **Google Play**　直接同类，滑块互相阻挡，移动主块到出口。 [Klotski · 10 万+](https://play.google.com/store/apps/details?id=com.alcamasoft.juegos.klotski.android&hl=en&gl=US)。另见[Klotski · 1 万+](https://play.google.com/store/apps/details?id=com.momokka.hakoiri&hl=en&gl=US)（机制相近）。

### 19. 十字熄灯 · 保留

点一格会切换本格及上下左右灯的亮灭，找出能熄灭全盘的点法。 3×3 到 5×5 棋盘都从全灭状态用合法点击扰动生成，解法随局面变化。

- **去留**　与 Gemini 有分歧。这是合集里唯一要求选择一组格子、使十字邻域翻转到全灭的玩法。按压次序可交换，按哪些格子仍随题面而变。直接样本体量小，保留为小众逻辑挑战有明确理由。Gemini 初评为退出。
- **权利**　低／英文 Cross Lights、自绘灯阵和逆向出题降低直接挪用风险。
- **Google Play**　直接同类，点击格子翻转附近灯，目标全灭。 [Lights Out! · 1 万+](https://play.google.com/store/apps/details?id=arnaud.desombre.lightsout&hl=en&gl=US)。另见[Lights Out Arcade · 5 千+](https://play.google.com/store/apps/details?id=uk.co.arcadegeek.lightsout&hl=en&gl=US)（机制相近）。

### 20. 色块归一 · 整改

选择颜色给左上方相连区域染色，在步数上限内吸收相邻格并统一全盘。 5×5 至 7×7 随机四色图，步数上限由一条可行路线加余量确定。

- **去留**　保留有限步数下的边界扩张决策。三档各 100 局，每步在三种非当前色中随机选，分别赢 42、23、14 局。调整余量前应先按档验证，随机点击不保证过关。Gemini 初评为整改。
- **权利**　低／颜色带有数字，自绘棋盘。核对美术和算法来源。
- **Google Play**　直接同类，从角落扩张颜色，限制步数填满棋盘。 [Flood-It! · 100 万+](https://play.google.com/store/apps/details?id=com.labpixies.flood&hl=en&gl=US)。另见[Color Flood · 50 万+](https://play.google.com/store/apps/details?id=com.wetpalm.colorflood&hl=en&gl=US)（机制相近）。

### 21. 迷宫寻路 · 整改

沿可通行的相邻格移动机器人，绕开墙壁到达出口。新局随机生成连通的 7×7、9×9 或 11×11 迷宫，转弯与岔路位置改变。

- **去留**　连通迷宫可换局，当前可走的路线受 7×7 至 11×11 的棋面限制。保留入口前先加强岔路选择和连续移动体验。Gemini 初评为整改。
- **权利**　低／迷宫生成，机器人、绿篱和出口图形留存来源。
- **Google Play**　直接同类，在迷宫中找到出口。 [Mazes & More · 5000 万+](https://play.google.com/store/apps/details?id=com.leodesol.games.classic.maze.labyrinth&hl=en&gl=US)。

### 22. 汉诺塔 · 退出

每次移动柱顶一个圆盘，小盘可置于大盘上，把全部圆盘搬到指定柱。 3 至 5 个盘，起始分布和目标柱会变，提供该局最少步数与计时纪录。

- **去留**　建议退出独立推荐位。随机起局、目标柱和最少步数都已存在，但 3 至 5 个盘的搬运规律容易掌握。教育或经典数学专题仍可收录。Gemini 初评为退出。
- **权利**　低／数学规则通用，圆盘、支柱和说明使用本项目版本。
- **Google Play**　直接同类，在三根柱间移动大小不同圆盘。 [Tower of Hanoi · 10 万+](https://play.google.com/store/apps/details?id=com.atagan.tower_of_hanoi&hl=en&gl=US)。另见[The Hanoi Towers Lite · 10 万+](https://play.google.com/store/apps/details?id=com.A3dlogical.hanoitowerslite&hl=en&gl=US)（机制相近）。

### 23. 跳子独留 · 退出

让棋子越过相邻棋子落入直线上的空位，移走被跳过的棋子，最终只剩一颗。固定 21 孔棋形，逆向合法跳跃生成可解的 4、7、10 步残局。

- **去留**　建议退出当前独立推荐位。21 孔短残局有真决策，也有 100 万+ 的直接样本，退出理由是本版残局规模和进阶有限。不据此断定棋种冷门。Gemini 初评为退出。
- **权利**　低／逆向生成题面，核对棋钉和棋盘绘制来源。
- **Google Play**　直接同类，跨越相邻棋子并移除它，终局保留一颗。 [Marble Solitaire Puzzle Games · 100 万+](https://play.google.com/store/apps/details?id=com.panagola.game.imarblefree&hl=en&gl=US)。

### 24. 推箱子 · 整改

逐格移动并向前推箱，把箱子推到对应目标，可撤销，闯关还需处理单向格和指定箱。 12 道固定闯关标有最少推动 7 至 25 次，另有 7×7 随机仓库，随机内墙、2 至 4 箱及逆向生成的可行路线。

- **去留**　12 个固定关的单向格、指定箱和随机仓库使本版有独立解题价值。优先调整英文名，补齐固定关卡来源。Gemini 初评为整改。
- **权利**　较高／英文现名 Sokoban。按地区改通用英文名或核授权，12 个固定关卡分别留存设计来源。[权利人说明][S]
- **Google Play**　直接同类，按网格把箱子推上指定位置。 [Sokoban Original & Extra · 50 万+](https://play.google.com/store/apps/details?id=br.com.orangevoid.sokobanfree&hl=en&gl=US)。

### 25. 绳结解开 · 整改

拖动圆点重新安排绳索端点，消除不共端点绳索的交叉或重叠。 6 至 8 个端点，环与随机平面三角剖分子图改变连接关系，开局再打乱结点位置。

- **去留**　拖动端点解交叉在合集里少有，代表作当日排名也说明有人在玩。保留核心，优先让不同关出现不同连接结构，避免只靠增大节点数。Gemini 初评为整改。
- **权利**　低／核生成图、绳索和节点绘制来源。
- **Google Play**　直接同类，同为拖动端点使线段不再交叉。竞品解开后显出图案。同一作品当日美国免费益智第 18（AppBrain 转录）。 [Line Tangle: Untangle Puzzle · 5 万+](https://play.google.com/store/apps/details?id=line.tangle.twist.away.puzzle&hl=en&gl=US)。另见[Untangle: Clear Lines · 10+](https://play.google.com/store/apps/details?id=com.gemduck.quiet.untangle&hl=en&gl=US)（机制相近）。

### 26. 图片拼图 · 退出

参考原图，任选两块碎片交换位置，恢复整幅画面。四种画面随机选一张，3×3 至 5×5 碎片打乱。允许自由交换，与数字滑块规则不同。

- **去留**　建议退出独立入口。只有四幅图，熟记后任意两块互换很少产生新策略。两个直接样本为 1 千+ 和 100+。若增加有来源的题图再复审。Gemini 初评为退出。
- **权利**　关注／四幅底图是这里最重要的权利对象，逐幅留存生成源或授权。
- **Google Play**　直接同类，交换图片碎块复原整图。样本另允许旋转。 [Picture Tile Swap Brain Puzzle · 1 千+](https://play.google.com/store/apps/details?id=jp.co.wasabiapps.swappuz&hl=en&gl=US)。另见[Tile Swap: Photo Puzzle Games · 100+](https://play.google.com/store/apps/details?id=com.most4dev.jigsawpuzzles&hl=en&gl=US)（机制相近）。

### 27. 滚动球闯关 · 整改

用触控引导带惯性的小球，绕过挡板与洞口，滚到旗帜。每局仍是三道挡板，开放端和纵向位置、终点横坐标会变。危险洞口随档为一至三个。

- **去留**　惯性绕障有独立手感，但地图始终以三道挡板为骨架。保留前应验证不同路径和控速要求能否带来足够变化。Gemini 初评为整改。
- **权利**　低／球、洞口、迷宫图和关卡设计留存来源。
- **Google Play**　邻近同类，引导带惯性钢珠绕过障碍到终点。竞品倾斜控制。 [Teeter Pro - labyrinth maze · 1000 万+](https://play.google.com/store/apps/details?id=pl.surix.teeterpro&hl=en&gl=US)。

## 消除、排序与调度

### 28. 方块拼填 · 整改

依次把备选拼块放到棋盘，填满整行或整列即可消除，达到目标分获胜。同为 6×6，每次三块，用完补充。三档改变块形池及 800、1200、1600 的目标分。

- **去留**　6×6 棋盘上的三块选位有真实取舍，竞品在累计下载和当日榜位上也有支持。优先验证玩家能否预判拼块的实际落点，再决定扩盘。Gemini 初评为整改。
- **权利**　低／重点是拼块轮廓、三选区和消线呈现，核视觉与商店宣传的区分度。
- **Google Play**　直接同类，选择形状拼入棋盘，填满行列后清除。美国免费益智第 6，Lite 第 2。 [Block Blast! · 10 亿+](https://play.google.com/store/apps/details?id=com.block.juggle&hl=en&gl=US)。

### 29. 堆叠三消 · 整改

取每叠最上面的牌放入七格槽，凑三张同图消除，槽满前清空全部牌。三档共 60、75、90 张牌，收取顶牌会暴露下一张，剩余槽位制约取牌顺序。

- **去留**　七格暂存槽应当迫使玩家权衡先取哪张。当前规整纵向牌叠使下层信息有限，优先让层间关系可读，再比较重复局面中的取牌决策。Gemini 初评为整改。
- **权利**　关注／复核叠牌图、七格槽和奖励反馈的组合，使用自有牌面与布局。
- **Google Play**　直接同类，从堆叠图牌中收集并凑三张相同牌。 [Tile Master® - Matching Game · 1 亿+](https://play.google.com/store/apps/details?id=com.tilemaster.puzzle.block.match&hl=en&gl=US)。

### 30. 泡泡龙 · 整改

瞄准或借墙反弹发射泡泡，连起至少三个同色泡泡并清空顶部泡群。初始 4 至 6 行随机颜色，发射预算 90 至 70 发，可让失去顶部连接的泡泡掉落。

- **去留**　瞄准、反弹和打断悬挂连接具有独立价值，保留发射玩法，优先更换中文名并复核形象。Gemini 初评为整改。
- **权利**　较高／中文名与 TAITO 授权作品接近，宜改名。英文 Bubble Shooter 在美国有效图文标明确放弃单独文字专用权，在相关欧盟案件中被视为描述性用语。按发行地核名、标识和形象。[中文发行][B] · [美国登记][BS] · [欧盟材料][BE]
- **Google Play**　直接同类，瞄准发射彩色泡泡，凑色消除。 [Bubble Shooter - Classic Pop · 5 亿+](https://play.google.com/store/apps/details?id=bubbleshooter.orig&hl=en&gl=US)。

### 31. 落果合成 · 整改

选择落点投水果，让同等级水果碰撞升级，在溢出警戒线之前合出最高等级。标准规则随机提供三种低阶水果，后续落点、堆积与物理碰撞持续改变局面。

- **去留**　落点和碰撞中的空间管理成立。保留十级短局，先检验掉落引导和合成上限之后是否仍有追分动机。Gemini 初评为整改。
- **权利**　关注／核十级水果轮廓、表情、容器和预览界面。保留自绘素材和差异化呈现。
- **Google Play**　直接同类，相同水果靠拢合成大水果。官方付费版本与免费合集有价格差异。 [Suika Game · 10 万+](https://play.google.com/store/apps/details?id=com.aladdinx.suikagame&hl=en&gl=US)。另见[Watermelon Merge Game · 100 万+](https://play.google.com/store/apps/details?id=puzzle.big.watermelon.free.games&hl=en&gl=US)（机制相近）。

### 32. 倒水排序 · 整改

把瓶顶水层倒进空瓶或同色水层上，直到每个有水的瓶子都装满一种颜色。三至五种颜色、两个空瓶，每瓶四层，由完成态逆向打乱并保留可行路径。

- **去留**　空瓶周转使同色整理有策略。现版每次只倒一层，优先评估这条规则带来的决策和重复操作成本，再考虑提高色数。Gemini 初评为整改。
- **权利**　低／通用倒水规则，核试管和液体动画资产来源。
- **Google Play**　直接同类，在瓶子间倒同色液体归类。 [SortPuz™: Water Sort Puzzle · 1 亿+](https://play.google.com/store/apps/details?id=sortpuz.water.sort.puzzle.game&hl=en&gl=US)。另见[Water Sort Puzzle - Sort Color · 5000 万+](https://play.google.com/store/apps/details?id=water.sort.puzzle.game.color.sorting.free&hl=en&gl=US)（机制相近）。

### 33. 箭头清除 · 合并

按箭头指向逐个将其移出棋盘，先清理挡路箭头，三次点错前清空棋盘。 5×5 至 7×7 生成具有可清顺序的箭头，依赖链与停车场挪车的方向阻挡循环相近。

- **去留**　Gemini 建议退出。当前可移出的箭头只会解除阻挡，错误选择不能制造新障碍，不过直接竞品有 1 亿+ 下载和同类当日榜位。建议与停车场挪车一起归入乘客上车入口的解障模式，保留箭头的三错上限。Gemini 初评为退出。
- **权利**　低／自排箭头和棋盘，避免复制现成关图或广告演示。
- **Google Play**　直接同类，按方向移走箭头，逐一解除遮挡。竞品可能使用折线轨迹。另一样本 Arrow Puzzle 当日美国免费益智第 28（AppBrain 转录）。 [Arrows – Puzzle Escape · 1 亿+](https://play.google.com/store/apps/details?id=com.ecffri.arrows&hl=en&gl=US)。

### 34. 拆螺丝 · 保留

取露出的螺丝入槽，三颗同色同编号便回收，逐层拆光板件，避免暂存槽堵满。可解生成，5、7、9 块板配 3、4、5 色。困难将槽位减到五个，并筛除特定贪心方法能清空的布局。

- **去留**　局面同时受露出哪些螺丝、同色三颗与暂存容量限制。可解生成和难度变化支撑独立入口。Gemini 初评为保留。
- **权利**　关注／使用生成板组和自绘螺丝，复核拆板顺序、槽位和图标与商业产品的整体相似性。
- **Google Play**　直接同类，按遮挡和颜色拆螺丝进行收集。同类 Bolt Out 当日美国免费益智第 9。 [Screw Jam · 100 万+](https://play.google.com/store/apps/details?id=com.quok.screwJam&hl=en&gl=US)。

### 35. 停车场挪车 · 合并

按车辆箭头让前方无阻的车离开，安排出车顺序直至停车场清空。随机车长、朝向和阻挡，6×6 至 8×8 停车场。车数增加未必让每局都更难。

- **去留**　并入乘客上车，保留「车场挪车」模式。单向开出不会堵住后来车辆，和有限泊位的颜色接客有明显区别，可用同一入口承载两套规则和成绩。Gemini 初评为合并。
- **权利**　低／核车辆造型、停车场图及宣传名，保留自身生成布局。
- **Google Play**　直接同类，按次序移动被阻挡的车辆以清空停车场。 [Parking Jam 3D · 1 亿+](https://play.google.com/store/apps/details?id=com.lszenlamzr.parkingjam&hl=en&gl=US)。

### 36. 连连看 · 整改

找出图案相同且可用至多两次拐弯连通的一对牌，依次消除直至清盘。 24、36、48 格随机配对布局，可沿盘外连线，无可消对子时能重排。

- **去留**　两折路线和盘外绕行有独特解谜价值。当前图案较少，优先检查玩家是否大量只消相邻对子，据此决定是否增加图案种类。Gemini 初评为整改。
- **权利**　低／折线路径规则通用，核配对牌图和提示特效来源。
- **Google Play**　直接同类，配对相同图块，以不超过两次转弯的路线连接。 [Connect Animal Classic Travel · 1000 万+](https://play.google.com/store/apps/details?id=com.HT93Studio.AnimalConnect&hl=en&gl=US)。

### 37. 麻将接龙 · 整改

配对取走两张同花纹的自由牌，每张须上方无牌压住且左右至少一边敞开。难度改变堆叠层数，牌面配对及遮挡影响后续能取哪些牌，可以撤销或重排。

- **去留**　自由牌与多层遮挡能让玩家考虑先消哪一对。直接对照作品当日免费桌游第 1，优先丰富有差异的叠层题面和可辨牌种。Gemini 初评为整改。
- **权利**　低／麻将牌符号与特定商业牌面美术分开核对，保留自绘牌图及层叠布局来源。
- **Google Play**　直接同类，配对移走自由麻将牌。与四人麻将不同。同类 Vita Mahjong 当日美国免费桌游第 1。 [Mahjong Solitaire - Master · 100 万+](https://play.google.com/store/apps/details?id=com.kiwifun.game.android.mahjong&hl=en&gl=US)。

### 38. 点击群消 · 整改

点一组上下左右连通的同色方块消除，利用下落和空列左移清盘或在无解时达标。固定 6×8 棋盘随机着色，三至五色，大片连通块按数量平方奖励。

- **去留**　按连通组平方计分，清除后的空列左移会制造下一个大组。优先检验达标分数能否奖励规划大组，和交换三消各自保留。Gemini 初评为整改。
- **权利**　低／颜色和连通组规则通用，保留自绘块面和生成局面的来源。
- **Google Play**　邻近同类，点相邻同色组消除。竞品强调关卡目标、道具和补充方块。 [Toy Blast · 1 亿+](https://play.google.com/store/apps/details?id=net.peakgames.amy&hl=en&gl=US)。

### 39. 乘客上车 · 保留

从三条车道挑车进有限停靠位，让队首乘客上同色车，依次接走全部乘客。三条车道、三个泊位，每辆坐三人。简单同色乘客成组，另外两档把队列颜色交错。

- **去留**　只能给队首乘客上车且泊位只有三个，发车次序一错就堵塞，区别于单纯挪车清障。Gemini 初评为保留。
- **权利**　关注／核巴士、乘客、候车位和排列方式，确保商店图文与同类商业产品可区分。
- **Google Play**　直接同类，同色乘客与待发车辆匹配、候车位有限。竞品还需在拥堵停车场挪车，各车容量不同。同类 Bus Fever Party! 当日美国免费休闲第 2。 [Bus Escape: Traffic Jam · 1000 万+](https://play.google.com/store/apps/details?id=com.abi.busjam.sortpuzzle&hl=en&gl=US)。

### 40. 毛线收卷 · 退出

选卷轴收走毛线柱顶连续同色线段，每卷凑八段收起，收完所有颜色即过关。三根卷轴同时暂存，4 至 6 列毛线，随机构造改变化开顶层颜色的先后次序。

- **去留**　在三档各 100 局中，只看柱顶可收线段，用同一根卷轴逐色收满，300 局全部获胜。另两根卷轴未产生必要取舍，支持现版退出。误入无合法移动局面仍可撤销。Gemini 初评为退出。
- **权利**　关注／卷轴、柱顶线团和界面配色需有自绘底稿，避免复用竞品图标。
- **Google Play**　邻近同类，按颜色将毛线归至匹配卷轴。竞品还要求填出成品图案。 [Wool Sort Color Puzzle · 10 万+](https://play.google.com/store/apps/details?id=com.wool.sort.color.puzzle&hl=en&gl=US)。

## 动作、节奏与驾驶

### 41. 跑酷闯关 · 退出

切换三条跑道躲路障、收金币，避免撞障并达到规定分数。分档目标为 600、900、1200 分，障碍持续出现并加速，达标后本局结算。

- **去留**　建议退出当前独立入口。三道即时换道和拾币能练反应，但目标分达成即结束，可重复变化主要靠速度和来障。十亿级对照 Subway Surfers 同时有跳滑、道具和内容运营。Gemini 初评为退出。
- **权利**　低／通用跑道操作，核主角、障碍、跑道与金币的资产来源。
- **Google Play**　邻近同类，三道切换躲障碍拾取金币。竞品另有跳跃、道具与持续活动。 [Subway Surfers · 10 亿+](https://play.google.com/store/apps/details?id=com.kiloo.subwaysurf&hl=en&gl=US)。

### 42. 黑洞吞噬 · 保留

引导黑洞先吞小玩具以扩大口径，在倒计时内吃掉所有物体。新局用种子生成玩具位置、大小与可行吞噬顺序，目标分别为 35、45、55 个。

- **去留**　随机物件和不同吞噬门槛要求先规划路线，在倒计时内清场，区别于追逐会移动的鱼群。Gemini 初评为保留。
- **权利**　关注／核黑洞成长图、场景与玩具，商店宣传使用自有名称和图像。
- **Google Play**　直接同类，引导黑洞吞小物成长。对战与关卡套件有差异。 [Hole.io - Original Hole Game · 1 亿+](https://play.google.com/store/apps/details?id=io.voodoo.holeio&hl=en&gl=US)。

### 43. 大鱼吃小鱼 · 整改

引导小鱼追吃比自己小的鱼并成长，避开大鱼，吃够指定数量获胜。鱼群的大小、方向与速度形成追猎和躲避两种压力，分档目标 20、25、30 条。

- **去留**　追逐移动的小鱼和躲大鱼有独立价值，优先核查不同档位、不同成长阶段是否还有能威胁玩家的鱼，再决定调整体型生成。Gemini 初评为整改。
- **权利**　低／核各体型鱼及水域图，避开商业作品的角色和标识。
- **Google Play**　直接同类，用小鱼吞吃更小的鱼成长。 [Big Fish Feeding - Grow Fish · 1 万+](https://play.google.com/store/apps/details?id=com.bigfishgames.bigfishh&hl=en&gl=US)。另见[Fish Eater.io · 1000 万+](https://play.google.com/store/apps/details?id=com.hg.FishEaterPro&hl=en&gl=US)（邻近，竞品另有进化和对战）。

### 44. 节奏落键 · 退出

选四轨落键，在音符到线时按轨道，或选三键跳跃，在节拍窗口按左右中方向，完成整段即过关。四轨按档生成 32、40 或 48 个随机音符，三键按档生成 16、24 或 32 个随机方向。都以时机和误判次数为核心，后者可共用入口。

- **去留**　建议退出当前音乐游戏入口。四轨和三键模式有命中、出错和结算反馈音，代码中未发现同步歌曲或连续节拍器。两种玩法可以改作视觉时机练习，商业曲库音游只提供宽品类参照。Gemini 初评为退出。
- **权利**　关注／当前项目有合成反馈音。[项目音效][A]。若引入伴奏或歌曲，应核词曲、编配和录音的使用权。
- **Google Play**　直接同类，点下落的音符或琴键。曲库和授权不能外推。 [Magic Tiles 3™ - Piano Game · 5 亿+](https://play.google.com/store/apps/details?id=com.youmusic.magictiles&hl=en&gl=US)。

### 45. 横版跳跃闯关 · 退出

左右移动并在平台边缘起跳，连续跨越缺口到达旗帜，掉落失败。平台宽度、高度及间隔随机，难度改变距离和间隙。每局仍围绕同一种跳台动作。

- **去留**　建议退出独立入口。平台宽度、高度和间距其实会随机变化，Gemini 所说「无关卡变化」不准确。更可靠的理由是所有布局仍只要求同一种跨隙动作，补足内容的成本较高。Gemini 初评为退出。
- **权利**　低／自有主角、平台、终点和地图，尤其留意商用角色外形。
- **Google Play**　邻近同类，左右移动、跳跃越过平台。竞品另有敌人和多世界。 [Lep's World 2 · 1 亿+](https://play.google.com/store/apps/details?id=at.ner.lepsWorld2&hl=en&gl=US)。

### 46. 钩索摆荡 · 整改

挂住前方锚点随重力摆荡，选择松手时机并接上下一个锚点，到达旗帜。平台和锚点位置逐局变化，绳长和释放角度决定落点，可练习接钩时机。

- **去留**　挂锚、松钩抛射和连续接钩区别于普通跳台，保留独立玩法。优先验证单手挂钩与松开操作，再衡量短关递进。Gemini 初评为整改。
- **权利**　低／核人物、锚点、场景和平台地图来源。
- **Google Play**　直接同类，钩住锚点摆荡，松开跳至下一处。 [Stickman Hook · 1 亿+](https://play.google.com/store/apps/details?id=com.mindy.grap1&hl=en&gl=US)。

### 47. 飞行穿柱 · 整改

点按振翅让角色起落，连续从柱间缺口穿过，避免撞柱或碰上下边界。缺口高度随机、宽度分档，须穿过 8、12 或 16 组，达标即结束。

- **去留**　缺口变化和控高提供追求稳定操作的动力。优先复核小鸟与成对柱体的整体呈现，再决定商店展示。Gemini 初评为整改。
- **权利**　关注／公开英文名是 Wing Gates。自绘金黄色小鸟与薄荷绿色宽边柱仍应按组合观感核与同类作品的差异。[生成代码](../scripts/generate-expansion-art.cjs)
- **Google Play**　直接同类，轻点振翅，在重力作用下穿过管柱空隙。 [Birdy bird - Game Original · 100 万+](https://play.google.com/store/apps/details?id=com.rectfy.birdybird&hl=en&gl=US)。另见[Flappy Arcade - Flying Bird · 5 万+](https://play.google.com/store/apps/details?id=com.KCCreations.FlappyFish&hl=en&gl=US)（机制相近）。

### 48. 切水果 · 整改

划线切开抛起的水果，在 60 秒内达到切果数，并避开炸弹及漏果上限。不同抛物速度和轨迹，切果目标 20、30、40 个，单次刀路可连切。

- **去留**　划切轨迹、连切与避炸弹有独特触控价值。把水果、炸弹、木纹、切痕和声音一起审查，明确区别于知名同类。Gemini 初评为整改。
- **权利**　关注／复核木纹、水果、炸弹、滑切特效和声音的组合，避免复刻 Fruit Ninja 的标志性呈现。
- **Google Play**　直接同类，滑动切抛起的水果并避开炸弹。 [Fruit Ninja® · 5 亿+](https://play.google.com/store/apps/details?id=com.halfbrick.fruitninjafree&hl=en&gl=US)。

### 49. 单键漂移 · 保留

按一键切换汽车横移方向，在弯道内坚持到倒计时结束，驶出赛道即失败。新局种子生成平滑赛道，整车边界判出界。三档目标分别为 30、40、50 秒。

- **去留**　同一键控制持续的横向速度，重开换赛道，熟练后仍需根据弯道修正时机。Gemini 初评为保留。
- **权利**　低／自绘车辆及程序赛道，复核车标与宣传素材。
- **Google Play**　邻近同类，单键漂移过弯。竞品通过绳索支点过弯。 [Sling Drift: Car Drifting Game · 5000 万+](https://play.google.com/store/apps/details?id=com.rubygames.slingdrift&hl=en&gl=US)。

### 50. 爬坡越野 · 整改

用油门和刹车跨过起伏山坡，控制落地冲击，在燃油用尽前抵达终点。新局随机两段地形波形的相位与波长，振幅随档改变，目标距离为 1200、1500、1800。

- **去留**　控油、刹车和落地冲击可以练习，随机坡度提供变化。英文名和越野车呈现优先与知名竞品拉开距离。Gemini 初评为整改。
- **权利**　关注／英文 Hill Climb 与同类知名产品名相近，连同车身剪影、地形和商店图核查区分度。
- **Google Play**　直接同类，油门刹车控制越野车翻越坡地。升级和车辆数量有差别。 [Hill Climb Racing · 10 亿+](https://play.google.com/store/apps/details?id=com.fingersoft.hillclimb&hl=en&gl=US)。

## 射击、防守、经营与体育

### 51. 房间塔防 · 退出

在六个炮位建塔或升级，也可花钱修门，守住房门并消灭整波敌人。塔位固定，守门、造塔和升级共用收入，各档改变来敌数量、速度与耐久。

- **去留**　相互替代的说法不足以裁决。固定每秒轮点六个塔位、不看敌情、不修门，三档各 100 局均胜。完全不操作均败。投入资源有用，但这批局面没有要求按敌情作选择，支持当前版退出独立入口。Gemini 初评为退出。
- **权利**　低／核房门、敌人和炮塔的原创图形，避开有识别性的商业角色与场景。
- **Google Play**　邻近同类，在位置建塔升级抵御波次。竞品地图和兵种更丰富。 [Tower Defense King · 1000 万+](https://play.google.com/store/apps/details?id=com.mobirix.towerking&hl=en&gl=US)。

### 52. 迷你餐厅 · 退出

花金币先做菜，再按顾客订单送餐，在两分钟内完成目标单量，避免流失五位顾客。三种菜、随机订单，三档目标 10、15、20 单，顾客到店间隔和耐心随档改变。

- **去留**　固定每游戏秒依次点三种菜，再点所有在场顾客，不读订单、库存或资金，三档各 100 局均胜。现有短局可绕开本应吸引人复玩的备餐优先级。Gemini 初评为退出。
- **权利**　低／顾客、餐品和菜谱图标使用自有资源。
- **Google Play**　邻近同类，按需求制作、供应餐点。竞品有餐厅升级和海量关卡。 [Cooking Fever: Restaurant Game · 1 亿+](https://play.google.com/store/apps/details?id=com.nordcurrent.canteenhd&hl=en&gl=US)。

### 53. 雷电战机 · 整改

拖动自动向上开火的战机，对准敌机并躲避碰撞，撑过本局敌群。横向随机刷敌，目标 18、24、30 架，失守会耗生命。持续练的是水平对准与躲避。

- **去留**　拖动与对齐固定向上射线支持短局射击。先处理中文名称，再衡量增加敌机阵形是否能改善同档复玩。Gemini 初评为整改。
- **权利**　较高／中文「雷电战机」和 MOSS《雷電》同属纵向战机射击。优先改描述性中文名，核战机造型。[MOSS 系列][R]
- **Google Play**　邻近同类，竖向飞行清敌、躲子弹。竞品长期机库成长规模有差异。 [1945 Air Force: Plane Shooter · 1 亿+](https://play.google.com/store/apps/details?id=com.os.airforce&hl=en&gl=US)。

### 54. 坦克对战 · 保留

拖动坦克移动并利用掩体改变交火角度，让自动炮台瞄准敌人，清完敌军。三处掩体各自随机选左或右，能挡双方炮弹。炮台自动瞄准，操控重点是绕障和站位。

- **去留**　与 Gemini 有分歧。拖动走位、自动攻击与生存模式相近，但三处掩体的位置会变化，墙能挡双方炮弹，玩家需要主动选射线。先保留这项战术差异，后续看玩家是否实际利用掩体。Gemini 初评为退出。
- **权利**　低／核坦克、砖墙、敌军和地图布局，避免复刻特定街机战场。
- **Google Play**　邻近同类，操控坦克、借地形清除敌车。瞄准与发射方式可能不同。 [Tank Hero · 1000 万+](https://play.google.com/store/apps/details?id=com.clapfootgames.tankhero&hl=en&gl=US)。

### 55. 射击守城 · 整改

点选敌群发射范围炮弹，用击杀金币升级火力，在城门被攻破前清完敌军。按档迎击 18、24、30 名来敌，落点与重叠范围决定一次能打几人，升级集中于火力。

- **去留**　与 Gemini 有分歧。同样每秒一炮，困难档固定扫五点 0/100 胜，观察敌人位置瞄准则 92/100 胜。每 0.32 秒一炮时盲扫三档 300/300 胜。普通点击节奏有明确选敌价值，优先整改高频扫射可绕过瞄准的问题。Gemini 初评为退出。
- **权利**　低／核城门、敌人、炮台及弹道素材。
- **Google Play**　邻近同类，手动瞄准守城并升级火力。竞品使用弩、法术和陷阱。 [Grim Defender: Castle Defense · 100 万+](https://play.google.com/store/apps/details?id=com.byteghoul.grimdefender&hl=en&gl=US)。

### 56. 自动攻击生存 · 整改

拖动角色避敌让武器自动攻击，击杀后选择加攻击、射速或回血，清完敌潮。三种敌人颜色对应速度或耐久差异，三档敌人数 24、32、40，局内三选一升级。

- **去留**　保留自动攻击和走位避敌。三项升级目前主要改变数值，优先补能真正改变走位策略的升级或敌群组合。Gemini 初评为整改。
- **权利**　关注／核主角、敌群、升级图标和命名，避免借用竞品的职业和标志性角色。
- **Google Play**　邻近同类，走位躲敌、武器持续攻击。竞品含局内技能选择与长线成长。 [Survivor.io · 5000 万+](https://play.google.com/store/apps/details?id=com.dxx.firenow&hl=en&gl=US)。

### 57. 挡板对战 · 退出

拖动下面的挡板反弹球，使球越过电脑的底线，先得七分获胜。固定球场，对手速度分档，击中挡板的不同位置改变反弹方向。

- **去留**　建议让出独立入口。挡板反弹角有技术空间，但同一 AI 球场重复，两个直接样本为 5 千+、1 万+。若想保留经典规则，可放进球桌对战作一维挡板模式。Gemini 初评为退出。
- **权利**　低／公开英文名 Paddle Duel。核挡板、声音和宣传素材，保持与知名街机标识的区分。
- **Google Play**　直接同类，球在两个挡板之间反弹，通过移板接球。 [Pong Classic Plus · 5 千+](https://play.google.com/store/apps/details?id=com.mnegames.pongclassicplus&hl=en&gl=US)。另见[Ping Pong Classic : Ball Game · 1 万+](https://play.google.com/store/apps/details?id=com.incinet.Ping_Pong_Classic_Neon_Ball_Game_klasik_masa_tenisi&hl=en&gl=US)（机制相近）。

### 58. 空气曲棍球 · 整改

在下半场拖动圆拍击打冰球，让球穿过对方中央球门，先得五分。固定场地与球门，但二维挥拍、侧墙反弹和电脑追球构成不同于横向挡板的技术。

- **去留**　二维挥拍、侧壁反弹和中央球门足以支撑桌面球类主入口。优先复核电脑守门与碰撞反馈。通用运动称谓的商标判断应按地区和类别核查。Gemini 初评为整改。
- **权利**　关注／美国 AIR-HOCKEY 注册列明实体球桌、滑片和配件。手机模拟游戏需另评商品关联、用名和标识。[美国登记][AH]
- **Google Play**　直接同类，移动圆形球拍，击打冰球进门。 [Glow Hockey · 1 亿+](https://play.google.com/store/apps/details?id=com.natenai.glowhockey&hl=en&gl=US)。

### 59. 休闲钓鱼 · 整改

等待咬钩并及时提竿，按住收线或松开卸力控制张力，钓足五条获胜。随机遇到六种鱼，各有不同拉力、挣扎和收线节奏，本局记录鱼种及控线表现。

- **去留**　提竿、控张力以及六种不同的挣扎节奏值得保留。一局钓到五条即胜，「鱼种 / 6」应说明是可遇见的种类数。若要鼓励集齐六种，可改为跨局收集。Gemini 初评为整改。
- **权利**　低／六种鱼的图形、挣扎声音和场景留存项目来源。
- **Google Play**　邻近同类，咬钩后提竿，管理张力收线。竞品鱼种、装备规模有差异。 [Fishing Hook · 1 亿+](https://play.google.com/store/apps/details?id=com.mobirix.fishinghook&hl=en&gl=US)。

## 棋类与纸牌

### 60. 中国象棋 · 保留

执红方按象棋规则与电脑轮流走子，将死或困毙对方获胜。开局固定，合法位置和战术变化丰富。电脑难度从候选着随机选择到评估对手应着。

- **去留**　与电脑对弈即可产生大量战术局面，法着与难度变化支持独立棋类入口。Gemini 初评为保留。
- **权利**　低／传统规则，棋子字形与棋盘图、引擎代码分别留存来源。
- **Google Play**　直接同类，标准中国象棋，支持与电脑对局。 [Chinese Chess - Xiangqi Basics · 100 万+](https://play.google.com/store/apps/details?id=com.datviet.chinesechess&hl=en&gl=US)。

### 61. 国际象棋 · 保留

执白方与电脑下国际象棋，按规则将死黑王，也可能以和棋结束。标准开局支持易位、吃过路兵与升变。电脑按难度采用不同选着策略。

- **去留**　局面由双方应着演化，易位、升变和吃过路兵皆可用。商店竞品的联网用户与本项目离线人机受众有差距。Gemini 初评为保留。
- **权利**　低／规则通用，棋子字形、图标和电脑引擎的代码来源另核。
- **Google Play**　直接同类，国际象棋单人与多难度电脑。同类 Chess.com 当日美国免费桌游第 2，产品亦含联网服务。 [Chess · 5000 万+](https://play.google.com/store/apps/details?id=uk.co.aifactory.chessfree&hl=en&gl=US)。

### 62. 经典纸牌 · 整改

单张翻牌，按红黑交替、点数递减移列，再按花色将 A 到 K 收入四个基础堆。随机发牌，采用固定的翻一张规则。翻开暗牌与留空列持续改变选择。

- **去留**　单翻克朗代克是完整主力玩法。优先验证手机上长列移动与末盘归位的操作次数，再考虑双击或自动收牌。Gemini 初评为整改。
- **权利**　低／接龙规则通用，牌背、人物牌、字体和牌面绘制需有来源。
- **Google Play**　直接同类，标准克朗代克纸牌移动及翻牌，可比单牌模式。 [Solitaire - Classic Card Games · 1 亿+](https://play.google.com/store/apps/details?id=com.mobilityware.solitaire&hl=en&gl=US)。

### 63. 蜘蛛纸牌 · 整改

在十列之间整理降序明牌，把完整 K 至 A 十三张一组收走，集齐八组获胜。固定单花色 104 张，局面随发牌变化。整列利用及发新牌约束使决策不同于经典纸牌。

- **去留**　单花色十列的基本规划成立，先核手机上查看远端列时是否丢失牌序上下文，再评估双花色或四花色是否值得。单花色胜率尚无本项目数据。Gemini 初评为整改。
- **权利**　低／使用共享自绘纸牌，核牌背与牌面字体。
- **Google Play**　直接同类，同花色降序叠牌消除，有单花色模式。 [Spider Solitaire: Card Games · 5000 万+](https://play.google.com/store/apps/details?id=com.mobilityware.spider&hl=en&gl=US)。

### 64. 空当接龙 · 整改

用四个空当临时放牌，在八列间红黑交替递减搬牌，最后按花色归位全部 52 张。每局重新洗牌，空当与空列共同决定一手能搬多长的牌序，关键在规划暂存空间。

- **去留**　四个空当与空列容量形成完整独立规则。优先验证能否快速找到第八列和回看搬牌路径，再决定改视图或收牌流程。Gemini 初评为整改。
- **权利**　低／使用共享自绘纸牌，核牌面来源，避免复用桌面系统的原画。
- **Google Play**　直接同类，用空当和桌面列搬牌，按花色归入基础堆。 [FreeCell Solitaire: Card Games · 1000 万+](https://play.google.com/store/apps/details?id=com.mobilityware.freecell&hl=en&gl=US)。

## 两个复合入口的七种模式

五种数学题型共用十题作答流程，两种节奏玩法共用时机判定。两入口的去留分别是整改和退出。下列模式建议给出了具体取舍。

| 模式 | 具体玩法与去留 | Google Play 样本 |
| --- | --- | --- |
| 心算 | 加、减、乘十题。随机出题支持短局练习，保留为默认模式。 | 邻近，[Math Workout: Brain Training · 500 万+](https://play.google.com/store/apps/details?id=com.akbur.mathsworkout&hl=en&gl=US)。含加减、乘除、限时心算和训练模式。其它四种子模式需分别看样本。 |
| 算式比大小 | 比较两式的运算结果。它复用了计算能力，适合作为心算变化。 | 邻近，[Math Kids: Math Games For Kids · 5000 万+](https://play.google.com/store/apps/details?id=com.rvappstudios.math.kids.counting&hl=en&gl=US)。该儿童数学合集含比较物体组数量的模式，与比较左右两道算式的项目机制有差距。安装量属于整款应用。 |
| 数列推演 | 推断等差或翻倍数列的下一项。这是五种里推理方式不同的一项，有限规律限制长期复玩。 | 直接，[Numerical Series. Next number? · 5 千+](https://play.google.com/store/apps/details?id=com.ferrmoldev.series.numeros.psicotecnicos&hl=en&gl=US)。推断数列的下一项。 |
| 二进制解码 | 把二进制转成十进制。Gemini 建议退出，若保留专项学习定位可留在模式菜单。 | 邻近，[Binary Fun: Number System Game · 10 万+](https://play.google.com/store/apps/details?id=com.petraapps.binarygame&hl=en&gl=US)。都是二进制和十进制转换训练，转换方向及答题控件有别。 |
| 补数求和 | 根据总和和已知加数找缺项。Gemini 建议把缺项题并入心算。 | 邻近，[Math Kids: Math Games For Kids · 5000 万+](https://play.google.com/store/apps/details?id=com.rvappstudios.math.kids.counting&hl=en&gl=US)。该儿童数学合集含加法找缺失数字的模式，项目是已知总和、两个加数并求第三个。安装量属于整款应用。 |
| 四轨落键 | 在音符到线时按对应轨。建议随现音乐入口退出，若另设视觉时机练习可保留操作。 | 直接，[Magic Tiles 3™ - Piano Game · 5 亿+](https://play.google.com/store/apps/details?id=com.youmusic.magictiles&hl=en&gl=US)。点下落的音符或琴键。曲库和授权不能外推。 |
| 三键节拍跳跃 | 在提示时机按正确方向。建议随现音乐入口退出，若改作视觉时机练习则保留三键规则和专属成绩。 | 邻近，[Tiles Hop Music & Ball Game · 5 亿+](https://play.google.com/store/apps/details?id=com.amanotes.beathopper&hl=en&gl=US)。跟随节奏让球跳到下一平台，竞品常用连续左右拖动。 |

## 判断依据

公开目录以本次工作树为准。项目基准提交为 `b868301`，其中推箱子、动作关卡和界面等包含尚未提交的改动。本文核对游戏入口、中文规则、出题方式和胜负条件。玩家重新打开游戏的次数、七日留存率、手机触控手感均无本轮实测数据。[公开目录](../entry/src/main/ets/model/GameData.ets) · [上架筛选](../entry/src/main/ets/common/GameAvailability.ets) · [模式映射](../entry/src/main/ets/common/GameModes.ets) · [规则资源](../entry/src/main/resources/zh_CN/element/string.json) · [游戏模型](../entry/src/main/ets/model/game)

权利等级是发布前的初筛。「低」表示目前找到项目内制作或通用规则的证据，「关注」提示要核对哪一种资产或呈现，「较高」和「高」涉及可指认的商业名称或整体表达。中国《计算机软件保护条例》第六条把开发软件所用的思想、处理过程、操作方法和数学概念排除在软件著作权保护范围之外。代码、图像、界面、音乐、具体关卡表达以及可能造成混淆的名称仍需按发布地区核实。项目有美术生成器和音效合成记录，尚无逐项完整权属材料。本轮没有逐地区检索商标注册、专利或取得品牌授权。[法规原文](https://www.cac.gov.cn/2013-02/08/c_12648744.htm) · [Google Play 知识产权政策](https://support.google.com/googleplay/android-developer/answer/9888072) · [项目美术来源](art/README.md) · [扩展美术来源](art/expansion-art.md) · [音效记录][A]

Google Play 安装档位取自各行链接的美国区英文商品详情页，表示单款 Android 应用的全球累计下载下限。选择样本优先匹配玩家动作和胜负条件，单款成绩还会受发行时间、品牌、定价、推广和活动影响。美国分类榜徽标及同日榜单只反映查询当日的相对位置。文中「直接」表示关键规则接近，「邻近」表示与本项目仍有明显机制或内容差异。未列榜位的游戏仅比较累计样本。Google Play 数据不能直接推算本合集的用户数或国内分发资格。[美国免费游戏总榜](https://www.appbrain.com/stats/google-play-rankings/top_free/game/us) · [美国免费益智榜](https://www.appbrain.com/stats/google-play-rankings/top_free/puzzle/us) · [项目历史上架咨询](release/status-2026-10-27.md)

[T]: https://www.govinfo.gov/app/details/USCOURTS-njd-3_09-cv-06115/USCOURTS-njd-3_09-cv-06115-0
[M]: https://github.com/gabrielecirulli/2048/blob/master/LICENSE.txt
[W]: https://shop.mattel.com/products/whac-a-mole-gvd47
[N]: https://www.nikoli.co.jp/ja/news/20230828_app/
[B]: https://asia.gamesource-ent.com/zh-Hans-HK/detail/570
[S]: https://sokoban.jp/
[R]: https://raiden.mossjp.co.jp/raiden3_mikado/
[A]: game-sounds.md

[DE]: https://register.dpma.de/DPMAregister/marke/register/964625/DE
[CA]: https://ised-isde.canada.ca/cipo/trademark-search/431841?lang=eng
[EU]: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A62010CO0369
[X]: https://www.10100.com/article/23484315
[K]: https://tsdr.uspto.gov/statusview/sn74161179?target=case

[BS]: https://tsdr.uspto.gov/statusview/sn88024487
[BE]: https://euipo.europa.eu/tunnel-web/secure/webdav/guest/document_library/contentPdfs/law_and_practice/appeal/2023_decisions_overview_Q3_en.pdf#page=40
[AH]: https://tsdr.uspto.gov/statusview/sn73037470?target=case
