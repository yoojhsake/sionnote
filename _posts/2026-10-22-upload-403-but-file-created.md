---
title: "[트러블슈팅] 채널 업로드 응답은 403인데 파일이 만들어졌을 때"
date: 2026-10-22 10:20:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 3
tags: [Teams, SharePoint, Graph, "403", 비공개 채널, 공유 채널, 업로드]
excerpt: "비공개·공유 채널 폴더에 올릴 때 Graph는 403을 돌려줬지만 SharePoint 화면에는 파일이 있었다. 응답 코드만 보지 말고 저장 위치를 같이 확인한다"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·사유·다음 방법 병기). 테넌트 도메인과 사이트 주소는 게시하지 않았고 사용자 이름은 적지 않았습니다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | 비공개·공유 채널 폴더에 시험 파일을 올렸을 때 Graph 응답은 403인데, SharePoint 화면에서는 파일이 있음 |
| 원인 | **확인 불가.** 응답 형식의 문제인지, 권한 범위의 문제인지 구분하지 못함 |
| 대처 | 업로드 성공 여부를 응답 코드만으로 판단하지 않고, 코드와 실제 저장 위치를 둘 다 확인 |
| 결과 | 같은 방식으로 다시 올리면 쓰기·읽기 모두 403이고 새 파일은 생기지 않음. 처음 요청·응답을 보존하지 못해 대조 불가 |

---

## 전체 기록

### 1. 증상

Cloud Shell에서 Graph로 세 채널에 시험 파일(`D3-test-<채널명>.txt`)을 올렸습니다. 표준 채널은 201 성공이었고, 비공개·공유 채널은 403이었습니다. 그런데 SharePoint 화면에서 각 주소를 열어 보니 비공개·공유 채널의 별도 사이트에도 파일이 있었습니다.

| 채널 | Graph 응답 | SharePoint 화면에서 파일 |
|---|---|---|
| ch-standard | **201 성공** | 있음(팀 사이트의 ch-standard 폴더) |
| ch-private | **403** | **있음**(별도 사이트) |
| ch-shared | **403** | **있음**(별도 사이트) |

![표준 채널은 팀 사이트 폴더, 비공개·공유 채널은 별도 사이트에 파일이 저장되고, 시험 업로드 결과가 표시됨]({{ "/assets/images/2026/10/d3-channel-storage.png" | relative_url }})
*그림 1. 채널 유형별 파일 위치와 시험 업로드 결과*

![세 채널의 SharePoint 문서 라이브러리. 표준은 팀 사이트 안 폴더, 비공개와 공유는 별도 사이트의 루트]({{ "/assets/images/2026/10/d3-sharepoint-files.png" | relative_url }})
*그림 2. 채널별 SharePoint 문서 화면(GUI: 각 주소를 브라우저에서 열어 캡처). 위: 팀 사이트 Practice-Team-01의 `Documents > ch-standard` 폴더. 가운데: 별도 사이트 Practice-Team-01-ch-private의 문서(D3-test-ch-private.txt). 아래: 별도 사이트 Practice-Team-01-ch-shared의 문서(D3-test-ch-shared.txt). 사용자 이름은 가렸다.*

### 2. 먼저 확인할 것

1. **응답 코드와 저장 위치를 따로 본다.** 코드는 Graph 응답에서, 위치는 SharePoint 화면에서 읽습니다.
2. **같은 방식으로 다시 올려 본다.** 새 파일이 생기는지, 읽기도 403인지 봅니다.
3. **403의 원인을 나눈다.** 채널 멤버십인지, 토큰의 권한 범위인지는 [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})에서 확인했습니다.

### 3. 시도와 결과

같은 방식(Cloud Shell에서 Graph로 채널의 파일 폴더 `driveId`·`itemId`를 구해 `PUT .../content`)으로 세 채널에 다시 올렸습니다.

| 채널 유형 | 업로드 | 폴더 읽기 | 새 파일 생성 |
|---|---|---|---|
| 표준 | 성공 | 성공 | 생성됨 |
| 비공개 | HTTP 403 | HTTP 403 | 생성 안 됨 |
| 공유 | HTTP 403 | HTTP 403 | 생성 안 됨 |

- 처음에 만들어진 비공개·공유 채널의 시험 파일은 SharePoint 화면에서 여전히 있었습니다(조회).
- 응답 본문은 accessDenied 계열이었습니다.

![채널별 업로드 결과]({{ "/assets/images/2026/10/m13-1-upload-result.png" | relative_url }})
*그림 3. Cloud Shell(PowerShell)에서 세 채널과 General에 시험 파일을 올린 결과(위쪽은 실행한 명령, 아래는 출력). ch-standard와 General은 "UPLOAD OK zz-test.txt", 비공개(ch-private)와 공유(ch-shared)는 "403 (Forbidden) accessDenied"가 출력된다. 프롬프트의 계정 부분은 가렸다.*

**실행한 스크립트** (아래 "공통 준비 코드"는 이 글의 모든 스크립트 앞에서 한 번 실행했고, Cloud Shell 세션이 유지되는 동안 변수가 남습니다. 팀 이름 Practice-Team-01은 시험용으로 만든 팀입니다.)

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
*그림 4. 폴더 읽기 결과(위쪽은 실행한 명령). 표준 채널(ch-standard)은 파일 목록 D3-test-ch-standard.txt, zz-test.txt, zz-test2-ch-standard.txt, zz-x.txt가 나오고, 비공개·공유 채널은 둘 다 "READ … 403 (Forbidden)", General은 zz-test.txt, zz-x.txt가 나온다. zz-x.txt는 제가 채널 폴더 경로를 잘못 지정해 시험하다 팀 문서함에 생긴 파일로 정리 목록에 넣었다.*

**실행한 스크립트**

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  try { $r = (Invoke-RestMethod -Headers $h -Uri "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id)/children").value.name -join ', '; "READ $($c.displayName): $r" }
  catch { "READ $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase))" }
}
```

**원인 후보 두 가지**

- 응답 형식의 문제: 실패로 보이는 응답이 돌아왔지만 저장은 이미 끝났을 가능성
- 권한 범위의 문제: 관리자가 해당 채널에 접근할 범위가 없어 403이 났을 가능성

다시 올렸을 때는 새 파일이 생기지 않았으므로, 이 현상을 같은 조건에서 재현하지 못했습니다. 이 글이 확인한 사실은 "응답은 403인데 파일이 있었다"는 것까지입니다.

- **확인 불가**: 처음 업로드에서 403인데 파일이 생긴 원인. 시도: 같은 방식으로 다시 올려 재현(새 파일은 생기지 않음). 사유: 처음 요청·응답을 저장해 두지 않아 대조할 수 없음. 다음 방법: 다음 재현 때 요청과 응답 전체를 파일로 저장.

### 4. 대처·원복

- 업로드를 시험할 때는 **응답 코드를 믿기 전에** SharePoint 화면에서 파일이 있는지 봅니다.
- 시험으로 생긴 파일은 삭제하지 않고 정리 목록에 넣었습니다(팀을 삭제할 때 함께 지워집니다). 표준 채널과 General의 zz-test*.txt, 채널 폴더 경로를 잘못 지정해 팀 문서함에 생긴 zz-x.txt가 해당합니다.

### 5. 운영에서는 이렇게 판단한다

- **403 = "아무 일도 안 일어남"이 아닙니다.** 실패로 보이는 응답 뒤에 데이터가 남아 있을 수 있습니다.
- 업로드 성공 여부는 **응답 코드와 실제 저장 위치를 둘 다** 확인합니다.
- 재현할 때는 요청과 응답 전체를 파일로 남겨 두어, 원인을 나중에 대조할 수 있게 합니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 조회 | 표준 201, 비공개·공유 403, 세 채널의 파일이 SharePoint 화면에 존재 | Cloud Shell(Graph), SharePoint 화면 |
| 조회 | 다시 올렸을 때 비공개·공유 403, 폴더 읽기 403, 새 파일 생성 안 됨 | Cloud Shell(Graph) |
| 문서 | 파일 업로드(`PUT .../content`) 방식과 필요한 권한 | [Upload or replace the contents of a driveItem](https://learn.microsoft.com/graph/api/driveitem-put-content?view=graph-rest-1.0) |
| 문서 | 비공개·공유 채널은 별도 사이트 | [Shared channels in Microsoft Teams](https://learn.microsoft.com/microsoftteams/shared-channels) |
| 확인 불가 | 403인데 파일이 생긴 원인 | 시도·사유·다음 방법은 3절 |

관련 글: [Teams 저장 구조 — 채널 유형별 파일·일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }}), [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}), [채널 경로 업로드 400]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }})
