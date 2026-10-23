#!/usr/bin/env python3
"""生成 AI 新闻博客文章，并同步首页 / 归档 / 标签页 (Hexo 静态结构)。"""
import argparse, html, json, os, re, sys

BLOG_DIR = "/root/.openclaw/workspace/ai-news-blog-source"
SITE = "/ai-news-blog"


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def write(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)


def insert_before(path, marker, block, after=False):
    """在 path 文本中插入 block；after=True 表示插到 marker 之后。"""
    if not os.path.exists(path):
        return False
    s = read(path)
    if block.strip() in s:
        return False
    i = s.find(marker)
    if i < 0:
        return False
    if after:
        i += len(marker)
    s = s[:i] + block + s[i:]
    write(path, s)
    return True


def article_body(items, intro=None):
    out = []
    if intro:
        out.append("<h2>今日要点速览</h2>")
        out.append("<ul>")
        for line in intro:
            out.append(f"<li>{line}</li>")
        out.append("</ul>")
    out += ["<h2>今日AI科技要闻</h2>", "<ul>"]
    for it in items:
        t = html.escape(it.get("title", ""))
        l = html.escape(it.get("link", ""))
        sn = html.escape(it.get("snippet", ""))[:260]
        out.append(f'<li><a href="{l}" target="_blank">{t}</a></li>')
        if sn:
            out.append(f'<p style="color:#666;font-size:14px;margin:5px 0 15px 0;">{sn}</p>')
    out.append("</ul>")
    return "\n".join(out)


def archive_entry(url, iso, m, d, title):
    return f"""
    <article class="archive-article archive-type-post">
  <div class="archive-article-inner">
    <header class="archive-article-header">
      <a href="{url}" class="archive-article-date">
  <time class="dt-published" datetime="{iso}" itemprop="datePublished">{m}月 {d}</time>
</a>

    <h1 itemprop="name">
      <a class="archive-article-title" href="{url}">{html.escape(title)}</a>
    </h1>

    </header>
  </div>
</article>
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", required=True)
    ap.add_argument("--news", required=True)
    ap.add_argument("--title", default=None)
    args = ap.parse_args()

    y, m, d = args.date.split("-")
    title = args.title or f"{y}年{int(m)}月{int(d)}日 AI新闻汇总"
    slug = f"{args.date}-ai-news"
    url = f"{SITE}/{y}/{m}/{d}/{slug}/"
    iso = f"{args.date}T08:00:00.000Z"
    data = json.load(open(args.news, encoding="utf-8"))
    items = data["items"] if isinstance(data, dict) else data
    intro = data.get("intro", []) if isinstance(data, dict) else []
    body = article_body(items, intro)

    # 1) 文章页
    article_dir = f"{BLOG_DIR}/{y}/{m}/{d}/{slug}"
    page = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>{html.escape(title)} | AI新闻博客</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="每日AI科技新闻汇总">
  <meta property="og:title" content="{html.escape(title)}">
  <meta property="og:url" content="https://chu-jue.github.io{url}">
  <meta property="article:published_time" content="{iso}">
  <meta property="article:author" content="初觉">
  <link rel="stylesheet" href="{SITE}/css/style.css">
  <meta name="generator" content="Hexo 7.3.0">
</head>
<body>
  <div id="container">
    <div id="wrap">
      <header id="header">
        <div id="banner"></div>
        <div id="header-outer" class="outer">
          <div id="header-title" class="inner">
            <h1 id="logo-wrap"><a href="{SITE}/" id="logo">AI新闻博客</a></h1>
            <h2 id="subtitle-wrap"><a href="{SITE}/" id="subtitle">每日AI热点资讯</a></h2>
          </div>
        </div>
      </header>
      <div class="outer">
        <section id="main">
          <article class="article article-type-post">
            <div class="article-meta">
              <a class="article-date"><time>{args.date}</time></a>
            </div>
            <div class="article-inner">
              <header class="article-header">
                <h1 class="article-title">{html.escape(title)}</h1>
              </header>
              <div class="article-entry">
                {body}
                <hr>
                <p style="margin-top:20px;"><a href="{SITE}/">&larr; 返回首页</a></p>
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
"""
    write(f"{article_dir}/index.html", page)

    # 2) 首页文章列表
    idx_block = f"""
<article id="post-{slug}" class="h-entry article article-type-post" itemprop="blogPost" itemscope itemtype="https://schema.org/BlogPosting">
  <div class="article-meta">
    <a href="{url}" class="article-date">
  <time class="dt-published" datetime="{iso}" itemprop="datePublished">{args.date}</time>
</a>
  </div>
  <div class="article-inner">
      <header class="article-header">
    <h1 itemprop="name">
      <a class="p-name article-title" href="{url}">{html.escape(title)}</a>
    </h1>
      </header>
    <div class="e-content article-entry" itemprop="articleBody">
      {body}
    </div>
  </div>
</article>
"""
    insert_before(f"{BLOG_DIR}/index.html", '<article id="post-', idx_block)

    # 3) 归档 / 标签列表
    aentry = archive_entry(url, iso, int(m), int(d), title)
    for p in [f"{BLOG_DIR}/archives/index.html",
              f"{BLOG_DIR}/archives/{y}/index.html",
              f"{BLOG_DIR}/archives/{y}/{m}/index.html",
              f"{BLOG_DIR}/tags/AI/index.html",
              f"{BLOG_DIR}/tags/新闻/index.html"]:
        if os.path.exists(p):
            insert_before(p, '<div class="archives">', aentry, after=True)
        elif p.endswith(f"{m}/index.html"):
            tmpl = read(f"{BLOG_DIR}/archives/2026/03/index.html")
            head = tmpl.split('<div class="archives">')[0] + '<div class="archives">'
            tail = "</div></section>" + tmpl.split("</div></section>", 1)[1]
            write(p, head + aentry + "\n    " + tail)

    print(f"OK: {article_dir}/index.html")


if __name__ == "__main__":
    main()
