# AGENTS.md — ai-performance-admin（RuoYi）

> 开发流程、编码规范、Agent 路由详见 `.codefree-o/instructions/zbiti-code-rules.md`

## 技术栈与版本

| 项 | 值 |
|---|---|
| Java | 17 |
| Spring Boot | 4.0.3（见根 pom.xml） |
| ORM | MyBatis（Mapper XML：`classpath*:mapper/**/*Mapper.xml`） |
| 连接池 | Druid |
| 缓存 | Redis |
| 数据库 | MySQL（默认方言：PageHelper `mysql`） |
| 分页 | PageHelper |
| API 文档 | springdoc-openapi |

## 模块结构树

```
ai-performance-admin (根)
├── ruoyi-admin        # Web 入口（启动类、Controller、配置）
├── ruoyi-framework    # 框架基础设施（安全、配置、MyBatis装配等）
├── ruoyi-system       # 系统域（domain/mapper/service 等）
├── ruoyi-quartz       # 定时任务域
├── ruoyi-generator    # 代码生成（gen）
├── ruoyi-common       # 通用工具与基础结构
├── ruoyi-modules      # 业务模块（domain/mapper/service 等）
├── docs               # 文档目录（API 文档、数据库文档等）
└── sql/               # 初始化/示例 SQL
```

## 启动与端口

| 应用 | Main Class | 端口(dev) | Context Path |
|------|-----------|----------|-------------|
| Web | `com.ruoyi.RuoYiApplication` | 8080 | / |

## 配置文件加载与关键配置

- 主配置：`ruoyi-admin/src/main/resources/application.yml`
- Profile：`spring.profiles.active=druid`
- MyBatis：
  - `mybatis.typeAliasesPackage = com.ruoyi.**.domain`
  - `mybatis.mapperLocations = classpath*:mapper/**/*Mapper.xml`

## 关键约束（RuoYi 适配）

- ⛔ Controller / Service 中禁止写 SQL，SQL 必须落在 Mapper XML
- ⛔ 新增接口必须按现有风格返回 `AjaxResult` / `TableDataInfo`，并补齐 `@PreAuthorize` 权限控制
- Mapper XML 路径必须匹配：`classpath*:mapper/**/*Mapper.xml`

## 工具配置

| 工具 | 配置文件 | Skill/Agent/Instructions 目录 |
|------|---------|-------------------------------|
| CodeFree | `codefree.json` | `.codefree-o/` |

- CodeFree 指令入口：`.codefree-o/instructions/zbiti-code-rules.md`
- MCP 当前仅配置：`db-op`（见 `codefree.json`）
