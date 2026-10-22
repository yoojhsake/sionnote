# 사용법 (PowerShell, 저장소 루트): .\tools\new-post.ps1 "제목" "m365" 영문-파일이름   (트러블슈팅: "m365, troubleshooting")
# 파일 이름은 깨짐 방지를 위해 영문·숫자·하이픈만 사용합니다(제목은 글 안에 한글로 들어갑니다).
param([Parameter(Mandatory=$true)][string]$Title, [string]$Category = "m365", [string]$Slug = "")
$date = Get-Date -Format "yyyy-MM-dd"
if ($Slug -eq "") { $Slug = ($Title -replace '[^A-Za-z0-9\-]+','-').Trim('-').ToLower() }
if ($Slug -eq "") { $Slug = "post-" + (Get-Date -Format "HHmm") }
$path = "_posts\$date-$Slug.md"
$body = (Get-Content "tools\post-template.md" -Raw -Encoding UTF8) -replace 'title: ".*"', "title: `"$Title`"" -replace 'categories: \[[^\]]*\]', "categories: [$Category]"
Set-Content -Path $path -Value $body -Encoding UTF8
Write-Host "만들었습니다: $path"
