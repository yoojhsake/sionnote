---
title: "[Troubleshooting] 채널 업로드 응답은 403인데 파일이 만들어졌을 때"
date: 2026-10-22 10:20:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 3
tags: [Teams, SharePoint, Graph, "403", 비공개 채널, 공유 채널, 업로드]
excerpt: "채널 업로드에 Graph는 403을 줬는데 SharePoint에는 파일이 있었다. 응답 코드와 저장 위치를 둘 다 본다"
---

비공개·공유 채널 폴더에 시험 파일을 올렸더니 Graph는 403을 돌려줬는데, SharePoint 화면에는 그 파일이 있었습니다. 원인은 확인 불가로 남았고, 그래서 업로드 성공은 응답 코드와 실제 저장 위치를 둘 다 보고 판단합니다.

## 요약

- 실패로 보이는 응답 뒤에도 파일이 남아 있을 수 있음
- 업로드 성공은 SharePoint 화면의 실제 파일까지 보고 판단해야 함
- 다시 올리면 새 파일이 생기지 않아 처음 403의 원인은 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 화면과 PowerShell에서 읽었고, 사이트 주소도 게시하지 않았습니다.

---

## 전체 기록

### 1. 증상

- Cloud Shell에서 Graph로 세 채널에 시험 파일(`D3-test-<채널명>.txt`)을 올리니 표준은 201, 비공개·공유는 403이었는데 SharePoint 별도 사이트에는 파일이 있었습니다.

| 채널 | Graph 응답 | SharePoint 화면에서 파일 |
|---|---|---|
| ch-standard | 201 성공 | 있음(팀 사이트의 ch-standard 폴더) |
| ch-private | 403 | **있음**(별도 사이트) |
| ch-shared | 403 | **있음**(별도 사이트) |

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/10/d3-channel-storage-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/10/d3-channel-storage.png" | relative_url }}" alt="표준 채널은 팀 사이트 폴더, 비공개·공유 채널은 별도 사이트에 파일이 저장되고, 시험 업로드 결과가 표시됨" loading="lazy"></picture>

*그림 1. 채널 유형별 파일 위치와 시험 업로드 결과*

![세 채널의 SharePoint 문서 라이브러리. 표준은 팀 사이트 안 폴더, 비공개와 공유는 별도 사이트의 루트]({{ "/assets/images/2026/10/d3-sharepoint-files.png" | relative_url }})
*그림 2. 채널별 SharePoint 문서 화면(GUI: 각 주소를 브라우저에서 열어 캡처). 위: 팀 사이트 Practice-Team-01의 `Documents > ch-standard` 폴더. 가운데: 별도 사이트 Practice-Team-01-ch-private의 문서(D3-test-ch-private.txt). 아래: 별도 사이트 Practice-Team-01-ch-shared의 문서(D3-test-ch-shared.txt). 사용자 이름은 가렸습니다.*

### 2. 원인 및 분석

비공개·공유 채널은 별도 사이트에 파일을 둡니다(문서: Shared channels in Microsoft Teams). 후보는 응답 형식(실패 응답이지만 저장은 끝남)과 권한 범위(채널 접근 범위가 없어 403)였습니다.

- 처음 업로드: 응답 403 / 파일 있음
- 다시 업로드: 업로드·폴더 읽기 403(accessDenied 계열) / 새 파일 생성 안 됨

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 2장)</summary>

#### 나눠 본 순서

1. 응답 코드와 저장 위치를 따로 봅니다. 코드는 Graph 응답에서, 위치는 SharePoint 화면에서 읽습니다.
2. 같은 방식으로 다시 올려 봅니다. 새 파일이 생기는지, 읽기도 403인지 봅니다.
3. 403의 원인을 나눕니다. 채널 멤버십인지, 토큰의 권한 범위인지는 [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})에서 확인했습니다.

#### 다시 올려 본 결과

같은 방식(Cloud Shell에서 Graph로 채널의 파일 폴더 `driveId`·`itemId`를 구해 `PUT .../content`)으로 세 채널에 다시 올렸습니다.

| 채널 유형 | 업로드 | 폴더 읽기 | 새 파일 생성 |
|---|---|---|---|
| 표준 | 성공 | 성공 | 생성됨 |
| 비공개 | HTTP 403 | HTTP 403 | 생성 안 됨 |
| 공유 | HTTP 403 | HTTP 403 | 생성 안 됨 |

처음에 만들어진 비공개·공유 채널의 시험 파일은 SharePoint 화면에 여전히 있었고(조회), 응답 본문은 accessDenied 계열이었습니다.

![채널별 업로드 결과]({{ "/assets/images/2026/10/m13-1-upload-result.png" | relative_url }})
*그림 3. Cloud Shell(PowerShell)에서 세 채널과 General에 시험 파일을 올린 결과(위쪽은 실행한 명령, 아래는 출력). ch-standard와 General은 "UPLOAD OK zz-test.txt", 비공개(ch-private)와 공유(ch-shared)는 "403 (Forbidden) accessDenied"가 출력됩니다. 프롬프트의 계정 부분은 가렸습니다.*

실행한 스크립트입니다. 아래 "공통 준비 코드"는 이 글의 모든 스크립트 앞에서 한 번 실행했고, Cloud Shell 세션이 유지되는 동안 변수가 남습니다. 팀 이름 Practice-Team-01은 시험용으로 만든 팀입니다.

```powershell
# 공통(1~5줄): Cloud Shell(PowerShell)의 Azure 로그인 세션으로 Graph 토큰을 받아 호출 (조회·시험용)
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
$tid = (Invoke-RestMethod -Headers $h -Uri "$B/me/joinedTeams").value | Where-Object displayName -eq 'Practice-Team-01' | Select-Object -ExpandProperty id
$ch  = (Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/allChannels").value
```

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  $u  = "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id):/zz-test.txt:/content"
  try { Invoke-RestMethod -Method Put -Headers $h -Uri $u -ContentType 'text/plain' -Body 'zz-test' | Out-Null; "UPLOAD OK zz-test.txt -> $($c.displayName)" }
  catch { "UPLOAD $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase)) $(($_.ErrorDetails.Message | ConvertFrom-Json).error.code)" }
}
```

*이 스크립트는 채널마다 파일 폴더의 driveId·itemId를 읽은 뒤 `PUT .../content`로 시험 파일을 올리고, 실패하면 HTTP 코드와 오류 코드만 출력합니다(Graph 문서의 업로드 방식). 같은 파일명으로 다시 올리면 표준 채널과 General의 기존 zz-test.txt가 덮어써집니다.*

![채널 폴더 읽기 결과]({{ "/assets/images/2026/10/m13-2-read-403.png" | relative_url }})
*그림 4. 폴더 읽기 결과(위쪽은 실행한 명령). 표준 채널(ch-standard)은 파일 목록 D3-test-ch-standard.txt, zz-test.txt, zz-test2-ch-standard.txt, zz-x.txt가 나오고, 비공개·공유 채널은 둘 다 "READ … 403 (Forbidden)", General은 zz-test.txt, zz-x.txt가 나옵니다. zz-x.txt는 제가 채널 폴더 경로를 잘못 지정해 시험하다 팀 문서함에 생긴 파일로 정리 목록에 넣었습니다.*

zz-x.txt는 제가 채널 폴더 경로를 잘못 지정해 시험하다 생긴 파일로, 읽기 결과에서 ch-standard와 General 폴더 목록 양쪽에 보였습니다. 생긴 정확한 위치는 이 글에서 확정하지 않았습니다.

폴더 읽기에 실행한 스크립트입니다.

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  try { $r = (Invoke-RestMethod -Headers $h -Uri "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id)/children").value.name -join ', '; "READ $($c.displayName): $r" }
  catch { "READ $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase))" }
}
```

처음 업로드에서 403인데 파일이 생긴 원인(확인 불가):

- 시도: 같은 방식으로 다시 올려 재현(새 파일은 생기지 않음).
- 사유: 처음 요청·응답을 저장해 두지 않아 대조할 수 없음.
- 다음 방법: 다음 재현 때 요청과 응답 전체를 파일로 저장.

</details>

### 3. 결론

업로드 응답 403 → SharePoint 별도 사이트에는 파일이 있음 → 다시 올리면 새 파일이 생기지 않아 재현 안 됨

처음 403인데 파일이 생긴 원인은 확인 불가입니다(처음 요청·응답을 저장하지 않아 대조 불가, 시도와 다음 방법은 확인 과정).

### 4. 권고방안

1. 조치: 재현할 때는 요청·응답 전체를 파일로 남깁니다.
2. 확인: 응답 코드와 SharePoint 화면의 실제 파일이 둘 다 맞아야 성공입니다.
3. 하지 말 것: 403을 "아무 일도 안 일어남"으로 보지 않습니다.
4. 정리: 시험 파일(표준 채널과 General의 zz-test*.txt, 경로를 잘못 지정해 생긴 zz-x.txt)은 정리 목록에 넣었습니다(팀 삭제 때 함께 지워짐).

관련 글: [Teams 저장 구조: 채널 유형별 파일·일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }}) · [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) · [채널 경로 업로드 400]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- 조회: 표준 201, 비공개·공유 403, 세 채널의 파일이 SharePoint 화면에 존재
    - 출처: Cloud Shell(Graph), SharePoint 화면
- 조회: 다시 올렸을 때 비공개·공유 403, 폴더 읽기 403, 새 파일 생성 안 됨
    - 출처: Cloud Shell(Graph)
- 문서: 파일 업로드(`PUT .../content`) 방식과 필요한 권한
    - [Upload or replace the contents of a driveItem](https://learn.microsoft.com/graph/api/driveitem-put-content?view=graph-rest-1.0)
- 문서: 비공개·공유 채널은 별도 사이트
    - [Shared channels in Microsoft Teams](https://learn.microsoft.com/microsoftteams/shared-channels)
- 확인 불가: 403인데 파일이 생긴 원인
    - 시도, 사유, 다음 방법은 2절 확인 과정

</details>
