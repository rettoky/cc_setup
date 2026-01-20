---
name: statusline-mode
description: Statusline 모드 변경 (compact/default/full)
tools: Read, Write, Edit, Bash, AskUserQuestion
---

# Statusline 모드 변경

설치된 statusline의 모드를 변경합니다.

## 사용법
- `/cc-setup:statusline-mode` - 대화형 선택
- `/cc-setup:statusline-mode compact` - Compact 모드
- `/cc-setup:statusline-mode default` - Default 모드
- `/cc-setup:statusline-mode full` - Full 모드

## 모드 비교

| 모드 | 줄 수 | 프로그레스 바 | 정보 |
|------|-------|--------------|------|
| compact | 2 | 10블록 | 모델, 경로, Git, Ctx/5H/7D |
| default | 2 | 10블록 | + 리셋 시간 |
| full | 5 | 40블록 | + 비용, 세션시간, Git ahead/behind |

## 프로세스

### 1. 현재 모드 확인
```powershell
$currentScript = "$env:USERPROFILE\.claude\awesome-statusline.ps1"
if (Test-Path $currentScript) {
    $content = Get-Content $currentScript -First 15 | Out-String
    if ($content -match "COMPACT") { $currentMode = "compact" }
    elseif ($content -match "FULL") { $currentMode = "full" }
    else { $currentMode = "default" }
}
```

### 2. 대화형 선택 (인자 없을 경우)
```json
{
  "questions": [{
    "question": "변경할 모드를 선택하세요 (현재: {current_mode})",
    "header": "Mode",
    "options": [
      {"label": "Compact", "description": "2줄 최소 레이아웃"},
      {"label": "Default", "description": "2줄 + 리셋 시간"},
      {"label": "Full", "description": "5줄 상세 레이아웃"}
    ],
    "multiSelect": false
  }]
}
```

### 3. 스크립트 교체
```powershell
# 플러그인 경로 찾기
$pluginPaths = @(
    "$env:USERPROFILE\.claude\plugins\cc-setup",
    "$env:USERPROFILE\.claude\installed-plugins\cc-setup",
    "."
)

foreach ($base in $pluginPaths) {
    $testPath = Join-Path $base "statusline\scripts"
    if (Test-Path $testPath) {
        $PLUGIN_PATH = $base
        break
    }
}

$sourcePath = "$PLUGIN_PATH\statusline\scripts\awesome-statusline-2.1.0-{mode}.ps1"
$destPath = "$env:USERPROFILE\.claude\awesome-statusline.ps1"
Copy-Item $sourcePath $destPath -Force
```

### 4. 완료 메시지
```
✓ Statusline 모드 변경 완료!
  이전: {previous_mode}
  현재: {new_mode}

⚠ Claude Code를 재시작하면 적용됩니다.
```
