---
name: awesome-statusline-start
description: Awesome Statusline 설치 마법사 - 버전, 모드, 커스터마이징 선택
tools: Read, Write, Edit, Bash, AskUserQuestion
---

# Awesome Statusline 설치 마법사 (Windows)

Catppuccin 테마 기반의 Claude Code statusline을 설정합니다.

## 사용 가능한 모드

| 모드 | 줄 수 | 바 크기 | 특징 |
|------|-------|---------|------|
| **compact** | 2줄 | 10블록 | 최소 정보, 좁은 터미널용 |
| **default** | 2줄 | 10블록 | 균형잡힌 정보 (권장) |
| **full** | 5줄 | 40블록 | 상세 정보 (비용, 시간, Git ahead/behind) |

## 설치 프로세스

### 1. 인자 확인
사용자가 모드를 직접 지정했는지 확인:
- `/awesome-statusline-start` - 대화형 선택
- `/awesome-statusline-start compact` - Compact 모드
- `/awesome-statusline-start default` - Default 모드 (권장)
- `/awesome-statusline-start full` - Full 모드
- `/awesome-statusline-start restore` - 백업 복원

### 2. 대화형 모드 선택 (인자 없을 경우)
AskUserQuestion 도구를 사용하여 모드 선택:

```json
{
  "questions": [{
    "question": "어떤 statusline 모드를 설치하시겠습니까?",
    "header": "Mode",
    "options": [
      {"label": "Default (Recommended)", "description": "2줄 레이아웃, 균형잡힌 정보 표시"},
      {"label": "Compact", "description": "2줄 최소화 레이아웃, 좁은 터미널용"},
      {"label": "Full", "description": "5줄 상세 레이아웃, 모든 정보 표시"}
    ],
    "multiSelect": false
  }]
}
```

### 3. 백업 생성
기존 설정이 있으면 백업:
```powershell
$backupPath = "$env:USERPROFILE\.claude\statusline-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').ps1"
```

### 4. 스크립트 복사
선택한 모드의 스크립트를 `~/.claude/awesome-statusline.ps1`로 복사:

```powershell
$sourcePath = "plugins/awesome-statusline/scripts/awesome-statusline-2.1.0-{mode}.ps1"
$destPath = "$env:USERPROFILE\.claude\awesome-statusline.ps1"
Copy-Item $sourcePath $destPath -Force
```

### 5. settings.json 업데이트
`~/.claude/settings.json`에 statusLine 설정 추가:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -ExecutionPolicy Bypass -File \"$env:USERPROFILE\\.claude\\awesome-statusline.ps1\""
  }
}
```

### 6. 완료 메시지
설치 완료 후 안내:
- 선택한 모드 확인
- Claude Code 재시작 필요 안내
- 모드 변경 방법 안내 (`/awesome-statusline-mode`)

## 주요 파일 경로
- 스크립트: `~/.claude/awesome-statusline.ps1`
- 설정: `~/.claude/settings.json`
- 백업: `~/.claude/statusline-backup-{timestamp}.ps1`

## 주의사항
- Windows PowerShell 5.1+ 또는 PowerShell 7+ 필요
- 터미널이 ANSI 색상 지원 필요 (Windows Terminal 권장)
- Claude Code 재시작 후 적용
