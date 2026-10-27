# 저장소에 남은 옛 글·옛 이미지를 지우고 올리는 스크립트 (v1.0)
# 사용: 저장소를 내려받은 폴더(git clone)에서 실행하거나 -RepoPath 로 폴더를 지정합니다.
#   PowerShell>  .\Remove-StaleFiles_v1.0.ps1 -RepoPath "C:\work\sionnote"
param([Parameter(Mandatory=$true)][string]$RepoPath)
$RepoPath = (Resolve-Path $RepoPath).Path
Set-Location $RepoPath
if (-not (Test-Path ".git")) { Write-Host "여기는 git 저장소가 아닙니다: $RepoPath"; exit 1 }

# 1) 지울 대상: 이름에 옛 접두어가 붙은 글/이미지 + 새 구조에서 없어진 글
$stale = @()
$stale += Get-ChildItem "_posts" -Filter "*.md" | Where-Object { $_.Name -match '-r.adiness-' }
$stale += Get-ChildItem "assets/images/2026/10" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^r.adiness-' }
$names = @("2026-10-23-recheck.md","2026-10-23-mg-settings-403-elevate-refresh.md","2026-10-23-channel-upload-403-repro.md",
           "2026-10-23-cloud-shell-graph-scope.md","2026-10-27-troubleshooting-empty-reports-audit.md",
           "2026-10-27-troubleshooting-bulk-query.md","2026-10-26-audit-log-enable-rejected.md")
foreach ($n in $names) { if (Test-Path "_posts/$n") { $stale += Get-Item "_posts/$n" } }

if ($stale.Count -eq 0) { Write-Host "지울 파일이 없습니다. 이미 정리된 상태입니다."; exit 0 }
Write-Host "지울 파일 $($stale.Count)개:"; $stale | ForEach-Object { Write-Host "  " $_.FullName.Substring($RepoPath.Length).TrimStart('\','/') }

# 2) 확인 후 삭제 → 커밋 → 올리기
$ans = Read-Host "위 파일을 지우고 커밋해서 올릴까요? (y/n)"
if ($ans -ne "y") { Write-Host "중단했습니다. 아무것도 바꾸지 않았습니다."; exit 0 }
$stale | ForEach-Object { git rm -q -- $_.FullName }
git commit -m "옛 글·이미지 정리 (중복 표시 제거)"
git push
Write-Host "완료. 몇 분 뒤 사이트의 sitemap.xml 에서 옛 주소가 사라졌는지 확인하세요."
