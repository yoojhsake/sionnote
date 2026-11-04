---
title: "[Troubleshooting] 개인 달력이 403일 때: Calendars 범위와 일정 저장 위치"
date: 2026-10-23 12:30:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 7
tags: [Graph, Outlook, 일정, "403", Calendars.Read, 토큰 범위, 그룹 사서함]
excerpt: "팀 달력은 읽히는데 개인 달력만 403. Cloud Shell 토큰엔 Calendars 범위가 없어 403, Graph 탐색기에서 Calendars.Read를 동의한 토큰으로는 200 OK, 달력 소유자로 저장 위치도 갈랐다"
---

Cloud Shell 토큰으로 팀 달력은 읽히는데 내 개인 달력만 403(`ErrorAccessDenied`)이 납니다. Cloud Shell 토큰에는 Calendars 범위가 없어 `/me/events`가 403이었고, Graph 탐색기에서 Calendars.Read를 동의한 토큰으로는 `/me/calendar`가 200 OK였습니다.

## 요약

- 팀 일정은 그룹 사서함, 개인 일정은 사용자 사서함 달력에 저장됨
- 화면은 열리는데 Graph만 403이면 역할보다 토큰 범위를 먼저 의심하면 됨
- 보존과 검색 정책은 두 사서함을 따로 대상에 넣어야 함(문서, 정책 동작은 이 글에서 시험하지 않음)

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 캡처의 식별자도 가렸습니다.

---

## 전체 기록

### 1. 증상

- 같은 토큰으로 팀(그룹) 캘린더는 일정 만들기(HTTP 201)와 목록 조회가 됐지만 개인 캘린더(`/me/events`)만 403이었습니다(그림 1, 확인 과정에 있음).

### 2. 원인 및 분석

- 토큰 범위: 필요 Calendars 읽기 / Cloud Shell 토큰에는 없음(채널 파일 403과 같은 계열, [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})).
- 동의 후 `GET /me/calendar` owner는 사용자 계정 / 그룹 달력 owner는 팀(그룹) 계정. 팀 일정은 팀 캘린더에만, 개인 일정은 개인 캘린더에만 보였습니다(개인 회의 일정이 쌓이는 점은 문서 기준).

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 3장)</summary>

#### 나눠 본 순서

1. 같은 토큰으로 되는 호출과 안 되는 호출을 나눕니다. 팀(그룹) 캘린더는 되고 개인 캘린더만 안 되니, 로그인이나 계정 문제가 아니라 범위 차이로 봤습니다.
2. 토큰의 범위(scp)를 봅니다. 토큰 본문은 출력하지 않고 허용된 범위만 읽습니다.
    - Cloud Shell 토큰에는 Calendars 범위가 없었습니다.
    - 채널 403에서 읽은 토큰 범위 출력(AppCatalog.Read.All, Group.ReadWrite.All 등. Files.*·Sites.*도 없음)과도 일치합니다(조회).
3. 화면으로는 되는가. Outlook 웹의 개인 캘린더는 같은 관리자 계정으로 열렸습니다(조회).

#### 증상을 확인한 스크립트

그림 1의 출력을 낸 스크립트입니다. 준비 코드의 토큰, `$h`, `$B`, `$tid`는 Cloud Shell의 Azure 로그인 세션에서 받은 Graph 토큰과 팀 id입니다. 팀의 id가 곧 그룹 id라 `$tid`를 그대로 씁니다.

```powershell
# 공통 준비 코드
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
$tid = (Invoke-RestMethod -Headers $h -Uri "$B/me/joinedTeams").value | Where-Object displayName -eq 'Practice-Team-01' | Select-Object -ExpandProperty id
```

```powershell
$ev = @{ subject = 'zz-test-team-event-r2'; start = @{ dateTime = '2026-10-28T11:00:00'; timeZone = 'Korea Standard Time' }; end = @{ dateTime = '2026-10-28T11:30:00'; timeZone = 'Korea Standard Time' } } | ConvertTo-Json -Depth 3
$null = Invoke-RestMethod -Method Post -Headers $h -Uri "$B/groups/$tid/events" -ContentType 'application/json' -Body $ev -StatusCodeVariable sc; "1) create group event: HTTP $sc"
(Invoke-RestMethod -Headers $h -Uri "$B/groups/$tid/events?`$select=subject,start").value | ForEach-Object { "2) group calendar: $($_.subject)  $($_.start.dateTime)" }
try { Invoke-RestMethod -Headers $h -Uri "$B/me/events?`$top=1" | Out-Null; '3) personal calendar: OK' } catch { "3) personal calendar: HTTP $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase))" }
```

![팀 캘린더에 일정 생성]({{ "/assets/images/2026/10/m03-1-team-event-created.png" | relative_url }})
*그림 1. Cloud Shell 출력(위쪽 줄은 실행한 명령). 1) 팀(그룹) 캘린더에 일정 zz-test-team-event-r2(10/28 11:00 KST) 생성 HTTP 201, 2) 그룹 캘린더 목록에 그 일정이 보임(시작 시각은 UTC 표기라 02:00:00), 3) 내 개인 캘린더(`/me/events`)를 같은 토큰으로 읽으면 403(토큰에 Calendars 범위가 없음). 계정 부분은 가렸습니다.*

#### 동의 후 다시 조회

Graph 탐색기에서 Calendars.Read를 동의한 뒤 다시 조회했습니다.

- Cloud Shell 토큰으로 `/me/events`: 403(Calendars 범위 없음)
- Graph 탐색기에서 Calendars.Read 동의 후 `GET /me/calendar`: **200 OK**, 이름 Calendar, owner = 관리자 사용자 계정
- 같은 방식으로 `GET /groups/{id}/calendar`: owner = 팀(그룹) 계정
- 2026-11-04에 같은 동의된 Graph 탐색기 토큰으로 `GET /me/events?$top=1&$select=subject,start`도 조회했고 **200 OK**였습니다. 첫 일정은 subject `zz-test-personal-event`, 시작 `2026-10-28T01:00:00`(UTC, 10/28 10:00 KST)이었습니다(그림 3). 즉 같은 `/me/events` 호출이 Cloud Shell 토큰에서는 403, 동의된 토큰에서는 200입니다.
- Cloud Shell 토큰으로 `/me/events`를 11-04에 다시 호출하지는 않았습니다(시도 안 함). 10/23의 403 결과와 scp에 Calendars 범위가 없는 것으로 대신합니다.

![내 달력 조회 결과 200, 소유자는 사용자 계정]({{ "/assets/images/2026/10/m22-1-me-calendar-owner-200.png" | relative_url }})
*그림 2. 캘린더 읽기 범위 동의 후 `GET /me/calendar` 응답(200 OK). name은 Calendar입니다. owner 블록과 식별자, 사용자 이름, 주소는 가렸고, owner가 사용자 계정이라는 점은 본문 기록 기준입니다.*

![Graph 탐색기에서 /me/events가 200 OK로 zz-test-personal-event를 돌려준 화면]({{ "/assets/images/2026/10/m22-5-me-events-200-1104.png" | relative_url }})

*그림 3. 2026-11-04 Graph 탐색기에서 동의된 토큰으로 `GET /v1.0/me/events?$top=1&$select=subject,start`를 조회한 결과(200 OK). 사용자 ID와 일정 ID는 가렸습니다.*

</details>

### 3. 결론

토큰에 Calendars 범위 없음 → `/me/events` 403 → Outlook 웹과 팀 달력은 정상

역할이나 보안 설정은 바꾸지 않고 사용자 동의로 Calendars.Read만 추가했습니다.

### 4. 권고방안

1. 403이 나면 역할 부족인지 토큰 범위 부족인지부터 나눕니다.
2. 조치 후 확인: 동의한 토큰으로 `GET /me/calendar`가 200 OK인지 봅니다.
3. 동의한 범위는 필요 없어지면 Entra 관리 센터 > 엔터프라이즈 애플리케이션에서 철회합니다(원복).
4. 저장 위치는 달력 소유자로 구분해 보존 정책에 반영합니다(문서: 그룹 사서함은 "Microsoft 365 Group mailboxes & sites" 위치로 따로 지정).

관련 글: [Teams 저장 구조: 채널 유형별 파일·일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }}) · [만들어 둔 개인 일정이 사라졌을 때]({{ "/m365/troubleshooting/personal-event-disappeared/" | relative_url }}) · [Cloud Shell에서 Graph 호출: 되는 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (8건)</summary>

- 조회: 팀 일정 생성 201, 그룹 캘린더 목록에 있음, 개인 캘린더 `/me/events` 403
    - 출처: Cloud Shell(Graph)
- 조회: Calendars.Read 동의 후 `GET /me/calendar` 200, owner가 사용자 계정 / 팀 달력 owner가 팀(그룹) 계정
    - 출처: Graph 탐색기
- 조회: 동의된 토큰으로 `GET /me/events?$top=1` 200 OK, subject zz-test-personal-event (2026-11-04)
    - 출처: Graph 탐색기, 그림 3
- 조회: 팀 일정은 팀(그룹) 캘린더에만, 개인 일정은 개인 캘린더에만 보임
    - 출처: Cloud Shell(Graph), Outlook 웹
- 문서: 그룹 사서함과 사용자 사서함에 캘린더 항목이 저장됨
    - 출처: [Search for content in mailboxes (eDiscovery)](https://learn.microsoft.com/purview/edisc-search-mailboxes#content-stored-in-exchange-online-mailboxes-for-ediscovery)
- 문서: 그룹 사서함은 보존 정책에서 "Microsoft 365 Group mailboxes & sites" 위치로 지정
    - 출처: [Learn about retention policies and retention labels](https://learn.microsoft.com/purview/retention-settings#locations)
- Microsoft Q&A 답변(외부 스태프 작성, 공식 문서 아님): 채널 캘린더 항목은 팀에 연결된 Microsoft 365 그룹 캘린더에 있는 채널 회의
    - 출처: [Microsoft Q&A 답변](https://learn.microsoft.com/answers/a/12452933)
- 문서: 채널 회의 채팅은 팀의 사서함, 일반 회의 채팅은 참석자 사서함
    - 출처: [Finding content in Microsoft Teams in eDiscovery](https://learn.microsoft.com/purview/edisc-search-teams#where-teams-content-is-stored)

</details>
