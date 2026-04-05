---
description: 导出 macOS Calendar 日程到 Obsidian Markdown v1.0
prompt: |
  # Calendar Export Skill v1.0

  导出 macOS Calendar 日程到 Obsidian Markdown 文件。

  ## 参数

  - `--start-date`: 起始日期 (格式: YYYY-MM-DD，默认: 今天)
  - `--end-date`: 结束日期 (格式: YYYY-MM-DD，默认: start-date)
  - `--output-dir`: 输出目录 (默认: daily schedule)
  - `--exclude`: 排除的日历名称（包含匹配），用逗号分隔 (默认: 节假日,计划的提醒事项)

  ## 用法示例

  ```bash
  # 导出今天
  /calendar-export

  # 导出自定义日期范围
  /calendar-export --start-date 2026-04-01 --end-date 2026-04-30

  # 指定输出目录
  /calendar-export --output-dir "daily schedule/2026"

  # 排除特定日历
  /calendar-export --exclude "节假日,生日,提醒"
  ```

  ## 输出格式

  - 每天一个文件，文件名: `YYYY-MM-DD.md`
  - YAML frontmatter 包含结构化元数据
  - 跨日事件自动归类到主要活动日期
  - 2026 年文档存储到 `daily schedule/2026年/`

  ## 技术实现

  使用 Swift + EventKit 框架读取 macOS Calendar 数据。
---
