# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

이 저장소는 Claude Code의 전문 서브에이전트(subagent) 정의 파일들을 관리합니다. 각 에이전트는 특정 도메인에 특화된 전문가 역할을 수행하며, 복잡한 작업을 위해 조합하여 사용할 수 있습니다.

## Architecture

```
.claude/
└── agents/
    ├── 01-core-development/      # API, 백엔드, 프론트엔드, 풀스택, 모바일, UI 설계
    ├── 02-language-specialists/  # 언어별 전문가 (Python, TypeScript, Go, Rust, C#, Java 등)
    ├── 03-infrastructure/        # DevOps, 클라우드, Kubernetes, Terraform, 인시던트 대응
    ├── 04-quality-security/      # 테스트, 보안 감사, 성능, 접근성, 코드 리뷰
    ├── 05-data-ai/               # ML, 데이터 엔지니어링, LLM, NLP, PostgreSQL
    ├── 06-developer-experience/  # 빌드, CLI, 문서화, Git 워크플로우, 리팩토링, MCP
    ├── 07-specialized-domains/   # 블록체인, IoT, 핀테크, 게임, 결제
    ├── 08-business-product/      # 프로덕트 관리, 비즈니스 분석, 기술 문서
    ├── 09-meta-orchestration/    # 멀티에이전트 조율, 컨텍스트 관리, 워크플로우
    └── 10-research-analysis/     # 리서치, 경쟁 분석, 트렌드 분석, 시장 조사
```

## Agent Definition Format

각 에이전트 파일(.md)은 YAML frontmatter와 시스템 프롬프트로 구성됩니다:

```yaml
---
name: agent-name
description: 에이전트 설명
tools: Read, Write, Edit, Bash, Glob, Grep  # 사용 가능한 도구
model: opus  # 또는 sonnet, haiku
---

[시스템 프롬프트 내용]
```

## Key Patterns

### Agent Communication Protocol
에이전트들은 JSON 형식의 메시지로 context-manager와 통신합니다:
- `get_project_context`: 프로젝트 컨텍스트 요청
- `progress` 업데이트: 작업 진행 상황 보고
- 완료 시 context-manager에 생성/수정된 파일 알림

### Agent Combinations
복잡한 작업은 여러 에이전트를 조합하여 수행:
- 풀스택 앱: api-designer → backend-developer → frontend-developer
- ML 시스템: data-engineer → data-scientist → mlops-engineer
- 레거시 현대화: legacy-modernizer → refactoring-specialist → dependency-manager

### PowerShell/Windows 특화 에이전트
Windows 인프라 자동화를 위한 전문 에이전트 체계:
- `windows-infra-admin`: AD, DNS, DHCP, GPO 관리
- `powershell-5.1-expert`: Windows PowerShell 5.1, 레거시 .NET Framework
- `powershell-7-expert`: 크로스플랫폼 PowerShell 7+, Az 모듈
- `it-ops-orchestrator`: PowerShell 기반 IT 운영 작업 라우팅

## MCP Server Configuration

**MCP 관련 작업 시 반드시 이 저장소의 `.mcp.json` 파일을 먼저 참고하세요.**

`.mcp.json`에 정의된 MCP 서버:
- **supabase**: Supabase 프로젝트 관리
- **context7**: 라이브러리 문서 검색
- **n8n-mcp**: n8n 워크플로우 자동화
- **chrome-devtools**: Chrome DevTools Protocol을 통한 브라우저 자동화 및 디버깅

## Adding New Agents

1. 적절한 카테고리 디렉토리에 `.md` 파일 생성
2. YAML frontmatter에 name, description, tools, model 정의
3. 시스템 프롬프트 작성 (Communication Protocol, Execution Flow, Deliverables 포함)
4. 카테고리 README.md에 에이전트 추가
