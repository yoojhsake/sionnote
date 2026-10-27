---
title: "[M365·Azure] Teams 저장 구조 — 채널 유형별 파일·일정 위치 (전체 기록)"
date: 2026-10-22 09:40:00 +0900
categories: [m365]
phase: 구조 이해 실습
seq: 3
tags: [M365·Azure, Teams, SharePoint, OneDrive, 채널, 일정, 전체 기록]
excerpt: "표준·비공개·공유 채널의 파일, 팀·개인 일정, OneDrive 폴더가 실제로 어디에 저장되는지 확인한 전체 기록. 막힌 곳은 상황별 글로 정리"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·사유·다음 방법 병기). 테넌트 도메인은 주소에서 뺐고(`<테넌트>`로 표기) 사용자 이름은 적지 않았습니다.

## 요약

| 질문 | 결과 | 근거 |
|---|---|---|
| 표준 채널 파일은 어디에 저장되나 | 팀 사이트의 문서 라이브러리 안 채널 폴더 | 조회 |
| 비공개·공유 채널 파일은 | 각각 **별도 SharePoint 사이트**의 문서 라이브러리 | 조회 |
| 채널 유형 값(Graph) | 표준 `standard`, 비공개 `private`, 공유 `unknownFutureValue` | 조회 |
| 팀 일정은 어디에 저장되나 | 팀(그룹) 캘린더. 달력 소유자가 팀(그룹) 계정 | 조회 |
| 개인 일정은 | 사용자 개인 캘린더. 달력 소유자가 사용자 계정 | 조회 |
| 관리자 OneDrive의 녹화·채팅 파일 폴더 | My files에 Meetings, Microsoft Copilot Chat Files, Recordings 폴더 존재(모두 0개) | 조회 |
| 실제 녹화·1:1 채팅 파일이 그 폴더에 들어가는지 | 확인 불가(녹화·파일 전송 시험을 하지 않음) | - |

---

## 전체 기록

Team 생성부터 시험 업로드까지는 2026-10-22(목) 09:30~10:06에 수행했습니다. 이어서 일정 저장 위치와 OneDrive 폴더를 확인했습니다. 막힌 곳은 이 글에 모두 풀어 쓰지 않고, 상황별 글로 나눠 두었습니다(5절).

### 1. 목표

1. Team 하나를 만들면 무엇이 같이 만들어지는지(M365 그룹, SharePoint 사이트, 사서함) 확인한다.
2. 채널 유형(표준·비공개·공유)에 따라 **파일이 저장되는 SharePoint 위치가 어떻게 다른지** 실제 주소로 확인한다.
3. **팀 일정과 개인 일정이 저장되는 곳**을 시험 일정으로 나눠 본다.
4. 1:1 채팅 파일과 회의 녹화 파일의 저장 위치(OneDrive)를 확인한다.

### 2. 먼저 알아야 할 개념

![표준 채널은 팀 사이트 폴더, 비공개·공유 채널은 별도 사이트에 파일이 저장되고, 시험 업로드 결과가 표시됨]({{ "/assets/images/2026/10/d3-channel-storage.png" | relative_url }})
*그림 1. 채널 유형별 파일 위치와 시험 업로드 결과*

| 개념 | 쉬운 설명 |
|---|---|
| Team | Microsoft 365 그룹 + SharePoint 팀 사이트 + 그룹 사서함(일정)이 묶인 것 |
| 표준 채널 | 팀 사이트를 같이 씀. 채널마다 문서 라이브러리 안에 폴더가 하나 생김 |
| 비공개 채널 | 구성원이 제한된 채널. **별도의 SharePoint 사이트**가 생김 |
| 공유 채널 | 다른 팀·조직과 공유할 수 있는 채널. **별도의 SharePoint 사이트**가 생김 |
| 1:1·그룹 채팅 파일 | 보낸 사람의 OneDrive에 저장(문서 기준) |
| 회의 녹화 | 일반 회의: 주최자의 OneDrive > Recordings 폴더 / 채널 회의: 팀 SharePoint 사이트 > Documents > Recordings 폴더(문서: Teams 회의 녹화 저장 문서) |
| **Team 일정**(채널 일정·채널 회의) | **그룹 사서함**(Microsoft 365 그룹 캘린더)에 저장. 팀을 만들 때 같이 생긴 사서함입니다(문서·Q&A 기준) |
| **개인 회의 일정**(Teams·Outlook에서 만든 일반 회의) | **사용자 사서함**에 저장. 주최자 사서함에 원본이, 참석자 각자의 사서함에 복사본이 생깁니다(문서 기준) |
| 회의 채팅 | 일반 회의는 참석자 각자의 사서함, 채널 회의는 팀의 그룹 사서함(문서: Purview eDiscovery의 Teams 콘텐츠 저장 위치 표) |

### 3. 절차

#### 3-1. Team 만들기 (09:30)

1. teams.microsoft.com > 팀 > 팀 만들기 > 처음부터 > **비공개**
2. 이름 **Practice-Team-01**, 만들기 (소유자: 관리자 계정, 구성원 추가는 건너뜀)

#### 3-2. 채널 3종 만들기 (09:31)

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

결과는 아래와 같습니다(조회). 공유 채널의 값이 `unknownFutureValue`로 나오는 이유는 [공유 채널이 unknownFutureValue로 보일 때]({{ "/m365/troubleshooting/shared-channel-unknownfuturevalue/" | relative_url }})에 정리했습니다.

| 채널 | Graph `membershipType` |
|---|---|
| General | standard |
| ch-standard | standard |
| ch-private | private |
| ch-shared | **unknownFutureValue** (공유 채널) |

#### 3-3. 파일 폴더 주소 조회와 시험 업로드 (10:06)

브라우저의 파일 선택 창을 쓸 수 없어서 Cloud Shell에서 Graph로 대신했습니다([브라우저 파일 선택창을 쓸 수 없을 때]({{ "/m365/troubleshooting/browser-file-picker-unavailable/" | relative_url }})). 각 채널의 `filesFolder`를 조회해 폴더 주소를 얻고, 시험 파일(`D3-test-<채널명>.txt`)을 올려 본 뒤, **SharePoint 화면**에서 파일이 실제로 어디 있는지 확인했습니다.

**채널별 파일 폴더 주소 패턴**(조회)

| 채널 | 폴더 주소 패턴 | 설명 |
|---|---|---|
| General | `https://<테넌트>.sharepoint.com/sites/Practice-Team-01/Shared Documents/General` | 팀 사이트 안 폴더 |
| ch-standard | `…/sites/Practice-Team-01/Shared Documents/ch-standard` | 팀 사이트 안 폴더 |
| ch-private | `…/sites/Practice-Team-01-ch-private/Shared Documents` | **별도 사이트** |
| ch-shared | `…/sites/Practice-Team-01-ch-shared/Shared Documents` | **별도 사이트** |

**시험 업로드 응답과 SharePoint 화면 결과**(조회)

| 채널 | Graph 응답 | SharePoint 화면에서 파일 |
|---|---|---|
| ch-standard | **201 성공** | 있음(팀 사이트의 ch-standard 폴더) |
| ch-private | **403** | **있음**(별도 사이트) |
| ch-shared | **403** | **있음**(별도 사이트) |

![세 채널의 SharePoint 문서 라이브러리. 표준은 팀 사이트 안 폴더, 비공개와 공유는 별도 사이트의 루트]({{ "/assets/images/2026/10/d3-sharepoint-files.png" | relative_url }})
*그림 2. 채널별 SharePoint 문서 화면(GUI: 각 주소를 브라우저에서 열어 캡처). 위: 팀 사이트 Practice-Team-01의 `Documents > ch-standard` 폴더(파일 4개: D3-test-ch-standard.txt와 채널 업로드 시험 중 생긴 시험 파일 3개). 가운데: 별도 사이트 Practice-Team-01-ch-private의 문서(D3-test-ch-private.txt). 아래: 별도 사이트 Practice-Team-01-ch-shared의 문서(D3-test-ch-shared.txt). 사용자 이름은 가렸다.*

비공개·공유 채널은 응답이 403인데도 파일이 만들어져 있었습니다. 코드와 저장 위치를 둘 다 봐야 하는 이유는 [응답은 403인데 파일이 만들어졌을 때]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }})에, 같은 방식으로 다시 올렸을 때 403이 나는 원인(멤버십이 아니라 토큰 범위)은 [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})에 적었습니다.

#### 3-4. 일정 저장 위치 시험

"Team 일정은 그룹 사서함, 개인 회의 일정은 사용자 사서함"이라는 설명을 이 테넌트에서 실제로 나눠 보았습니다. 시험 일정 2개를 만들어 어느 달력에 보이는지 봤습니다.

| 일정 종류 | 만든 방법 | 보인 곳 | 보이지 않은 곳 |
|---|---|---|---|
| 팀 일정 `zz-test-team-event-r2` (10/28 11:00 KST) | Cloud Shell에서 Graph로 팀(그룹) 캘린더에 생성(HTTP 201) | 팀(그룹) 캘린더 목록(조회) | 관리자의 개인 Outlook 캘린더(조회) |
| 개인 일정 `zz-test-personal-event` (10/28 10:00) | Outlook 웹에서 새 이벤트 저장 | 관리자의 개인 Outlook 캘린더 10/28 10:00(조회) | 팀(그룹) 캘린더 목록(조회) |

같은 시험을 처음에는 `zz-test-team-event`(10/27 10:00)로 했고, 확인한 뒤 삭제했습니다. 그때도 관리자의 개인 캘린더 10/27 10:00 칸은 비어 있었습니다. 그림은 이름만 바꿔(`-r2`) 다시 실행해 화면을 선명하게 남긴 것입니다.

**① 팀 일정 만들기 (Graph)**

팀의 id가 곧 그룹 id라 `$tid`를 그대로 씁니다. 준비 코드는 Cloud Shell(PowerShell)의 Azure 로그인 세션으로 Graph 토큰을 받아 쓰는 것입니다(조회·시험용).

```powershell
# 공통 준비 코드: 토큰, 헤더, 주소, 팀 id, 채널 목록
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
$tid = (Invoke-RestMethod -Headers $h -Uri "$B/me/joinedTeams").value | Where-Object displayName -eq 'Practice-Team-01' | Select-Object -ExpandProperty id
$ch  = (Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/allChannels").value
```

```powershell
$ev = @{ subject = 'zz-test-team-event-r2'; start = @{ dateTime = '2026-10-28T11:00:00'; timeZone = 'Korea Standard Time' }; end = @{ dateTime = '2026-10-28T11:30:00'; timeZone = 'Korea Standard Time' } } | ConvertTo-Json -Depth 3
$null = Invoke-RestMethod -Method Post -Headers $h -Uri "$B/groups/$tid/events" -ContentType 'application/json' -Body $ev -StatusCodeVariable sc; "1) create group event: HTTP $sc"
(Invoke-RestMethod -Headers $h -Uri "$B/groups/$tid/events?`$select=subject,start").value | ForEach-Object { "2) group calendar: $($_.subject)  $($_.start.dateTime)" }
try { Invoke-RestMethod -Headers $h -Uri "$B/me/events?`$top=1" | Out-Null; '3) personal calendar: OK' } catch { "3) personal calendar: HTTP $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase))" }
```

![팀 캘린더에 일정 생성]({{ "/assets/images/2026/10/m03-1-team-event-created.png" | relative_url }})
*그림 3. Cloud Shell 출력(위쪽 줄은 실행한 명령). 1) 팀(그룹) 캘린더에 일정 zz-test-team-event-r2(10/28 11:00 KST) 생성 HTTP 201, 2) 그룹 캘린더 목록에 그 일정이 보임(시작 시각은 UTC 표기라 02:00:00), 3) 내 개인 캘린더(`/me/events`)를 같은 토큰으로 읽으면 403(토큰에 Calendars 범위가 없음). 계정 부분은 가렸다.*

세 번째 줄의 403은 개인 달력을 같은 토큰으로 읽지 못한다는 뜻입니다. 이 403은 ⑤에서 범위를 동의해 풀었고, 과정은 [개인 달력이 403일 때]({{ "/m365/troubleshooting/personal-calendar-403-calendars-read/" | relative_url }})에 정리했습니다.

**② 개인 일정 만들기 (GUI)**

Outlook 웹 → 캘린더 → 새 이벤트 → 제목 `zz-test-personal-event`, 날짜 2026-10-28, 시작 오전 10:00(끝 10:30) → 저장 → 주 보기에서 확인.

![개인 일정 만들기]({{ "/assets/images/2026/10/m03-3a-personal-event-create.png" | relative_url }})
*그림 4. Outlook 웹에서 개인 일정을 만드는 화면. 제목 zz-test-personal-event, 2026-10-28 오전 10:00~10:30을 넣고 저장 직전.*

이 개인 일정은 한 번 화면에서 보이지 않게 되어 같은 이름·같은 시각으로 다시 만든 것입니다. 경위는 [만들어 둔 개인 일정이 사라졌을 때]({{ "/m365/troubleshooting/personal-event-disappeared/" | relative_url }})에 있습니다.

**③ 팀(그룹) 캘린더에 개인 일정이 들어갔는지 확인 (Graph)**

```powershell
$ev = (Invoke-RestMethod -Headers $h -Uri "$B/groups/$tid/events?`$select=subject,start").value
$ev | Format-Table subject, @{ n = 'start (UTC)'; e = { $_.start.dateTime } } -AutoSize
'zz-test-personal-event in group calendar: ' + [bool]($ev | Where-Object subject -eq 'zz-test-personal-event')
```

![팀 캘린더 목록]({{ "/assets/images/2026/10/m03-2-team-calendar-list.png" | relative_url }})
*그림 5. 개인 일정(zz-test-personal-event)을 Outlook에서 만든 뒤 다시 읽은 팀(그룹) 캘린더 목록. zz-test-team-event-r2 한 건만 있고, 아래 줄에서 개인 일정이 이 목록에 있는지 검사한 결과가 False이다. 계정 부분은 가렸다.*

**④ 개인 캘린더 화면 확인 (GUI)**

![개인 Outlook 캘린더]({{ "/assets/images/2026/10/m03-3-personal-calendar.png" | relative_url }})
*그림 6. Outlook 웹의 관리자 개인 캘린더(10/25~10/31주). 10/28(수) 10:00에 개인 일정 zz-test-personal-event만 있고, 팀 일정을 넣었던 10/27(화) 10:00 칸은 비어 있다. 팀(그룹) 캘린더에 넣은 일정이 개인 캘린더에 보이지 않는다는 점은 이 화면과 그림 3·5로 함께 확인한다.*

**⑤ 달력 소유자 확인 (Graph 탐색기)**

Graph 탐색기(Graph Explorer)에서 캘린더 읽기 범위(Calendars.Read)를 직접 동의한 뒤 `GET /me/calendar`를 실행했더니 **200 OK**였고, 달력 이름은 Calendar, **소유자(owner)가 관리자 사용자 계정**으로 나왔습니다(조회). 같은 방식으로 읽은 팀 달력(`GET /groups/{id}/calendar`)은 소유자가 팀(그룹) 계정이었습니다(조회).

![내 달력 조회 결과 200, 소유자는 사용자 계정]({{ "/assets/images/2026/10/m22-1-me-calendar-owner-200.png" | relative_url }})
*그림 7. 캘린더 읽기 범위 동의 후 `GET /me/calendar` 응답(200 OK). name은 Calendar이고 owner가 사용자 계정이다. 사용자 이름·주소와 식별자는 가렸다.*

**해석**

- 팀 일정은 팀(그룹) 캘린더에만, 개인 일정은 개인 캘린더에만 들어갔습니다. 달력 소유자 기준으로 **팀 일정은 그룹 사서함, 개인 일정은 사용자 사서함의 달력**에 저장됩니다.
- 개인 회의 일정이 이 개인 달력에 쌓인다는 점은 문서 기준입니다.

#### 3-5. OneDrive 위치 확인

회의 녹화(일반 회의)와 1:1 채팅 파일이 저장되는 곳으로 문서가 설명하는 관리자 OneDrive를 열어 폴더를 확인했습니다. 처음에는 "기본 문서 라이브러리를 찾을 수 없음" 오류로 열리지 않았고, 시간을 두고 다시 열자 정상으로 열렸습니다([관리자 OneDrive가 열리지 않을 때]({{ "/m365/troubleshooting/onedrive-default-library-not-found/" | relative_url }})).

GUI 경로: Microsoft 365 앱 시작 관리자 → OneDrive → My files.

![OneDrive My files 화면. Meetings, Microsoft Copilot Chat Files, Recordings 폴더, 모두 0 items]({{ "/assets/images/2026/10/m03-4-onedrive.png" | relative_url }})
*그림 8. 관리자 OneDrive의 My files. Meetings, Microsoft Copilot Chat Files, Recordings 폴더 3개가 모두 0 items이다. 계정 이름 부분은 가렸다.*

- **조회**: My files에 **Meetings, Microsoft Copilot Chat Files, Recordings** 폴더가 있고 모두 0개입니다.
- 문서가 설명하는 "개인 회의 녹화는 진행자의 OneDrive에 저장"되는 대상 폴더는 있는 것입니다.
- **확인 불가**: 실제 녹화와 1:1 채팅 파일이 그 폴더에 들어가는지. 시도: OneDrive 폴더 존재 확인. 사유: 녹화·파일 전송은 마이크·카메라와 두 번째 사용자가 필요한 조작이라 수행하지 않았습니다. 다음 방법: 시험 사용자와 함께 회의를 열어 녹화하고 파일을 보냄.

### 4. 전·후 비교와 실제 값

![Teams 관리 센터 Manage teams 화면. 8 teams, Practice-Team 행이 표준 채널 2, 비공개 채널 1, 공유 채널 1]({{ "/assets/images/2026/10/d3-manage-teams.png" | relative_url }})
*그림 9. Teams 관리 센터 팀 목록(빨간 상자: Practice-Team-01, 일부 팀 이름은 가림). 표준 채널 2, 비공개 채널 1, 공유 채널 1이 각각 다른 열에 표시된다.*

| 항목 | 만들기 전 | 만든 후 |
|---|---|---|
| Team 수 | **7** | **8** |
| Practice-Team-01 채널 | - | General, ch-standard, ch-private, ch-shared (Graph 4개) |
| 관리 센터 열 값 | - | 표준 채널 2, 비공개 채널 1, 공유 채널 1 (합계 4, Graph 4개와 일치) |
| 채널 사이트 | - | 2개(비공개·공유 채널 각 1) |
| 시험 일정 | - | 팀(그룹) 캘린더 `zz-test-team-event-r2`, 개인 캘린더 `zz-test-personal-event` |

관리 센터 숫자와 Graph 채널 수를 맞춰 보는 방법은 [관리 센터 숫자·사이트 목록과 Graph 채널 수가 다를 때]({{ "/m365/troubleshooting/channel-count-mismatch/" | relative_url }})에 있습니다.

![SharePoint 관리 센터 활성 사이트 목록. Practice-Team-01 한 행, 채널 사이트 2개로 표시]({{ "/assets/images/2026/10/d3-active-sites.png" | relative_url }})
*그림 10. 활성 사이트 목록 (빨간 상자: Practice-Team-01 행)*

- 활성 사이트에는 **Practice-Team-01 한 행만** 보이고, 채널 사이트는 별도 행이 아니라 "채널 사이트" 열의 "사이트 2개"라는 링크로 묶여 보였습니다.

**변경 이력**

| 항목 | 내용 |
|---|---|
| 언제 | Team·채널·시험 파일: 2026-10-22 09:30 ~ 10:06 / 이어서 채널 업로드 시험, 시험 일정 생성, 읽기 범위 동의 |
| 무엇을 | Team 1개 + 채널 3개 생성, 시험 파일 업로드, 시험 일정 2개 생성, Graph 탐색기에서 읽기 범위(Calendars.Read 등) 동의 |
| 전 → 후 | Team 7→8, 채널 사이트 2개 생성, 시험 파일 3개(D3-test-*.txt) 생성, 팀 일정 1건·개인 일정 1건 |
| 왜 | 채널 유형별 파일 저장 위치와 일정 저장 위치를 실제 값으로 확인 |
| 근거 | Teams·SharePoint·Outlook 화면, Graph 조회, 문서 아래 URL |
| 검증 결과 | 사이트·폴더 주소 4개, 업로드 응답 201/403/403, 파일 존재 3개, 일정 위치 2곳 구분 |
| 정리 대상 | 표준 채널 폴더와 General에 생긴 zz-test*.txt, 팀 문서함 루트의 zz-x.txt, 팀 문서함의 ch-private·ch-shared 폴더(채널 폴더 경로를 잘못 지정한 시험으로 생김), 팀 캘린더의 zz-test-team-event-r2 |
| 원복 방법 | Team 삭제(삭제하면 30일간 복구 가능). **삭제는 하지 않았고** 정리 항목으로 남김. 동의한 읽기 범위는 Entra 관리 센터의 엔터프라이즈 애플리케이션에서 철회할 수 있음 |

### 5. 작업 중 막힌 곳

| 상황 | 한 줄 대처 | 글 |
|---|---|---|
| 응답은 403인데 파일이 만들어짐 | 코드와 실제 저장 위치를 둘 다 확인. 원인은 확인 불가 | [응답은 403인데 파일이 만들어졌을 때]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }}) |
| 비공개·공유 채널 파일이 403 | 구성원·화면을 확인해 멤버십을 배제, 토큰의 읽기 범위를 추가 | [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) |
| 채널 경로로 올리면 400 | `filesFolder`에서 driveId·itemId를 읽어 그 경로로 올림 | [채널 경로 업로드 400]({{ "/m365/troubleshooting/channel-upload-400-filesfolder/" | relative_url }}) |
| 공유 채널이 `unknownFutureValue`로 보임 | 유형 문자열 대신 `filesFolder`로 실제 주소를 얻음 | [공유 채널이 unknownFutureValue로 보일 때]({{ "/m365/troubleshooting/shared-channel-unknownfuturevalue/" | relative_url }}) |
| 관리 센터 숫자·사이트 목록과 Graph 채널 수가 다름 | 열별로 더해 맞추고, 채널 사이트는 "채널 사이트" 열 링크로 들어감 | [관리 센터 숫자·사이트 목록과 Graph 채널 수가 다를 때]({{ "/m365/troubleshooting/channel-count-mismatch/" | relative_url }}) |
| 브라우저 파일 선택창을 쓸 수 없음 | Cloud Shell의 Graph 호출로 대체 | [브라우저 파일 선택창을 쓸 수 없을 때]({{ "/m365/troubleshooting/browser-file-picker-unavailable/" | relative_url }}) |
| 개인 달력이 403 | Calendars.Read를 동의한 뒤 다시 조회 | [개인 달력이 403일 때]({{ "/m365/troubleshooting/personal-calendar-403-calendars-read/" | relative_url }}) |
| 만들어 둔 개인 일정이 사라짐 | 같은 이름·시각으로 GUI에서 다시 만들고 경위를 기록 | [만들어 둔 개인 일정이 사라졌을 때]({{ "/m365/troubleshooting/personal-event-disappeared/" | relative_url }}) |
| 관리자 OneDrive가 "기본 문서 라이브러리를 찾을 수 없음" | 시간을 두고 다시 열어 확인 | [관리자 OneDrive가 열리지 않을 때]({{ "/m365/troubleshooting/onedrive-default-library-not-found/" | relative_url }}) |

### 6. 검증

| 검증 | 결과 |
|---|---|
| Teams 목록·Graph Team 수 | 8 |
| Graph 채널 수 | 4 (standard 2, private 1, unknownFutureValue 1) |
| 관리 센터 채널 열 합계 | 표준 2 + 비공개 1 + 공유 1 = 4 (Graph와 일치) |
| 폴더 주소 4개를 SharePoint 화면과 대조 | 일치 |
| 시험 파일 존재 | 3개 모두 SharePoint 화면에서 확인 |
| 활성 사이트 목록 | 팀 사이트 1행 + 채널 사이트 2개 표시 |
| 팀 일정 | 팀(그룹) 캘린더 목록에 있고 개인 캘린더에는 없음 |
| 개인 일정 | 개인 캘린더에 있고 팀(그룹) 캘린더 목록에는 없음(검사 결과 False) |
| 달력 소유자 | 개인 달력은 사용자 계정, 팀 달력은 팀(그룹) 계정 |
| 관리자 OneDrive | My files에 Meetings, Microsoft Copilot Chat Files, Recordings 폴더(모두 0개) |

### 7. 운영에서는 이렇게 판단한다

- **"이 파일이 어디 있나"에 대한 답이 채널 유형마다 다릅니다.** 표준 채널은 팀 사이트, 비공개·공유는 별도 사이트이므로, 보존·검색·외부 공유·백업 정책을 세울 때 **사이트 단위로 대상을 따로 잡아야** 합니다.
- **일정은 달력 소유자로 저장 위치를 구분합니다.** 팀 일정은 그룹 사서함, 개인 일정은 사용자 사서함의 달력입니다. 채널 회의의 채팅은 팀의 그룹 사서함, 일반 회의의 채팅은 참석자 사서함에 있어(문서 기준) 보존·검색 대상 사서함이 달라집니다.
- 정리(삭제)할 때는 팀 사이트뿐 아니라 **채널 사이트가 따로 있다는 점**을 목록에 넣어 둡니다. 삭제 때 채널 사이트가 어떻게 처리되는지는 **확인 불가**입니다(시도: 없음. 사유: 팀을 삭제하지 않았음. 다음 방법: 삭제할 때 결과를 기록). 시험 파일(zz-test*.txt)이 팀 사이트에 남아 있어 정리 항목에 넣었습니다.
- 개발·자동화에서는 채널 유형 문자열보다 `filesFolder` 같은 실제 주소 API를 믿습니다.
- 업로드 성공 여부는 응답 코드만으로 판단하지 않고, 코드와 실제 저장 위치를 둘 다 확인합니다.

### 8. 근거 자료

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
| 조회 | Team 7→8, 채널 4개와 유형 값, 관리 센터 채널 열 값, 폴더 주소 패턴, 업로드 응답, 파일 존재, 활성 사이트 | Teams·SharePoint 화면 + Graph |
| 조회 | 팀 일정은 팀(그룹) 캘린더에만, 개인 일정은 개인 캘린더에만 있음. `GET /me/calendar` 200, 소유자는 사용자 계정 | Cloud Shell(Graph), Outlook 웹, Graph 탐색기 |
| 조회 | 관리자 OneDrive My files에 Meetings, Microsoft Copilot Chat Files, Recordings 폴더(모두 0개) | OneDrive 웹 |
| 확인 불가 | 403인데 파일이 생긴 원인 — 시도: 같은 방식으로 다시 시험(새 파일은 생기지 않음). 사유: 처음 요청·응답을 저장하지 않아 대조할 수 없음. 다음 방법: 재현할 때 요청·응답 전체를 저장 | - |
| 확인 불가 | 직접 업로드와 Graph 업로드의 차이 — 시도: 없음. 사유: 브라우저 파일 선택창을 쓸 수 없어 직접 업로드를 시도하지 못함. 다음 방법: 파일 선택창을 쓸 수 있는 환경에서 Teams로 직접 올려 비교 | - |
| 확인 불가 | 회의 녹화가 Recordings 폴더에 저장되는지, 1:1 채팅 파일의 OneDrive 위치 — 시도: 폴더 존재 확인. 사유: 마이크·카메라와 두 번째 사용자가 필요. 다음 방법: 시험 사용자와 회의를 열어 녹화 | - |

### 9. 정리·남은 일

- Practice-Team-01(채널 사이트 2개와 시험 파일 포함)은 **삭제하지 않았습니다.** 실습을 마무리할 때 정리할 항목으로 남겼습니다(삭제 후 30일간 복구 가능).

> 작업 당시 입력한 PowerShell 원문은 일부 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 화면 확인 값은 실제와 같습니다.
