---
name: ruoyi-verification
description: RuoYi 多模块 Maven 验证命令速查与失败摘要规范。需要编译/测试/定位失败根因时调用。
allowed-tools: Read, Grep
---

# RuoYi Verification

## 推荐命令

- 全量验证：`mvn -q test`
- 快速验证（推荐）：`mvn -q -pl ruoyi-admin -am test`
- 仅编译：`mvn -q -DskipTests clean compile`

## 输出约束

- 只输出关键错误摘要（文件/行号/错误类型）
- 禁止输出整段 `[INFO]` 日志
- 禁止输出敏感配置值（密码/secret/token）

