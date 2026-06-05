-- ============================================================
-- AI+绩效考核系统 建表脚本
-- 数据库：MySQL
-- 日期：2026-06-05
-- ============================================================

-- 1. 考核类型表
CREATE TABLE IF NOT EXISTS perf_assess_type (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键ID',
    type_name       VARCHAR(32)     NOT NULL                 COMMENT '类型名称（周/月/季/年）',
    type_code       VARCHAR(16)     NOT NULL                 COMMENT '类型编码（WEEK/MONTH/QUARTER/YEAR）',
    status          CHAR(1)         NOT NULL DEFAULT '0'     COMMENT '状态（0=正常 1=停用）',
    create_by       VARCHAR(64)     DEFAULT ''               COMMENT '创建者',
    create_time     DATETIME        DEFAULT NULL             COMMENT '创建时间',
    update_by       VARCHAR(64)     DEFAULT ''               COMMENT '更新者',
    update_time     DATETIME        DEFAULT NULL             COMMENT '更新时间',
    remark          VARCHAR(500)    DEFAULT NULL             COMMENT '备注',
    PRIMARY KEY (id),
    UNIQUE KEY uk_type_code (type_code)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='考核类型表';

-- 2. 考核配置表
CREATE TABLE IF NOT EXISTS perf_assess_config (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键ID',
    config_key      VARCHAR(64)     NOT NULL                 COMMENT '配置项KEY',
    config_value    VARCHAR(256)    NOT NULL                 COMMENT '配置值',
    config_name     VARCHAR(128)    NOT NULL                 COMMENT '配置名称',
    config_type     VARCHAR(16)     NOT NULL                 COMMENT '配置类型（NUMBER/STRING/BOOLEAN）',
    status          CHAR(1)         NOT NULL DEFAULT '0'     COMMENT '状态（0=正常 1=停用）',
    create_by       VARCHAR(64)     DEFAULT ''               COMMENT '创建者',
    create_time     DATETIME        DEFAULT NULL             COMMENT '创建时间',
    update_by       VARCHAR(64)     DEFAULT ''               COMMENT '更新者',
    update_time     DATETIME        DEFAULT NULL             COMMENT '更新时间',
    remark          VARCHAR(500)    DEFAULT NULL             COMMENT '备注',
    PRIMARY KEY (id),
    UNIQUE KEY uk_config_key (config_key)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='考核配置表';

-- 3. 考核关系配置表
CREATE TABLE IF NOT EXISTS perf_assess_relation (
    id                  BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键ID',
    assess_type_id      BIGINT          NOT NULL                 COMMENT '考核类型ID',
    employee_id         BIGINT          NOT NULL                 COMMENT '员工ID',
    leader_id           BIGINT          NOT NULL                 COMMENT '领导ID',
    level_order         INT             NOT NULL                 COMMENT '层级序号（1=直属领导）',
    effective_period    VARCHAR(16)     NOT NULL                 COMMENT '生效周期（如2026-06/2026-Q1）',
    status              CHAR(1)         NOT NULL DEFAULT '0'     COMMENT '状态（0=正常 1=停用）',
    create_by           VARCHAR(64)     DEFAULT ''               COMMENT '创建者',
    create_time         DATETIME        DEFAULT NULL             COMMENT '创建时间',
    update_by           VARCHAR(64)     DEFAULT ''               COMMENT '更新者',
    update_time         DATETIME        DEFAULT NULL             COMMENT '更新时间',
    remark              VARCHAR(500)    DEFAULT NULL             COMMENT '备注',
    PRIMARY KEY (id),
    UNIQUE KEY uk_type_employee_period_level (assess_type_id, employee_id, effective_period, level_order),
    KEY idx_employee_id (employee_id),
    KEY idx_leader_id (leader_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='考核关系配置表';

-- 4. 考核关系历史表
CREATE TABLE IF NOT EXISTS perf_assess_relation_history (
    id                  BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键ID',
    assess_id           BIGINT          NOT NULL                 COMMENT '绩效单ID',
    relation_id         BIGINT          NOT NULL                 COMMENT '原考核关系ID',
    employee_id         BIGINT          NOT NULL                 COMMENT '员工ID（快照）',
    leader_id           BIGINT          NOT NULL                 COMMENT '领导ID（快照）',
    level_order         INT             NOT NULL                 COMMENT '层级序号（快照）',
    snapshot_time       DATETIME        NOT NULL                 COMMENT '快照时间',
    create_by           VARCHAR(64)     DEFAULT ''               COMMENT '创建者',
    create_time         DATETIME        DEFAULT NULL             COMMENT '创建时间',
    PRIMARY KEY (id),
    KEY idx_assess_id (assess_id),
    KEY idx_employee_id (employee_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='考核关系历史表';

-- 5. 绩效单主表
CREATE TABLE IF NOT EXISTS perf_assess (
    id                  BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键ID',
    assess_type_id      BIGINT          NOT NULL                 COMMENT '考核类型ID',
    period              VARCHAR(16)     NOT NULL                 COMMENT '考核周期（如2026-06）',
    employee_id         BIGINT          NOT NULL                 COMMENT '员工ID',
    status              CHAR(2)         NOT NULL DEFAULT '01'    COMMENT '状态（01=草稿中 02=待领导审批 03=待员工自评 04=待领导评分 05=差异判定中 06=待绩效面谈 07=待改进计划确认 08=已完成）',
    deadline            DATETIME        DEFAULT NULL             COMMENT '截止日期',
    self_score_total    DECIMAL(5,2)    DEFAULT NULL             COMMENT '自评总分',
    leader_score_total  DECIMAL(5,2)    DEFAULT NULL             COMMENT '领导评分总分',
    score_diff          DECIMAL(5,2)    DEFAULT NULL             COMMENT '总分差',
    diff_triggered      CHAR(1)         DEFAULT '0'              COMMENT '是否触发差异（0=否 1=是）',
    create_by           VARCHAR(64)     DEFAULT ''               COMMENT '创建者',
    create_time         DATETIME        DEFAULT NULL             COMMENT '创建时间',
    update_by           VARCHAR(64)     DEFAULT ''               COMMENT '更新者',
    update_time         DATETIME        DEFAULT NULL             COMMENT '更新时间',
    remark              VARCHAR(500)    DEFAULT NULL             COMMENT '备注',
    PRIMARY KEY (id),
    UNIQUE KEY uk_type_employee_period (assess_type_id, employee_id, period),
    KEY idx_employee_id (employee_id),
    KEY idx_status (status)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='绩效单主表';

-- 6. 评分项子表
CREATE TABLE IF NOT EXISTS perf_assess_item (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键ID',
    assess_id       BIGINT          NOT NULL                 COMMENT '绩效单ID',
    item_name       VARCHAR(128)    NOT NULL                 COMMENT '评分项名称',
    weight          DECIMAL(5,2)    NOT NULL                 COMMENT '权重',
    sort_order      INT             DEFAULT 0                COMMENT '排序号',
    self_score      DECIMAL(5,2)    DEFAULT NULL             COMMENT '员工自评分',
    self_desc       VARCHAR(2000)   DEFAULT NULL             COMMENT '员工成果描述',
    leader_score    DECIMAL(5,2)    DEFAULT NULL             COMMENT '领导评分',
    leader_comment  VARCHAR(2000)   DEFAULT NULL             COMMENT '领导评语',
    create_by       VARCHAR(64)     DEFAULT ''               COMMENT '创建者',
    create_time     DATETIME        DEFAULT NULL             COMMENT '创建时间',
    update_by       VARCHAR(64)     DEFAULT ''               COMMENT '更新者',
    update_time     DATETIME        DEFAULT NULL             COMMENT '更新时间',
    PRIMARY KEY (id),
    KEY idx_assess_id (assess_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='评分项子表';

-- 7. 驳回记录表
CREATE TABLE IF NOT EXISTS perf_assess_reject (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键ID',
    assess_id       BIGINT          NOT NULL                 COMMENT '绩效单ID',
    reject_reason   VARCHAR(500)    NOT NULL                 COMMENT '驳回原因',
    reject_by       VARCHAR(64)     NOT NULL                 COMMENT '驳回人',
    reject_time     DATETIME        NOT NULL                 COMMENT '驳回时间',
    create_by       VARCHAR(64)     DEFAULT ''               COMMENT '创建者',
    create_time     DATETIME        DEFAULT NULL             COMMENT '创建时间',
    PRIMARY KEY (id),
    KEY idx_assess_id (assess_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='驳回记录表';

-- 8. 面谈记录表
CREATE TABLE IF NOT EXISTS perf_assess_interview (
    id                  BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键ID',
    assess_id           BIGINT          NOT NULL                 COMMENT '绩效单ID',
    interview_time      DATETIME        DEFAULT NULL             COMMENT '面谈时间',
    interview_location  VARCHAR(128)    DEFAULT NULL             COMMENT '面谈地点',
    interview_minutes   VARCHAR(4000)   DEFAULT NULL             COMMENT '面谈纪要',
    interview_summary   VARCHAR(2000)   DEFAULT NULL             COMMENT '面谈总结',
    status              CHAR(1)         NOT NULL DEFAULT '0'     COMMENT '状态（0=草稿 1=已完成）',
    create_by           VARCHAR(64)     DEFAULT ''               COMMENT '创建者',
    create_time         DATETIME        DEFAULT NULL             COMMENT '创建时间',
    update_by           VARCHAR(64)     DEFAULT ''               COMMENT '更新者',
    update_time         DATETIME        DEFAULT NULL             COMMENT '更新时间',
    PRIMARY KEY (id),
    KEY idx_assess_id (assess_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='面谈记录表';

-- 9. 改进计划表
CREATE TABLE IF NOT EXISTS perf_assess_improve (
    id                  BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键ID',
    assess_id           BIGINT          NOT NULL                 COMMENT '绩效单ID',
    improve_item        VARCHAR(500)    NOT NULL                 COMMENT '改进项',
    responsible_person  VARCHAR(64)     NOT NULL                 COMMENT '负责人',
    responsible_user_id BIGINT          DEFAULT NULL             COMMENT '负责人ID',
    deadline            DATE            NOT NULL                 COMMENT '截止日期',
    accept_standard     VARCHAR(500)    NOT NULL                 COMMENT '验收标准',
    confirm_status      CHAR(1)         NOT NULL DEFAULT '0'     COMMENT '确认状态（0=待确认 1=已确认 2=申请调整 3=已调整）',
    adjust_reason       VARCHAR(500)    DEFAULT NULL             COMMENT '调整原因',
    sort_order          INT             DEFAULT 0                COMMENT '排序号',
    create_by           VARCHAR(64)     DEFAULT ''               COMMENT '创建者',
    create_time         DATETIME        DEFAULT NULL             COMMENT '创建时间',
    update_by           VARCHAR(64)     DEFAULT ''               COMMENT '更新者',
    update_time         DATETIME        DEFAULT NULL             COMMENT '更新时间',
    PRIMARY KEY (id),
    KEY idx_assess_id (assess_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='改进计划表';

-- ============================================================
-- 初始化数据
-- ============================================================

-- 初始化考核类型
INSERT INTO perf_assess_type (type_name, type_code, status, create_by, create_time, remark) VALUES
('周考核', 'WEEK', '0', 'admin', NOW(), '周度绩效考核'),
('月度考核', 'MONTH', '0', 'admin', NOW(), '月度绩效考核'),
('季度考核', 'QUARTER', '0', 'admin', NOW(), '季度绩效考核'),
('年度考核', 'YEAR', '0', 'admin', NOW(), '年度绩效考核');

-- 初始化考核配置
INSERT INTO perf_assess_config (config_key, config_value, config_name, config_type, status, create_by, create_time, remark) VALUES
('assess.diff.item_ratio', '30', '单项差异比例阈值', 'NUMBER', '0', 'admin', NOW(), '差异判定：单项差异比例阈值（百分比）'),
('assess.diff.total_score', '20', '总分差阈值', 'NUMBER', '0', 'admin', NOW(), '差异判定：总分差阈值（分值）'),
('assess.improve.required', 'true', '是否强制改进计划', 'BOOLEAN', '0', 'admin', NOW(), '所有绩效流程结束后是否必须确认改进计划');
