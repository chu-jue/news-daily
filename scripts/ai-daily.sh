#!/bin/bash
# AI日报获取脚本 - 每天早上8点执行

DATE=$(date "+%Y-%m-%d")
WORKDIR="/root/.openclaw/workspace"
LOGFILE="$WORKDIR/logs/ai-daily.log"

mkdir -p "$WORKDIR/logs"

echo "[$(date)] 开始获取AI日报..." >> $LOGFILE

# 获取36氪AI快讯
KRAI_CONTENT=$(curl -s "https://www.36kr.com/newsflashes" 2>/dev/null | grep -oP '(?<=<p class="text-[a-z]-?[^"]*">)[^<]+(?=</p>)' | head -15)

if [ -z "$KRAI_CONTENT" ]; then
    # 备用方法获取
    KRAI_CONTENT=$(curl -s "https://www.36kr.com/information/AI/" 2>/dev/null | grep -oP 'title\">[^<]+' | head -20 | sed 's/title">//')
fi

# 构建消息
MSG="🤖 **AI日报 - $DATE**\n\n"
MSG+="【36氪AI快讯】\n"

# 添加36氪内容
if [ -n "$KRAI_CONTENT" ]; then
    echo "$KRAI_CONTENT" | head -10 | while read line; do
        MSG+="- ${line}\n"
    done
else
    MSG+="暂无最新快讯\n"
fi

MSG+="\n💡 *每天早上8点自动推送*"

# 保存到临时文件
echo -e "$MSG" > "$WORKDIR/tmp/ai-daily-$DATE.txt"

echo "[$(date)] AI日报获取完成" >> $LOGFILE
