---
title: "[Troubleshooting] 공유 채널이 unknownFutureValue로 보일 때"
date: 2026-10-22 10:30:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 4
tags: [Teams, Graph, 공유 채널, membershipType, unknownFutureValue, filesFolder]
excerpt: "Graph allChannels에서 공유 채널의 membershipType이 unknownFutureValue로 나온다. 유형 문자열로 분기하지 말고 filesFolder로 실제 주소를 얻는다"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·사유·다음 방법 병기). 테넌트 도메인은 주소에서 뺐고(`<테넌트>`로 표기) 사용자 이름은 적지 않았습니다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | Graph `allChannels`에서 공유 채널(ch-shared)의 `membershipType`이 `unknownFutureValue`로 나옴 |
| 원인 | 문서 기준: 채널 유형 값은 evolvable enum이라 v1.0에서 새 값(`shared`)은 기본적으로 `unknownFutureValue`로 반환됨 |
| 대처 | 유형 문자열로 분기하지 않고 채널마다 `filesFolder`로 실제 주소를 얻음. 유형이 꼭 필요하면 `Prefer: include-unknown-enum-members` 헤더 사용(문서) |
| 결과 | 이 테넌트에서 헤더를 붙여 조회한 동작은 **확인 불가** |

---

## 전체 기록

### 1. 증상

Practice-Team-01에 채널 3종(표준 ch-standard, 비공개 ch-private, 공유 ch-shared)을 만든 뒤 Cloud Shell에서 Graph로 채널 목록을 조회했습니다. 공유 채널만 유형 값이 `unknownFutureValue`였습니다.

| 채널 | Graph `membershipType` |
|---|---|
| General | standard |
| ch-standard | standard |
| ch-private | private |
| ch-shared | **unknownFutureValue** (공유 채널) |

```powershell
$B = 'https://graph.microsoft.com/v1.0'
$t = ((Invoke-AzRestMethod -Uri "$B/groups?`$filter=resourceProvisioningOptions/Any(x:x eq 'Team')&`$select=id,displayName").Content | ConvertFrom-Json).value
"TEAMS|$($t.Count)"
$id = ($t | ? displayName -eq 'Practice-Team-01').id
((Invoke-AzRestMethod -Uri "$B/teams/$id/allChannels?`$select=displayName,membershipType").Content | ConvertFrom-Json).value | % { "CH|$($_.displayName)|$($_.membershipType)" }
```

![표준 채널은 팀 사이트 폴더, 비공개·공유 채널은 별도 사이트에 파일이 저장되고, 시험 업로드 결과가 표시됨]({{ "/assets/images/2026/10/d3-channel-storage.png" | relative_url }})
*그림 1. 채널 유형별 파일 위치와 시험 업로드 결과. 공유 채널(ch-shared)은 비공개 채널처럼 별도 사이트(…-ch-shared)에 파일이 저장된다.*

### 2. 먼저 확인할 것

1. **화면에서는 공유 채널로 보이는가.** 채널을 만들 때 유형을 **공유**로 골랐고, Teams 관리 센터 팀 목록에도 공유 채널 열에 1이 잡혀 있습니다(조회).
2. **파일 위치는 따로 얻을 수 있는가.** 채널 유형 값과 관계없이 `filesFolder`로 폴더 주소를 얻을 수 있는지 봅니다.

![Teams 관리 센터 Manage teams 화면. Practice-Team 행이 표준 채널 2, 비공개 채널 1, 공유 채널 1]({{ "/assets/images/2026/10/d3-manage-teams.png" | relative_url }})
*그림 2. Teams 관리 센터 팀 목록(빨간 상자: Practice-Team-01, 일부 팀 이름은 가림). 공유 채널 열에 1이 표시된다.*

### 3. 시도와 결과

- **문서에서 확인한 것**: 개발자 문서는 채널 유형 값에 의존하지 말고, 파일 폴더는 `GET /teams/{teamId}/channels/{channelId}/filesFolder`로 얻으라고 안내합니다(문서: 공유·비공개 채널용 앱).
- **원인(문서)**: 채널 `membershipType`은 evolvable enum입니다. v1.0에서 새 값(공유 채널의 `shared`)은 기본적으로 `unknownFutureValue`로 반환되고, 요청에 `Prefer: include-unknown-enum-members` 헤더를 붙이면 `shared`로 나옵니다(문서: channel 리소스 유형).
- **조회**: `filesFolder`로 얻은 공유 채널의 폴더 주소는 별도 사이트 `…/sites/Practice-Team-01-ch-shared/Shared Documents`였고, SharePoint 화면의 주소와 일치했습니다.
- **확인 불가**: 헤더를 붙였을 때 이 테넌트에서 실제로 `shared`가 나오는지. 시도: 이 테넌트에서는 헤더 없이만 조회함. 사유: 헤더를 붙여 시험하지 않음. 다음 방법: 같은 `allChannels` 요청에 `Prefer: include-unknown-enum-members` 헤더를 붙여 값을 비교(재측정 항목).

### 4. 대처·원복

- 채널 유형 문자열(`private`, `shared`)로 분기하지 말고, 채널마다 `filesFolder`로 `driveId`와 `itemId`를 읽어 씁니다.
- 변경한 것은 없습니다(조회만 했습니다).

### 5. 운영에서는 이렇게 판단한다

- 개발·자동화에서는 채널 유형 문자열보다 `filesFolder` 같은 **실제 주소 API**를 믿습니다.
- 목록에서 `unknownFutureValue`가 보이면 오류로 보지 말고, 문서가 말하는 새 값이 아직 이름으로 풀리지 않은 것인지부터 봅니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 채널 유형 값에 의존하지 말고 filesFolder 사용 | [공유·비공개 채널용 앱](https://learn.microsoft.com/microsoftteams/platform/build-apps-for-shared-private-channels) |
| 문서 | `membershipType`은 evolvable enum이고 `Prefer: include-unknown-enum-members` 헤더로 `shared`를 얻음 | [channel 리소스 유형](https://learn.microsoft.com/graph/api/resources/channel?view=graph-rest-1.0) |
| 조회 | ch-shared의 `membershipType`이 `unknownFutureValue`, 폴더 주소가 별도 사이트 | Graph, SharePoint 화면 |
| 조회 | 관리 센터 팀 목록의 공유 채널 열 값 1 | Teams 관리 센터 |
| 확인 불가 | 헤더를 붙인 조회 결과 | 시도·사유·다음 방법은 3절 |

관련 글: [Teams 저장 구조 — 채널 유형별 파일·일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }}), [관리 센터 숫자·사이트 목록과 Graph 채널 수가 다를 때]({{ "/m365/troubleshooting/channel-count-mismatch/" | relative_url }})
