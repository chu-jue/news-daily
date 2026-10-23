#!/usr/bin/env python3
"""通过 GitHub REST API 推送文件（github.com 直连被墙时的兜底方案）。"""
import base64, json, os, sys, urllib.request, urllib.parse

API = "https://api.github.com"
REPO = "chu-jue/ai-news-blog"
REF = "gh-pages"
TOKEN = open("/root/.openclaw/workspace/.github_token").read().strip()


def req(method, path, data=None):
    url = API + path
    body = json.dumps(data).encode() if data is not None else None
    r = urllib.request.Request(url, data=body, method=method)
    r.add_header("Authorization", "Bearer " + TOKEN)
    r.add_header("Accept", "application/vnd.github+json")
    r.add_header("X-GitHub-Api-Version", "2022-11-28")
    if body:
        r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r, timeout=45) as resp:
            return resp.status, json.loads(resp.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")


def push(files, message):
    for path, content in files:
        p = path.lstrip("/")
        status, info = req("GET", f"/repos/{REPO}/contents/{urllib.parse.quote(p)}?ref={REF}")
        sha = info.get("sha") if status == 200 else None
        payload = {
            "message": message,
            "content": base64.b64encode(content.encode()).decode(),
            "branch": REF,
        }
        if sha:
            payload["sha"] = sha
        status, res = req("PUT", f"/repos/{REPO}/contents/{urllib.parse.quote(p)}", payload)
        print(status, p, res.get("content", {}).get("path", "") or res.get("message", ""))


if __name__ == "__main__":
    base = sys.argv[1]
    message = sys.argv[2]
    files = []
    for rel in sys.argv[3:]:
        full = os.path.join(base, rel)
        files.append((rel, open(full, encoding="utf-8").read()))
    push(files, message)
