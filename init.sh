#!/bin/bash

# 博客初始化脚本
# 此脚本会：
# 1. 初始化 develop 分支
# 2. 提交所有文件
# 3. 推送到 GitHub

set -e

echo "🚀 开始初始化博客..."

# 检查是否在 git 仓库中
if [ ! -d ".git" ]; then
  echo "❌ 错误：请先在 git 仓库中运行此脚本"
  exit 1
fi

# 创建 develop 分支（如果不存在）
git branch develop 2>/dev/null || echo "✅ develop 分支已存在"

# 切换到 develop 分支
git checkout develop || git checkout -b develop

# 添加所有文件
git add .

# 提交
git commit -m "🎉 初始化博客项目

- 使用 Astro 框架
- 配置 GitHub Actions 自动部署
- 设置 develop/blog 分支结构"

echo "✅ 本地提交完成！"
echo ""
echo "📝 下一步："
echo "1. 推送到远程仓库："
echo "   git push -u origin develop"
echo ""
echo "2. 在 GitHub 仓库设置中："
echo "   - Settings → Pages"
echo "   - Source 选择 'GitHub Actions'"
echo ""
echo "3. 博客地址将是：https://ibreez3.github.io/"
