# 代码生成工作流程（RuoYi 适配版）

## 完整工作流程图

```
开始
  ↓
1. 读取application.yml确定激活的profile
  ↓
2. 读取对应profile的数据源配置文件
  ↓
3. 提取数据库连接信息
  ↓
4. 配置pom.xml的dataSource
  ↓
5. 补充JDBC驱动依赖
  ↓
6. 配置strategy和packageInfo
  ↓
7. 设置tableConfigs（MySQL无需序列配置）
  ↓
8. [PostgreSQL/Oracle] 检查序列是否存在
  ↓
9. [PostgreSQL/Oracle] 不存在则创建序列
  ↓
10. 执行代码生成命令
  ↓
11. 等待生成完成
  ↓
12. RuoYi风格适配（Domain→BaseEntity、Controller→AjaxResult等）
  ↓
13. 将生成的代码迁移到ruoyi-modules/{业务域}模块
  ↓
14. 配置Mapper XML扫描路径
  ↓
结束
```

## 详细步骤说明

### 步骤1：读取application.yml确定激活的profile

**文件位置：** `ruoyi-admin/src/main/resources/application.yml`

**示例内容：**
```yaml
spring:
  profiles:
    active: druid
```

**解析逻辑：**
- 读取`spring.profiles.active`的值
- RuoYi 项目通常为 `druid`（单一数据源配置）
- 与 anvil 不同，RuoYi 不使用 Maven profile 切换环境

### 步骤2：读取对应profile的数据源配置文件

**文件位置：** `ruoyi-admin/src/main/resources/application-{profile}.yml`

**RuoYi 特点：** 单一配置文件 `application-druid.yml`，不按数据库类型分文件

**示例内容（MySQL）：**
```yaml
spring:
    datasource:
        type: com.alibaba.druid.pool.DruidDataSource
        driverClassName: com.mysql.cj.jdbc.Driver
        druid:
            master:
                url: jdbc:mysql://192.168.144.66:44996/ai_performance?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8
                username: root
                password: Zbiti@2024
```

### 步骤3：提取数据库连接信息

**提取路径：**
- `driverName`：`spring.datasource.druid.master.driverClassName`（或 `spring.datasource.driverClassName`）
- `url`：`spring.datasource.druid.master.url`
- `username`：`spring.datasource.druid.master.username`
- `password`：`spring.datasource.druid.master.password`

**数据库类型识别：**
- MySQL：`com.mysql.cj.jdbc.Driver`（RuoYi 默认）
- PostgreSQL：`org.postgresql.Driver`
- Oracle：`oracle.jdbc.OracleDriver`

### 步骤4：配置pom.xml的dataSource

**目标文件：** `generator-code/pom.xml`

**配置位置：** `<plugin><configuration><dataSource>`

**配置示例（MySQL — RuoYi默认）：**
```xml
<dataSource>
    <driverName>com.mysql.cj.jdbc.Driver</driverName>
    <url>jdbc:mysql://192.168.144.66:44996/ai_performance?useUnicode=true&amp;characterEncoding=utf8&amp;zeroDateTimeBehavior=convertToNull&amp;useSSL=true&amp;serverTimezone=GMT%2B8</url>
    <username>root</username>
    <password>Zbiti@2024</password>
</dataSource>
```

**注意事项：**
- URL中的`&`需要转义为`&amp;`
- 确保所有必填项都已配置
- 数据源信息来源于 `application-druid.yml`

### 步骤5：补充JDBC驱动依赖

**配置位置：** `<plugin><dependencies>`

**MySQL驱动（RuoYi默认）：**
```xml
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
    <version>8.0.33</version>
</dependency>
```

**PostgreSQL驱动（如需切换）：**
```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
</dependency>
```

**Oracle驱动（如需切换）：**
```xml
<dependency>
    <groupId>com.oracle</groupId>
    <artifactId>ojdbc6</artifactId>
    <version>11.2.0.3</version>
</dependency>
```

### 步骤6：配置strategy和packageInfo

**strategy配置：**
```xml
<strategy>
    <naming>underline_to_camel</naming>
    <tablePrefix>perf_</tablePrefix>
    <idGenType>id_worker</idGenType>
    <include>
        <property>perf_indicator</property>
    </include>
    <tableConfigs>
        <!-- 表配置 -->
    </tableConfigs>
</strategy>
```

**packageInfo配置（RuoYi规范）：**
```xml
<packageInfo>
    <!-- 格式：com.ruoyi.{业务域} -->
    <parent>com.ruoyi.performance</parent>
</packageInfo>
```

> **与 anvil 的区别**：anvil 使用 `com.zbiti.module.{业务}.base`，RuoYi 使用 `com.ruoyi.{业务域}`

### 步骤7：设置tableConfigs

**MySQL配置示例（无需序列）：**
```xml
<tableConfigs>
    <tableConfig>
        <table>perf_indicator</table>
        <requestMapping>/performance/indicator</requestMapping>
    </tableConfig>
</tableConfigs>
```

**PostgreSQL/Oracle配置示例（需要序列）：**
```xml
<tableConfigs>
    <tableConfig>
        <table>perf_indicator</table>
        <sequence>SEQ_PERF_INDICATOR</sequence>
        <requestMapping>/performance/indicator</requestMapping>
    </tableConfig>
</tableConfigs>
```

**配置说明：**
- `table`：数据库表名（必填）
- `sequence`：序列名（PostgreSQL/Oracle必填，MySQL不需要）
- `requestMapping`：Controller请求路径（可选，不填则自动计算）

### 步骤8-9：序列管理（仅PostgreSQL/Oracle）

> **RuoYi 默认 MySQL，通常跳过此步骤。**

**检查序列是否存在：**

PostgreSQL：
```sql
SELECT sequence_name
FROM information_schema.sequences
WHERE sequence_name = 'SEQ_PERF_INDICATOR';
```

Oracle：
```sql
SELECT sequence_name
FROM user_sequences
WHERE sequence_name = 'SEQ_PERF_INDICATOR';
```

**创建序列（如果不存在）：**

PostgreSQL：
```sql
CREATE SEQUENCE SEQ_PERF_INDICATOR
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;
```

Oracle：
```sql
CREATE SEQUENCE SEQ_PERF_INDICATOR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;
```

### 步骤10：执行代码生成命令

**重要提示：** 代码生成命令必须使用 `zbiti-generator:code`，**严禁使用** `zbiti-generator:generate` 或其他变体命令。

**方式一：IDEA图形化界面**
1. 打开IDEA右侧Maven面板
2. 展开`generator-code` -> `plugins`
3. 点击`zbiti-generator:code`执行

**方式二：命令行执行（推荐）**

***Linux / macOS***
```bash
cd generator-code && mvn zbiti-generator:code
```

*** Windows (cmd)***
```cmd
cd generator-code && mvn zbiti-generator:code
```

*** Windows (powershell)***
```powershell
cd generator-code; mvn zbiti-generator:code
```

### 步骤11：等待生成完成

**生成位置：** `generator-code/generate/main/java/`

**生成的文件：**
- Domain实体类（entity目录，需适配为domain）
- Mapper接口和XML
- Service接口和实现类
- Controller控制器
- Vue页面（如果`generateVue=true`，RuoYi默认不生成）

### 步骤12：RuoYi风格适配（关键步骤）

> **此步骤是 RuoYi 与 anvil 的核心差异**。生成的代码需要适配 RuoYi 框架规范，否则无法正常使用。

#### 12.1 Domain 适配

**生成代码：** 继承 `Model` 或无基类
**RuoYi 规范：** 继承 `BaseEntity`

```java
// 适配前
public class PerfIndicator extends Model<PerfIndicator> {

// 适配后
public class PerfIndicator extends BaseEntity {
```

**需要添加的 import：**
```java
import com.ruoyi.common.core.domain.BaseEntity;
```

**需要移除的 import：**
```java
import com.baomidou.mybatisplus.extension.activerecord.Model; // ⛔ 禁止使用mybatisplus
```

#### 12.2 Controller 适配

**生成代码：** 可能使用通用返回体
**RuoYi 规范：** 使用 `AjaxResult` / `TableDataInfo` + `@PreAuthorize`

```java
// 适配前
public class PerfIndicatorController {

// 适配后
@RestController
@RequestMapping("/performance/indicator")
public class PerfIndicatorController extends BaseController {

    @Autowired
    private IPerfIndicatorService perfIndicatorService;

    /** 查询列表 */
    @PreAuthorize("@ss.hasPermi('performance:indicator:list')")
    @GetMapping("/list")
    public TableDataInfo list(PerfIndicator perfIndicator) {
        startPage();
        List<PerfIndicator> list = perfIndicatorService.selectPerfIndicatorList(perfIndicator);
        return getDataTable(list);
    }

    /** 获取详细信息 */
    @PreAuthorize("@ss.hasPerfi('performance:indicator:query')")
    @GetMapping("/{id}")
    public AjaxResult getInfo(@PathVariable Long id) {
        return success(perfIndicatorService.selectPerfIndicatorById(id));
    }

    /** 新增 */
    @PreAuthorize("@ss.hasPermi('performance:indicator:add')")
    @PostMapping
    public AjaxResult add(@RequestBody PerfIndicator perfIndicator) {
        return toAjax(perfIndicatorService.insertPerfIndicator(perfIndicator));
    }

    /** 修改 */
    @PreAuthorize("@ss.hasPermi('performance:indicator:edit')")
    @PutMapping
    public AjaxResult edit(@RequestBody PerfIndicator perfIndicator) {
        return toAjax(perfIndicatorService.updatePerfIndicator(perfIndicator));
    }

    /** 删除 */
    @PreAuthorize("@ss.hasPermi('performance:indicator:remove')")
    @DeleteMapping("/{ids}")
    public AjaxResult remove(@PathVariable Long[] ids) {
        return toAjax(perfIndicatorService.deletePerfIndicatorByIds(ids));
    }
}
```

**需要添加的 import：**
```java
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.annotation.PreAuthorize;
```

#### 12.3 Service 适配

**生成代码：** 可能使用 MyBatis-Plus 的 IService
**RuoYi 规范：** 使用纯 MyBatis 接口

```java
// 适配前（MyBatis-Plus风格）
public interface IPerfIndicatorService extends IService<PerfIndicator> {

// 适配后（RuoYi风格）
public interface IPerfIndicatorService {
    public List<PerfIndicator> selectPerfIndicatorList(PerfIndicator perfIndicator);
    public PerfIndicator selectPerfIndicatorById(Long id);
    public int insertPerfIndicator(PerfIndicator perfIndicator);
    public int updatePerfIndicator(PerfIndicator perfIndicator);
    public int deletePerfIndicatorByIds(Long[] ids);
}
```

#### 12.4 Mapper XML 适配

**生成代码：** XML 可能在不规范的路径
**RuoYi 规范：** 放在 `resources/mapper/{业务域}/` 下

**目标路径：** `ruoyi-modules/{业务域}/src/main/resources/mapper/{业务域}/PerfIndicatorMapper.xml`

**确保匹配扫描规则：** `classpath*:mapper/**/*Mapper.xml`

### 步骤13：将生成的代码迁移到ruoyi-modules/{业务域}模块

**迁移目标结构：**
```
ruoyi-modules/
└── ruoyi-performance/                          # 业务子模块
    ├── pom.xml
    └── src/main/
        ├── java/com/ruoyi/performance/
        │   ├── controller/
        │   │   └── PerfIndicatorController.java
        │   ├── domain/
        │   │   └── PerfIndicator.java
        │   ├── mapper/
        │   │   └── PerfIndicatorMapper.java
        │   └── service/
        │       ├── IPerfIndicatorService.java
        │       └── impl/
        │           └── PerfIndicatorServiceImpl.java
        └── resources/
            └── mapper/performance/
                └── PerfIndicatorMapper.xml
```

**迁移步骤：**
1. 确认 `ruoyi-modules` 目录存在，不存在则创建
2. 确认 `ruoyi-modules/pom.xml` 聚合 POM 存在
3. 创建 `ruoyi-modules/ruoyi-{业务域}/` 子模块
4. 将适配后的代码文件复制到对应目录
5. 在 `ruoyi-admin/pom.xml` 中添加子模块依赖

> **注意**：模块创建应使用 `zbiti-modules-create-agent` 子Agent执行

### 步骤14：配置Mapper XML扫描路径

**确认扫描配置：** `ruoyi-admin/src/main/resources/application.yml`

```yaml
mybatis:
    mapperLocations: classpath*:mapper/**/*Mapper.xml
```

**验证：** 迁移后的 Mapper XML 路径必须匹配此扫描规则。

## 快速开始示例

### 示例1：为perf_indicator表生成代码（MySQL）

**1. 配置pom.xml**
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

**2. 执行生成**
参照`步骤10：执行代码生成命令的方式二`来执行生成

**3. RuoYi风格适配**
参照`步骤12`对生成的代码进行适配

**4. 迁移代码**
将适配后的代码迁移到 `ruoyi-modules/ruoyi-performance/` 模块

### 示例2：批量生成多个表的代码

**1. 配置pom.xml**
```xml
<include>
    <property>perf_indicator</property>
    <property>perf_plan</property>
    <property>perf_score</property>
</include>

<tableConfigs>
    <tableConfig>
        <table>perf_indicator</table>
        <requestMapping>/performance/indicator</requestMapping>
    </tableConfig>
    <tableConfig>
        <table>perf_plan</table>
        <requestMapping>/performance/plan</requestMapping>
    </tableConfig>
    <tableConfig>
        <table>perf_score</table>
        <requestMapping>/performance/score</requestMapping>
    </tableConfig>
</tableConfigs>

<packageInfo>
    <parent>com.ruoyi.performance</parent>
</packageInfo>
```

**2. 执行生成**
参照`步骤10：执行代码生成命令的方式二`来执行生成

**3. RuoYi风格适配 + 迁移代码**
参照`步骤12-14`进行适配和迁移

## 故障排查

### 问题1：数据库连接失败

**检查清单：**
- [ ] 数据库服务是否启动
- [ ] 主机、端口、数据库名是否正确
- [ ] 用户名密码是否正确
- [ ] 网络是否可达
- [ ] 防火墙是否开放对应端口
- [ ] 配置来源：`ruoyi-admin/src/main/resources/application-druid.yml`

### 问题2：序列不存在（PostgreSQL/Oracle）

**解决方案：**
- 检查pom.xml中是否配置了`<sequence>`标签
- 执行序列创建SQL
- 或者不配置`<sequence>`标签（MySQL不需要序列）

### 问题3：文件覆盖

**解决方案：**
- 设置`<fileOverride>false</fileOverride>`不覆盖已存在文件
- 或者手动备份已修改的文件

### 问题4：生成的代码与RuoYi风格不兼容

**解决方案：**
- 严格按照步骤12进行RuoYi风格适配
- Domain必须继承BaseEntity
- Controller必须继承BaseController，返回AjaxResult/TableDataInfo
- Service不使用MyBatis-Plus的IService
- Mapper XML放在`resources/mapper/{业务域}/`下

### 问题5：Mapper XML扫描不到

**解决方案：**
- 确认XML文件路径匹配 `classpath*:mapper/**/*Mapper.xml`
- 确认XML文件在 `resources/mapper/{业务域}/` 目录下
- 确认 `ruoyi-admin/pom.xml` 中已添加子模块依赖

## 最佳实践

1. **先适配后迁移**：生成代码后先完成RuoYi风格适配，再迁移到目标模块
2. **小步迭代**：一次生成少量表，逐步验证
3. **版本控制**：将生成的代码纳入版本控制
4. **代码审查**：生成后进行代码审查，确保RuoYi规范一致性
5. **权限配置**：Controller中必须添加`@PreAuthorize`权限注解
6. **禁止MyBatis-Plus**：⛔ RuoYi项目禁止使用mybatisplus，Service和Mapper必须使用纯MyBatis
