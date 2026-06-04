---
description: 扫描项目Controller类，生成API接口文档（Markdown格式）。当用户提到"生成API文档"、"扫描接口"、"接口文档"、"API扫描"、"接口扫描"、"API列表"等关键词时触发。
---
请开始为当前项目的controller生成文档。
通过 `skill` 工具激活 `tool-ruoyi-api-doc-scanner` 并严格按其步骤执行全流程。

## 执行方式

1. 通过 `skill` 工具加载 `tool-ruoyi-api-doc-scanner`，获取完整流程定义
2. 严格按 Skill 定义的步骤顺序执行，Skill 内容为唯一执行依据

## 与 Skill 的关系

- **Skill 为执行主体**：本命令仅负责触发和路由，所有流程细节、模板格式、子Agent指令模板均以 Skill 定义为准
- **禁止重复声明**：Skill 内已包含完整的约束规则，本命令不再重复列举，避免两份约束冲突导致执行歧义
- **冲突处理**：若本命令与 Skill 内容有矛盾，以 Skill 为准

## 命令级约束（Skill 未覆盖的部分）

- ⛔ 任务开始后静默完成所有步骤，中途不要求用户确认
- ⛔ 本命令的执行方式优先级高于 `zbiti-code-rules.md` 子Agent路由表中"生成前端API文档"行（路由表指向 `zbiti-doc-generator-agent`，本命令指向 `tool-ruoyi-api-doc-scanner` skill，二者用途不同：前者生成阶段4的前端对接文档，后者生成测试用例格式的API文档）
