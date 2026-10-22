#!/bin/bash
# 每天早上8点：收集科技新闻 -> 生成博客 -> 推送GitHub -> 发送飞书

set -e

# 修复 cron 环境下的 PATH
export PATH="/root/.nvm/versions/node/v22.22.1/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

cd /root/.openclaw/workspace

echo "==== $(date) 开始每日新闻 ===="

# 获取日期
TODAY=$(date +%Y-%m-%d)
DATE_CN=$(date +%Y年%m月%d日)
MONTH=$(date +%m)
DAY=$(date +%d)

# 临时目录
TMP_DIR="/tmp/ai-news-blog"
BLOG_DIR="/root/.openclaw/workspace/ai-news-blog-source"

# 如果没有克隆过博客源码，先克隆
if [ ! -d "$BLOG_DIR/.git" ]; then
    echo "克隆博客源码..."
    rm -rf $BLOG_DIR
    git clone https://chu-jue:***REDACTED***@github.com/chu-jue/ai-news-blog.git $BLOG_DIR
fi

cd $BLOG_DIR

# 1. 搜索今日AI新闻
echo "搜索今日AI科技新闻..."
cd /root/.openclaw/workspace
mcporter call minimax.web_search query="2026年 ${MONTH}月${DAY}日 AI 人工智能 科技 最新新闻" > /tmp/search_result.json 2>/dev/null || echo '{}' > /tmp/search_result.json
cd - > /dev/null

# 解析搜索结果为HTML列表
NEWS_HTML_FILE="/tmp/news_html_$$.txt"
python3 << 'PYEOF' > "$NEWS_HTML_FILE"
import json, sys, html
try:
    with open('/tmp/search_result.json') as f:
        data = json.load(f)
    items = data.get('organic', [])[:10]
    if items:
        print('<ul>')
        for item in items:
            title = html.escape(item.get('title', ''))
            link = html.escape(item.get('link', ''))
            snippet = html.escape(item.get('snippet', ''))[:200]
            print(f'<li><a href="{link}" target="_blank">{title}</a></li>')
            if snippet:
                print(f'<p style="color:#666;font-size:14px;margin:5px 0 15px 0;">{snippet}...</p>')
        print('</ul>')
    else:
        print('<p>暂无新闻</p>')
except Exception as e:
    print(f'<p>Error: {str(e)}</p>')
PYEOF

NEWS_HTML=$(cat "$NEWS_HTML_FILE" 2>/dev/null || echo "<p>新闻加载失败</p>")
rm -f "$NEWS_HTML_FILE"

# 2. 创建博客文章
ARTICLE_DIR="$BLOG_DIR/2026/03/${DAY}/2026-03-${DAY}-ai-news"
mkdir -p "$ARTICLE_DIR"

# 生成HTML文章
cat > "$ARTICLE_DIR/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${DATE_CN} AI新闻汇总 | AI新闻博客</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="每日AI科技新闻汇总">
  <meta property="og:title" content="${DATE_CN} AI新闻汇总">
  <meta property="og:url" content="https://chu-jue.github.io/ai-news-blog/2026/03/${DAY}/2026-03-${DAY}-ai-news/">
  <meta property="article:published_time" content="${TODAY}T08:00:00.000Z">
  <meta property="article:author" content="初觉">
  <link rel="stylesheet" href="/ai-news-blog/css/style.css">
  <meta name="generator" content="Hexo 7.3.0">
</head>
<body>
  <div id="container">
    <div id="wrap">
      <header id="header">
        <div id="banner"></div>
        <div id="header-outer" class="outer">
          <div id="header-title" class="inner">
            <h1 id="logo-wrap"><a href="/ai-news-blog/" id="logo">AI新闻博客</a></h1>
            <h2 id="subtitle-wrap"><a href="/ai-news-blog/" id="subtitle">每日AI热点资讯</a></h2>
          </div>
        </div>
      </header>
      <div class="outer">
        <section id="main">
          <article class="article article-type-post">
            <div class="article-meta">
              <a class="article-date"><time>${TODAY}</time></a>
            </div>
            <div class="article-inner">
              <header class="article-header">
                <h1 class="article-title">${DATE_CN} AI新闻汇总</h1>
              </header>
              <div class="article-entry">
                <h2>今日AI科技要闻</h2>
                $NEWS_HTML
                <hr>
                <p style="margin-top:20px;"><a href="/ai-news-blog/">← 返回首页</a></p>
              </div>
            </div>
          </article>
        </section>
      </div>
      <footer id="footer">
        <div class="outer">
          <div id="footer-info">
            <p>Powered by <a href="http://hexo.io/" target="_blank">Hexo</a></p>
          </div>
        </div>
      </footer>
    </div>
  </div>
</body>
</html>
EOF

echo "已创建文章: $ARTICLE_DIR/index.html"

# 3. 提交并推送
git add .
git commit -m "添加 ${DATE_CN} AI新闻"
git push -q origin gh-pages

echo "已推送到GitHub"

# 4. 发送飞书通知
echo "发送飞书通知..."
/root/.nvm/versions/node/v22.22.1/bin/openclaw message send \
  --channel feishu \
  --target ou_62a864e6b43b6d9ad653f7207d0363f2 \
  --message "☀️ 早安！${DATE_CN} AI新闻已更新：https://chu-jue.github.io/ai-news-blog/"

echo "飞书通知已发送"
echo "==== 完成 ===="
