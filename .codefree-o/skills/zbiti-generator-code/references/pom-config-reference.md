# Generator Code pom.xml 配置参考（RuoYi 适配版）

## 完整pom.xml模板

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <groupId>com.ruoyi</groupId>
        <artifactId>ai-performance-admin</artifactId>
        <version>3.9.2</version>
        <relativePath>../pom.xml</relativePath>
    </parent>
    <modelVersion>4.0.0</modelVersion>
    <name>代码生成工具【${project.artifactId}】</name>
    <artifactId>generator-code</artifactId>

    <build>
        <plugins>
            <!--代码生成器-->
            <plugin>
                <groupId>com.zbiti</groupId>
                <artifactId>zbiti-generator-maven-plugin</artifactId>
                <version>2.2.18</version>
                <configuration>
                    <!-- 输出目录 -->
                    <outputDir>${project.basedir}/generate/main/java</outputDir>

                    <!-- 是否覆盖同名文件(默认false) -->
                    <fileOverride>true</fileOverride>

                    <!-- 是否打开输出目录(默认false) -->
                    <open>false</open>

                    <!-- 是否只生成generate文件(默认false) -->
                    <generateOnly>false</generateOnly>

                    <!-- 是否生成MdaDomain文件(默认false) — ⛔ RuoYi项目强制为false -->
                    <generateMdaDomain>false</generateMdaDomain>

                    <!-- 是否生成VUE文件(默认true) — RuoYi前端独立管理，默认false -->
                    <generateVue>false</generateVue>

                    <!-- 生成vue文件版本(默认3) -->
                    <generateVueVersion>3</generateVueVersion>

                    <!-- 开发者名称 -->
                    <author>ruoyi</author>

                    <!-- 数据源配置，( **必配** ) -->
                    <dataSource>
                        <driverName>com.mysql.cj.jdbc.Driver</driverName>
                        <url>jdbc:mysql://192.168.144.66:44996/ai_performance?useUnicode=true&amp;characterEncoding=utf8&amp;zeroDateTimeBehavior=convertToNull&amp;useSSL=true&amp;serverTimezone=GMT%2B8</url>
                        <username>root</username>
                        <password>Zbiti@2024</password>
                    </dataSource>

                    <!-- 生成策略 -->
                    <strategy>
                        <!-- 字段生成策略 -->
                        <naming>underline_to_camel</naming>

                        <!-- 表前缀（可选，根据实际表名设置） -->
                        <tablePrefix>perf_</tablePrefix>

                        <!-- Entity中的ID生成策略（可选） -->
                        <idGenType>id_worker</idGenType>

                        <!-- 要包含的表（与exclude二选一） -->
                        <include>
                            <property>perf_indicator</property>
                            <property>perf_plan</property>
                        </include>

                        <!-- 要排除的表（可选） -->
                        <exclude>
                            <property>schema_version</property>
                        </exclude>

                        <!-- 表配置信息 -->
                        <tableConfigs>
                            <tableConfig>
                                <table>perf_indicator</table>
                                <requestMapping>/performance/indicator</requestMapping>
                            </tableConfig>
                            <tableConfig>
                                <table>perf_plan</table>
                                <requestMapping>/performance/plan</requestMapping>
                            </tableConfig>
                        </tableConfigs>
                    </strategy>

                    <!-- 生成包信息配置 -->
                    <packageInfo>
                        <!-- 父级包名称 — 格式：com.ruoyi.{业务域} -->
                        <parent>com.ruoyi.performance</parent>
                    </packageInfo>
                </configuration>

                <dependencies>
                    <!-- MySQL驱动（RuoYi默认数据库） -->
                    <dependency>
                        <groupId>com.mysql</groupId>
                        <artifactId>mysql-connector-j</artifactId>
                        <version>8.0.33</version>
                    </dependency>

                    <!-- PostgreSQL驱动（如需切换数据库时使用） -->
                    <dependency>
                        <groupId>org.postgresql</groupId>
                        <artifactId>postgresql</artifactId>
                    </dependency>

                    <!-- Oracle驱动（如需切换数据库时使用） -->
                    <dependency>
                        <groupId>com.oracle</groupId>
                        <artifactId>ojdbc6</artifactId>
                        <version>11.2.0.3</version>
                    </dependency>
                </dependencies>
            </plugin>
        </plugins>
    </build>
</project>
```

## RuoYi 与 Anvil 配置差异对照

| 配置项 | Anvil 值 | RuoYi 值 | 说明 |
|--------|----------|----------|------|
| parent groupId | `com.zbiti.anvil.anvilAiCodingDemo` | `com.ruoyi` | RuoYi 项目 groupId |
| parent artifactId | `anvilAiCodingDemo-admin` | `ai-performance-admin` | RuoYi 项目 artifactId |
| parent version | `4.6.0` | `3.9.2` | RuoYi 项目版本 |
| plugin version | `2.2.17` | `2.2.18` | 使用最新版本 |
| generateMdaDomain | `true` | **`false`** | ⛔ RuoYi 强制 false |
| generateVue | `false` | `false` | RuoYi 前端独立管理 |
| author | `generator` | `ruoyi` | RuoYi 风格 |
| 默认数据库 | PostgreSQL | MySQL | RuoYi 默认 MySQL |
| packageInfo parent | `com.zbiti.module.{业务}.base` | `com.ruoyi.{业务域}` | RuoYi 包名规范 |
| 代码迁移目标 | anvil 四层模块 | ruoyi-modules 单层 | RuoYi 模块结构 |

## 数据库配置示例

### MySQL配置（RuoYi默认）

```xml
<dataSource>
    <driverName>com.mysql.cj.jdbc.Driver</driverName>
    <url>jdbc:mysql://192.168.144.66:44996/ai_performance?useUnicode=true&amp;characterEncoding=utf8&amp;zeroDateTimeBehavior=convertToNull&amp;useSSL=true&amp;serverTimezone=GMT%2B8</url>
    <username>root</username>
    <password>Zbiti@2024</password>
</dataSource>

<dependencies>
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <version>8.0.33</version>
    </dependency>
</dependencies>
```

**配置来源：** `ruoyi-admin/src/main/resources/application-druid.yml` 中 `spring.datasource.druid.master.*`

### PostgreSQL配置

```xml
<dataSource>
    <driverName>org.postgresql.Driver</driverName>
    <url>jdbc:postgresql://host:port/dbname?useSSL=false&amp;connectTimeout=60000&amp;socketTimeout=60000</url>
    <username>postgres</username>
    <password>password</password>
</dataSource>

<dependencies>
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
    </dependency>
</dependencies>
```

### Oracle配置

```xml
<dataSource>
    <driverName>oracle.jdbc.OracleDriver</driverName>
    <url>jdbc:oracle:thin:@host:1521:orcl</url>
    <username>system</username>
    <password>password</password>
</dataSource>

<dependencies>
    <dependency>
        <groupId>com.oracle</groupId>
        <artifactId>ojdbc6</artifactId>
        <version>11.2.0.3</version>
    </dependency>
</dependencies>
```

## 字段命名策略示例

### nochange（不改变）

数据库字段：`user_name` → Java属性：`user_name`

### underline_to_camel（下划线转驼峰）— RuoYi推荐

数据库字段：`user_name` → Java属性：`userName`

### remove_prefix（去除前缀）

数据库字段：`sys_user_name` → Java属性：`user_name`

### remove_prefix_and_camel（去除前缀并转驼峰）

数据库字段：`sys_user_name` → Java属性：`userName`

## 序列创建SQL示例

> **RuoYi 说明**：RuoYi 默认使用 MySQL，通常不需要序列。以下仅在使用 PostgreSQL/Oracle 时需要。

### PostgreSQL序列创建

```sql
-- 检查序列是否存在
SELECT sequence_name
FROM information_schema.sequences
WHERE sequence_name = 'SEQ_PERF_INDICATOR';

-- 创建序列
CREATE SEQUENCE SEQ_PERF_INDICATOR
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

-- 查看序列
SELECT * FROM SEQ_PERF_INDICATOR;

-- 删除序列（如需要）
DROP SEQUENCE IF EXISTS SEQ_PERF_INDICATOR;
```

### Oracle序列创建

```sql
-- 检查序列是否存在
SELECT sequence_name
FROM user_sequences
WHERE sequence_name = 'SEQ_PERF_INDICATOR';

-- 创建序列
CREATE SEQUENCE SEQ_PERF_INDICATOR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

-- 查看序列
SELECT SEQ_PERF_INDICATOR.NEXTVAL FROM DUAL;

-- 删除序列（如需要）
DROP SEQUENCE SEQ_PERF_INDICATOR;
```

## requestMapping配置规则

requestMapping决定了Controller的请求路径。

### 规则说明

- 格式：`/{业务域}/{实体}`
- 示例：`/performance/indicator` → Controller路径：`/performance/indicator`
- 多级路径：`/performance/plan/detail` → Controller路径：`/performance/plan/detail`

### RuoYi 常见配置示例

```xml
<!-- 绩效管理模块 -->
<requestMapping>/performance/indicator</requestMapping>
<requestMapping>/performance/plan</requestMapping>
<requestMapping>/performance/score</requestMapping>

<!-- 系统管理模块（参考） -->
<requestMapping>/system/user</requestMapping>
<requestMapping>/system/role</requestMapping>
<requestMapping>/system/menu</requestMapping>
```

## 包名配置示例

### 绩效管理模块

```xml
<packageInfo>
    <parent>com.ruoyi.performance</parent>
</packageInfo>
```

生成的代码包结构：
```
com.ruoyi.performance
├── domain
│   └── PerfIndicator.java
├── mapper
│   └── PerfIndicatorMapper.java
├── service
│   ├── IPerfIndicatorService.java
│   └── impl
│       └── PerfIndicatorServiceImpl.java
└── controller
    └── PerfIndicatorController.java
```

### 其他业务模块

```xml
<packageInfo>
    <parent>com.ruoyi.{业务域}</parent>
</packageInfo>
```

> **注意**：RuoYi 中 Domain 目录名为 `domain`（非 anvil 的 `entity`），与 RuoYi 现有规范保持一致。

## 常见问题

### 1. URL中的特殊字符转义

问题：URL中的`&`符号导致XML解析错误

错误示例：
```xml
<url>jdbc:mysql://host:port/db?useSSL=true&serverTimezone=GMT%2B8</url>
```

正确示例：
```xml
<url>jdbc:mysql://host:port/db?useSSL=true&amp;serverTimezone=GMT%2B8</url>
```

### 2. generateMdaDomain 必须为 false

问题：RuoYi 项目中设置 `generateMdaDomain=true` 会导致生成不兼容的 MdaDomain 类

解决方案：
- ⛔ **强制**：`<generateMdaDomain>false</generateMdaDomain>`
- RuoYi 的 Domain 类应继承 `BaseEntity`，不使用 MdaDomain

### 3. 序列不存在导致生成失败

问题：PostgreSQL/Oracle数据库中序列不存在

解决方案：
- 在pom.xml中配置`<sequence>`标签
- 执行序列创建SQL
- 或者不配置`<sequence>`标签（MySQL不需要序列）

### 4. 中文乱码问题

**说明：** 乱码问题已解决，无需额外配置编码参数。

**解决方案：**
直接执行标准命令即可：
```powershell
cd generator-code; mvn zbiti-generator:code
```

### 5. 文件覆盖问题

问题：重新生成时覆盖了已修改的文件

解决方案：
- 设置`<fileOverride>false</fileOverride>`不覆盖已存在文件
- 或者手动备份已修改的文件

### 6. 数据库连接失败

问题：无法连接到数据库

检查项：
- 数据库服务是否启动
- 主机、端口、数据库名是否正确
- 用户名密码是否正确
- 网络是否可达
- 防火墙是否开放对应端口
- 配置来源：`ruoyi-admin/src/main/resources/application-druid.yml`
