---
name: tool-ruoyi-api-doc-scanner
description: 扫描RuoYi项目的Controller类，生成用于测试用例的API文档（Markdown格式）。当用户提到"生成API文档"、"扫描接口"、"接口文档"、"测试用例文档"、"API扫描"、"接口扫描"、"生成测试文档"、"Controller文档"、"导出接口"、"接口清单"、"API列表"等关键词时，均应触发此skill。即使用户只是想了解项目有哪些接口、查看Controller的API定义，也应使用此skill。默认全量扫描覆盖生成，仅当用户明确要求增量扫描时才基于进度文件续扫，每个Controller生成独立文档文件。
---

# tool-ruoyi-api-doc-scanner - Controller API文档扫描器

扫描RuoYi项目的所有Controller类，为每个Controller生成用于测试用例的Markdown格式API文档。

## 为什么需要预生成模板

RuoYi项目通常包含多个Controller，绝大多数继承`BaseController`，使用`AjaxResult`/`TableDataInfo`统一响应格式。如果每个子agent都独立读取BaseController源码和Domain基类源码，会造成重复IO和token浪费。本skill通过主agent在激活依赖skills后，根据实际项目中的类定义动态生成模板文件，子agent只做占位符替换。

## 前置依赖

执行前必须激活以下skills获取项目上下文：
- **ruoyi-architecture**：模块架构、Controller规范、MyBatis约定、权限注解
- **zbiti-code-reader**：源码读取能力，辅助理解Controller和Domain结构

## 总体流程

```
主Agent                                    子Agent(s)
  │
  ├─1. 激活依赖skills
  ├─2. 读取项目源码，动态生成模板文件
  │   ├─ docs/apidoc/base-controller-methods-template.md
  │   └─ docs/apidoc/domain-base-classes-template.md
  ├─3. 扫描所有Controller（Bash命令，非Glob）
  ├─4. 创建进度文件
  │   docs/apidoc/api-scan-progress-YYYYMMDD.md
  ├─5. 按序号分发子agent ────────────────────┐
  │   (每批5个，传入模板内容)                │
  │                                         ├─ 读取Controller源码
  │                                         ├─ 解析自定义方法
  │                                         ├─ 替换模板占位符
  │                                         ├─ 读取Domain类合并字段
  │                                         ├─ 生成完整API文档
  │                                         └─ 写入docs/apidoc/目录
  ├─6. 每个子agent完成后立即更新进度文件 ─────┘
  └─7. 输出扫描报告
```

## 详细步骤

### 步骤1：激活依赖skills

依次激活 `ruoyi-architecture`、`zbiti-code-reader`，获取模块架构、Controller规范和源码读取能力。

### 步骤2：读取项目源码，动态生成模板文件

**关键原则：模板内容必须从项目实际源码中提取，不能硬编码。** 不同版本的RuoYi框架，BaseController的方法列表、Domain基类的字段定义可能不同。激活skills后，主agent需要读取项目中的实际源码来生成模板。

**2a. 生成BaseController基础方法模板**

1. 根据激活的`ruoyi-architecture` skill中Controller规范的定义，找到项目中BaseController的源码位置
2. 读取BaseController源码，提取基础方法（方法签名、参数类型、返回类型、@RequestMapping路径、权限注解）
3. RuoYi典型Controller基础方法：

| # | 方法名 | 路径 | HTTP方法 | 接口说明 | 权限 | 说明 |
|---|--------|------|----------|----------|------|------|
| 1 | list | /list | GET/POST | 分页查询列表 | @PreAuthorize | 返回TableDataInfo |
| 2 | getInfo | /{id} | GET | 根据ID查询详情 | @PreAuthorize | 返回AjaxResult |
| 3 | add | / | POST | 新增 | @PreAuthorize | 返回AjaxResult |
| 4 | edit | / | PUT | 修改 | @PreAuthorize | 返回AjaxResult |
| 5 | remove | /{ids} | DELETE | 删除 | @PreAuthorize | 返回AjaxResult |

4. 为上述基础CRUD方法各生成完整的API文档片段，包含：请求头、请求参数表、响应结构、响应示例、测试步骤、预期结果、curl请求示例
5. 文档片段中使用占位符：`{basePath}`（Controller的@RequestMapping路径）、`{序号}`（接口在文档中的序号）、`{DomainName}`（Domain类名）、`{Domain字段}`（Domain的完整字段列表）、`{host}`/`{port}`（保留为占位符）
6. 将生成的文档片段写入 `docs/apidoc/base-controller-methods-template.md`

**2b. 生成Domain基类字段模板**

1. 根据激活的`ruoyi-architecture` skill中Domain基类的定义，找到项目中各Domain基类（如BaseEntity）的源码位置
2. 读取每个Domain基类源码，提取所有字段（包括继承链上的字段），记录字段名、类型、来源、说明
3. 为每个Domain基类生成字段列表文档，包含继承体系说明和各基类的完整字段表
4. 将生成的文档写入 `docs/apidoc/domain-base-classes-template.md`

**子agent使用规则（写入模板文件中）：**
- 子agent收到 `baseMethodsDoc` 后，只需替换占位符即可，禁止再读取BaseController源码
- 子agent收到 `domainBaseFieldsDoc` 后，根据Domain的`extends`声明查找对应基类字段，与自身字段合并，禁止再读取Domain基类源码

### 步骤3：扫描所有Controller

**禁止使用Glob工具** — Glob有结果数量限制（约100条），大型项目会截断遗漏。必须使用Bash命令：

```powershell
# Windows PowerShell
Get-ChildItem -Path "<项目根目录>" -Recurse -Filter "*Controller.java" | ForEach-Object { $_.FullName } | Out-File -FilePath "docs/apidoc/controller-list-YYYYMMDD.txt" -Encoding utf8

# 统计总数
(Get-ChildItem -Path "<项目根目录>" -Recurse -Filter "*Controller.java").Count

# 按模块分组统计
Get-ChildItem -Path "<项目根目录>" -Recurse -Filter "*Controller.java" | ForEach-Object {
    if ($_.FullName -match '\\ruoyi-modules\\([^\\]+)\\') { $matches[1] }
} | Group-Object | Select-Object Name, Count | Sort-Object Count -Descending
```

```bash
# Linux/Mac
find <项目根目录> -name "*Controller.java" -type f > docs/apidoc/controller-list-YYYYMMDD.txt
```

Controller数量超过100时，先导出到 `docs/apidoc/controller-list-YYYYMMDD.txt` 再分批读取。获取结果后必须统计总数并做合理性校验。

对每个Controller提取：类名、类描述（`@Tag(name=...)` > Javadoc > 类名去Controller后缀）、基础路径（`@RequestMapping`）、所属模块、文件路径。

### 步骤4：创建进度文件

路径：`docs/apidoc/api-scan-progress-YYYYMMDD.md`

**强制要求：进度文件的扫描清单必须从 `docs/apidoc/controller-list-YYYYMMDD.txt` 程序化生成，禁止手动编写。**

**程序化生成流程：**

1. 读取 `docs/apidoc/controller-list-YYYYMMDD.txt` 的每一行（每行是一个Controller的绝对路径）
2. 对每一行提取：
   - **Controller类名**：路径最后一段去掉 `.java` 后缀
   - **相对路径**：去掉项目根目录前缀
3. 初始状态统一设为 `⏳未开始`
4. 生成后**必须验证**：进度清单行数 = controller-list行数 = 总Controller数，不一致则报错停止

**进度文件格式：**

```markdown
# API文档扫描进度 - YYYYMMDD

> 生成时间: YYYY-MM-DD HH:mm:ss
> 总Controller数: N
> 并发控制: 每批最多5个子agent

## 统计

| 指标 | 数量 |
|------|------|
| 总数 | N |
| ✅已完成 | 0 |
| ❌失败 | 0 |
| 🔄进行中 | 0 |
| ⏳未开始 | N |

## 扫描清单

| 序号 | Controller类名 | 相对路径 | 状态 | 文档路径 | API数 | 备注 |
|------|---------------|----------|------|----------|-------|------|
| 1 | XxxController | ruoyi-modules/xxx/.../XxxController.java | ⏳未开始 | - | - | - |
| ... | ... | ... | ... | ... | ... | ... |
```

**状态值：** `⏳未开始` | `🔄进行中` | `✅已完成` | `❌失败`

**扫描模式：** 默认全量扫描（覆盖已有文档），仅当用户明确要求增量扫描时才基于进度文件续扫未完成的Controller。

### 步骤5：分发子Agent扫描

**执行前检查点：**
1. 进度文件已创建且清单行数 = 总Controller数
2. `docs/apidoc/base-controller-methods-template.md` 已生成
3. `docs/apidoc/domain-base-classes-template.md` 已生成
4. `docs/apidoc/controller-list-YYYYMMDD.txt` 已生成且行数一致

对每个Controller使用Task工具dispatch子agent。

**传入参数：** `controllerFilePath`、`controllerClassName`、`controllerDescription`、`basePath`、`baseMethodsDoc`（步骤2a生成的文件内容）、`domainBaseFieldsDoc`（步骤2b生成的文件内容）。

**子agent无需检查 `docs/apidoc/` 目录是否存在** — 该目录由主agent在步骤4中已创建，子agent直接写入文档即可，禁止做目录存在性校验。

**并发策略：** 每批最多5个子agent，按进度文件序号顺序分发，完成一批再启动下一批。

**闭环分发流程（强制执行）：**

```
每轮分发循环：
  ┌─────────────────────────────────────────────────┐
  │ 1. 读取进度文件，筛选"⏳未开始"行              │
  │ 2. 若无"⏳未开始"行 → 跳出循环，进入步骤7      │
  │ 3. 将"🔄进行中"的行改回"⏳未开始"（中断可续）  │
  │ 4. 取前5个"⏳未开始"行                         │
  │ 5. 更新这5行状态为"🔄进行中"，写回进度文件      │
  │ 6. 并发分发5个子agent                          │
  │ 7. 每个子agent返回后：                         │
  │    - 成功：更新为"✅已完成"，填入文档路径和API数 │
  │    - 失败：更新为"❌失败"，填入备注              │
  │    - 立即写回进度文件                           │
  │ 8. 验证：已完成+失败+进行中+未开始 = 总数       │
  │ 9. 回到步骤1                                   │
  └─────────────────────────────────────────────────┘
```

**关键约束：**
- **每轮分发前必须从进度文件读取"⏳未开始"列表**，不从内存或硬编码获取
- **每个子agent完成后立即更新进度文件**，不等批量
- **中断可续**：子agent中断后，"🔄进行中"的行在下一轮开始前（步骤3）改回"⏳未开始"重试

### 步骤6：更新进度文件

每个子agent完成后立即更新进度文件中对应行（状态、文档路径、API数、备注），不等批量更新。每批5个全部返回后验证：✅已完成 + ❌失败 + 🔄进行中 + ⏳未开始 = 总Controller数。

### 步骤7：输出扫描报告

**双重校验（强制执行）：**

1. **进度文件校验**：读取进度文件，确认 `⏳未开始` + `🔄进行中` = 0（即所有Controller都已处理完毕）
2. **文件数校验**：统计 `docs/apidoc/` 目录下 `*Controller-API.md` 文件数，确认 = 进度文件中 `✅已完成` 数
3. **不一致处理**：如果两个数字不一致，列出差异（哪些Controller标记已完成但无文档，或有哪些文档但未标记），逐一处理直到一致

校验通过后输出摘要：

```
API文档扫描完成！
- 扫描模式: 全量/增量
- 总计: N个Controller
- 成功: M个
- 失败: K个
- 文档目录: docs/apidoc/
- 进度文件: docs/apidoc/api-scan-progress-YYYYMMDD.md
- 文档文件数: M（与成功数一致 ✓）
```

## API文档格式规范

每个Controller生成独立Markdown文件，命名：`{Controller类名}-API.md`

### 每个接口必须包含的字段

| 字段 | 说明 |
|------|------|
| 请求方法 | GET/POST/PUT/DELETE |
| 请求路径 | 基础路径+方法路径 |
| 请求参数 | 参数名、类型、必填、说明 |
| 请求头 | Content-Type、Authorization |
| 响应结构 | AjaxResult/TableDataInfo封装的响应体 |
| 响应示例 | 成功和失败的JSON示例 |
| 测试步骤 | 操作步骤描述 |
| 预期结果 | 期望的响应状态和数据 |
| 请求示例 | curl格式 |

### BaseController继承方法

Controller继承`BaseController`时，需额外文档化基础CRUD方法（list、getInfo、add、edit、remove）。使用步骤2a预生成的模板，替换占位符即可。如果Controller中已显式定义了同路径方法，以显式定义为准，不重复生成。

### AjaxResult/TableDataInfo响应结构

```json
// AjaxResult 普通响应
{ "code": 200, "msg": "操作成功", "data": { ... } }

// TableDataInfo 分页响应
{ "total": 100, "rows": [ ... ], "code": 200, "msg": "查询成功" }
```

## 关键规则

1. **禁止Glob扫描Controller列表** — 用Bash命令获取完整列表并验证总数
2. **模板必须从项目源码动态生成** — 不能硬编码BaseController方法或Domain基类字段，不同版本可能不同
3. **禁止子agent读取BaseController源码** — 使用预生成的baseMethodsDoc
4. **禁止子agent读取Domain基类源码** — 使用预生成的domainBaseFieldsDoc
5. **每个接口必须完整展开** — 禁止"2-6. 基础CRUD"等合并简写
6. **进度文件实时更新** — 每个子agent完成后立即更新，不等批量
7. **参数解析需读Domain类** — 不能仅依赖Controller方法签名
8. **并发控制** — 每批最多5个子agent
9. **日期格式** — 文件名用YYYYMMDD，文件内用YYYY-MM-DD HH:mm:ss
10. **进度文件必须从controller-list程序化生成** — 禁止手动编写进度清单
11. **分发子agent必须从进度文件读取待处理列表** — 每轮分发前读取进度文件筛选"⏳未开始"行
12. **最终双重校验** — 进度文件✅已完成数 = 实际生成的文档文件数
13. **中断可续** — 子agent中断后，"🔄进行中"的行在下一轮开始前改回"⏳未开始"重试
14. **⛔ 子agent源码读取范围限制** — 子agent读取Controller源码和Domain类时，仅允许读取项目根目录下的文件，禁止读取项目目录外的任何内容
15. **⛔ 子agent无需检查 `docs/apidoc/` 目录是否存在** — 该目录由主agent在步骤4中已创建
