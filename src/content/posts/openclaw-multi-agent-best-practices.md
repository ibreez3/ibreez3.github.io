---
title: OpenClaw Multi-Agent 最佳实践：构建智能协作系统
date: 2026-02-10
description: 深入解析 OpenClaw 多智能体架构，从概念到实战，掌握主 Agent 协调、子 Agent 执行的最佳设计方案。
tags: [OpenClaw, Multi-Agent, AI, 架构设计, 实战]
category: AI
---

# OpenClaw Multi-Agent 最佳实践：构建智能协作系统

在现代 AI 应用中，单一智能体往往难以应对复杂任务。OpenClaw 的 Multi-Agent 功能允许我们创建多个独立的"大脑"，通过主 Agent 协调和子 Agent 执行，构建高效的智能协作系统。本文将从概念解析到实战配置，带你掌握 Multi-Agent 的最佳实践。

## 🧠 什么是 Multi-Agent？

### 核心概念

每个智能体（Agent）是一个完全独立的作用域，拥有自己的：

- **工作区**（Workspace）：独立的文件目录、AGENTS.md、SOUL.md、USER.md、本地笔记、人设规则
- **状态目录**（agentDir）：用于认证配置文件、模型注册表和每智能体配置
- **会话存储**：聊天历史 + 路由状态，位于 `~/.openclaw/agents/<agentId>/sessions` 下

### 关键隔离

- **认证独立**：每个智能体从自己的 `~/.openclaw/agents/<agentId>/agent/auth-profiles.json` 读取凭证
- **会话隔离**：主智能体凭证不会自动共享到子智能体
- **技能独立**：通过每个工作区的 `skills/` 文件夹实现

### 沙箱与权限

从 v2026.1.6 开始，每个智能体可以拥有独立的沙箱和工具限制：

```json5
{
  "agents": {
    "list": [
      {
        "id": "family",
        "workspace": "~/.openclaw/workspace-family",
        "sandbox": {
          "mode": "all",
          "scope": "agent"
        },
        "tools": {
          "allow": ["read"],
          "deny": ["exec", "write", "edit"]
        }
      }
    ]
  }
}
```

## 🎯 架构设计：主 Agent + 子 Agent

### 推荐架构

```
                    ┌─────────────┐
                    │   用户请求   │
                    └──────┬──────┘
                           │
                    ┌────────▼─────────┐
                    │   主 Agent      │ ← 协调者
                    │  (Coordinator)  │
                    │                 │
                    │ - 任务分解      │
                    │ - 结果汇总      │
                    │ - 路由调度      │
                    └────┬────┬───────┘
                         │    │
        ┌────────────────┘    └────────────────┐
        │                                      │
   ┌────▼─────────┐                      ┌───▼──────────┐
   │ 子 Agent A   │                      │ 子 Agent B   │
   │ (Researcher) │                      │ (Coder)     │
   │ - 信息搜集   │                      │ - 代码生成   │
   │ - 资料整理   │                      │ - 代码审查   │
   └──────┬───────┘                      └───┬──────────┘
          │                                      │
          └──────────────┬───────────────────────┘
                         │
                    ┌────▼─────────┐
                    │  最终输出    │
                    └─────────────┘
```

### 主 Agent 的职责

1. **任务理解与分解**：将复杂任务拆分为可执行的子任务
2. **子 Agent 调度**：根据任务类型分发给合适的子 Agent
3. **结果汇总与验证**：收集子 Agent 的输出，进行质量检查
4. **最终输出**：生成完整的、符合用户需求的响应

### 子 Agent 的职责

1. **专注领域**：每个子 Agent 专注于特定领域（代码、研究、测试等）
2. **独立执行**：在自己的工作区中完成任务
3. **结果返回**：将执行结果返回给主 Agent

## ⚙️ 实战配置

### 场景：代码审查自动化系统

#### 配置结构

```json5
{
  "agents": {
    "list": [
      {
        "id": "coordinator",
        "name": "主协调器",
        "default": true,
        "workspace": "~/.openclaw/workspace-coordinator",
        "model": "anthropic/claude-opus-4-5",
        "tools": {
          "allow": [
            "sessions_spawn",
            "sessions_send",
            "sessions_list",
            "read",
            "exec"
          ]
        }
      },
      {
        "id": "static-analyzer",
        "name": "静态分析专家",
        "workspace": "~/.openclaw/workspace-static",
        "model": "anthropic/claude-sonnet-4-5",
        "tools": {
          "allow": ["read", "exec"],
          "deny": ["write", "edit"]
        }
      },
      {
        "id": "security-scanner",
        "name": "安全扫描专家",
        "workspace": "~/.openclaw/workspace-security",
        "model": "anthropic/claude-sonnet-4-5",
        "tools": {
          "allow": ["read", "exec"],
          "deny": ["write", "edit"]
        }
      },
      {
        "id": "performance-analyzer",
        "name": "性能分析专家",
        "workspace": "~/.openclaw/workspace-perf",
        "model": "anthropic/claude-sonnet-4-5",
        "tools": {
          "allow": ["read", "exec"],
          "deny": ["write", "edit"]
        }
      }
    ]
  },

  // 启用智能体间通信
  "tools": {
    "agentToAgent": {
      "enabled": true,
      "allow": ["coordinator", "static-analyzer", "security-scanner", "performance-analyzer"]
    }
  },

  // 配置 bindings（如需要多账户）
  "bindings": [
    {
      "agentId": "coordinator",
      "match": { "channel": "*" }
    }
  ]
}
```

#### 工作流程

1. **用户请求**："帮我审查这个代码仓库的安全性和性能"
2. **主 Agent 分析**：识别需要静态分析、安全扫描、性能评估
3. **并行分发**：同时调用三个子 Agent
4. **收集结果**：等待所有子 Agent 完成任务
5. **汇总报告**：生成综合审查报告

### 场景：多渠道智能体路由

#### 配置示例：WhatsApp + Telegram

```json5
{
  "agents": {
    "list": [
      {
        "id": "chat",
        "name": "日常聊天",
        "workspace": "~/.openclaw/workspace-chat",
        "model": "anthropic/claude-sonnet-4-5"
      },
      {
        "id": "work",
        "name": "深度工作",
        "workspace": "~/.openclaw/workspace-work",
        "model": "anthropic/claude-opus-4-5"
      }
    ]
  },

  "bindings": [
    {
      "agentId": "chat",
      "match": { "channel": "whatsapp" }
    },
    {
      "agentId": "work",
      "match": { "channel": "telegram" }
    }
  ],

  "channels": {
    "whatsapp": {
      "dmPolicy": "pairing"
    },
    "telegram": {
      "dmPolicy": "pairing"
    }
  }
}
```

### 场景：单渠道多智能体（多人格）

#### 配置示例：一个 WhatsApp 号码，不同人

```json5
{
  "agents": {
    "list": [
      {
        "id": "alex",
        "name": "Alex",
        "workspace": "~/.openclaw/workspace-alex"
      },
      {
        "id": "mia",
        "name": "Mia",
        "workspace": "~/.openclaw/workspace-mia"
      }
    ]
  },

  "bindings": [
    {
      "agentId": "alex",
      "match": {
        "channel": "whatsapp",
        "peer": { "kind": "dm", "id": "+15551230001" }
      }
    },
    {
      "agentId": "mia",
      "match": {
        "channel": "whatsapp",
        "peer": { "kind": "dm", "id": "+15551230002" }
      }
    }
  ],

  "channels": {
    "whatsapp": {
      "dmPolicy": "allowlist",
      "allowFrom": ["+15551230001", "+15551230002"]
    }
  }
}
```

## 🚀 主 Agent 协调实战

### 使用 sessions_spawn 启动子 Agent

```javascript
// 在主 Agent 的代码或对话中执行
const spawnResult = await sessions_spawn({
  task: "对当前代码仓库进行安全漏洞扫描",
  agentId: "security-scanner",
  model: "anthropic/claude-sonnet-4-5",
  timeoutSeconds: 300,
  message: "请检查 src/ 目录下的所有代码，重点关注：\n1. SQL 注入风险\n2. XSS 漏洞\n3. 敏感信息泄露\n4. 依赖安全问题\n\n输出详细的发现和建议。"
});

// spawnResult 返回子 Agent 的 session key
console.log("子 Agent session:", spawnResult.sessionKey);
```

### 等待子 Agent 完成

主 Agent 可以：

1. **轮询状态**：定期检查子 Agent 的会话状态
2. **等待结果**：设置超时时间，等待子 Agent 完成任务
3. **超时处理**：如果超时，可以取消或重新分配任务

### 收集子 Agent 结果

```javascript
// 方式1：通过 sessions_history 获取历史
const history = await sessions_history({
  sessionKey: "agent:security-scanner:telegram:*"
});

// 方式2：子 Agent 主动通过 sessions_send 发送
await sessions_send({
  sessionKey: "agent:coordinator:*",
  message: "扫描完成，发现 3 个高危漏洞"
});
```

### 汇总最终结果

主 Agent 收集所有子 Agent 的结果后，生成综合报告：

```markdown
# 代码审查报告

## 🔍 静态分析
- 代码质量评分：8.5/10
- 主要问题：未处理的异常、缺少类型注解

## 🛡️ 安全扫描
- 发现漏洞：3 个高危，2 个中危
- 关键问题：SQL 注入风险（user-service.ts:45）

## ⚡ 性能分析
- 响应时间：平均 245ms
- 内存使用：峰值 512MB
- 优化建议：使用缓存减少数据库查询

## 💡 综合建议
1. 优先修复 3 个高危安全漏洞
2. 添加错误处理和日志记录
3. 引入 Redis 缓存层
4. 考虑使用 TypeScript 增强类型安全
```

## 🔒 安全最佳实践

### 1. 沙箱隔离

对于不可信的或高风险的子 Agent，使用严格的沙箱隔离：

```json5
{
  "id": "untrusted-code-runner",
  "sandbox": {
    "mode": "all",
    "scope": "agent",
    "docker": {
      "setupCommand": "apt-get update && apt-get install -y python3 python3-pip"
    }
  },
  "tools": {
    "allow": ["read"],
    "deny": ["exec", "write", "edit", "apply_patch"]
  }
}
```

### 2. 工具权限控制

```json5
{
  "tools": {
    "allow": [
      "sessions_spawn",      // 允许启动子 Agent
      "sessions_send",       // 允许发送消息
      "sessions_history",    // 允许读取历史
      "read"               // 允许读取文件
    ],
    "deny": [
      "write",             // 禁止写入文件
      "edit",              // 禁止编辑文件
      "apply_patch"        // 禁止应用补丁
    ]
  }
}
```

### 3. 智能体间通信控制

默认情况下，智能体到智能体的通信是关闭的。需要显式启用：

```json5
{
  "tools": {
    "agentToAgent": {
      "enabled": true,
      "allow": ["coordinator", "static-analyzer", "security-scanner"]
      // 只允许这些智能体互相通信
    }
  }
}
```

## 📊 性能优化建议

### 1. 并行执行

对于独立的任务，使用 `Promise.all` 并行启动多个子 Agent：

```javascript
const tasks = [
  spawnSubAgent({ agentId: "static-analyzer", task: "..." }),
  spawnSubAgent({ agentId: "security-scanner", task: "..." }),
  spawnSubAgent({ agentId: "performance-analyzer", task: "..." })
];

const results = await Promise.all(tasks);
```

### 2. 任务队列

对于大量任务，实现任务队列，避免同时启动过多子 Agent：

```javascript
const MAX_CONCURRENT = 3;
const queue = [];

async function processQueue() {
  const running = queue.filter(t => t.status === 'running').length;

  if (running >= MAX_CONCURRENT) return;

  const pendingTasks = queue.filter(t => t.status === 'pending');
  for (const task of pendingTasks.slice(0, MAX_CONCURRENT - running)) {
    task.status = 'running';
    await spawnSubAgent(task);
    task.status = 'completed';
  }
}
```

### 3. 超时与重试

```javascript
const SUBAGENT_TIMEOUT = 300; // 5 分钟

const result = await spawnSubAgent({
  task: "...",
  timeoutSeconds: SUBAGENT_TIMEOUT,
  cleanup: "delete" // 任务完成后删除子会话
});

// 如果失败，可以实现重试逻辑
if (!result.success) {
  console.log("子 Agent 失败，准备重试...");
}
```

## 🎨 人设与角色设计

### 为每个子 Agent 设计独特的人设

**静态分析专家（static-analyzer）**

```markdown
# AGENTS.md

你是一个代码静态分析专家。

## 你的专长
- 代码质量评估
- 最佳实践检查
- 代码风格审查
- 技术债务识别

## 你的输出风格
- 结构化的检查清单
- 具体的改进建议
- 优先级标注
- 代码示例

## 你的原则
- 关注可维护性
- 提倡简洁设计
- 重视类型安全
- 强调测试覆盖
```

**安全扫描专家（security-scanner）**

```markdown
# AGENTS.md

你是一个网络安全专家。

## 你的专长
- 漏洞识别
- 安全编码规范
- 依赖安全检查
- 渗透测试指导

## 你的输出风格
- 风险分级（高危/中危/低危）
- 具体的漏洞描述
- CVE 编码参考
- 修复建议和示例

## 你的原则
- 安全优先
- 防御深度
- 最小权限原则
- 持续监控
```

## 📝 工作区管理最佳实践

### 1. 目录结构

```
~/.openclaw/
├── workspace-coordinator/        # 主 Agent 工作区
│   ├── AGENTS.md
│   ├── SOUL.md
│   ├── USER.md
│   ├── skills/
│   └── docs/
│
├── workspace-static/            # 静态分析专家工作区
│   ├── AGENTS.md
│   ├── rules/                # 静态分析规则
│   └── templates/            # 检查模板
│
├── workspace-security/          # 安全扫描专家工作区
│   ├── AGENTS.md
│   ├── vulnerabilities/      # 已知漏洞库
│   └── patterns/            # 恶意模式库
│
└── workspace-perf/             # 性能分析专家工作区
    ├── AGENTS.md
    ├── benchmarks/           # 性能基准
    └── profiles/             # 性能分析配置
```

### 2. 技能共享与隔离

- **共享技能**：放在 `~/.openclaw/skills/`，所有 Agent 都可访问
- **私有技能**：放在每个 Agent 的 `workspace/skills/`，仅该 Agent 可访问

### 3. 配置文件管理

为每个 Agent 创建独立的配置模板：

```bash
# ~/.openclaw/workspace-coordinator/.agent-config.json5
{
  "model": "anthropic/claude-opus-4-5",
  "temperature": 0.7,
  "maxTokens": 4096,
  "tools": {
    "allow": ["sessions_spawn", "read"]
  }
}
```

## 🚦 故障排查

### 常见问题

#### 1. 子 Agent 未启动

**原因**：`agentToAgent` 工具未启用

**解决**：
```json5
{
  "tools": {
    "agentToAgent": {
      "enabled": true
    }
  }
}
```

#### 2. 子 Agent 超时

**原因**：任务复杂或模型响应慢

**解决**：
- 增加 `timeoutSeconds`
- 使用更快的模型（Sonnet 代替 Opus）
- 简化任务描述

#### 3. 结果未返回

**原因**：子 Agent 会话已清理

**解决**：
- 设置 `cleanup: "keep"` 保留会话
- 使用 `sessions_history` 读取结果
- 检查子 Agent 的 sessionKey 是否正确

#### 4. 权限错误

**原因**：子 Agent 缺少必要工具权限

**解决**：
- 检查 `tools.allow` 列表
- 确认沙箱模式不会阻止必要操作
- 验证文件路径是否在工作区内

## 🎯 总结

Multi-Agent 架构为复杂任务提供了强大的解决方案。关键要点：

1. **主 Agent 是协调者**：负责任务分解、分发、汇总
2. **子 Agent 是专家**：专注特定领域，独立执行
3. **安全隔离是关键**：使用沙箱和权限控制保护系统
4. **性能优化很重要**：并行执行、任务队列、超时管理
5. **人设增强效果**：为每个 Agent 设计独特的人设和专长

## 参考资源

- [OpenClaw Multi-Agent 文档](https://docs.openclaw.ai/zh-CN/concepts/multi-agent)
- [智能体沙箱和工具](https://docs.openclaw.ai/zh-CN/tools/multi-agent-sandbox-tools)
- [会话管理](https://docs.openclaw.ai/zh-CN/sessions)
