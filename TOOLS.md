# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

### 网络搜索
- 使用 MiniMax Web Search (mcporter call minimax.web_search)
- 配置: MINIMAX_API_KEY 已配置
- 用途: 搜索AI新闻、最新资讯等

### GitHub
- username: chu-jue
- token: 存放于 `/root/.openclaw/workspace/.github_token`（已 gitignore，勿写入仓库或提交历史）
- 凭证方式: `credential.helper store --file=/root/.openclaw/workspace/.git-credentials`
- remote URL 不要内嵌 token
