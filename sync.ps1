# TANOMO の skills を ~/.claude/skills へ反映する
#
#   .\sync.ps1          repo → ~/.claude/skills （通常はこちら）
#   .\sync.ps1 -Pull    ~/.claude/skills → repo （手元で直したものを取り込む）
#   .\sync.ps1 -WhatIf  何が変わるか見るだけ

param(
    [switch]$Pull,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$repoSkills  = Join-Path $PSScriptRoot "skills"
$claudeSkills = Join-Path $env:USERPROFILE ".claude\skills"

if (-not (Test-Path $repoSkills)) {
    Write-Error "skills/ が見つかりません: $repoSkills"
}

if ($Pull) {
    $from = $claudeSkills
    $to   = $repoSkills
    $label = "~/.claude/skills  ->  repo"
} else {
    $from = $repoSkills
    $to   = $claudeSkills
    $label = "repo  ->  ~/.claude/skills"
}

Write-Host "TANOMO sync : $label" -ForegroundColor Cyan
Write-Host ""

New-Item -ItemType Directory -Force -Path $to | Out-Null

# repo 側にあるスキル名だけを対象にする（~/.claude/skills の無関係なスキルは触らない）
$names = Get-ChildItem $repoSkills -Directory | Select-Object -ExpandProperty Name

$changed = 0
foreach ($name in $names) {
    $src = Join-Path $from "$name\SKILL.md"
    $dst = Join-Path $to   "$name\SKILL.md"

    if (-not (Test-Path $src)) {
        Write-Host "  skip    $name  (コピー元なし)" -ForegroundColor DarkGray
        continue
    }

    $same = (Test-Path $dst) -and
            ((Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash)

    if ($same) {
        Write-Host "  same    $name" -ForegroundColor DarkGray
        continue
    }

    if ($WhatIf) {
        Write-Host "  would   $name" -ForegroundColor Yellow
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item $src $dst -Force
        Write-Host "  copied  $name" -ForegroundColor Green
    }
    $changed++
}

Write-Host ""
if ($changed -eq 0) {
    Write-Host "変更なし。" -ForegroundColor DarkGray
} elseif ($WhatIf) {
    Write-Host "$changed 件が変わります（-WhatIf のため実行していません）。"
} else {
    Write-Host "$changed 件を反映しました。Claude Code を再起動すると読み込まれます。"
}
