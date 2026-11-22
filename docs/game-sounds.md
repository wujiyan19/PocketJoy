# 游戏音效

当前 60 个公开入口含 65 个玩法。每个玩法有自己的操作与得分音效，另有错误、胜利、结束、平局四个公共提示，共 134 个 WAV。旋律记忆另外使用四个音符。生成器按公开目录及其子模式打包，历史玩法的曲调和种子仍由同一生成源码保留。重新开放玩法后再次运行脚本即可恢复相同的音频。

资源由本项目脚本原创合成，无外部音频下载和第三方素材许可要求。WAV 为 44.1 kHz / 16 bit / 单声道，带短淡入淡出并限制峰值；随 HAP 打包，离线可用。

生成：

```powershell
& 'C:/Program Files/Huawei/DevEco Studio/tools/node/node.exe' scripts/generate-game-sounds.cjs
```

播放器使用 Media Kit SoundPool（四路并发），进入页面只加载该款游戏的两个文件和四个公共提示。普通反馈间隔至少 60 ms，结算提示优先。静音、暂停、设置遮挡、切后台与离开页面停止声音，异步返回的旧播放请求会被取消。撤销和恢复存档不会重复播放结算声音；旋律示范期间保留原音符，普通操作声避免遮盖示范。

音效开关继续由 GameDataManager 持久化，无新增依赖或权限。资源对应关系、长度、大小和 SHA-256 见 [manifest.json](audio/manifest.json)。

官方接口依据：[SoundPool](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-multimedia-soundpool) 和 [短音播放说明](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/using-soundpool-for-playback)，并核对 DevEco API 24 的 multimedia/soundPool.d.ts。

| 游戏 ID | 操作音色 | 资源前缀 |
| --- | --- | --- |
| snake | 轻快弹消 | sounds/snake_ |
| tetris | 方块滑动 | sounds/tetris_ |
| 2048 | 方块滑动 | sounds/2048_ |
| whackmole | 柔和击打 | sounds/whackmole_ |
| minesweeper | 方块滑动 | sounds/minesweeper_ |
| sudoku | 清脆提示 | sounds/sudoku_ |
| slidepuzzle | 方块滑动 | sounds/slidepuzzle_ |
| klotski | 木质落子 | sounds/klotski_ |
| guessnumber | 清脆提示 | sounds/guessnumber_ |
| memorycard | 纸牌翻动 | sounds/memorycard_ |
| brickbreaker | 柔和击打 | sounds/brickbreaker_ |
| match3 | 轻快弹消 | sounds/match3_ |
| lights | 清脆提示 | sounds/lights_ |
| flood | 清脆提示 | sounds/flood_ |
| maze | 清脆提示 | sounds/maze_ |
| hanoi | 木质落子 | sounds/hanoi_ |
| peg | 木质落子 | sounds/peg_ |
| nonogram | 清脆提示 | sounds/nonogram_ |
| arithmetic | 清脆提示 | sounds/arithmetic_ |
| compare | 清脆提示 | sounds/compare_ |
| sequence | 清脆提示 | sounds/sequence_ |
| binary | 清脆提示 | sounds/binary_ |
| targetsum | 清脆提示 | sounds/targetsum_ |
| schulte | 清脆提示 | sounds/schulte_ |
| memorysequence | 清脆提示 | sounds/memorysequence_ |
| reaction | 清脆提示 | sounds/reaction_ |
| blockfit | 方块滑动 | sounds/blockfit_ |
| tilestack | 方块滑动 | sounds/tilestack_ |
| bubbleshooter | 轻快弹消 | sounds/bubbleshooter_ |
| fruitmerge | 轻快弹消 | sounds/fruitmerge_ |
| watersort | 流水气泡 | sounds/watersort_ |
| arrowclear | 轻快弹消 | sounds/arrowclear_ |
| screwout | 方块滑动 | sounds/screwout_ |
| parkingjam | 方块滑动 | sounds/parkingjam_ |
| runner | 起跳滑行 | sounds/runner_ |
| blackhole | 轻快弹消 | sounds/blackhole_ |
| fisheat | 轻快弹消 | sounds/fisheat_ |
| sokoban | 方块滑动 | sounds/sokoban_ |
| solitaire | 纸牌翻动 | sounds/solitaire_ |
| rhythm | 清脆提示 | sounds/rhythm_ |
| beatjump | 清脆提示 | sounds/beatjump_ |
| linktiles | 轻快弹消 | sounds/linktiles_ |
| mahjongsolitaire | 轻快弹消 | sounds/mahjongsolitaire_ |
| groupclear | 轻快弹消 | sounds/groupclear_ |
| buscolor | 轻快弹消 | sounds/buscolor_ |
| untangle | 清脆提示 | sounds/untangle_ |
| platformer | 起跳滑行 | sounds/platformer_ |
| grapple | 起跳滑行 | sounds/grapple_ |
| flappy | 起跳滑行 | sounds/flappy_ |
| fruitslice | 柔和击打 | sounds/fruitslice_ |
| rollingball | 起跳滑行 | sounds/rollingball_ |
| shooter | 街机射击 | sounds/shooter_ |
| tanks | 街机射击 | sounds/tanks_ |
| survival | 街机射击 | sounds/survival_ |
| pingpong | 柔和击打 | sounds/pingpong_ |
| drift | 起跳滑行 | sounds/drift_ |
| hillclimb | 起跳滑行 | sounds/hillclimb_ |
| airhockey | 柔和击打 | sounds/airhockey_ |
| xiangqi | 木质落子 | sounds/xiangqi_ |
| chess | 木质落子 | sounds/chess_ |
| spider | 纸牌翻动 | sounds/spider_ |
| freecell | 纸牌翻动 | sounds/freecell_ |
| picturepuzzle | 方块滑动 | sounds/picturepuzzle_ |
| melody | 清脆提示 | sounds/melody_ |
| fishing | 流水气泡 | sounds/fishing_ |
