---
name: ruoyi-controller-pattern
description: RuoYi Controller 编写与统一响应/权限/分页规范。需要新增/修改接口或修复接口风格不一致时调用。
allowed-tools: Read, Grep
---

# RuoYi Controller Pattern

## 适用场景

- 新增/修改 REST 接口
- 修复返回结构不统一、分页不正确、权限缺失

## 规范要点

- 普通接口返回 `AjaxResult`
- 列表分页返回 `TableDataInfo`，并启动分页（通常 `BaseController.startPage()`）
- 管理类接口必须加 `@PreAuthorize("@ss.hasPermi('xxx:yyy:zzz')")`
- 禁止在 Controller 内写 SQL 或复杂业务逻辑

