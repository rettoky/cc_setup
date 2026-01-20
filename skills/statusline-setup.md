---
name: statusline-setup
description: Awesome Statusline 설치 - Catppuccin 테마 statusline을 ~/.claude/에 설정합니다
tools: Read, Write, Edit, Bash, AskUserQuestion
---

# Statusline 설치 마법사

cc-setup 플러그인의 Catppuccin 테마 statusline을 설정합니다.

## 사용 가능한 모드

| 모드 | 줄 수 | 바 크기 | 특징 |
|------|-------|---------|------|
| **compact** | 2줄 | 10블록 | 최소 정보 (기본값) |
| **default** | 2줄 | 10블록 | 리셋 시간 포함 |
| **full** | 5줄 | 40블록 | 상세 정보 |

## 설치 프로세스

### 1. 인자 확인
- `/cc-setup:statusline-setup` - 대화형 선택
- `/cc-setup:statusline-setup compact` - Compact 모드
- `/cc-setup:statusline-setup default` - Default 모드
- `/cc-setup:statusline-setup full` - Full 모드

### 2. 대화형 모드 선택 (인자 없을 경우)
AskUserQuestion으로 모드 선택:

```json
{
  "questions": [{
    "question": "어떤 statusline 모드를 설치하시겠습니까?",
    "header": "Mode",
    "options": [
      {"label": "Compact (Recommended)", "description": "2줄 최소 레이아웃"},
      {"label": "Default", "description": "2줄 레이아웃 + 리셋 시간"},
      {"label": "Full", "description": "5줄 상세 레이아웃"}
    ],
    "multiSelect": false
  }]
}
```

### 3. 플러그인 경로 찾기
플러그인 설치 위치에서 statusline 스크립트 찾기:

**Windows:**
```powershell
# 플러그인 설치 경로 (user scope 기준)
$pluginPaths = @(
    "$env:USERPROFILE\.claude\plugins\cc-setup",
    "$env:USERPROFILE\.claude\installed-plugins\cc-setup",
    "."  # 현재 디렉토리 (개발/테스트용)
)

foreach ($base in $pluginPaths) {
    $scriptPath = Join-Path $base "statusline\scripts\awesome-statusline-2.1.0-{mode}.ps1"
    if (Test-Path $scriptPath) {
        $PLUGIN_PATH = $base
        break
    }
}
```

**macOS/Linux:**
```bash
PLUGIN_PATHS=(
    "$HOME/.claude/plugins/cc-setup"
    "$HOME/.claude/installed-plugins/cc-setup"
    "."
)

for base in "${PLUGIN_PATHS[@]}"; do
    if [ -f "$base/statusline/scripts/{mode}.sh" ]; then
        PLUGIN_PATH="$base"
        break
    fi
done
```

### 4. 백업 생성
```powershell
$existingScript = "$env:USERPROFILE\.claude\awesome-statusline.ps1"
if (Test-Path $existingScript) {
    $backupPath = "$env:USERPROFILE\.claude\statusline-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').ps1"
    Copy-Item $existingScript $backupPath
}
```

### 5. 스크립트 복사
```powershell
$sourcePath = "$PLUGIN_PATH\statusline\scripts\awesome-statusline-2.1.0-{mode}.ps1"
$destPath = "$env:USERPROFILE\.claude\awesome-statusline.ps1"
Copy-Item $sourcePath $destPath -Force
```

### 6. settings.json 업데이트
`~/.claude/settings.json`에 statusLine 설정 추가/수정:

```powershell
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
$scriptPath = "$env:USERPROFILE\.claude\awesome-statusline.ps1"

$statusLineConfig = @{
    type = "command"
    command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
}

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $settings | Add-Member -NotePropertyName "statusLine" -NotePropertyValue $statusLineConfig -Force
} else {
    $settings = @{ statusLine = $statusLineConfig }
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Force
```

### 7. 완료 메시지
```
✓ Statusline 설치 완료!
  모드: {selected_mode}
  스크립트: ~/.claude/awesome-statusline.ps1

⚠ Claude Code를 재시작하면 적용됩니다.

모드 변경: /cc-setup:statusline-mode
```

## 파일 경로
- 소스: `{plugin_path}/statusline/scripts/`
- 대상: `~/.claude/awesome-statusline.ps1`
- 설정: `~/.claude/settings.json`

## 요구사항
- Windows: PowerShell 5.1+, Windows Terminal (ANSI 색상)
- macOS/Linux: Bash 4+, jq
