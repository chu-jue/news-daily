#!/bin/bash
# 每天早上8点：AI新闻日报 -> 博客文章 -> 推送 GitHub Pages -> 飞书通知
set -u
export PATH="/root/.nvm/versions/node/v22.22.1/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

WORKDIR="/root/.openclaw/workspace"
BLOG_DIR="$WORKDIR/ai-news-blog-source"
TODAY=$(date +%Y-%m-%d)
Y=$(date +%Y); MONTH=$(date +%m); DAY=$(date +%d)
SLUG="$TODAY-ai-news"
NEWS_JSON="$WORKDIR/tmp/news-$TODAY.json"

mkdir -p "$WORKDIR/tmp" "$WORKDIR/logs"
cd "$WORKDIR"

echo "==== $TODAY AI日报开始 ===="

# 1) 搜索新闻
mcporter call minimax.web_search query="$Y年${MONTH}月${DAY}日 AI 人工智能 大模型 最新动态" > "/tmp/search_$TODAY.json" 2>/dev/null || echo '{}' > "/tmp/search_$TODAY.json"

python3 - "$TODAY" "/tmp/search_$TODAY.json" "$NEWS_JSON" << 'PYEOF'
import json, sys, html
date, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.load(open(src))
except Exception:
    data = {}
items = []
for it in (data.get('organic') or [])[:12]:
    title = (it.get('title') or '').strip()
    link = (it.get('link') or '').strip()
    sn = ' '.join((it.get('snippet') or '').split())
    if title and link:
        items.append({'title': title, 'link': link, 'snippet': sn})
json.dump({'items': items}, open(dst, 'w'), ensure_ascii=False, indent=1)
print(f"收集到 {len(items)} 条")
PYEOF

# 2) 生成文章 + 同步首页/归档/标签
python3 "$WORKDIR/scripts/build_blog.py" --date "$TODAY" --news "$NEWS_JSON"

# 3) 推送 GitHub（先 git，失败则走 REST API 兜底）
cd "$BLOG_DIR"
# 先与远端对齐：避免 REST API 兜底产生的远端提交让本地 git push 被拒
timeout 60 git fetch -q origin gh-pages 2>/dev/null
git reset -q --hard origin/gh-pages 2>/dev/null
git add -A >/dev/null 2>&1
git commit -q -m "添加 ${Y}年${MONTH}月${DAY}日 AI新闻" >/dev/null 2>&1
if timeout 90 git push -q origin gh-pages 2>/dev/null; then
    echo "git push 成功"
else
    echo "git push 失败，改用 REST API 兜底"
    cd "$WORKDIR"
    timeout 300 python3 scripts/gh_api_push.py ai-news-blog-source "添加 ${Y}年${MONTH}月${DAY}日 AI新闻" \
        index.html archives/index.html "archives/$Y/index.html" "archives/$Y/$MONTH/index.html" \
        tags/AI/index.html "tags/新闻/index.html" "$Y/$MONTH/$DAY/$SLUG/index.html" || echo "API 兜底也失败"
    # 兜底提交会让远端领先本地，重新对齐以便明天的 git push 可用
    cd "$BLOG_DIR"
    timeout 60 git fetch -q origin gh-pages 2>/dev/null
    git reset -q --hard origin/gh-pages 2>/dev/null && echo "本地已与远端重新对齐"
fi

# 4) 飞书通知
python3 - "$TODAY" "$NEWS_JSON" > /tmp/feishu_ai_daily.txt << 'PYEOF'
import json, sys
date, src = sys.argv[1], sys.argv[2]
items = json.load(open(src))['items']
lines = [f"☀️ 早安初觉！{date} AI 日报来啦", "", "【今日快讯】"]
for it in items[:8]:
    lines.append(f"• {it['title']}")
lines.append("")
lines.append(f"📖 完整日报：https://chu-jue.github.io/ai-news-blog/{date[:4]}/{date[5:7]}/{date[8:]}/{date}-ai-news/")
lines.append("😄 教官为你蹲守前排")
print("\n".join(lines))
PYEOF
timeout 120 openclaw message send --channel feishu --target ou_62a864e6b43b6d9ad653f7207d0363f2 --message "$(cat /tmp/feishu_ai_daily.txt)" 2>&1 | tail -1

echo "==== $TODAY 完成 ===="
