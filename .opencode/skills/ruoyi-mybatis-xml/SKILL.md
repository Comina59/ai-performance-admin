---
name: ruoyi-mybatis-xml
description: RuoYi MyBatis Mapper/Mapper XML 规范与排错清单。涉及 SQL、Mapper 方法、XML 扫描或别名问题时调用。
allowed-tools: Read, Grep
---

# RuoYi MyBatis XML

## 项目扫描约定（以本仓库配置为准）

- `mybatis.mapperLocations = classpath*:mapper/**/*Mapper.xml`
- `mybatis.typeAliasesPackage = com.ruoyi.**.domain`

## 规范要点

- ⛔ SQL 必须落在 Mapper XML，禁止在 Java 代码中写 SQL
- Mapper 接口方法名 ↔ XML id 必须一致
- XML namespace 必须是 Mapper 接口全限定名
- 优先使用 `#{}`，避免 `${}` 注入风险

## 快速排错

- `Invalid bound statement`：检查 XML 路径、namespace、id 是否对齐
- `Type alias`：检查 domain 是否在 `com.ruoyi.**.domain`

