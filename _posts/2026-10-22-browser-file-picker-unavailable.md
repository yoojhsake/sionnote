---
title: "[Troubleshooting] 브라우저 파일 선택창을 쓸 수 없을 때"
date: 2026-10-22 10:10:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 6
tags: [Teams, Graph, Cloud Shell, 파일 업로드, 파일 선택창]
excerpt: "실습 환경에서 브라우저의 파일 선택 대화상자를 쓸 수 없어 Cloud Shell의 Graph 호출로 시험 파일을 올렸다. 직접 업로드와 결과가 같은지는 확인 불가"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·사유·다음 방법 병기). 테넌트 도메인과 사이트 주소는 게시하지 않았습니다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | Teams·SharePoint에서 파일을 올리려 해도 브라우저의 파일 선택 대화상자를 쓸 수 없음 |
| 원인 | 이 실습 환경에서 브라우저의 파일 선택 대화상자를 쓸 수 없음 |
| 대처 | Cloud Shell에서 Graph로 채널의 `filesFolder`를 조회하고 `PUT .../content`로 시험 파일을 올림 |
| 결과 | 표준 채널은 201 성공, 비공개·공유 채널은 403. 사람이 직접 올릴 때와 결과가 같은지는 **확인 불가** |

---

## 전체 기록

### 1. 증상

채널 유형별 파일 위치를 보려고 시험 파일을 올려야 했는데, 이 실습 환경에서는 브라우저의 파일 선택 대화상자를 쓸 수 없었습니다. Teams의 파일 탭이나 SharePoint의 업로드 버튼으로는 파일을 고를 수 없는 상태입니다.

### 2. 먼저 확인할 것

1. **같은 증상이 다른 방법에서도 나는가.** 파일 선택 대화상자가 필요한 방법은 모두 막힙니다.
2. **파일 선택이 필요 없는 방법이 있는가.** Graph의 `PUT .../content`는 본문을 명령에 직접 넣어 올리므로 선택창이 필요 없습니다(문서: driveItem 업로드).
3. **Cloud Shell에서 Graph를 호출할 수 있는가.** 팀 목록·채널 목록·채널 파일 폴더 정보를 읽을 수 있는지 봅니다.

### 3. 시도와 결과

각 채널의 `filesFolder`를 조회해 폴더 주소(`driveId`, `itemId`)를 얻고, 시험 파일(`D3-test-<채널명>.txt`)을 올린 뒤, **SharePoint 화면**에서 파일이 어디 있는지 확인했습니다.

| 채널 | Graph 응답 | SharePoint 화면에서 파일 |
|---|---|---|
| ch-standard | **201 성공** | 있음(팀 사이트의 ch-standard 폴더) |
| ch-private | **403** | **있음**(별도 사이트) |
| ch-shared | **403** | **있음**(별도 사이트) |

![채널별 시험 파일 업로드 결과 출력]({{ "/assets/images/2026/10/m13-1-upload-result.png" | relative_url }})
*그림 1. Cloud Shell에서 채널마다 시험 파일을 올린 결과. 표준 채널과 General은 `UPLOAD OK`, 비공개·공유 채널은 `403 (Forbidden) accessDenied`. 계정이 보이던 프롬프트 부분은 가렸다.*

![채널별 SharePoint 문서 화면]({{ "/assets/images/2026/10/d3-sharepoint-files.png" | relative_url }})
*그림 2. 같은 시험 뒤 SharePoint 문서 화면. 위: 팀 사이트의 ch-standard 폴더, 가운데: 별도 사이트(ch-private), 아래: 별도 사이트(ch-shared). 사용자 이름은 가렸다.*

파일 선택창을 쓸 수 없는 상태 자체는 대화상자가 열리지 않는 것이라 따로 캡처할 화면이 없었습니다.

아래는 같은 방식의 스크립트입니다(준비 코드와 업로드 부분. 팀 이름 Practice-Team-01은 시험용으로 만든 팀입니다).

```powershell
# 공통 준비 코드: Cloud Shell(PowerShell)의 Azure 로그인 세션으로 Graph 토큰을 받아 호출
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

*이 스크립트는 채널마다 파일 폴더의 driveId·itemId를 읽은 뒤 `PUT .../content`로 시험 파일을 올리고, 실패하면 HTTP 코드와 오류 코드만 출력합니다. 처음 시험 때 입력한 명령 원문은 복구하지 못해, 같은 방식으로 정리한 형태입니다.*

- 이 방식 때문에 비공개·공유 채널에서 403이 났을 수 있습니다. 403의 원인은 [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}), 403인데 파일이 생긴 현상은 [응답은 403인데 파일이 만들어졌을 때]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }})에 있습니다.
- **확인 불가**: 사람이 Teams에서 직접 올리는 경우와 Graph 업로드의 결과가 같은지. 시도: 브라우저 파일 선택창으로 직접 업로드. 사유: 파일 선택창을 쓸 수 없어 직접 업로드를 시도하지 못함. 다음 방법: 파일 선택창을 쓸 수 있는 환경에서 같은 채널에 직접 올려 응답과 저장 위치를 비교.

### 4. 대처·원복

- 파일 선택이 필요한 작업은 Graph 호출로 대체하고, 결과는 **SharePoint 화면에서 다시 확인**합니다.
- 시험으로 올린 파일(zz-test*.txt 등)은 삭제하지 않았고, 팀을 삭제할 때 함께 지우도록 정리 목록에 넣었습니다.

### 5. 운영에서는 이렇게 판단한다

- 자동화로 올린 결과를 "사람이 올린 결과"와 같다고 단정하지 않습니다. 환경 제약 때문에 방법을 바꿨다면, 바꾼 방법이 결과에 영향을 줄 수 있다는 점을 기록해 둡니다.
- 응답 코드만 믿지 않고 저장 위치를 화면으로 확인합니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 파일 업로드(`PUT .../content`) 방식과 필요한 권한 | [Upload or replace the contents of a driveItem](https://learn.microsoft.com/graph/api/driveitem-put-content?view=graph-rest-1.0) |
| 문서 | 채널의 파일 폴더 정보 조회 | [Get filesFolder](https://learn.microsoft.com/graph/api/channel-get-filesfolder?view=graph-rest-1.0) |
| 조회 | 표준 201, 비공개·공유 403, 세 채널의 파일이 SharePoint 화면에 존재 | Cloud Shell(Graph), SharePoint 화면 |
| 확인 불가 | 직접 업로드와 Graph 업로드의 차이 | 시도·사유·다음 방법은 3절 |

관련 글: [Teams 저장 구조 — 채널 유형별 파일·일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }}), [Cloud Shell에서 Graph 호출 — 되는 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }})
