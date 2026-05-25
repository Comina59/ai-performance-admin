-- 员工目标主表（ai_performance_goal）存储员工手动 / AI 生成的绩效目标主数据
CREATE TABLE `ai_performance_goal` (
  `id` BIGINT NOT NULL COMMENT '目标ID',
  `employee_id` VARCHAR(64) NOT NULL COMMENT '员工ID',
  `employee_name` VARCHAR(64) NOT NULL COMMENT '员工姓名',
  `dept_id` VARCHAR(64) NOT NULL COMMENT '部门ID',
  `dept_name` VARCHAR(128) NOT NULL COMMENT '部门名称',
  `leader_id` VARCHAR(64) NOT NULL COMMENT '直属主管ID',
  `cycle_code` VARCHAR(32) NOT NULL COMMENT '绩效周期编码(如2025Q1)',
  `cycle_name` VARCHAR(64) NOT NULL COMMENT '周期名称(2025年第一季度)',
  `post_name` VARCHAR(64) DEFAULT NULL COMMENT '岗位名称',
  `level_name` VARCHAR(32) DEFAULT NULL COMMENT '职级',
  `goal_title` VARCHAR(255) DEFAULT NULL COMMENT '目标标题',
  `goal_content` TEXT DEFAULT NULL COMMENT '目标完整内容',
  `goal_type` TINYINT NOT NULL DEFAULT 1 COMMENT '目标类型 1-个人目标 2-团队目标',
  `difficulty` TINYINT DEFAULT 2 COMMENT '目标强度 1-保守 2-平衡 3-挑战',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '状态 0-草稿 1-已提交 2-已审核 3-已驳回',
  `reject_reason` VARCHAR(512) DEFAULT NULL COMMENT '驳回原因',
  `create_source` TINYINT NOT NULL COMMENT '创建来源 1-手动创建 2-AI起草 3-AI润色 4-AI重写',
  `related_goal_id` BIGINT DEFAULT NULL COMMENT '关联历史目标ID(参考用)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_employee_cycle` (`employee_id`,`cycle_code`),
  KEY `idx_leader_cycle` (`leader_id`,`cycle_code`),
  KEY `idx_dept_cycle` (`dept_id`,`cycle_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='员工绩效目标主表';

--  AI 目标生成记录表（ai_goal_generate_record） 记录所有 AI 起草 / 重生成的调用、方案、结果数据
CREATE TABLE `ai_goal_generate_record` (
  `id` BIGINT NOT NULL COMMENT 'AI生成记录ID',
  `goal_id` BIGINT DEFAULT NULL COMMENT '关联目标ID(采纳后绑定)',
  `employee_id` VARCHAR(64) NOT NULL COMMENT '操作员工ID',
  `cycle_code` VARCHAR(32) NOT NULL COMMENT '周期编码',
  `user_intent` TEXT NOT NULL COMMENT '用户输入意图',
  `difficulty` TINYINT DEFAULT 2 COMMENT '生成强度 1-保守 2-平衡 3-挑战',
  `use_history` TINYINT DEFAULT 1 COMMENT '是否参考历史 0-否 1-是',
  `model_name` VARCHAR(64) DEFAULT NULL COMMENT '调用AI模型名称',
  `generate_status` TINYINT NOT NULL DEFAULT 0 COMMENT '状态 0-生成中 1-成功 2-失败 3-降级(模板)',
  `fail_reason` VARCHAR(255) DEFAULT NULL COMMENT '失败原因(超时/限流/敏感词)',
  `cost_time` INT DEFAULT NULL COMMENT '耗时(ms)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_goal_id` (`goal_id`),
  KEY `idx_employee` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI目标生成记录表';

-- AI 生成目标方案表（ai_goal_scheme） 存储 AI 返回的3 套方案，支持单套采纳 / 重生成
CREATE TABLE `ai_goal_scheme` (
  `id` BIGINT NOT NULL COMMENT '方案ID',
  `generate_id` BIGINT NOT NULL COMMENT '关联生成记录ID',
  `scheme_content` TEXT NOT NULL COMMENT '方案完整内容',
  `smart_score` INT DEFAULT NULL COMMENT 'SMART预评分(0-100)',
  `smart_tags` VARCHAR(255) DEFAULT NULL COMMENT 'SMART标签(S/M/A/R/T/量化)',
  `is_adopted` TINYINT NOT NULL DEFAULT 0 COMMENT '是否采纳 0-否 1-是',
  `is_regenerated` TINYINT DEFAULT 0 COMMENT '是否重生成 0-否 1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_generate_id` (`generate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI生成目标方案表';

-- AI 目标润色记录表（ai_goal_polish_record） 记录目标原文、润色文、风格、操作记录
CREATE TABLE `ai_goal_polish_record` (
  `id` BIGINT NOT NULL COMMENT '润色记录ID',
  `goal_id` BIGINT NOT NULL COMMENT '关联目标ID',
  `employee_id` VARCHAR(64) NOT NULL COMMENT '操作人ID',
  `original_content` TEXT NOT NULL COMMENT '原文内容',
  `polish_style` TINYINT NOT NULL COMMENT '润色风格 1-精炼 2-正式 3-数据导向',
  `polished_content` TEXT NOT NULL COMMENT '润色后内容',
  `diff_content` TEXT DEFAULT NULL COMMENT '差异对比内容(JSON/HTML)',
  `improve_points` TEXT DEFAULT NULL COMMENT '改进点说明',
  `is_applied` TINYINT NOT NULL DEFAULT 0 COMMENT '是否应用 0-否 1-是',
  `is_undo` TINYINT DEFAULT 0 COMMENT '是否撤销 0-否 1-是',
  `cost_time` INT DEFAULT NULL COMMENT '耗时(ms)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_goal_id` (`goal_id`),
  KEY `idx_employee` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI目标润色记录表';

-- AI 目标 SMART 体检表（ai_goal_smart_check） 单条 / 批量体检结果、得分、等级、建议
CREATE TABLE `ai_goal_smart_check` (
  `id` BIGINT NOT NULL COMMENT '体检记录ID',
  `goal_id` BIGINT NOT NULL COMMENT '目标ID',
  `employee_id` VARCHAR(64) NOT NULL COMMENT '目标所属员工ID',
  `checker_id` VARCHAR(64) NOT NULL COMMENT '体检操作人ID(员工/主管/HRBP)',
  `check_type` TINYINT NOT NULL COMMENT '体检类型 1-单条体检 2-批量体检',
  `batch_id` VARCHAR(64) DEFAULT NULL COMMENT '批量体检批次ID',
  `total_score` INT NOT NULL COMMENT '总分(0-100)',
  `grade` VARCHAR(16) NOT NULL COMMENT '等级 S/A/B/C/D',
  -- SMART 5维度细分得分
  `s_score` INT DEFAULT 0 COMMENT '具体性得分',
  `m_score` INT DEFAULT 0 COMMENT '可衡量得分',
  `a_score` INT DEFAULT 0 COMMENT '可达成得分',
  `r_score` INT DEFAULT 0 COMMENT '相关性得分',
  `t_score` INT DEFAULT 0 COMMENT '时限性得分',
  `check_suggestion` TEXT DEFAULT NULL COMMENT '体检优化建议',
  `is_qualified` TINYINT NOT NULL COMMENT '是否合格 0-否 1-是(≥80分)',
  `handle_status` TINYINT DEFAULT 0 COMMENT '处理状态 0-未处理 1-已优化 2-无需修改 3-已驳回',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_goal_id` (`goal_id`),
  KEY `idx_batch_id` (`batch_id`),
  KEY `idx_employee_checker` (`employee_id`,`checker_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI目标SMART体检表';

-- 绩效周期配置表（performance_cycle_config） 统一管理绩效周期，供全模块使用
CREATE TABLE `performance_cycle_config` (
  `id` BIGINT NOT NULL COMMENT '周期配置ID',
  `cycle_code` VARCHAR(32) NOT NULL COMMENT '周期编码(唯一)',
  `cycle_name` VARCHAR(64) NOT NULL COMMENT '周期名称',
  `start_time` DATE NOT NULL COMMENT '开始日期',
  `end_time` DATE NOT NULL COMMENT '结束日期',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态 0-禁用 1-启用',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cycle_code` (`cycle_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='绩效周期配置表';

-- 二、表关系说明（极简清晰）
-- 目标主表 ← 生成记录表 ← 方案表（1:N:N）
-- 目标主表 ← 润色表（1:N）
-- 目标主表 ← 体检表（1:N）
-- 周期配置表 → 所有表（通过cycle_code关联）