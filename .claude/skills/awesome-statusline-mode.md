---
name: awesome-statusline-mode
description: Awesome Statusline 모드를 변경합니다 (compact/default/full)
tools: Read, Write, Edit, Bash, AskUserQuestion
---

# Awesome Statusline 모드 변경 (Windows)

현재 설치된 Awesome Statusline의 모드를 변경합니다.

## 사용법

- `/awesome-statusline-mode` - 대화형 선택
- `/awesome-statusline-mode compact` - Compact 모드
- `/awesome-statusline-mode default` - Default 모드
- `/awesome-statusline-mode full` - Full 모드
- `/awesome-statusline-mode restore` - 백업에서 복원

## 모드 비교

| 모드 | 줄 수 | 바 크기 | 정보 |
|------|-------|---------|------|
| **compact** | 2줄 | 10블록 | 모델, 경로, Git, 사용량 바 |
| **default** | 2줄 | 10블록 | + 스타일, 상세 퍼센트 |
| **full** | 5줄 | 40블록 | + 비용, 시간, Git ahead/behind, 토큰 수 |

## 실행 프로세스

### 1. 인자 확인
```
args = compact | default | full | restore | (empty)
```

### 2. 대화형 선택 (인자 없을 경우)
AskUserQuestion 도구 사용:

```json
{
  "questions": [{
    "question": "어떤 모드로 변경하시겠습니까?",
    "header": "Mode",
    "options": [
      {"label": "Default", "description": "2줄, 균형잡힌 정보"},
      {"label": "Compact", "description": "2줄, 최소 정보"},
      {"label": "Full", "description": "5줄, 상세 정보"},
      {"label": "Restore", "description": "최근 백업 복원"}
    ],
    "multiSelect": false
  }]
}
```

### 3. 기존 설정 백업
```powershell
$currentScript = "$env:USERPROFILE\.claude\awesome-statusline.ps1"
$backupPath = "$env:USERPROFILE\.claude\statusline-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').ps1"

if (Test-Path $currentScript) {
    Copy-Item $currentScript $backupPath
}
```

### 4. 모드 변경
선택한 모드의 스크립트로 교체:

```powershell
$modes = @{
    "compact" = "awesome-statusline-2.1.0-compact.ps1"
    "default" = "awesome-statusline-2.1.0-default.ps1"
    "full"    = "awesome-statusline-2.1.0-full.ps1"
}

$sourcePath = "plugins/awesome-statusline/scripts/$($modes[$selectedMode])"
$destPath = "$env:USERPROFILE\.claude\awesome-statusline.ps1"
Copy-Item $sourcePath $destPath -Force
```

### 5. 복원 (restore 선택 시)
```powershell
$backups = Get-ChildItem "$env:USERPROFILE\.claude\statusline-backup-*.ps1" |
           Sort-Object LastWriteTime -Descending |
           Select-Object -First 1

if ($backups) {
    Copy-Item $backups.FullName "$env:USERPROFILE\.claude\awesome-statusline.ps1" -Force
}
```

### 6. 완료 메시지
- 변경된 모드 확인
- 백업 파일 경로 안내
- Claude Code 재시작 필요 안내

## 파일 경로
- 현재 스크립트: `~/.claude/awesome-statusline.ps1`
- 백업 위치: `~/.claude/statusline-backup-{timestamp}.ps1`
- 소스 스크립트: `plugins/awesome-statusline/scripts/`

## 주의사항
- 모드 변경 시 현재 스크립트는 자동 백업됨
- 커스텀 수정사항은 백업에서만 복원 가능
- Claude Code 재시작 후 변경 적용
