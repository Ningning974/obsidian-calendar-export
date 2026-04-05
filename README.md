# Calendar Export Skill

将 macOS Calendar 日程导出到 Obsidian Markdown 文件。

## 文件结构

```
.obsidian/skills/calendar-export/
├── skill.md              # Skill 定义文件
├── export-calendar.swift # Swift 主脚本
├── run.sh                # Shell 包装脚本
└── README.md             # 本文件
```

## 使用方法

### 基本用法

```bash
# 导出今天（默认）
./run.sh

# 导出自定义日期范围
./run.sh --start-date 2026-04-01 --end-date 2026-04-30

# 指定输出目录
./run.sh --output-dir "daily schedule/2026"

# 排除特定日历（包含匹配）
./run.sh --exclude "节假日,生日,提醒"
```

### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--start-date` | 起始日期 (YYYY-MM-DD) | 今天 |
| `--end-date` | 结束日期 (YYYY-MM-DD) | 与 start-date 相同 |
| `--output-dir` | 输出目录 | `daily schedule` |
| `--exclude` | 排除的日历名称（包含匹配） | `节假日,计划的提醒事项` |

## 输出格式

### 文件命名

- 每天一个文件
- 格式: `YYYY-MM-DD.md`
- 例如: `2026-04-01.md`

### 文件结构

```markdown
---
type: daily_schedule
date: 2026-04-01
weekday: 2026-04-01 (周二)
events: 3
---

### 09:00 - 10:30 | 项目会议
---
type: calendar_event
date: 2026-04-01
start: 09:00
end: 10:30
category: 工作
---
**活动内容**: 项目会议
**备注**: 准备演示文档

### 全天 | 全天
---
type: calendar_event
date: 2026-04-02
duration: 全天
category: 个人
---
**活动内容**: 休息日
```

## 首次运行

首次运行时，系统会弹出日历访问权限请求，请点击"允许"。

## 技术实现

- **语言**: Swift 5.x
- **框架**: EventKit (macOS 原生日历框架)
- **输出**: UTF-8 编码的 Markdown 文件
- **路径**: 自动定位到 Obsidian Vault 根目录
