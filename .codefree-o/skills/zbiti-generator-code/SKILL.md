---
name: zbiti-generator-code
description: RuoYi项目代码生成器配置与执行管理。用于自动配置generator-code模块的pom.xml，从yml文件获取数据库连接信息，自动处理序列创建，并执行代码生成。使用场景包括：1)配置代码生成器的pom.xml数据库连接信息，2)自动创建PostgreSQL/Oracle序列，3)执行代码生成命令，4)生成代码后通过zbiti-modules-create-agent迁移代码到ruoyi-modules下的业务子模块。当用户提到"代码生成"、"生成代码"、"generator"、"建表后生成"、"自动生成CRUD"等关键词时，均应触发此skill。
---

# ZBITI Generator Code（RuoYi 适配版）

代码生成器配置与执行管理工具，用于 RuoYi 框架 Maven+Spring Boot 项目的代码自动生成。

## 核心功能

### 1. 数据库配置自动填充

从项目的 yml 配置文件中自动提取数据库连接信息，填充到 `generator-code/pom.xml` 中。

**配置来源：**
- 主配置文件：`ruoyi-admin/src/main/resources/application.yml`
- 激活的 profile：通过 `spring.profiles.active` 确定（RuoYi 默认为 `druid`）
- 数据源配置：`ruoyi-admin/src/main/resources/application-druid.yml`

**配置映射规则：**

| pom.xml 配置项 | yml 配置路径 | 说明 |
|---------------|-------------|------|
| `driverName` | `spring.datasource.druid.master.driverClassName` 或 `spring.datasource.driverClassName` | JDBC 驱动类名 |
| `url` | `spring.datasource.druid.master.url` | 数据库连接 URL |
| `username` | `spring.datasource.druid.master.username` | 数据库用户名 |
| `password` | `spring.datasource.druid.master.password` | 数据库密码 |

**数据库类型识别：**

通过 `driverClassName` 或 URL 前缀判断：

| 数据库类型 | driverClassName | URL 前缀 |
|-----------|----------------|---------|
| MySQL | `com.mysql.cj.jdbc.Driver` | `jdbc:mysql://` |
| PostgreSQL | `org.postgresql.Driver` | `jdbc:postgresql://` |
| Oracle | `oracle.jdbc.OracleDriver` | `jdbc:oracle:` |

**JDBC 驱动依赖补充：**

根据数据库类型自动添加对应的 JDBC 驱动依赖到 pom.xml 的 `<dependencies>` 节点：

```xml
<!-- MySQL驱动（RuoYi默认） -->
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
    <version>8.0.33</version>
</dependency>

<!-- PostgreSQL驱动 -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.6.0</version>
</dependency>

<!-- Oracle驱动 -->
<dependency>
    <groupId>com.oracle</groupId>
    <artifactId>ojdbc6</artifactId>
    <version>11.2.0.3</version>
</dependency>
```

### 2. 序列自动管理

对于 PostgreSQL 和 Oracle 数据库，自动处理序列的创建。MySQL 不需要序列。

**序列命名规则：**
- 默认格式：`SEQ_表名`（表名转大写）
- 用户自定义：如果用户提供了序列名，以用户输入为准（最高优先级）

**序列创建流程：**

1. **检查序列是否存在**
   - PostgreSQL：`SELECT sequence_name FROM information_schema.sequences WHERE sequence_name = '序列名'`
   - Oracle：`SELECT sequence_name FROM user_sequences WHERE sequence_name = '序列名'`

2. **创建序列（如果不存在）**
   - PostgreSQL：
     ```sql
     CREATE SEQUENCE SEQ_表名
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;
     ```
   - Oracle：
     ```sql
     CREATE SEQUENCE SEQ_表名
     START WITH 1
     INCREMENT BY 1
     NOCACHE
     NOCYCLE;
     ```

**pom.xml 中的序列配置：**

```xml
<tableConfig>
    <table>表名</table>
    <sequence>SEQ_表名</sequence>
    <requestMapping>/业务域/实体</requestMapping>
</tableConfig>
```

### 3. pom.xml 配置项说明

**核心配置项：**

| 配置项 | 必填 | 默认值 | 说明 |
|-------|------|--------|------|
| `outputDir` | 否 | `${project.basedir}/generate/main/java` | 代码输出目录 |
| `fileOverride` | 否 | `false` | 是否覆盖同名文件 |
| `generateOnly` | 否 | `false` | 是否只生成 generate 文件 |
| `generateMdaDomain` | 否 | `false` | 是否生成 MdaDomain 文件（**强制为 false，不允许设置为 true**） |
| `generateVue` | 否 | `false` | 是否生成 VUE 文件（RuoYi 前端独立，默认关闭） |
| `generateVueVersion` | 否 | `3` | 生成 vue 文件版本 |
| `author` | 否 | `generator` | 开发者名称 |
| `dataSource` | 是 | - | 数据源配置（必配） |
| `strategy` | 是 | - | 生成策略配置 |
| `packageInfo` | 是 | - | 生成包信息配置（必配，决定代码归属模块） |

**数据源配置（dataSource）：**

```xml
<dataSource>
    <driverName>com.mysql.cj.jdbc.Driver</driverName>
    <url>jdbc:mysql://host:port/database?useUnicode=true&amp;characterEncoding=utf8&amp;useSSL=true&amp;serverTimezone=GMT%2B8</url>
    <username>用户名</username>
    <password>密码</password>
</dataSource>
```

**生成策略配置（strategy）：**

```xml
<strategy>
    <!-- 字段命名策略：nochange/underline_to_camel/remove_prefix/remove_prefix_and_camel -->
    <naming>underline_to_camel</naming>

    <!-- 表前缀（可选，RuoYi常用如 sys_） -->
    <tablePrefix>sys_</tablePrefix>

    <!-- ID生成策略（可选）：id_worker/uuid -->
    <idGenType>id_worker</idGenType>

    <!-- 要包含的表（与exclude二选一） -->
    <include>
        <property>表名</property>
    </include>

    <!-- 要排除的表（可选） -->
    <exclude>
        <property>schema_version</property>
    </exclude>

    <!-- 表配置信息 -->
    <tableConfigs>
        <tableConfig>
            <table>表名</table>
            <sequence>SEQ_表名</sequence>
            <requestMapping>/业务域/实体</requestMapping>
        </tableConfig>
    </tableConfigs>
</strategy>
```

**包信息配置（packageInfo）—— RuoYi 关键配置：**

包名必须与目标业务子模块的包路径一致，格式为 `com.ruoyi.{业务域}`：

```xml
<packageInfo>
    <parent>com.ruoyi.performance</parent>
</packageInfo>
```

生成的代码包结构：
```
com.ruoyi.{业务域}
├── domain/          ← 实体类（生成后需调整为继承 BaseEntity）
│   └── Xxx.java
├── mapper/          ← Mapper 接口
│   └── XxxMapper.java
├── service/         ← Service 接口与实现
│   ├── IXxxService.java
│   └── impl/
│       └── XxxServiceImpl.java
└── controller/      ← Controller（生成后需调整为 RuoYi 风格）
    └── XxxController.java
```

### 4. 代码生成执行

**执行方式一：IDEA 图形化界面**

1. 打开 IDEA 右侧 Maven 面板
2. 展开 `generator-code` -> `plugins`
3. 点击 `zbiti-generator:code` 执行

**执行方式二：命令行执行（推荐）**

**重要提示：** 代码生成命令必须使用 `zbiti-generator:code`，**严禁使用** `zbiti-generator:generate` 或其他变体命令。

***Linux / macOS***
```bash
cd generator-code && mvn zbiti-generator:code
```

*** Windows (cmd)***
```cmd
cd generator-code && mvn zbiti-generator:code
```

*** Windows (PowerShell)***
```powershell
cd generator-code; mvn zbiti-generator:code
```

**生成代码位置：**

- 默认输出目录：`generator-code/generate/main/java/`
- 生成的代码包括：Entity、Mapper、Service、Controller 等

### 5. 代码迁移（RuoYi 适配）

代码生成完成后，需要将代码迁移到 `ruoyi-modules/{业务域}/` 下的业务子模块中。

**迁移流程：**

1. 确认目标业务子模块已存在（若不存在，先由 `zbiti-modules-create-agent` 创建）
2. 将生成的代码文件移动到对应的模块目录
3. **RuoYi 风格适配**（关键步骤）：
   - Domain 类：调整为继承 `BaseEntity`（而非 GeneratorDomain）
   - Controller 类：调整为返回 `AjaxResult` / `TableDataInfo`，添加 `@PreAuthorize` 权限注解
   - Service 类：调整为 RuoYi 的 Service 接口模式
   - Mapper XML：放置到 `resources/mapper/{业务域}/` 目录下
4. 更新包名和导入语句

**迁移目标目录结构：**

```
ruoyi-modules/{业务域}/
└── src/main/
    ├── java/com/ruoyi/{业务域}/
    │   ├── controller/     ← @RestController + @PreAuthorize
    │   ├── domain/         ← 继承 BaseEntity
    │   ├── mapper/         ← Mapper 接口
    │   └── service/        ← 接口与实现
    │       └── impl/
    └── resources/
        └── mapper/{业务域}/  ← Mapper XML
```

## 使用流程

### 完整工作流程

1. **获取数据库配置**
   - 读取 `ruoyi-admin/src/main/resources/application.yml` 确定激活的 profile
   - 读取 `ruoyi-admin/src/main/resources/application-druid.yml` 提取数据源信息
   - 识别数据库类型

2. **配置 pom.xml**
   - 填充 `dataSource` 配置
   - 补充 JDBC 驱动依赖
   - 配置 `strategy`（含表名、命名策略、表前缀）
   - 配置 `packageInfo`（包名 = `com.ruoyi.{业务域}`）
   - 设置 `tableConfigs`（包括序列配置，MySQL 可省略序列）
   - **确保 `generateMdaDomain` 设置为 `false`（强制约束）**
   - **确保 `generateVue` 设置为 `false`（RuoYi 前端独立管理）**

3. **处理序列（PostgreSQL/Oracle）**
   - 连接数据库
   - 检查序列是否存在
   - 不存在则创建序列

4. **执行代码生成**
   - 使用命令行执行 `mvn zbiti-generator:code`
   - 等待生成完成

5. **迁移代码到 ruoyi-modules**
   - 确认目标业务子模块存在（不存在则先创建）
   - 将生成的代码迁移到 `ruoyi-modules/{业务域}/` 对应目录
   - 执行 RuoYi 风格适配（详见第5节）
   - 更新 `ruoyi-admin/pom.xml` 添加对业务子模块的依赖

## 配置优先级

配置项的优先级从高到低：

1. **用户明确输入** - 最高优先级
2. **自动生成的合理默认值** - 中等优先级
3. **pom.xml 中的现有配置** - 最低优先级

**强制约束：**
- `generateMdaDomain` 必须始终为 `false`，**不允许设置为 true**，此约束具有最高优先级
- `generateVue` 在 RuoYi 项目中默认为 `false`，除非用户明确要求生成 Vue 文件

## 特殊字符转义

在 pom.xml 中需要注意 XML 特殊字符的转义：

| 原字符 | 转义后 |
|--------|--------|
| `<` | `&lt;` |
| `>` | `&gt;` |
| `&` | `&amp;` |
| `'` | `&apos;` |
| `"` | `&quot;` |

**RuoYi MySQL URL 常见转义示例：**

```xml
<!-- 错误 -->
<url>jdbc:mysql://host:port/db?useUnicode=true&characterEncoding=utf8&useSSL=true</url>

<!-- 正确 -->
<url>jdbc:mysql://host:port/db?useUnicode=true&amp;characterEncoding=utf8&amp;useSSL=true</url>
```

## 常见场景

### 场景1：为单个表生成代码（MySQL）

```xml
<include>
    <property>perf_indicator</property>
</include>

<tableConfigs>
    <tableConfig>
        <table>perf_indicator</table>
        <requestMapping>/performance/indicator</requestMapping>
    </tableConfig>
</tableConfigs>

<packageInfo>
    <parent>com.ruoyi.performance</parent>
</packageInfo>
```

### 场景2：为多个表生成代码

```xml
<include>
    <property>perf_indicator</property>
    <property>perf_score</property>
    <property>perf_template</property>
</include>

<tableConfigs>
    <tableConfig>
        <table>perf_indicator</table>
        <requestMapping>/performance/indicator</requestMapping>
    </tableConfig>
    <tableConfig>
        <table>perf_score</table>
        <requestMapping>/performance/score</requestMapping>
    </tableConfig>
    <tableConfig>
        <table>perf_template</table>
        <requestMapping>/performance/template</requestMapping>
    </tableConfig>
</tableConfigs>
```

### 场景3：PostgreSQL 表带序列

```xml
<tableConfigs>
    <tableConfig>
        <table>perf_indicator</table>
        <sequence>SEQ_PERF_INDICATOR</sequence>
        <requestMapping>/performance/indicator</requestMapping>
    </tableConfig>
</tableConfigs>
```

### 场景4：排除某些表

```xml
<exclude>
    <property>schema_version</property>
    <property>flyway_schema_history</property>
</exclude>
```

## 注意事项

1. **数据库连接**：确保数据库服务可访问，用户名密码正确
2. **序列创建**：PostgreSQL/Oracle 需要数据库有创建序列的权限；MySQL 不需要序列
3. **文件覆盖**：`fileOverride=true` 会覆盖已存在的文件，谨慎使用
4. **包名配置**：`packageInfo.parent` 必须为 `com.ruoyi.{业务域}` 格式，与 ruoyi-modules 子模块包路径一致
5. **依赖管理**：确保 pom.xml 中包含正确的 JDBC 驱动依赖
6. **特殊字符**：注意 XML 中的特殊字符转义，特别是 URL 中的 `&` 符号
7. **generateMdaDomain 强制约束**：必须始终设置为 `false`
8. **代码生成命令**：必须使用 `zbiti-generator:code`，严禁使用其他变体命令
9. **RuoYi 风格适配**：生成代码后必须进行 RuoYi 风格适配（BaseEntity、AjaxResult、@PreAuthorize 等），详见第5节
10. **Mapper XML 路径**：迁移后 Mapper XML 必须放在 `resources/mapper/{业务域}/` 下，匹配 `classpath*:mapper/**/*Mapper.xml` 扫描规则

## 相关技能

- **ruoyi-architecture**：RuoYi 项目架构落点、Controller 规范、MyBatis 约定
- **zbiti-modules-create-agent**：用于创建 ruoyi-modules 下的业务子模块

## 参考文档

- **[pom.xml 配置参考](references/pom-config-reference.md)**：完整的 pom.xml 模板、数据库配置示例、字段命名策略、序列创建 SQL、requestMapping 配置规则、包名配置示例和常见问题解答
- **[工作流程参考](references/workflow.md)**：详细的代码生成工作流程、步骤说明、RuoYi 风格适配指南、快速开始示例、故障排查和最佳实践
