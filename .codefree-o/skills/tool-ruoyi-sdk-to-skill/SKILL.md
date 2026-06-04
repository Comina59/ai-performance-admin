---
name: tool-ruoyi-sdk-to-skill
description: 
  将Java项目转换为SKILL.md文件的工作流。当用户需要将Java项目转成skill、为Java项目生成代码知识库、
  或提到"项目转skill"、"生成skill"、"Java项目知识库"、"把SDK做成skill"等关键词时，应使用此skill。
  即使用户只是说"帮我把这个项目做成skill"、"为这个SDK生成skill"、"把这个Java项目转成知识库"，
  也应触发此skill。
---

# Java项目SKILL生成指南

将Java项目转换为SKILL.md文件，生成模块级类索引表格和MCP工具使用说明。

此skill需要配合 **skill-creator** skill 使用。调用 skill-creator 进入其工作流后，按以下步骤执行。

## 前置条件：获取Maven GA坐标

GA坐标是SKILL的必要元素，必须由用户提供。如果用户未提供，**必须先询问用户**，不可跳过。

需要用户提供的信息：
- **groupId**（如 `com.ruoyi`）
- **artifactId**（如 `ruoyi-common`）

获取后写入SKILL的Maven坐标区，格式为：
```xml
<dependency>
  <groupId>{groupId}</groupId>
  <artifactId>{artifactId}</artifactId>
</dependency>
```

## SKILL包含的必要元素

1. SKILL的元数据（name、description）
2. Maven GA坐标（用户输入，格式如上）
3. 模块级类索引表格（按模块分组，表格列：类名、作用、extends/implements）
4. MCP代码读取工具说明

**不需要**：类依赖关系树形图、import路径列。模块级类索引中已包含extends/implements信息，无需额外展示多层级依赖；import路径通过MCP工具按需获取，无需在SKILL中存储。

**重要**：类索引表格中的"作用"列是类作用的唯一来源，MCP工具不返回类作用描述，因此该列不可省略或删除。

## 处理流程

### 第一步：确认GA坐标

检查用户是否已提供GA坐标。若未提供，必须询问用户，等待用户输入后再继续。

### 第二步：主agent收集项目元信息

主agent直接读取以下文件（不交给子agent）：
- 根目录 pom.xml → 提取模块列表（若无子模块，整个项目视为一个模块）
- 各子模块 pom.xml → 提取子模块artifactId

### 第三步：主agent生成真实Java文件清单并统计行数

主agent使用文件搜索工具（如glob **/*.java），获取项目中所有Java文件的完整路径列表。

**排除规则**：路径中包含 `/test/` 或 `\test\` 的文件一律排除，只保留 `src/main/java` 下的类。glob搜索时即应过滤，而非事后剔除。

将此列表保存为变量 `JAVA_FILE_LIST`，后续每一步都必须引用此列表。

**行数统计**：主agent使用Bash工具一次性统计所有文件行数，禁止逐文件使用Read工具。示例命令（已排除test目录）：
```powershell
Get-ChildItem -Recurse -Filter *.java | Where-Object { $_.FullName -notmatch '\\test\\|/test/' } | ForEach-Object { "$($_.FullName) $((Get-Content $_.FullName -Encoding UTF8 | Measure-Object -Line).Lines)" }
```
生成 `(文件路径, 行数)` 的列表，按模块分组汇总每模块总行数。此数据用于第四步分批，以及子agent批量读取时的分批参考（每次Bash调用总行数不超过3000行）。

### 第四步：按模块+行数分批派发子agent处理Java类

**分批策略**（按优先级）：

1. **按模块分组**：同一模块的类优先分配给同一个子agent，因为同类模块的类之间有上下文关联，子agent能更准确理解类的作用。
2. **按行数控制批次大小**：每个子agent分配的文件总行数上限为 **8000行**。若某模块总行数 ≤ 8000，该模块作为一个完整批次；若超过 8000 行，则按包路径拆分为多批，每批总行数尽量接近但不超过 8000 行。
3. **大文件单独成批**：若单个文件行数 > 8000 行，该文件单独成为一个批次，并在子agent prompt中标注 `[该文件行数较多，批量读取时请确保完整输出]`。

**示例**：
- 模块A（共5000行，8个文件）→ 1个批次
- 模块B（共15000行，20个文件）→ 拆为2批（如 8000行+7000行）
- 模块C中某文件有 12000 行 → 单独1个批次

**每个子agent的prompt必须包含以下内容**（完整模板见 [references/sub-agent-prompt.md](references/sub-agent-prompt.md)，主agent将模板中的占位符替换为实际值后派发）：

- 文件读取方式：要求子agent使用Bash批量cat，每批总行数≤3000，文件间加 `=== FILE: 路径 ===` 分隔符
- 必须处理的文件列表 + 文件行数表
- 作用描述要求（含好/差示例）
- extends/implements列填写规则
- 严格规则（禁止虚构、按分隔符区分文件等）

### 第五步：主agent汇总并生成SKILL.md

1. 合并所有子agent的输出
2. 去重检查：对照 `JAVA_FILE_LIST`，确保没有虚构的类
3. 按 [references/output-template.md](references/output-template.md) 中的结构组织SKILL.md
4. 将生成的SKILL.md写入文件

### 第六步：质量自检

SKILL.md生成后，主agent必须执行以下自检，全部通过后方可交付。若某项不通过，修复后重新检查该项。

**格式校验**：
1. 调用 skill-creator 对生成的SKILL.md进行校验，确认通过
2. 确认YAML frontmatter中包含 `name` 和 `description`

**内容完整性校验**：
3. 从生成的SKILL.md中提取所有类名，与 `JAVA_FILE_LIST` 中的文件名（去掉.java后缀）做对比：
   - 若SKILL.md中多出类名 → 标记为疑似虚构，核实后删除
   - 若 `JAVA_FILE_LIST` 中的类未出现在SKILL.md → 标记为遗漏，补充该类的索引行
4. 确认Maven GA坐标区包含用户提供的 groupId 和 artifactId
5. 确认MCP工具使用说明区存在且包含三个方法的描述

**描述质量抽检**：
6. 随机抽取3-5个类，使用Bash批量读取其源码（参考第四步的批量读取方式），验证SKILL.md中的作用描述是否与源码一致：
   - 若描述仅复述类名（如"XXX类"、"XXX工具类"），标记为不合格，重新总结
   - 若描述与源码不符，标记为错误，重新总结

**自检结果输出**：向用户报告自检结果，格式：
```
质量自检报告：
- 格式校验：通过/未通过（原因）
- 类索引完整性：X/Y 个类已收录，遗漏 N 个，虚构 M 个（已处理）
- Maven坐标：通过/缺失
- MCP工具说明：通过/缺失
- 描述质量抽检：抽检 X 个，合格 X 个，不合格 N 个（已修复）
```

## SKILL.md 结构规范

详细模板见 [references/output-template.md](references/output-template.md)，包含四个区：

1. **元数据区**：YAML front matter（name + description）
2. **Maven坐标区**：用户提供的GA坐标，XML格式
3. **模块级类索引区**：按模块分组的表格（列：类名 | 作用 | extends/implements）
4. **MCP工具使用说明区**：zbiti-code-reader 的使用说明及调用原则

## 禁止规则

1. 禁止将类的具体源代码内容写入SKILL
2. 禁止虚构不存在的Java类
3. 禁止虚构类的作用
4. 禁止在不读取Java类的情况下，就做出作用总结
5. 禁止子agent处理不在其分配文件列表中的文件
6. 禁止在类索引中出现项目里不存在的类
7. 禁止包含test目录下的Java类
8. 禁止在类索引中列出import路径（只需类名）
9. 禁止添加类依赖关系树形图（模块级索引已包含extends/implements信息）
10. 禁止在用户未提供GA坐标的情况下跳过询问直接继续
