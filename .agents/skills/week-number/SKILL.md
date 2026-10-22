# Week Number Skill

获取指定日期是当年的第几周。

## 使用方法

运行 Python 脚本计算周数：

```bash
python3 -c "
import datetime
import sys

# 获取日期（默认今天）
if len(sys.argv) > 1:
    date_str = sys.argv[1]
    try:
        today = datetime.datetime.strptime(date_str, '%Y-%m-%d').date()
    except:
        print('日期格式错误，请使用 YYYY-MM-DD 格式')
        sys.exit(1)
else:
    today = datetime.date.today()

iso_week = today.isocalendar()[1]
print(f'{today} 是第 {iso_week} 周')
"
```

或者指定日期：
```bash
python3 -c "import datetime; d=datetime.date(2026,3,17); print(f'第{d.isocalendar()[1]}周')"
```

## 说明

- **ISO周**: 周一为一周的第一天
- 2026年3月17日 = 第12周
