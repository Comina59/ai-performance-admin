---
name: ruoyi-architecture
description: RuoYi 项目架构落点、Controller 规范、MyBatis 约定与验证命令速查。当需要判断"代码放哪个模块"、"Controller 怎么写才合规"、"Mapper XML 放哪/怎么排错"、"mvn 验证用什么命令"、"ruoyi-modules 目录不存在怎么办"时调用本 Skill。即使只是想确认某个注解或配置的用法，也应先查本 Skill 再动手。
allowed-tools: Read, Grep, Bash
---

# RuoYi Architecture & Conventions

本 Skill 是 `zbiti-code-rules.md` 的**项目事实补充**，提供 RuoYi 框架层面的模块落点、编码约定、MyBatis 规范和验证命令。zbiti-code-rules 管控开发流程与方法论，本 Skill 管控 RuoYi 项目的技术事实——二者互补，不重复。

## 一、模块职责与代码落点

不确定新代码该放哪时，按以下规则判断：

| 模块 | 职责 | 可存放 | 禁止存放 |
|------|------|--------|----------|
| `ruoyi-admin` | Web 启动入口 | `RuoYiApplication`、`application.yml`、全局配置 | 任何业务 Controller |
| `ruoyi-system` | 系统基础域 | 用户/角色/菜单/部门/岗位/字典/参数/通知公告的 Domain/Service/Mapper | 业务功能代码 |
| `ruoyi-modules` | 业务功能落点 | 按业务域创建子模块（如 `ruoyi-modules/performance`），每个子模块含完整 MVC | 跨模块分散存放同一业务的代码 |
| `ruoyi-framework` | 基础设施 | 安全、过滤器、MyBatis 装配、全局配置 | 业务逻辑 |
| `ruoyi-quartz` | 定时任务 | 定时任务 domain/service/mapper | 非定时任务代码 |
| `ruoyi-common` | 通用工具 | 工具类、常量、枚举、基础结构 | 业务逻辑 |

### 业务子模块内部结构（ruoyi-modules 下的每个子模块必须遵循）

```
ruoyi-modules/{业务域}/
├── pom.xml
└── src/main/
    ├── java/com/ruoyi/{业务域}/
    │   ├── controller/     ← @RestController + @PreAuthorize 鉴权
    │   ├── domain/         ← 实体 / VO / BO / DTO
    │   ├── mapper/         ← Mapper 接口
    │   └── service/        ← 接口与实现
    │       └── impl/
    └── resources/
        └── mapper/{业务域}/  ← Mapper XML
```

### 最小化确认清单

1. 从根 `pom.xml` 的 `<modules>` 确认模块存在性与名称
2. Controller 必须在 `ruoyi-modules/.../controller/` 下
3. SQL 必须拆到 `mapper/` 接口 + `resources/mapper/**/*Mapper.xml`
4. 涉及 `ruoyi-framework` 的改动优先级最高、风险最高，需额外审慎

### ruoyi-modules 自动创建规则（⛔ 强制）

当项目中**不存在** `ruoyi-modules` 目录时，`zbiti-modules-create-agent` 必须自动执行以下步骤：

1. **创建 `ruoyi-modules/pom.xml`**（聚合 POM）：
   - `parent` → `com.ruoyi:ruoyi`（根项目）
   - `artifactId` → `ruoyi-modules`
   - `packaging` → `pom`
   - `<modules>` 中声明所有业务子模块

2. **在根 `pom.xml` 的 `<modules>` 中添加 `<module>ruoyi-modules</module>`**

3. **在根 `pom.xml` 的 `<dependencyManagement>` 中添加子模块依赖声明**

4. **在 `ruoyi-admin/pom.xml` 中添加对业务子模块的依赖**

5. **业务子模块的 `parent` 指向 `ruoyi-modules`**（不是根项目），`artifactId` 格式为 `ruoyi-modules-{业务域}`

⛔ **禁止**：在根目录平级创建业务模块（如 `ruoyi-performance/`），所有业务模块必须在 `ruoyi-modules/` 下

## 二、Controller 编写规范

### 统一响应

| 场景 | 返回类型 | 说明 |
|------|----------|------|
| 普通接口（增删改、单条查询） | `AjaxResult` | `AjaxResult.success()` / `AjaxResult.error()` |
| 分页列表 | `TableDataInfo` | 通过 `getDataTable(list)` 构造 |

### 分页

分页列表接口必须在查询前启动分页：

```java
startPage();  // BaseController 方法，设置 PageHelper 分页参数
List<XxxVo> list = xxxService.selectList(query);
return getDataTable(list);
```

分页参数由前端传入 `pageNum` 和 `pageSize`，`BaseController` 自动从请求中获取。

### 权限控制

管理类接口必须加权限注解：

```java
@PreAuthorize("@ss.hasPermi('module:entity:action')")
```

权限串命名规则：`模块:实体:操作`（如 `system:user:list`）。新增权限串时，先搜索同类 Controller 的既有权限串保持风格一致，再在菜单管理中配置对应权限。

### ICommonController 通用接口模式

本项目采用 `ICommonController` 通用 REST 控制器接口，标准 CRUD 操作（list/add/update/delete/get）应实现此接口，保持接口风格统一。API 分级规则见 zbiti-code-rules.md 阶段1。

### 操作日志

写操作接口建议加 `@Log` 注解记录操作日志：

```java
@Log(title = "用户管理", businessType = BusinessType.INSERT)
```

### 禁止事项

- 在 Controller 内直接写 SQL 或拼装复杂查询——业务逻辑下沉到 Service
- 缺失权限注解或使用过宽权限
- 将敏感配置（token secret、Redis 密码等）写入日志或返回体

## 三、MyBatis 规范与排错

### 扫描约定（以本仓库配置为准）

```yaml
mybatis:
  mapperLocations: classpath*:mapper/**/*Mapper.xml
  typeAliasesPackage: com.ruoyi.**.domain
```

### SQL 落点

SQL 必须写在 `resources/mapper/**/**Mapper.xml` 中，禁止在 Java 代码中写 SQL（包括字符串拼接）。

### Mapper 接口与 XML 对齐

| 检查项 | 要求 |
|--------|------|
| namespace | 必须是 Mapper 接口全限定名 |
| SQL id | 必须与 Mapper 接口方法名一致 |
| 参数引用 | `@Param` 注解名需与 XML 内 `#{}` 引用一致 |

### 安全要求

- 优先使用 `#{}` 预编译参数，避免 `${}` 引入注入风险
- 对可控排序/字段拼接等必须白名单化，不要直接拼用户输入

### 批量操作

使用 `<foreach>` 实现批量操作时，注意：
- `collection` 属性与 `@Param` 注解名一致
- 大批量数据需分批提交（建议每批 500-1000 条），避免 SQL 过长
- MySQL 需在连接 URL 加 `allowMultiQueries=true` 才支持多语句批量

### BaseEntity 基类

Domain 实体若继承 `BaseEntity`，自动拥有 `createBy`、`createTime`、`updateBy`、`updateTime`、`remark`、`params` 等公共字段。Mapper XML 中查询结果映射需包含这些字段，否则分页查询等场景会丢失数据。

### 快速排错清单

| 错误 | 排查步骤 |
|------|----------|
| `Invalid bound statement (not found)` | ① XML 是否在 `resources/mapper/` 下且路径匹配扫描规则 ② namespace 是否等于 Mapper 接口全名 ③ SQL id 是否与方法名一致 |
| `Type alias` 找不到 | Domain 是否位于 `com.ruoyi.**.domain` 下，或改用全限定名 |
| 扫描不到 XML | 多模块下检查资源目录是否被打包（`pom.xml` 中 `<resources>` 配置） |

## 四、验证命令速查

### 推荐命令

| 场景 | 命令 | 说明 |
|------|------|------|
| 全量验证 | `mvn -q test` | 慢但最稳 |
| 快速验证（推荐） | `mvn -q -pl ruoyi-admin -am test` | 只测启动模块及其依赖 |
| 仅编译 | `mvn -q -DskipTests clean compile` | 不跑测试 |
| 单模块验证 | `mvn -q -pl ruoyi-modules/{业务域} -am test` | 缩小范围到指定模块 |

> Windows 环境下上述命令直接在 PowerShell 中执行即可。

### 失败摘要规范

验证失败时，只输出以下信息（禁止输出整段 Maven 日志）：

1. 错误类型（编译/测试/环境）
2. 栈顶 1-3 个关键文件与行号
3. 最高优先级根因判断（1 条）
4. 建议修复动作（1-3 条）

禁止输出敏感配置值（密码/secret/token）。

## 五、项目关键配置速查

| 配置项 | 值 | 位置 |
|--------|-----|------|
| 启动入口 | `com.ruoyi.RuoYiApplication` | `ruoyi-admin` |
| 统一响应（普通） | `AjaxResult` | `ruoyi-common` |
| 统一响应（分页） | `TableDataInfo` | `ruoyi-common` |
| 权限控制 | `@PreAuthorize("@ss.hasPermi('xxx')")` | `ruoyi-framework` |
| MyBatis 别名包 | `com.ruoyi.**.domain` | `application.yml` |
| MyBatis XML 扫描 | `classpath*:mapper/**/*Mapper.xml` | `application.yml` |
