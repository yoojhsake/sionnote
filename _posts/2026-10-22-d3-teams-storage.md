---
title: "[M365·Azure] 03 D3 Teams 저장 구조 — 채널 유형별 파일 위치 (전체 기록)"
date: 2026-10-22 09:40:00 +0900
last_modified_at: 2026-10-23 12:00:00 +0900
categories: [m365]
tags: [M365·Azure, D3, Teams, SharePoint, 채널, 전체 기록]
excerpt: "표준·비공개·공유 채널의 파일이 실제로 어느 SharePoint 주소에 저장되는지 확인한 전체 기록. 403 응답인데 파일이 생긴 이상 현상과 정정 사항 포함"
---

수행일은 2026-10-22(목)이고, 프로그램 일정상 D3(Teams 저장 구조) 주제입니다.

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·사유 병기, 2026-10-23 재확인 반영). 테넌트 도메인은 주소에서 뺐고(`<테넌트>`로 표기) 사용자 이름은 적지 않았습니다.

## 1. 목표

1. Team 하나를 만들면 무엇이 같이 만들어지는지(M365 그룹, SharePoint 사이트, 사서함) 확인한다.
2. 채널 유형(표준·비공개·공유)에 따라 **파일이 저장되는 SharePoint 위치가 어떻게 다른지** 실제 주소로 확인한다.
3. 1:1 채팅 파일과 회의 녹화 파일의 저장 위치는 문서로 정리한다.

## 2. 먼저 알아야 할 개념

![표준 채널은 팀 사이트 폴더, 비공개·공유 채널은 별도 사이트에 파일이 저장되고, 시험 업로드 결과가 표시됨]({{ "/assets/images/2026/10/d3-channel-storage.png" | relative_url }})
*그림 1. 채널 유형별 파일 위치와 시험 업로드 결과*

| 개념 | 쉬운 설명 |
|---|---|
| Team | Microsoft 365 그룹 + SharePoint 팀 사이트 + 그룹 사서함(일정)이 묶인 것 |
| 표준 채널 | 팀 사이트를 같이 씀. 채널마다 문서 라이브러리 안에 폴더가 하나 생김 |
| 비공개 채널 | 구성원이 제한된 채널. **별도의 SharePoint 사이트**가 생김 |
| 공유 채널 | 다른 팀·조직과 공유할 수 있는 채널. **별도의 SharePoint 사이트**가 생김 |
| 1:1·그룹 채팅 파일 | 보낸 사람의 OneDrive에 저장(문서 기준, 이 테넌트에서 확인 안 함) |
| 회의 녹화 | 일반 회의: 주최자의 OneDrive > Recordings 폴더 / 채널 회의: 팀 SharePoint 사이트 > Documents > Recordings 폴더(문서: Teams 회의 녹화 저장 문서) |
| **Team 일정**(채널 일정·채널 회의) | **그룹 사서함**(Microsoft 365 그룹 캘린더)에 저장. 팀을 만들 때 같이 생긴 사서함입니다(문서·Q&A 기준, 이 테넌트 시험 결과는 6-2번 참고) |
| **개인 회의 일정**(Teams·Outlook에서 만든 일반 회의) | **사용자 사서함**에 저장. 주최자 사서함에 원본이, 참석자 각자의 사서함에 복사본이 생깁니다(문서 기준) |
| 회의 채팅 | 일반 회의는 참석자 각자의 사서함, 채널 회의는 팀의 그룹 사서함(문서: Purview eDiscovery의 Teams 콘텐츠 저장 위치 표) |

## 3. 절차

### 3-1. Team 만들기 (09:30)

1. teams.microsoft.com > 팀 > 팀 만들기 > 처음부터 > **비공개**
2. 이름 **Practice-Team-01**, 만들기 (소유자: 관리자 계정, 구성원 추가는 건너뜀)

### 3-2. 채널 3종 만들기 (09:31)

1. 팀 목록에서 Practice-Team-01 옆 "+" > 새 채널 (채널 머리글의 "+"는 다른 메뉴가 열려서 쓰지 않음)
2. ch-standard(표준), ch-private(채널 유형 **비공개**), ch-shared(채널 유형 **공유**) 생성. 비공개·공유는 구성원 지정 단계가 따로 나옴
3. Cloud Shell에서 Graph로 채널 목록 조회

```powershell
$B = 'https://graph.microsoft.com/v1.0'
$t = ((Invoke-AzRestMethod -Uri "$B/groups?`$filter=resourceProvisioningOptions/Any(x:x eq 'Team')&`$select=id,displayName").Content | ConvertFrom-Json).value
"TEAMS|$($t.Count)"
$id = ($t | ? displayName -eq 'Practice-Team-01').id
((Invoke-AzRestMethod -Uri "$B/teams/$id/allChannels?`$select=displayName,membershipType").Content | ConvertFrom-Json).value | % { "CH|$($_.displayName)|$($_.membershipType)" }
```

### 3-3. 파일 폴더 주소 조회와 시험 업로드 (10:06)

브라우저의 파일 선택 창을 쓸 수 없어서 Cloud Shell에서 Graph로 대신했습니다. 각 채널의 `filesFolder`를 조회해 폴더 주소를 얻고, 시험 파일(`D3-test-<채널명>.txt`)을 올려 본 뒤, **SharePoint 화면**에서 파일이 실제로 어디 있는지 확인했습니다.

마지막으로 SharePoint 관리 센터 > 사이트 > 활성 사이트에서 사이트 수를 봤습니다.

## 4. 전·후 비교와 실제 값

![Teams 관리 센터 Manage teams 화면. 8 teams, Practice-Team 행이 표준 채널 2, 비공개 채널 1]({{ "/assets/images/2026/10/d3-manage-teams.png" | relative_url }})
*그림 2. Teams 관리 센터 팀 목록 (빨간 상자: Practice-Team-01, 일부 팀 이름은 가림)*

| 항목 | 만들기 전 | 만든 후 |
|---|---|---|
| Team 수 | **7** | **8** |
| Practice-Team-01 채널 | - | General, ch-standard, ch-private, ch-shared (Graph 4개) |
| 관리 센터 열 값 | - | 표준 채널 2, 비공개 채널 1 (공유 채널은 이 두 열에 잡히지 않음) |

**채널 유형 값(Graph)**

| 채널 | Graph `membershipType` |
|---|---|
| General | standard |
| ch-standard | standard |
| ch-private | private |
| ch-shared | **unknownFutureValue** (공유 채널) |

**채널별 파일 폴더 주소 패턴**

| 채널 | 폴더 주소 패턴 | 설명 |
|---|---|---|
| General | `https://<테넌트>.sharepoint.com/sites/Practice-Team-01/Shared Documents/General` | 팀 사이트 안 폴더 |
| ch-standard | `…/sites/Practice-Team-01/Shared Documents/ch-standard` | 팀 사이트 안 폴더 |
| ch-private | `…/sites/Practice-Team-01-ch-private/Shared Documents` | **별도 사이트** |
| ch-shared | `…/sites/Practice-Team-01-ch-shared/Shared Documents` | **별도 사이트** |

![세 채널의 SharePoint 문서 라이브러리. 표준은 팀 사이트 안 폴더, 비공개와 공유는 별도 사이트의 루트]({{ "/assets/images/2026/10/d3-sharepoint-files.png" | relative_url }})
*그림 3. 채널별 SharePoint 문서 화면(GUI: 각 주소를 브라우저에서 열어 캡처, 10/24 01시경). 위: 팀 사이트 Practice-Team-01의 `Documents > ch-standard` 폴더(파일 4개: D3-test-ch-standard.txt와 이후 시험 파일 3개). 가운데: 별도 사이트 Practice-Team-01-ch-private의 문서(D3-test-ch-private.txt). 아래: 별도 사이트 Practice-Team-01-ch-shared의 문서(D3-test-ch-shared.txt). 사용자 이름은 가렸다. 이전 그림의 빨간 상자와 도메인 가림은 이번 캡처에서는 주소 표시줄을 포함하지 않아 필요 없다.*

**시험 업로드 응답과 SharePoint 화면 결과**

| 채널 | Graph 응답 | SharePoint 화면에서 파일 |
|---|---|---|
| ch-standard | **201 성공** | 있음(팀 사이트의 ch-standard 폴더) |
| ch-private | **403** | **있음**(별도 사이트) |
| ch-shared | **403** | **있음**(별도 사이트) |

![SharePoint 관리 센터 활성 사이트 목록. Practice-Team-01 한 행, 채널 사이트 2개로 표시]({{ "/assets/images/2026/10/d3-active-sites.png" | relative_url }})
*그림 4. 활성 사이트 목록 (빨간 상자: Practice-Team-01 행)*

- 활성 사이트에는 **Practice-Team-01 한 행만** 보이고, 채널 사이트는 별도 행이 아니라 "사이트 2개"라는 표시로 묶여 보였습니다.

변경 이력(8개 항목):

| 항목 | 내용 |
|---|---|
| 언제 | 2026-10-22 09:30 ~ 10:06 |
| 무엇을 | Team 1개 + 채널 3개 생성, 시험 파일 3개 업로드 |
| 전 → 후 | Team 7→8, 채널 사이트 2개 생성, 시험 파일 3개 생성 |
| 왜 | 채널 유형별 파일 저장 위치를 실제 주소로 확인 |
| 근거 | Teams·SharePoint 화면, Graph 조회, 문서 아래 URL |
| 검증 결과 | 사이트·폴더 주소 4개, 업로드 응답 201/403/403, 파일 존재 3개 |
| 원복 방법 | Team 삭제(삭제하면 30일간 복구 가능). **삭제는 하지 않았고** 정리 항목으로 남김 |

## 5. 문제점과 원인, 해결 방안

### 문제 1 — 응답은 403인데 파일이 만들어졌다

- **상황**: 비공개·공유 채널 폴더에 올릴 때 Graph가 403을 돌려줬지만, SharePoint 화면에서 보니 파일은 있었습니다.
- **원인**: **확인 불가**. 응답 형식의 문제인지, 권한 범위(관리자가 해당 채널의 구성원이 아님 등)의 문제인지 구분하지 못했습니다. 10/23에 같은 방식으로 다시 시도했더니 비공개·공유 채널은 올리기도 읽기도 403이었고 새 파일은 생기지 않았습니다(10/22 파일은 그대로 있음). 10/22의 "403인데 파일이 생긴" 요청은 요청·응답을 보존하지 못해 대조할 수 없습니다. 자세한 재현은 [트러블슈팅 글]({{ "/m365/troubleshooting/channel-upload-403-repro/" | relative_url }})에 있습니다.
- **해결 방안(원칙)**: 업로드 성공 여부를 **응답 코드만으로 판단하지 않습니다.** 코드와 실제 저장 위치를 둘 다 확인합니다. 원인은 확인 사항으로 남겼습니다.
- **교훈**: 403 = "아무 일도 안 일어남"이 아닙니다. 실패로 보이는 응답 뒤에 데이터가 남아 있을 수 있습니다.

### 문제 2 — 공유 채널이 `unknownFutureValue`로 보인다

- **원인(문서)**: 개발자 문서는 채널 유형 값에 의존하지 말고, 파일 폴더는 `GET /teams/{teamId}/channels/{channelId}/filesFolder`로 얻으라고 안내합니다. 채널 유형 값은 evolvable enum이라, v1.0에서 새 값(공유 채널의 `shared`)은 기본적으로 `unknownFutureValue`로 반환됩니다(문서). 요청에 `Prefer: include-unknown-enum-members` 헤더를 붙이면 `shared`로 나옵니다(문서). 이 헤더로 이 테넌트에서 다시 조회해 보지는 않았으므로 실제 동작은 **확인 불가**(사유: 이번에 헤더를 붙여 시험하지 않음, 재측정 항목)입니다.
- **해결 방안**: 채널 유형 문자열로 분기하지 말고, 채널마다 `filesFolder`로 실제 주소를 얻어 씁니다.

### 문제 3 — 관리 센터 숫자와 Graph 채널 수가 다르게 보인다

- 관리 센터의 열 값은 표준 2·비공개 1이고 공유 채널은 두 열에 잡히지 않았습니다. Graph `allChannels`는 4개(General 포함)를 돌려줬습니다. 공유 채널이 관리 센터에서 어디에 집계되는지는 **이 화면만으로는 알 수 없어 확인 불가**입니다(시도: 관리 센터 열 값과 Graph 목록 대조, 사유: 공유 채널이 두 열에 잡히지 않음). 10/23에 공유 채널 사이트 주소를 직접 열어 문서 라이브러리가 있는 것은 확인했습니다.

### 문제 4 — 활성 사이트 목록에 채널 사이트가 별도 행으로 안 보인다

- **관찰**: 팀 사이트 한 행과 "사이트 2개" 표시만 있었습니다.
- **해결 방안**: 문서에 따르면 SharePoint 관리 센터에서 채널 사이트는 "채널 사이트" 열의 링크로 들어가서 개별 사이트를 고를 수 있습니다. 사이트별 외부 공유 설정을 바꿀 때도 그 경로를 씁니다(이 글에서는 설정을 바꾸지 않음).

### 문제 5 — 브라우저 파일 선택창을 쓸 수 없다

- **원인**: 이 실습 환경에서는 브라우저의 파일 선택 대화상자를 쓸 수 없었습니다.
- **해결 방안**: Cloud Shell의 Graph 호출로 대체했습니다. 이 방식은 문제 1의 403 현상을 만들었을 수 있으므로, 사람이 Teams에서 직접 올리는 경우와 결과가 같은지는 **확인 불가**입니다(사유: 브라우저 파일 선택창을 쓸 수 없어 직접 업로드를 시도하지 못함).

### 문제 6 — 이전 기록의 오류 정정

- 이전 정리본의 "Team 6개"는 오류였고 조회 결과는 **7개(실습 전) → 8개(후)**입니다.

## 6. 검증

| 검증 | 결과 |
|---|---|
| Teams 목록·Graph Team 수 | 8 |
| Graph 채널 수 | 4 (standard 2, private 1, unknownFutureValue 1) |
| 폴더 주소 4개를 SharePoint 화면과 대조 | 일치 |
| 시험 파일 존재 | 3개 모두 SharePoint 화면에서 확인 |
| 활성 사이트 목록 | 팀 사이트 1행 + 채널 사이트 2개 표시 |

### 6-2. 일정 저장 위치 시험 (10/23 추가)

Team 일정은 그룹 사서함, 개인 회의 일정은 사용자 사서함이라는 설명을 이 테넌트에서 실제로 나눠 보았습니다. 시험 일정 2개를 만들었고, 확인한 뒤 삭제했습니다.

| 일정 종류 | 만든 방법 | 보인 곳 | 보이지 않은 곳 |
|---|---|---|---|
| 팀 일정 `zz-test-team-event` (10/27 10:00) | Cloud Shell에서 Graph로 팀(그룹) 캘린더에 생성(HTTP 201) | 팀(그룹) 캘린더 목록(조회) | 관리자의 개인 Outlook 캘린더 10/27 10:00(조회) |
| 개인 일정 `zz-test-personal-event` (10/28 10:00) | Outlook 웹에서 새 이벤트 저장 | 관리자의 개인 Outlook 캘린더 10/28 10:00(조회) | 팀(그룹) 캘린더 목록(조회) |


![팀 캘린더에 일정 생성]({{ "/assets/images/2026/10/m03-1-team-event-created.png" | relative_url }})
*그림 5. Cloud Shell 출력(10/23 저녁 재실행, 위쪽 줄은 실행한 명령). 1) 팀(그룹) 캘린더에 일정 zz-test-team-event-r2(10/28 11:00 KST) 생성 HTTP 201, 2) 그룹 캘린더 목록에 그 일정이 보임(시작 시각은 UTC 표기라 02:00:00), 3) 내 개인 캘린더(`/me/events`)를 같은 토큰으로 읽으면 403(토큰에 Calendars 범위가 없음). 계정 부분은 가렸다.*

**실행한 스크립트** (준비 코드: [13 글]({{ "/m365/troubleshooting/channel-upload-403-repro/" | relative_url }})의 "공통 준비 코드". 팀의 id가 곧 그룹 id라 `$tid`를 그대로 씁니다)

```powershell
$ev = @{ subject = 'zz-test-team-event-r2'; start = @{ dateTime = '2026-10-28T11:00:00'; timeZone = 'Korea Standard Time' }; end = @{ dateTime = '2026-10-28T11:30:00'; timeZone = 'Korea Standard Time' } } | ConvertTo-Json -Depth 3
$null = Invoke-RestMethod -Method Post -Headers $h -Uri "$B/groups/$tid/events" -ContentType 'application/json' -Body $ev -StatusCodeVariable sc; "1) create group event: HTTP $sc"
(Invoke-RestMethod -Headers $h -Uri "$B/groups/$tid/events?`$select=subject,start").value | ForEach-Object { "2) group calendar: $($_.subject)  $($_.start.dateTime)" }
try { Invoke-RestMethod -Headers $h -Uri "$B/me/events?`$top=1" | Out-Null; '3) personal calendar: OK' } catch { "3) personal calendar: HTTP $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase))" }
```

*위 표의 `zz-test-team-event`(10/27)는 오전 시험에서 만들고 확인한 뒤 삭제했습니다. 이 그림은 같은 시험을 이름만 바꿔(`-r2`) 다시 실행해 화면을 선명하게 남긴 것이고, 새로 만든 일정은 정리 목록에 넣었습니다.*

![팀 캘린더 목록]({{ "/assets/images/2026/10/m03-2-team-calendar-list.png" | relative_url }})
*그림 6. 개인 일정(zz-test-personal-event)을 Outlook에서 만든 뒤 다시 읽은 팀(그룹) 캘린더 목록. zz-test-team-event-r2 한 건만 있고, 아래 줄에서 개인 일정이 이 목록에 있는지 검사한 결과가 False이다. 계정 부분은 가렸다.*

**실행한 스크립트**

```powershell
$ev = (Invoke-RestMethod -Headers $h -Uri "$B/groups/$tid/events?`$select=subject,start").value
$ev | Format-Table subject, @{ n = 'start (UTC)'; e = { $_.start.dateTime } } -AutoSize
'zz-test-personal-event in group calendar: ' + [bool]($ev | Where-Object subject -eq 'zz-test-personal-event')
```

**재확인과 재생성 (10/24 새벽)**: 그림 7을 선명하게 다시 찍으려고 Outlook 웹(`outlook.office.com` → 캘린더 → 주 보기/월 보기)을 열었더니 10/28에 개인 일정이 **없었습니다**. 일정 검색(`zz-test`)도 0건이었고, 월 보기에서도 10월 전체가 비어 있었습니다. 일정이 사라진 원인은 확인 불가입니다(시도한 방법: 주·월 보기, 일정 검색, 필터 확인 — 필터는 "예약"만 꺼져 있어 원인이 아니었음. Graph로 `/me/events`를 읽는 방법은 토큰에 Calendars 범위가 없어 403이라 쓰지 못함. 다음 방법: 캘린더 읽기 범위를 동의한 토큰으로 조회 → 10/27에 조회함, 아래 "10/27 확인"). 이 일정을 지운 작업은 한 적이 없습니다. 그래서 같은 이름·같은 시각으로 GUI에서 다시 만들어 그 과정을 남겼습니다.

**GUI 경로**: Outlook 웹 → 캘린더 → 새 이벤트 → 제목 `zz-test-personal-event`, 날짜 2026-10-28, 시작 오전 10:00(끝 10:30) → 저장 → 주 보기에서 확인.

![개인 일정 만들기]({{ "/assets/images/2026/10/m03-3a-personal-event-create.png" | relative_url }})
*그림 7-1. Outlook 웹에서 개인 일정을 만드는 화면(10/24 재생성). 제목 zz-test-personal-event, 2026-10-28 오전 10:00~10:30을 넣고 저장 직전.*

![개인 Outlook 캘린더]({{ "/assets/images/2026/10/m03-3-personal-calendar.png" | relative_url }})
*그림 7. Outlook 웹의 관리자 개인 캘린더(10/25~10/31주, 10/24 새벽 재생성 후 촬영). 10/28(수) 10:00에 개인 일정 zz-test-personal-event만 있고, 팀 일정을 넣었던 10/27(화) 10:00 칸은 비어 있다. 팀(그룹) 캘린더에 넣은 일정이 개인 캘린더에 보이지 않는다는 점은 이 화면과 그림 5·6으로 함께 확인한다.*

- **해석**: 팀 일정은 팀(그룹) 캘린더에만, 개인 일정은 개인 캘린더에만 들어갔습니다. 저장 단위가 서로 다르다는 문서·Q&A의 설명과 같은 결과입니다.
- **한계(확인 불가)**: 사서함 내부를 직접 열어 "그룹 사서함에 들어 있다"는 물리 저장 위치까지 본 것은 아닙니다. 캘린더가 어느 쪽에 속하는지(그룹 캘린더 vs 사용자 캘린더)만 확인했습니다. 사서함 내부 확인은 Exchange PowerShell(`Get-MailboxFolderStatistics`)이 필요한데, 이 글을 쓸 때는 보안 기본값(AADSTS530035) 때문에 연결하지 못했습니다(확인 불가, 시도한 방법은 장치 코드 로그인)이고 이 글에서는 확인하지 않았습니다.
- **10/27 확인(조회)**: Graph 탐색기에서 캘린더 읽기 범위(Calendars.Read)를 직접 동의한 뒤 `GET /me/calendar`를 다시 실행했더니 **200 OK**였고, 달력 이름은 Calendar, **소유자(owner)가 관리자 사용자 계정**으로 나왔습니다. 같은 방식으로 읽은 팀 달력(`GET /groups/{id}/calendar`)은 소유자가 팀(그룹) 계정이었습니다. 그래서 **팀 일정은 그룹 사서함, 개인 일정은 사용자 사서함의 달력**에 저장된다는 것을 달력 소유자 기준으로 확인했습니다. 개인 회의 일정이 이 달력에 쌓인다는 점은 문서 기준입니다.

![내 달력 조회 결과 200, 소유자는 사용자 계정]({{ "/assets/images/2026/10/m22-1-me-calendar-owner-200.png" | relative_url }})
*그림 7-2. 캘린더 읽기 범위 동의 후 `GET /me/calendar` 응답(200 OK). name은 Calendar이고 owner가 사용자 계정이다. 사용자 이름·주소와 식별자는 가렸다.*

- **참고(동의 전 상태)**: 같은 토큰으로 개인 캘린더(`/me/events`)를 읽으면 403이 났습니다. 비공개 채널 403과 같은 계열의 원인(토큰 범위 부족)으로 보이며, 토큰에 Calendars 범위가 없다는 점은 앞의 토큰 범위 출력과 일치합니다.

### 6-3. OneDrive 위치 다시 확인 (10/23 오후 추가)

오전에는 관리자 OneDrive가 "기본 문서 라이브러리를 찾을 수 없음" 오류로 열리지 않아 회의 녹화·1:1 채팅 파일이 저장되는 위치를 확인하지 못했습니다.

오후에 OneDrive 웹을 다시 열었더니 홈과 My files가 정상으로 열렸습니다(조회). My files에는 **Meetings, Microsoft Copilot Chat Files, Recordings** 폴더가 있고 모두 0개였습니다.

문서가 설명하는 "개인 회의 녹화는 진행자의 OneDrive에 저장"되는 대상 폴더는 있는 것이고, 실제 녹화가 거기에 들어가는지는 녹화를 해 봐야 합니다(아직 수행하지 않음).

![OneDrive My files 화면. Meetings, Microsoft Copilot Chat Files, Recordings 폴더, 모두 0 items]({{ "/assets/images/2026/10/m03-4-onedrive.png" | relative_url }})
*그림 8. 관리자 OneDrive의 My files(GUI 경로: Microsoft 365 앱 시작 관리자 → OneDrive → My files, 10/24 새벽에 선명하게 다시 촬영, 폴더 3개 모두 0 items 그대로). 계정 이름 부분은 가렸다.*

## 7. 운영에서는 이렇게 판단한다

- **"이 파일이 어디 있나"에 대한 답이 채널 유형마다 다릅니다.** 표준 채널은 팀 사이트, 비공개·공유는 별도 사이트이므로, 보존·검색·외부 공유·백업 정책을 세울 때 **사이트 단위로 대상을 따로 잡아야** 합니다.
- 정리(삭제)할 때는 팀 사이트뿐 아니라 **채널 사이트가 따로 있다는 점**을 목록에 넣어 둡니다(삭제 시 채널 사이트가 어떻게 처리되는지는 이 실습에서 확인하지 않음 → 10/23에도 확인 불가, 사유: 팀을 삭제하지 않았음. 삭제 때 결과를 추가로 기록). 또 10/23 시험 파일(zz-test*.txt)이 팀 사이트에 남아 있어 정리 항목에 넣었음.
- 개발·자동화에서는 채널 유형 문자열보다 `filesFolder` 같은 실제 주소 API를 믿습니다.

## 8. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 표준 채널은 팀 사이트 공유(채널별 폴더), 비공개·공유 채널은 각각 별도 사이트 | [Teams connected sites](https://learn.microsoft.com/sharepoint/teams-connected-sites) |
| 문서 | 채널 유형과 개요 | [Teams 채널 개요](https://learn.microsoft.com/microsoftteams/teams-channels-overview), [표준 채널](https://learn.microsoft.com/microsoftteams/standard-channels) |
| 문서 | Team은 M365 그룹 + SharePoint + 사서함 | [Teams와 M365 그룹](https://learn.microsoft.com/microsoftteams/office-365-groups) |
| 문서 | 채널 메시지·채널 회의 채팅은 팀의 사서함, 일반 회의 채팅은 참석자 사서함, 녹화는 주최자 OneDrive | [Finding content in Microsoft Teams in eDiscovery](https://learn.microsoft.com/purview/edisc-search-teams#where-teams-content-is-stored) |
| 문서 | 회의 녹화 저장 위치(일반 회의=주최자 OneDrive, 채널 회의=팀 사이트 Recordings) | [Teams meeting recording and transcript storage and permissions](https://learn.microsoft.com/microsoftteams/tmr-meeting-recording-change#recording-storage) |
| 참고(커뮤니티 답변) | 채널 캘린더 항목은 팀에 연결된 Microsoft 365 그룹 캘린더에 있는 채널 회의 | [Microsoft Q&A 답변](https://learn.microsoft.com/answers/a/12452933) |
| 문서 | 채널 유형 값에 의존하지 말고 filesFolder 사용 | [공유·비공개 채널용 앱](https://learn.microsoft.com/microsoftteams/platform/build-apps-for-shared-private-channels) |
| 문서 | 채널 사이트는 활성 사이트의 "채널 사이트" 열 링크로 들어가 사이트별 공유 설정을 바꿈 | [Change sharing settings for a site](https://learn.microsoft.com/sharepoint/change-external-sharing-site) |
| 문서 | SharePoint 파일 협업 배포 | [File collaboration](https://learn.microsoft.com/sharepoint/deploy-file-collaboration) |
| 조회 | Team 7→8, 채널 4개와 유형 값, 폴더 주소 패턴, 업로드 응답, 파일 존재, 활성 사이트 | Teams·SharePoint 화면 + Graph |
| 확인 불가 | 403인데 파일이 생긴 원인(10/22 요청·응답 미보존) / 공유 채널의 관리 센터 집계 / 직접 업로드와 Graph 업로드의 차이(파일 선택창 사용 불가) | - |
| 조회(10/23 재시도) | 관리자 OneDrive가 열림. My files에 Meetings, Microsoft Copilot Chat Files, Recordings 폴더(모두 0개). 오전에 나던 "기본 문서 라이브러리를 찾을 수 없음" 오류는 이번엔 재현되지 않음(원인은 확인 불가, 프로비저닝 지연으로 추정) | OneDrive 웹 |
| 확인 불가 | 회의 녹화가 실제로 Recordings 폴더에 저장되는지, 1:1 채팅 파일의 OneDrive 위치 — 시도: 폴더 존재 확인. 사유: 녹화·파일 전송은 마이크·카메라와 두 번째 사용자가 필요한 조작이라 아직 수행하지 않음(시험 사용자와 함께 회의를 열면 가능) | - |

## 9. 정리·남은 일

- Practice-Team-01(채널 사이트 2개와 시험 파일 3개 포함)은 **삭제하지 않았습니다.** 실습을 마무리할 때 정리할 항목으로 남겼습니다(삭제 후 30일간 복구 가능).

> 오늘 입력한 PowerShell 원문은 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 화면 확인 값은 실제와 같습니다.
