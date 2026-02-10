#!/bin/bash

# GitHub Actions 构建监控脚本
# 作者：OpenClaw
# 用途：监控 GitHub Actions 构建状态

set -e

REPO="ibreez3/ibreez3.github.io"
INTERVAL=30  # 检查间隔（秒）
TIMEOUT=600  # 超时时间（秒）

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 开始监控 GitHub Actions 构建状态${NC}"
echo -e "${BLUE}仓库: ${REPO}${NC}"
echo -e "${BLUE}----------------------------------------${NC}"

# 获取最新的 workflow run
LATEST_RUN=$(gh run list --repo ${REPO} --limit 1 --json databaseId,status,conclusion,displayTitle,workflowName,createdAt --jq '.[0]')

if [ -z "$LATEST_RUN" ]; then
    echo -e "${RED}❌ 错误：无法获取最新的构建${NC}"
    exit 1
fi

RUN_ID=$(echo $LATEST_RUN | jq -r '.databaseId')
STATUS=$(echo $LATEST_RUN | jq -r '.status')
CONCLUSION=$(echo $LATEST_RUN | jq -r '.conclusion')
TITLE=$(echo $LATEST_RUN | jq -r '.displayTitle')
WORKFLOW=$(echo $LATEST_RUN | jq -r '.workflowName')
CREATED=$(echo $LATEST_RUN | jq -r '.createdAt')

echo -e "${BLUE}📋 构建信息：${NC}"
echo "  Workflow: ${WORKFLOW}"
echo "  标题: ${TITLE}"
echo "  状态: ${STATUS}"
echo "  结论: ${CONCLUSION}"
echo "  开始时间: ${CREATED}"
echo -e "${BLUE}Run ID: ${RUN_ID}${NC}"
echo ""

# 如果构建已完成，直接显示结果
if [ "$STATUS" = "completed" ]; then
    if [ "$CONCLUSION" = "success" ]; then
        echo -e "${GREEN}✅ 构建成功！${NC}"
        echo -e "${GREEN}🚀 博客地址: https://ibreez3.github.io/${NC}"
    else
        echo -e "${RED}❌ 构建失败！${NC}"
        echo ""
        echo -e "${YELLOW}查看详细日志：${NC}"
        echo "  gh run view --repo ${REPO} ${RUN_ID} --log"
    fi
    exit 0
fi

# 监控构建过程
echo -e "${YELLOW}⏳ 构建进行中...${NC}"
echo -e "${YELLOW}每 ${INTERVAL} 秒检查一次${NC}"
echo ""

ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    # 获取最新状态
    RUN_INFO=$(gh run view --repo ${REPO} ${RUN_ID} --json status,conclusion --jq '.')

    CURRENT_STATUS=$(echo $RUN_INFO | jq -r '.status')
    CURRENT_CONCLUSION=$(echo $RUN_INFO | jq -r '.conclusion')

    if [ "$CURRENT_STATUS" = "completed" ]; then
        echo ""
        if [ "$CURRENT_CONCLUSION" = "success" ]; then
            echo -e "${GREEN}✅ 构建成功！${NC}"
            echo -e "${GREEN}🚀 博客地址: https://ibreez3.github.io/${NC}"
        else
            echo -e "${RED}❌ 构建失败！${NC}"
            echo ""
            echo -e "${YELLOW}查看详细日志：${NC}"
            echo "  gh run view --repo ${REPO} ${RUN_ID} --log"
        fi
        exit 0
    fi

    # 显示进度
    echo -ne "\r${YELLOW}⏳ 等待中... ${ELAPSED}/${TIMEOUT} 秒${NC}"

    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo ""
echo -e "${RED}⏰ 超时：构建未在 ${TIMEOUT} 秒内完成${NC}"
exit 1
