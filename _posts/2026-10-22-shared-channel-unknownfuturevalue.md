---
title: "[Troubleshooting] 공유 채널이 unknownFutureValue로 보일 때"
date: 2026-10-22 10:30:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 4
tags: [Teams, Graph, 공유 채널, membershipType, unknownFutureValue, filesFolder]
excerpt: "Graph에서 공유 채널 유형이 unknownFutureValue로 나올 때, 유형 문자열 대신 filesFolder로 채널의 실제 주소를 얻는 법"
---

Graph `allChannels`로 채널을 읽었더니 공유 채널(ch-shared)의 `membershipType`만 `unknownFutureValue`로 나옵니다. 새 유형 값이 v1.0에서 그렇게 반환되는 evolvable enum이라서이고, 유형 문자열로 분기하지 말고 채널마다 `filesFolder`로 실제 주소를 얻으면 됩니다.

## 요약

- Graph `allChannels`에서 공유 채널(ch-shared)의 `membershipType`만 `unknownFutureValue`
- 채널 유형 값이 evolvable enum이라 v1.0에서는 새 값(`shared`)이 기본적으로 `unknownFutureValue`로 반환됨(문서)
- 유형 문자열로 분기하지 않고 채널마다 `filesFolder`로 실제 주소를 얻으면 해결
- 유형이 꼭 필요하면 `Prefer: include-unknown-enum-members` 헤더(문서). 이 테넌트에서 헤더를 붙인 동작은 확인 불가

> 근거 표기: 조회 = 이 테넌트에서 직접 읽은 값, 문서 = Microsoft Learn, 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID, 도메인, 계정, 사용자 이름 등 비공개 정보는 가리거나 게시하지 않았습니다. 주소의 테넌트 부분은 `<테넌트>`로 적었습니다.

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

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/10/d3-channel-storage-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/10/d3-channel-storage.png" | relative_url }}" alt="표준 채널은 팀 사이트 폴더, 비공개·공유 채널은 별도 사이트에 파일이 저장되고, 시험 업로드 결과가 표시됨" loading="lazy"></picture>

*그림 1. 채널 유형별 파일 위치와 시험 업로드 결과. 공유 채널(ch-shared)은 비공개 채널처럼 별도 사이트(…-ch-shared)에 파일이 저장됩니다.*

### 2. 왜 이렇게 나오고, 어떻게 피하나

문서를 보면 채널 `membershipType`은 evolvable enum입니다. v1.0에서 새 값(공유 채널의 `shared`)은 기본적으로 `unknownFutureValue`로 반환되고, 요청에 `Prefer: include-unknown-enum-members` 헤더를 붙여야 `shared`로 나옵니다(문서: channel 리소스 유형). 오류가 아니라 정해진 동작입니다.

그래서 채널 유형 문자열(`private`, `shared`)로 분기하지 않고, 채널마다 `filesFolder`로 `driveId`와 `itemId`를 읽어 쓰면 됩니다. 개발자 문서도 채널 유형 값에 의존하지 말고, 파일 폴더는 `GET /teams/{teamId}/channels/{channelId}/filesFolder`로 얻으라고 안내합니다(문서: 공유·비공개 채널용 앱).

변경한 것은 없어 원복할 것도 없습니다(조회만 했습니다).

### 3. 스크립트를 짤 때 기억할 것

개발이나 자동화에서는 채널 유형 문자열보다 `filesFolder` 같은 **실제 주소 API**를 믿습니다. 목록에 `unknownFutureValue`가 보이면 오류로 단정하지 말고, 문서가 말하는 새 값이 아직 이름으로 풀리지 않은 것인지부터 봅니다.

### 4. 확인 과정

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 1장)</summary>

#### 화면과 비교

먼저 화면에서는 공유 채널로 보이는지 봤습니다. 채널을 만들 때 유형을 공유로 골랐고, Teams 관리 센터 팀 목록에도 공유 채널 열에 1이 잡혀 있었습니다(조회). 다음으로, 채널 유형 값과 관계없이 `filesFolder`로 폴더 주소를 따로 얻을 수 있는지 봤습니다.

![Teams 관리 센터 Manage teams 화면. Practice-Team 행이 표준 채널 2, 비공개 채널 1, 공유 채널 1]({{ "/assets/images/2026/10/d3-manage-teams.png" | relative_url }})
*그림 2. Teams 관리 센터 팀 목록(빨간 상자: Practice-Team-01, 일부 팀 이름은 가림). 공유 채널 열에 1이 표시됩니다.*

#### 해 본 것과 결과

위 2절의 원인과 해결 방법은 두 문서(channel 리소스 유형, 공유·비공개 채널용 앱)에서 확인했습니다. `filesFolder`로 얻은 공유 채널의 폴더 주소는 별도 사이트 `…/sites/Practice-Team-01-ch-shared/Shared Documents`였고, SharePoint 화면의 주소와 일치했습니다(조회).

헤더를 붙였을 때 이 테넌트에서 실제로 `shared`가 나오는지는 확인 불가입니다.
    - 시도: 이 테넌트에서는 헤더 없이만 조회함
    - 사유: 헤더를 붙여 시험하지 않음
    - 다음 방법: 같은 `allChannels` 요청에 `Prefer: include-unknown-enum-members` 헤더를 붙여 값을 비교(재측정 항목)

</details>

### 5. 관련 글

- [Teams 저장 구조: 채널 유형별 파일과 일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }})
- [관리 센터 숫자·사이트 목록과 Graph 채널 수가 다를 때]({{ "/m365/troubleshooting/channel-count-mismatch/" | relative_url }})

### 6. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- **문서**: 채널 유형 값에 의존하지 말고 filesFolder 사용
    - 출처: [공유·비공개 채널용 앱](https://learn.microsoft.com/microsoftteams/platform/build-apps-for-shared-private-channels)
- **문서**: `membershipType`은 evolvable enum이고 `Prefer: include-unknown-enum-members` 헤더로 `shared`를 얻음
    - 출처: [channel 리소스 유형](https://learn.microsoft.com/graph/api/resources/channel?view=graph-rest-1.0)
- **조회**: ch-shared의 `membershipType`이 `unknownFutureValue`, 폴더 주소가 별도 사이트
    - 출처: Graph, SharePoint 화면
- **조회**: 관리 센터 팀 목록의 공유 채널 열 값 1
    - 출처: Teams 관리 센터
- **확인 불가**: 헤더를 붙인 조회 결과
    - 시도·사유·다음 방법은 4절 "해 본 것과 결과"

</details>
