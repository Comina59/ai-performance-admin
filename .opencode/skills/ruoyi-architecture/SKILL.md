---
name: ruoyi-architecture
description: RuoYi 项目架构与模块落点速查。遇到“代码该放哪/改动影响哪些模块/启动入口与配置在哪”时调用。
allowed-tools: Read, Grep
---

# RuoYi Architecture

用于快速对齐 RuoYi 项目的模块职责、代码落点与关键约束，帮助做出“最小改动、正确落点”的决策。

## 适用场景

- 不确定新接口/新业务逻辑应该落在哪个模块
- 不确定 MyBatis Mapper XML 应放置位置与扫描规则
- 需要快速确认启动入口、配置文件位置、生成器模块位置

## 项目事实（以本仓库为准）

- 启动入口：`ruoyi-admin` 模块下 `com.ruoyi.RuoYiApplication`
- 统一响应：`AjaxResult`（普通接口）、`TableDataInfo`（分页列表）
- 权限控制：`@PreAuthorize("@ss.hasPermi('xxx:yyy:zzz')")`
- MyBatis：
  - 别名：`com.ruoyi.**.domain`
  - XML：`classpath*:mapper/**/*Mapper.xml`
- 代码生成：`ruoyi-generator`，路由前缀 `/tool/gen`

