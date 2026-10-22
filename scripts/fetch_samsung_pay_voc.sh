#!/bin/bash
# 三星钱包VOC抓取脚本
# 每天从盖乐世社区抓取三星钱包的问题反馈/讨论帖子

OUTPUT_FILE="/root/.openclaw/workspace/scripts/voc_output.txt"
LAST_VOC_FILE="/root/.openclaw/workspace/scripts/last_voc.json"
USER_CHAT_ID="ou_62a864e6b43b6d9ad653f7207d0363f2"

# 获取当前日期
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# 抓取三星钱包讨论页面
CONTENT=$(curl -s "https://www.galaxyclub.cn/bbs/pay-348-last-0.html" | grep -oP '<a href="/thread-\d+-\d+-\d+\.html"[^>]*>[^<]+</a>' | head -20)

# 提取帖子标题和链接
TITLES=$(echo "$CONTENT" | sed -n 's/.*>\([^<]*\)<\/a>.*/\1/p')

if [ -z "$TITLES" ]; then
    echo "[$DATE] 未能获取到帖子内容" >> /root/.openclaw/workspace/scripts/voc.log
    exit 1
fi

# 格式化输出
echo "📱 三星钱包VOC动态 - $DATE" > "$OUTPUT_FILE"
echo "==============================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

count=1
echo "$TITLES" | while read -r title; do
    if [ -n "$title" ]; then
        echo "$count. $title" >> "$OUTPUT_FILE"
        count=$((count + 1))
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "来源: 盖乐世社区 - 三星钱包讨论区" >> "$OUTPUT_FILE"

# 发送消息通过 OpenClaw Gateway API
curl -s -X POST "http://localhost:8080/api/messages" \
    -H "Content-Type: application/json" \
    -d "{
        \"chat_id\": \"$USER_CHAT_ID\",
        \"message\": \"$(cat $OUTPUT_FILE)\"
    }" >> /root/.openclaw/workspace/scripts/voc.log 2>&1

echo "[$DATE] VOC抓取完成" >> /root/.openclaw/workspace/scripts/voc.log
