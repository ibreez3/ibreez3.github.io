# ibreez3.github.io

基于 Astro 的个人博客项目

## 分支说明

- `develop` - 源代码分支（Markdown 文章、配置文件）
- `blog` - 编译后的静态文件分支（由 GitHub Actions 自动部署）

## 本地开发

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build
```

## 写文章

在 `src/content/posts/` 目录下创建 Markdown 文件：

```markdown
---
title: 文章标题
date: 2026-02-10
tags: [标签1, 标签2]
category: 分类
---

文章内容...
```

## 部署

推送到 `develop` 分支后，GitHub Actions 会自动构建并部署到 `blog` 分支。
博客访问地址：https://ibreez3.github.io/
