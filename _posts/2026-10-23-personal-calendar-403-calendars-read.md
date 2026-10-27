---
title: "[Troubleshooting] 개인 달력이 403일 때 — Calendars 범위와 일정 저장 위치"
date: 2026-10-23 12:30:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 7
tags: [Graph, Outlook, 일정, "403", Calendars.Read, 토큰 범위, 그룹 사서함]
excerpt: "같은 토큰으로 팀(그룹) 달력은 읽히는데 개인 달력은 403이다. Calendars.Read를 동의하면 200이 되고, 달력 소유자로 팀 일정과 개인 일정의 저장 위치를 나눌 수 있다"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·사유·다음 방법 병기). 계정과 식별자는 가렸고 사용자 이름은 적지 않았습니다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | Cloud Shell 토큰으로 팀(그룹) 캘린더는 읽히는데 개인 캘린더(`/me/events`, `/me/calendar`)는 403(`ErrorAccessDenied`) |
| 원인 | 토큰에 Calendars 읽기 범위가 없음(조회) |
| 대처 | Graph 탐색기에서 Calendars.Read를 직접 동의한 뒤 다시 조회 |
| 결과 | `GET /me/calendar`가 **200 OK**, 달력 소유자(owner)는 사용자 계정. 팀 달력의 소유자는 팀(그룹) 계정 |

---

## 전체 기록

### 1. 증상

팀 일정과 개인 일정이 저장되는 곳을 나눠 보려고, Cloud Shell에서 팀(그룹) 캘린더에 시험 일정을 만들고 같은 토큰으로 개인 캘린더를 읽어 봤습니다. 팀 캘린더는 만들기(HTTP 201)와 목록 조회가 모두 되었습니다. 개인 캘린더(`/me/events`)는 403이었습니다.

![팀 캘린더에 일정 생성]({{ "/assets/images/2026/10/m03-1-team-event-created.png" | relative_url }})
*그림 1. Cloud Shell 출력(위쪽 줄은 실행한 명령). 1) 팀(그룹) 캘린더에 일정 zz-test-team-event-r2(10/28 11:00 KST) 생성 HTTP 201, 2) 그룹 캘린더 목록에 그 일정이 보임(시작 시각은 UTC 표기라 02:00:00), 3) 내 개인 캘린더(`/me/events`)를 같은 토큰으로 읽으면 403(토큰에 Calendars 범위가 없음). 계정 부분은 가렸다.*

**실행한 스크립트** (준비 코드: 토큰·`$h`·`$B`·`$tid`는 Cloud Shell의 Azure 로그인 세션에서 받은 Graph 토큰과 팀 id입니다. 팀의 id가 곧 그룹 id라 `$tid`를 그대로 씁니다)

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

### 2. 먼저 확인할 것

1. **같은 토큰으로 되는 호출과 안 되는 호출을 나눈다.** 팀(그룹) 캘린더는 되고 개인 캘린더만 안 되므로, 로그인이나 계정 문제가 아니라 범위 차이로 봅니다.
2. **토큰의 범위(scp)를 본다.** 토큰 본문은 출력하지 않고 허용된 범위만 읽습니다. Cloud Shell 토큰에는 Calendars 범위가 없었고, 이는 채널 403에서 읽은 토큰 범위 출력(AppCatalog.Read.All, Group.ReadWrite.All 등. Files.*·Sites.*도 없음)과 일치합니다(조회).
3. **화면으로는 되는가.** Outlook 웹의 개인 캘린더는 같은 관리자 계정으로 열렸습니다(조회).

### 3. 시도와 결과

Graph 탐색기(Graph Explorer)에서 캘린더 읽기 범위 **Calendars.Read**를 직접 동의하고 `GET /me/calendar`를 다시 실행했습니다.

| 시도 | 결과 |
|---|---|
| Cloud Shell 토큰으로 `/me/events` | 403(Calendars 범위 없음) |
| Graph 탐색기에서 Calendars.Read 동의 후 `GET /me/calendar` | **200 OK**, 이름 Calendar, **owner = 관리자 사용자 계정** |
| 같은 방식으로 `GET /groups/{id}/calendar` | owner = 팀(그룹) 계정 |

![내 달력 조회 결과 200, 소유자는 사용자 계정]({{ "/assets/images/2026/10/m22-1-me-calendar-owner-200.png" | relative_url }})
*그림 2. 캘린더 읽기 범위 동의 후 `GET /me/calendar` 응답(200 OK). name은 Calendar이고 owner가 사용자 계정이다. 사용자 이름·주소와 식별자는 가렸다.*

- **의미**: 팀 일정은 그룹 사서함의 달력에, 개인 일정은 사용자 사서함의 달력에 저장된다는 것을 **달력 소유자 기준**으로 확인했습니다. 팀 일정은 팀(그룹) 캘린더에만, 개인 일정은 개인 캘린더에만 보였습니다(조회).
- 동의 전 403은 비공개 채널 파일 403과 같은 계열의 원인(토큰 범위 부족)입니다([비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})).
- 개인 회의 일정이 이 달력에 쌓인다는 점은 문서 기준입니다.

### 4. 대처·원복

- 토큰 범위를 넓히려고 관리자 역할을 부여받거나 보안 설정을 바꾸는 일은 하지 않았습니다. 사용자 동의로 읽기 범위(Calendars.Read)만 추가했습니다.
- 동의한 읽기 범위는 필요가 없어지면 Entra 관리 센터의 엔터프라이즈 애플리케이션에서 철회할 수 있습니다.

### 5. 운영에서는 이렇게 판단한다

- 403이 나면 **권한(역할)이 부족한지, 토큰의 범위가 부족한지**부터 나눕니다. 화면에서 열리는데 Graph만 403이면 토큰 범위를 먼저 봅니다.
- 일정이 어디에 저장되는지는 **달력 소유자**로 구분합니다. 팀 일정은 그룹 사서함, 개인 일정은 사용자 사서함입니다. 보존·검색 대상 사서함이 다르다는 점은 보존 정책을 세울 때 반영합니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 조회 | 팀 일정 생성 201, 그룹 캘린더 목록에 있음, 개인 캘린더 `/me/events` 403 | Cloud Shell(Graph) |
| 조회 | Calendars.Read 동의 후 `GET /me/calendar` 200, owner가 사용자 계정 / 팀 달력 owner가 팀(그룹) 계정 | Graph 탐색기 |
| 조회 | 팀 일정은 팀(그룹) 캘린더에만, 개인 일정은 개인 캘린더에만 보임 | Cloud Shell(Graph), Outlook 웹 |
| 문서 | 채널 캘린더 항목은 팀에 연결된 Microsoft 365 그룹 캘린더에 있는 채널 회의 | [Microsoft Q&A 답변](https://learn.microsoft.com/answers/a/12452933) |
| 문서 | 채널 회의 채팅은 팀의 사서함, 일반 회의 채팅은 참석자 사서함 | [Finding content in Microsoft Teams in eDiscovery](https://learn.microsoft.com/purview/edisc-search-teams#where-teams-content-is-stored) |

관련 글: [Teams 저장 구조 — 채널 유형별 파일·일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }}), [만들어 둔 개인 일정이 사라졌을 때]({{ "/m365/troubleshooting/personal-event-disappeared/" | relative_url }}), [Cloud Shell에서 Graph 호출 — 되는 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }})
