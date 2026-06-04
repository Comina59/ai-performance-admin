---
description: RuoYi 通用 Harness 开发规则（OpenCode 体系独立副本）。强调 Superpowers 工作流（门控+计划+日志），并约束 skills/agents 的调用与代码落点规范。
---

# 最高准则：核心开发方法论（Superpowers 工作流深度融合）

## 首要原则

**收到任何开发任务时，必须严格按照下文阶段流转，启用每阶段的【入口自检】与【出口自检】机制。门控阶段未通过时，任何实施动作均禁止。**

> 主Agent定位：**编排者，非实施者**。主Agent负责调度、状态同步、自审、决策；批量探索、批量编写由子Agent或 skill 工具完成。
>
> **主Agent 可直接 Read 的文件白名单**：
> - Plan 文档（`docs/plans/*-plan.md`）
> - 执行日志（`docs/plans/*-execution-log.md`）
> - 设计文档（`docs/plans/*-design.md`、`*-API-*-design.md`）
> - 配置文件（`*.yml`、`*.xml`（pom）、`.opencode/**`、`AGENTS.md`）
> - 用户在对话中直接粘贴 / 上传的代码片段
>
> **框架适配：RuoYi（本仓库）**
> - 启动入口：`com.ruoyi.RuoYiApplication`（模块：`ruoyi-admin`）
> - 统一响应：`AjaxResult`（普通接口）、`TableDataInfo`（分页列表）
> - 权限控制：`@PreAuthorize("@ss.hasPermi('xxx:yyy:zzz')")`
> - MyBatis：别名 `com.ruoyi.**.domain`，XML `classpath*:mapper/**/*Mapper.xml`
> - 代码生成：`ruoyi-generator`，路由前缀 `/tool/gen`
>
> ⛔ 仍然禁止：主Agent批量扫描业务源码、一次性读完整 Service/Controller。批量探索必须走 `zbiti-code-reader`，且读取路径必须位于任一模块的 `src/main/` 下。

---

## 阶段门控（0-4）

### 阶段0：需求范围审查

- 目标：单功能原则；复杂需求必须拆分
- 出口：给出“允许/阻断”结论与理由

### 阶段1：构思设计（Brainstorming）

- 目标：至少 2 种方案对比 + 选型理由 + 风险点
- 本地探索：若需要读源码，必须经由 `zbiti-code-reader`（先 tree 再筛 1-3 个文件）

### 阶段2：制定实施计划（Plan）

- 目标：任务拆分表（涉及文件、验证标准、依赖、可并行性）
- 强制：创建 execution-log 骨架，用于压缩恢复

### 阶段3：实施（子Agent驱动）

- 所有编码任务必须两层审查（规范一致性 + 代码质量）
- 完成前强制验证（编译/测试按 verifier 规范执行）

### 阶段4：完成与交付

- 汇总变更点、验证结果、回滚建议

---

## 全局约束（RuoYi）

- ⛔ Controller / Service 中禁止写 SQL，SQL 必须落在 Mapper XML
- Mapper XML 路径必须匹配：`classpath*:mapper/**/*Mapper.xml`
- 新增/修改接口必须按现有风格返回 `AjaxResult` / `TableDataInfo`，并补齐 `@PreAuthorize` 权限控制
- ⛔ 禁止在任何输出中泄露配置中的凭据类字段（token secret、Redis 密码等），必须脱敏或省略

---

## 子Agent路由协议（精简版）

| 触发场景 | 调度方式 | 说明 |
|----------|----------|------|
| 需要建表 / 执行 SQL | 子agent:`zbiti-database-operate-agent` | 数据库 DDL/DML |
| RuoYi 代码生成与合入模块 | 子agent:`general` | 默认下载 zip；合入后校对 package/权限/Mapper XML |
| 编写业务代码 | 子agent:`zbiti-business-code-agent` | Controller/Service/Mapper/XML 联动实现 |
| 代码审查与修复 | 子agent:`zbiti-code-fix-agent` | 两层审查后的修复 |
| 编译 / 测试验证 | 子agent:`zbiti-verifier-agent` | Maven 编译与测试（输出精简报告） |
| 读取本地代码摘要 | skill:`zbiti-code-reader` | 主Agent禁止批量 Read 业务源码 |

