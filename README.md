# Obsidian Calendar Export

[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/macOS-11%2B-blue)](https://www.apple.com/macos/)

将 macOS Calendar 日程导出到 Obsidian Markdown 文件，便于 Claude 等工具体制分析日程管理效率。

## 功能特性

- ✅ 自动导出 macOS Calendar 日程到 Markdown
- ✅ 每天一个文件，按日期组织
- ✅ 时间分布统计（上午/下午/晚上）
- ✅ 跨日事件支持（如睡眠自动显示"昨日延续"）
- ✅ 睡眠时长自动计算
- ✅ 日历类型 Emoji 图标
- ✅ 节假日自动排除（可配置）
- ✅ 按年份自动组织输出目录（2026 → 2026年/）

## 安装

### 方式一：下载使用

```bash
# 克隆仓库
git clone https://github.com/Ningning974/obsidian-calendar-export.git
cd obsidian-calendar-export

# 或者直接下载 ZIP 文件解压
```

### 方式二：集成到 Obsidian

1. 将整个 `calendar-export` 文件夹复制到你的 Obsidian vault 的 `.obsidian/skills/` 目录下：
   ```
   你的Vault/.obsidian/skills/calendar-export/
   ├── skill.md
   ├── export-calendar.swift
   ├── run.sh
   └── README.md
   ```

2. 首次运行时会请求日历访问权限，请点击"允许"

## 使用方法

### 直接运行脚本

```bash
cd /path/to/calendar-export

# 导出今天
./export-calendar.swift

# 导出自定义日期范围
./export-calendar.swift --start-date 2026-04-01 --end-date 2026-04-30

# 排除特定日历
./export-calendar.swift --exclude "节假日,生日,提醒"
```

### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--start-date` | 起始日期 (YYYY-MM-DD) | 今天 |
| `--end-date` | 结束日期 (YYYY-MM-DD) | 与 start-date 相同 |
| `--output-dir` | 输出目录 | `daily schedule` |
| `--exclude` | 排除的日历名称（包含匹配），逗号分隔 | `节假日,计划的提醒事项` |

## 输出格式

### 文件命名

```
daily schedule/2026年/2026-04-05.md
```

- 每天一个文件：`YYYY-MM-DD.md`
- 2026 年文档存储到 `2026年/` 子目录
- 其他年份存储在 `daily schedule/` 根目录

### 文件内容

```markdown
---
type: daily_schedule
date: 2026-04-05
weekday: 2026-04-05 (周日)
events: 8
---
⏰ 时间分布：上午 4.8h | 下午 7.8h | 晚上 0.0h

### 😴 昨日延续：#睡觉
---
入睡时间: 23:30
起床时间: 07:15
睡眠时长: 7.8

### 07:15 - 07:40 🔋 正念冥想🧘
---
start: 07:15
end: 07:40
分类：充电游乐场🔋
备注：（如果有）

### 13:15 - 14:30 🎮 #看综艺
---
start: 13:15
end: 14:30
分类：多巴胺
备注：看浪姐
```

### Emoji 映射

| 日历类型 | Emoji |
|----------|-------|
| 充电游乐场 | 🔋 |
| Operating System | 👿 |
| Reading, Study & PKM | 📚 |
| 多巴胺 | 🎮 |
| 必要时间 | ⚡ |
| Planning | 📝 |
| 工作 | 💼 |
| Foundation | 🏗️ |
| Growth | 📈 |

## 技术实现

- **语言**: Swift 5.x
- **框架**: EventKit (macOS 原生日历框架)
- **输出**: UTF-8 编码的 Markdown 文件
- **依赖**: 无

## 自动运行

### 使用 Cron 每天自动导出

```bash
# 编辑 crontab
crontab -e

# 添加每天 23:59 自动导出
59 23 * * * /Users/zhangyuning/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/你的Vault/.obsidian/skills/calendar-export/export-calendar.swift
```

### 查看当前定时任务
```bash
crontab -l
```

## 常见问题

### Q: 首次运行提示权限错误
A: 系统设置 → 隐私与安全性 → 日历 → 确保已勾选对应应用

### Q: 跨日事件显示在哪里
A: 跨日事件（如睡眠）会显示为"昨日延续"，并归类到主要活动日期

### Q: 时间分布为什么不包括睡眠
A: 时间分布只统计纯白天活动，睡眠不计入。这样反映的是"清醒时间"分配。

### Q: 如何修改默认排除的日历
A: 使用 `--exclude` 参数，逗号分隔多个日历名称（支持包含匹配）

### Q: 2026 年的文件为什么在 `2026年/` 目录下
A: 这是硬编码的年份规则，如需修改其他年份，编辑 `export-calendar.swift` 中的 `year == 2026` 条件。

## 效率分析建议

配合 Claude 使用时，可以询问以下问题：

- "分析我今天的时间分配"
- "计算我本周的工作学习占比"
- "找出我的高效率时段"
- "根据备注中的满意度，分析哪些活动值得保留"

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**Created by**: [Ningning974](https://github.com/Ningning974)
