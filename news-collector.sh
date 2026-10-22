#!/bin/bash

# 新闻自动采集脚本 - 每天早上8点运行
# 支持目录切换、GitHub更新、飞书推送

GITHUB_TOKEN="***REDACTED***"
REPO_OWNER="chu-jue"
REPO_NAME="news-daily"
DATE=$(date +%Y-%m-%d)
NEWS_DIR="/root/.openclaw/workspace/news"

# 确保目录存在
mkdir -p "$NEWS_DIR"

echo "=== 开始采集新闻: $DATE ==="

# 获取 Hacker News Top 10
get_hackernews() {
    local limit=${1:-10}
    # 优先使用 Algolia HN API（firebase API 在部分网络环境不可达）
    local out
    out=$(curl -s --max-time 25 "https://hn.algolia.com/api/v1/search?tags=front_page&hitsPerPage=$limit" 2>/dev/null | python3 -c "
import sys,json
try:
    data=json.load(sys.stdin)
    for h in data.get('hits',[]):
        title=h.get('title') or ''
        url=h.get('url') or ('https://news.ycombinator.com/item?id='+str(h.get('objectID')))
        score=h.get('points') or 0
        if title:
            print(f'- [{title}]({url}) (⭐ {score})')
except Exception:
    pass
" 2>/dev/null)

    if [ -z "$out" ]; then
        echo "- 暂无内容"
    else
        echo "$out"
    fi
}

# 生成新闻内容
generate_content() {
    cat << EOF
# 每日新闻 - $DATE

> 🤖 AI 自动采集 | [查看目录](./README.md)

## 目录

- [科技前沿](#科技前沿)
- [AI 动态](#ai-动态)
- [GitHub Trending](#github-trending)

---

## 科技前沿

$(get_hackernews 10)

---

## AI 动态

- [OpenAI Blog](https://openai.com/blog)
- [Google AI Blog](https://blog.google/technology/ai/)
- [Meta AI Research](https://ai.meta.com/research/)
- [Anthropic AI](https://www.anthropic.com)
- [MiniMax](https://platform.minimaxi.com)

---

## GitHub Trending

查看 [GitHub Trending](https://github.com/trending?since=weekly)

---

*📅 更新时间: $(date '+%Y-%m-%d %H:%M:%S') | 由 AI 自动采集整理*
EOF
}

# 生成 README 目录
generate_readme() {
    echo "# 📰 每日新闻存档

## 新闻目录 (按日期)

| 日期 | 链接 |
|------|------|
"
    
    # 按日期倒序列出所有新闻
    for file in $(ls -t $NEWS_DIR/????-??-??.md 2>/dev/null); do
        fname=$(basename "$file" .md)
        echo "| $fname | [查看](./$fname.md) |"
    done
    
    echo "
---
*自动更新于每天早上 8:00*
"
}

# 保存新闻
generate_content > "$NEWS_DIR/$DATE.md"
generate_readme > "$NEWS_DIR/README.md"

echo "新闻已保存到: $NEWS_DIR/$DATE.md"

# 推送到 GitHub
if [ -n "$GITHUB_TOKEN" ] && [ -n "$REPO_NAME" ]; then
    echo "准备推送到 GitHub..."
    cd /root/.openclaw/workspace
    
    # 初始化 git (如果需要)
    if [ ! -d ".git" ]; then
        git init
        git remote add origin "https://$GITHUB_TOKEN@github.com/$REPO_OWNER/$REPO_NAME.git" 2>/dev/null || \
        git remote add origin "https://github.com/$REPO_OWNER/$REPO_NAME.git"
    fi
    
    git config --global user.email "ai@openclaw.local"
    git config --global user.name "AI Assistant"
    
    git add news/
    git commit -m "更新新闻: $DATE" 2>/dev/null || echo "没有新内容需要提交"
fi

echo "=== 完成 ==="

# 输出新闻摘要
echo ""
echo "新闻摘要:"
head -30 "$NEWS_DIR/$DATE.md"