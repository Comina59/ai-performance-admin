---
name: ruoyi-generator
description: RuoYi 代码生成（ruoyi-generator）使用与合入规范。需要生成 CRUD、导入表或处理 allowOverwrite 时调用。
allowed-tools: Read, Grep
---

# RuoYi Generator

## 关键事实（参考）

- 生成器路由前缀：`/tool/gen`
- 默认配置：`generator.yml` 中 `gen.allowOverwrite=false`

## 推荐流程

- 推荐：下载 zip → 解压 → 合入对应模块 → 校对权限/分页/Mapper XML 路径
- 落盘生成：仅在 `gen.allowOverwrite=true` 时允许（否则必须视为失败并停止）

