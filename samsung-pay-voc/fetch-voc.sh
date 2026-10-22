#!/bin/bash
# 抓取三星钱包VOC并发送到微信
# 定时任务：每天早上9点执行

GALAXY_URL="https://www.galaxyclub.cn"
PAY_FEEDBACK="$GALAXY_URL/bbs/pay-670-all-0.html"
BUG_FEEDBACK="$GALAXY_URL/bbs/pay-349-all-0.html"

STATE_FILE="/root/.openclaw/workspace/samsung-pay-voc/last_ids.txt"
LOG_FILE="/root/.openclaw/workspace/samsung-pay-voc/fetch.log"

mkdir -p "$(dirname "$STATE_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 初始化
if [ ! -f "$STATE_FILE" ]; then
    echo "" > "$STATE_FILE"
fi

# 获取最新帖子ID列表
get_latest_ids() {
    local url=$1
    curl -sL "$url" 2>&1 | grep -oE 'href="/thread-[0-9]+-[0-9]+-[0-9]+\.html"' | \
    sed 's/href="\/thread-//;s/-[0-9]\+-[0-9]\+\.html"//' | \
    sort -rn | uniq | head -10
}

# 获取问题反馈的最新帖子
log "开始抓取三星钱包VOC..."
PAY_IDS=$(get_latest_ids "$PAY_FEEDBACK")
BUG_IDS=$(get_latest_ids "$BUG_FEEDBACK")

# 合并并排序去重
ALL_IDS=$(echo -e "$PAY_IDS\n$BUG_IDS" | sort -rn | uniq | head -15)

# 读取上次已发送的ID
last_sent=$(cat "$STATE_FILE" 2>/dev/null)

# 找新帖子
new_posts=""
for id in $ALL_IDS; do
    # 检查是否已发送（精确匹配）
    if ! echo "$last_sent" | grep -qx "$id"; then
        new_posts="$new_posts $id"
    fi
done

if [ -z "$new_posts" ]; then
    log "没有新的VOC"
    exit 0
fi

log "发现新VOC: $new_posts"

# 构建消息
MESSAGE="📱 三星钱包 VOC 更新

"

for pid in $new_posts; do
    # 优先从问题反馈板块获取标题
    CONTENT=$(curl -sL "$PAY_FEEDBACK" 2>&1)
    DETAIL=$(echo "$CONTENT" | grep -E "thread-$pid-[0-9]+-[0-9]+\.html.*target" | head -1)
    
    # 如果问题反馈没有，尝试BUG反馈
    if [ -z "$DETAIL" ]; then
        CONTENT=$(curl -sL "$BUG_FEEDBACK" 2>&1)
        DETAIL=$(echo "$CONTENT" | grep -E "thread-$pid-[0-9]+-[0-9]+\.html.*target" | head -1)
    fi
    
    if [ -n "$DETAIL" ]; then
        TITLE=$(echo "$DETAIL" | grep -oE 'target="_blank">[^<]+' | sed 's/target="_blank">//' | head -1)
        
        # 判断板块
        board_id="670"
        if echo "$DETAIL" | grep -q "pay-349"; then
            board_id="349"
        fi
        
        LINK="https://www.galaxyclub.cn/thread-$pid-267-$board_id.html"
        
        MESSAGE="$MESSAGE▪️ $TITLE
🔗 $LINK

"
    fi
done

# 更新已发送ID (去重)
echo "$new_posts" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -rn | uniq > "$STATE_FILE"

# 打印消息
echo "$MESSAGE"