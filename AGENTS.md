# 项目开发规则（HarmonyOS / ArkTS）

> 本文件为本项目的强制开发约束，所有代码改动都需遵守。编译期不合规的写法将无法构建通过。

## 一、ArkTS / ets 语法约束

### 类型与声明
- 不支持索引访问类型（如 `T[K]`）：改用显式类型名称。
- 不支持环境模块声明（ambient module）：从原始模块直接 import 所需内容。
- 不支持 `any` / `unknown`：必须显式指定类型。
- 不支持 `as const` 断言：改用字面量的显式类型标注。
- 不支持对象类型中的调用签名：改用 `class`。
- 不支持类字面量：显式引入新的命名类类型。
- 不支持将类用作对象（赋值给变量等）：类只引入类型，不引入值。
- 不支持构造函数中声明类字段：在类声明内部声明字段。
- 不支持构造函数类型：改用箭头函数（lambda）。
- 不支持接口中的构造函数签名 / 对象类型中的构造函数签名：改用方法，或改用 `class`。
- 不支持声明合并：保持每个类/接口定义紧凑。
- 不支持枚举声明合并：保持每个枚举声明紧凑。
- 不支持用运行时表达式初始化枚举成员，且所有显式初始化器必须同类型：仅用同类型编译时表达式。
- 不支持 `export = ...`：改用普通 `export`/`import`。
- 不支持导入断言：改用普通 `import`（正确性在编译期检查）。
- 不支持模块名通配符：改用普通 `export`。
- 不支持 UMD：改用普通 `export`/`import`。
- 不支持 `require` 导入 / import 赋值：改用普通 `import`。
- 不支持 `var`：改用 `let`。
- 不支持 `with` 语句。

### 泛型 / 类型运算
- 不支持条件类型别名，不支持 `infer`：用带约束的新类型或 `Object` 重写。
- 不支持交叉类型：改用继承。
- 不支持映射类型：用常规 class/接口实现。
- 不支持结构化类型（structural typing）：改用继承、接口或类型别名。
- 不支持 `Record` 之外的 TS 工具类型（`Partial`/`Required`/`Readonly`/`Record` 例外）；`Record<K,V>` 中 `rec[index]` 类型为 `V | undefined`。
- 泛型类型参数在调用时可省略（若能推断）；但**仅基于返回类型推断泛型参数是被禁止的**，需显式指定返回类型。
- 函数返回类型推断受限：当 return 的表达式是调用一个省略返回类型的函数/方法时会报错，需显式标注返回类型。
- 不支持 `typeof` 用于类型标注：改用显式类型声明（`typeof` 仅可在表达式上下文使用）。
- 不支持 `is` 运算符：改用 `instanceof`，使用前用 `as` 转换类型。
- 不支持 `in` 运算符：用 `instanceof` 检查类成员。
- 不支持泛型标类型标注的 `this`：改用显式类型。

### 表达式 / 语句
- 仅 `for` 循环支持逗号运算符；循环外用显式顺序。
- 不支持解构赋值 / 解构变量声明 / 解构参数声明：用临时变量逐字段操作，参数直接传递并手动分配局部名。
- 不支持 `for..in` 遍历对象：对象布局编译期已知；数组用常规 `for` 循环。
- 不支持 `Function.apply` / `Function.call` / `Function.bind`：遵循传统 OOP 的 `this` 语义。
- 不支持函数表达式：改用箭头函数。
- 不支持在函数上声明属性（函数对象布局运行时不可改）。
- 不支持生成器函数：用 `async`/`await`。
- 不支持全局作用域 / `globalThis`：用显式模块导出导入共享数据。
- 不支持嵌套函数：改用箭头函数。
- 不支持 `new.target`（无运行时原型继承）。
- 不支持以 `#` 开头的私有标识符：改用 `private` 关键字。
- 不支持动态字段声明与 `obj["field"]` 索引访问：在类里声明所有字段，用 `obj.field` 访问（`Int32Array` 等定型数组的 `container[index]` 例外）。
- 不支持原型赋值。
- 不支持 `Symbol()`（除 `Symbol.iterator` 外）：避免使用。
- 不支持 JSX 表达式。
- 不支持命名空间用作对象；不支持命名空间中的语句：用 class/module 或函数。
- 不支持对象字面量直接作为类型声明：显式声明 class/接口。
- 一元运算符 `+`、`-`、`~` 仅作用于数字类型（无字符串隐式转换）。
- 展开运算符仅支持把数组（或派生自数组的类）展开到 rest 参数或数组字面量；其他场景手动解包。
- 不支持在独立函数和静态方法中使用 `this`（`this` 仅用于实例方法）。
- 所有 `import` 语句必须放在文件最开头（任何其他语句之前）。
- 不支持多个静态代码块：合并为一个。
- 仅表达式上下文支持 `typeof`。
- `catch` 子句省略类型标注（ArkTS 不支持 `any`/`unknown` 标注）。
- 对象字面量必须能推断出对应 class/接口，否则报错；避免用于 `any`/`Object`/`object`、带方法/带参构造函数/readonly 字段的类。
- 数组字面量中所有元素必须可推断类型；无类型对象字面量元素需显式转换。
- 不支持确定性赋值断言 `let v!: T`：改用带初始化声明；若用到 `!`，需确保使用前已赋值并注意运行时开销/警告。

### 接口
- 接口不能包含两个签名不可区分的方法（参数列表同但返回类型不同）：重构方法名/返回类型。
- 接口避免扩展含相同方法签名的其它接口。

## 二、HarmonyOS API 使用规范（必读）

- 优先使用 HarmonyOS 官方 API、UI 组件、动画、代码模板。
- 调用 API 前确认遵循官方文档的入参、返回值及对应 API Level 与设备支持情况。
- 对任何不确定的语法/API 使用，**不要猜测或自行构造 API**，用搜索工具查华为开发者官方文档确认。
- 使用 API 前确认是否需要在文件头添加 `import` 语句。
- 调用 API 前确认是否需要对应权限，并在对应模块的 `module.json5` 中配置权限。
- 如需依赖库，确认其存在与版本匹配，并在模块的 `oh-package.json5` 中添加依赖。
- 使用 `@Component` 与 `@ComponentV2` 注意兼容性，尽量与已有工程代码保持一致。
- UI 引用的常量应定义为 `resources` 资源值并用 `$r(...)` 引用，一般不直接用字面值。
- 新增国际化字符串时，在每种语言下都添加值，避免遗漏。
- 新增颜色等资源确认是否需要黑色主题支持（参考历史工程）；新工程建议默认支持黑/白双主题。

## 三、ArkUI 动画规范（animateTo / transform / renderGroup / opacity）

- 优先使用 HarmonyOS 原生动画 API 与高级模板。
- 优先使用声明式 UI + `@State`（/响应式状态）驱动动画，通过状态变量变化触发。
- 含复杂子组件的动画，将其设为 `renderGroup(true)`，减少渲染批次。
- **禁止在动画过程中频繁改变 `width`/`height`/`padding`/`margin` 等布局属性**（严重影响性能）。

## 备注

- 本工程编译与目标版本为 HarmonyOS `26.0.0`（API 26），最低兼容版本保持 `6.1.1(24)`。本机图形版 DevEco Studio 已升级为 `26.0.0.851`，安装在 `C:/Program Files/Huawei/DevEco Studio/`；独立 API 26 官方 Command Line Tools 仍保留于 `.local-tools/harmonyos-26.0.0.851/command-line-tools/`。工程根目录**没有** `hvigorw`，命令行使用已配置的构建入口：

  ```bash
  cd E:/lianxi/LittleGames
  node scripts/build-hap.cjs
  # Release 编译模式
  node scripts/build-hap.cjs release
  ```

  构建入口默认使用新版 IDE 内的 Node/Hvigor/SDK/JBR（本机 JBR 25.0.2 已通过签名构建）；可通过 `LITTLEGAMES_TOOLCHAIN_ROOT` 指定独立 `command-line-tools` 路径，通过 `JAVA_HOME` 指定其他兼容 JDK。产物在 `entry/build/default/outputs/default/`。迁移备份、工具和长期验证证据不要放在 `entry/build` 下，Hvigor 迁移/清理任务可能删除该目录。
- 废弃 API 已统一改为 `this.getUIContext().xxx`（如 `animateTo`、`getRouter()`、`px2vp`）。
