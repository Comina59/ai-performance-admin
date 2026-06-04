---
name: tool-ruoyi-component-version
description: "识别RuoYi平台组件依赖及每个组件的具体版本。从项目POM读取平台版本号，通过effective-pom解析BOM获取所有com.ruoyi组件的artifactId与version，输出为ruoyi-dependencies.md。⛔ 本技能仅当用户明确指定调用时才可触发，禁止自动调用。当用户主动提及'查看组件版本'、'列出RuoYi组件'、'tool-ruoyi-component-version'、'识别平台组件依赖'等明确意图时才触发，不应在初始化、升级或其他流程中自动附带触发。"
---

# RuoYi 平台组件版本识别

从项目 POM 读取 RuoYi 平台版本号，通过 effective-pom 解析 BOM 获取所有 `com.ruoyi` 组件依赖及其具体版本，输出为 `ruoyi-dependencies.md`。

## 步骤 1：读取根 POM 提取版本号

找到根 `pom.xml`（含 `<modules>` 或 `<parent>` 指向 `ruoyi` 的顶层 POM），提取：

- **平台版本**：`properties/ruoyi.version`（核心版本号，取完整值不截取）
- **Parent 版本**：`parent/version`（当 artifactId 为 `ruoyi` 时）

未找到 `ruoyi.version` 则检查子模块 POM，仍无则提示非 RuoYi 项目。

## 步骤 2：解析 BOM 组件版本 → ruoyi-dependencies.md

执行 effective-pom 过滤 `com.ruoyi` 依赖（以 groupId 为锚点捕获 groupId + artifactId + version 三行一组）：

```powershell
# Windows
mvn help:effective-pom -N 2>$null | Select-String -Pattern "<groupId>com\.ruoyi" -Context 0,2 | Out-String -Width 500
# Linux/Mac
mvn help:effective-pom -N 2>/dev/null | grep -A2 "<groupId>com\.ruoyi"
```

Maven 不可用时回退到仅输出步骤1结果并提示。

将过滤结果整理为 Markdown 表格（含 groupId、artifactId、version 三列），写入项目根目录 `ruoyi-dependencies.md`（与 pom.xml 同级，已存在则覆盖），文件头部注明平台版本号和生成时间。

## 步骤 3：Git 跟踪

```bash
git add ruoyi-dependencies.md
```

如 `.gitignore` 中有对应条目，先移除或使用 `git add -f`。仅 add 不 commit。

## 步骤 4：输出结果

输出平台版本号、Parent 版本、组件数量及 `ruoyi-dependencies.md` 文件路径。
