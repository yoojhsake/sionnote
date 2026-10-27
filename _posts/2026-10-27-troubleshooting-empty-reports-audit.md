---
title: "[M365·Azure] 16 트러블슈팅 — 보고서가 비어 있고 감사 기록이 안 켜질 때 (사용 현황 '데이터 없음', UnknownTenantId, 감사 로그 켜기 실패, 요약 + 전체 기록)"
date: 2026-10-27 10:20:00 +0900
categories: [m365, troubleshooting]
tags: [트러블슈팅, 사용 현황 보고서, UnknownTenantId, 감사 로그, Purview, Exchange Online PowerShell, 전체 기록]
excerpt: "활동 보고서가 '데이터 없음'이고 감사 로그를 켜는 명령이 거부될 때, 권한 문제와 데이터·서비스 상태 문제를 어떻게 나눠 보고 어디까지 확인했는지 정리한 기록"
toc: true
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell·Graph에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 테넌트·요청 ID, 계정은 게시하지 않았고 캡처에서는 가렸다.

## 요약

두 가지 상황을 다룹니다. 둘 다 **"권한이 없어서"가 아니라 "데이터가 없거나 서비스 쪽 상태가 달라서"** 막힌 경우였고, 그래서 권한을 더 올리는 방향으로 가지 않았습니다.

| # | 상황 | 먼저 나눈 것 | 한 일 | 결과 |
|---|---|---|---|---|
| A | 사용 현황 보고서 화면이 "데이터 없음", Graph 보고서는 404 `UnknownTenantId` | 권한 오류(403)인가, 데이터 부재(404)인가 | 화면·Graph를 시각을 달리해 3회 확인, 활동을 만든 뒤 재확인 | **조회**: 10/26~10/27 동안 계속 비어 있음. 원인은 확인 불가 |
| B | 감사 로그가 꺼져 있고(`False`) 켜는 명령이 서버 오류로 거부 | 내 권한 부족인가, 조직 상태 문제인가 | 같은 명령을 세션을 다시 연결해 가며 4회, 관련 상태값 조회 | **조회**: 켜지지 않음. 원인은 확인 불가, 다음 방법만 정리 |

---

## 전체 기록

### A. 활동 보고서가 비어 있을 때

#### A-1. 증상

- Microsoft 365 관리 센터 > 보고서 > 사용 현황 화면에 **"There is no data for this report."**가 나왔습니다(조회, 10/26 23:39). 화면 설명에는 "모든 보고 기간에 대한 데이터가 즉시 존재하지 않으며, 보고서는 48시간 이내에 사용할 수 있다"고 적혀 있습니다.
- 같은 내용을 Graph로 읽으면 `GET /reports/getTeamsTeamActivityDetail(period='D7')`가 **HTTP 404**와 함께 `UnknownTenantId`("이 테넌트 ID를 인식하지 못한다")를 돌려줬습니다(조회).

![사용 현황 보고서가 데이터 없음으로 표시된 화면]({{ "/assets/images/2026/10/m23-2-usage-report-no-data.png" | relative_url }})
*그림 1. 관리 센터 사용 현황 화면. 모든 보고서 탭에서 "There is no data for this report."가 나온다. 테넌트 표시는 가렸다.*

![Graph 보고서 호출이 UnknownTenantId 404로 응답]({{ "/assets/images/2026/10/m23-1-teams-report-unknowntenantid.png" | relative_url }})
*그림 2. `getTeamsTeamActivityDetail(period='D7')` 호출 결과. 404이며 오류 코드는 UnknownTenantId다. 응답 속 테넌트 ID와 요청 ID는 가렸다.*

#### A-2. 먼저 나눠 본 것: 403인가 404인가

| 응답 | 의미 | 이번 경우 |
|---|---|---|
| 403 Forbidden / accessDenied | 토큰 범위나 역할이 부족. 동의·역할을 확인할 대상 | 아님 |
| 404 `UnknownTenantId` | 요청은 받아들여졌지만 **보고서 서비스가 이 테넌트의 데이터를 갖고 있지 않음** | 해당 |

보고서 읽기 권한(Reports.Read.All)을 따로 동의하지 않은 상태였는데도 응답이 **권한 오류가 아니라 UnknownTenantId**였습니다(조회). 그래서 권한 동의를 늘려 다시 시도하는 쪽이 아니라 "데이터가 쌓이기를 기다리고 같은 방식으로 다시 확인하는" 쪽으로 정했습니다. 다만 "권한이 충분해서 이 응답이 나온 것"이라고는 말할 수 없고, 권한을 추가했을 때 결과가 달라지는지는 **확인하지 않았습니다**.

#### A-3. 한 일과 결과

1. **활동 만들기**: 보고서에 집계될 활동이 있어야 하므로 표준 채널에 시험 메시지 2건을 남겼습니다(10/26 19시대). 새 테넌트는 사용 이력이 거의 없어 보고서가 비어 있을 수 있기 때문입니다.
2. **시각을 달리해 재확인**: 같은 Graph 호출을 10/27 10:29와 19:17(KST)에 다시 실행했습니다. 두 번 모두 같은 404 `UnknownTenantId`였습니다(조회). Teams 관리 센터의 팀 사용 현황 보고서도 "데이터를 불러올 수 없음"이었습니다(조회).
3. **판단**: 메시지를 남긴 지 하루가 채 지나지 않은 시점의 결과라서, **"활동이 없어서 비어 있다"와 "이 테넌트가 보고서 서비스에 아직 등록되지 않았다"를 구분하지 못했습니다.** 오류 문구는 후자에 가깝지만, 이 문구가 곧 원인이라고 단정하지 않습니다.

#### A-4. 다음 방법

- 활동을 만든 뒤 **48시간 이상 지난 시점에** 같은 두 곳(관리 센터 화면, Graph)에서 다시 확인합니다. 여기서 값이 나오면 "집계 지연"이었던 것이고, 계속 같은 오류면 Microsoft 지원 요청 대상입니다.
- 보고서 값이 꼭 필요한 항목은 이 보고서에 기대지 않고, 같은 정보를 다른 경로(Teams 관리 센터 정책 화면, Entra 로그인 로그 등)로 읽을 수 있는지 먼저 봅니다.
- 보고서가 비어 있는 동안에는 해당 항목을 **"확인 불가"로 두고 시도한 방법·사유·다음 방법을 함께 적습니다.** 0건으로 적으면 "활동이 없었다"는 사실처럼 읽히기 때문입니다.

---

### B. 감사 로그를 켜는 명령이 거부될 때

#### B-1. 증상

- Microsoft Purview 포털 > 감사 > 검색 화면에 "활동을 기록 중인지 파악하는 데 문제가 있습니다"라는 안내와 **"사용자 및 관리자 활동 기록 시작"** 버튼이 표시됩니다(조회).
- Exchange Online PowerShell로 상태를 읽으면 `UnifiedAuditLogIngestionEnabled`가 **False**입니다(조회). 즉 통합 감사 로그 수집이 꺼져 있습니다.

![Purview 감사 검색 화면의 기록 시작 버튼과 상태 확인 오류]({{ "/assets/images/2026/10/m23-3-purview-audit-not-recording.png" | relative_url }})
*그림 3. 감사 검색 화면. 상단에 상태 확인 오류 안내와 "사용자 및 관리자 활동 기록 시작" 버튼이 보이고, 아래 검색 목록은 불러오지 못한다.*

#### B-2. 확인과 시도 순서

실행 환경은 **내 PC의 Windows PowerShell**(Exchange Online PowerShell 모듈, 브라우저 로그인)입니다. Cloud Shell에서는 장치 코드 로그인이 막혀 쓰지 못했습니다([05 AADSTS530035]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})).

- **GUI 경로**: Microsoft Purview 포털 > 감사 > 검색 > "사용자 및 관리자 활동 기록 시작"
- **PowerShell(전체)**

```powershell
# 1) 연결 — 브라우저 대화형 로그인
Connect-ExchangeOnline

# 2) 현재 상태 읽기(변경 없음)
Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled

# 3) 켜기(조직 설정을 바꾸는 작업이라 실행 전에 의도를 확인)
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

# 4) 3)이 거부될 때 확인한 것
Get-OrganizationConfig | Format-List IsDehydrated
Enable-OrganizationCustomization
```

| 시각(10/26) | 한 일 | 결과(조회) |
|---|---|---|
| 22:31 | 상태 읽기 | `UnifiedAuditLogIngestionEnabled : False` |
| 22:33 | 켜기 | **BadRequest, `InvalidOperationInDehydratedContextException`**. "이 명령을 실행하려면 먼저 Enable-OrganizationCustomization 명령을 실행해야 합니다." |
| 22:33 | `Enable-OrganizationCustomization` | "이 작업은 필수가 아닙니다. 조직이 사용자 지정을 위해 이미 활성화되었습니다." |
| 22:35 | 켜기 재시도 | 같은 오류 |
| 22:37 | **세션을 다시 연결** 후 `IsDehydrated` 읽기, 켜기 재시도 | `IsDehydrated : False`, 켜기는 같은 오류 |
| 23:00 | Purview 화면 다시 열기 | 기록 시작 버튼과 상태 확인 오류 안내가 그대로 |
| 23:02 | 켜기 재시도 | 같은 오류, 상태는 계속 False |

#### B-3. 왜 이게 "권한 문제가 아닌지" 나눠 본 이유

- 오류 문구가 **"먼저 Enable-OrganizationCustomization을 실행하라"**고 안내했는데, 그 명령은 **"이미 활성화되어 있어 필요 없다"**고 응답했습니다. 두 응답이 서로 모순됩니다(조회).
- `IsDehydrated`도 False였습니다. 이 값이 True인 조직에서 사용자 지정이 필요하다는 설명과 맞지 않습니다(문서: [Enable-OrganizationCustomization](https://learn.microsoft.com/powershell/module/exchange/enable-organizationcustomization)).
- 권한 부족이라면 보통 권한 오류(Access denied 계열)가 납니다. 이번 오류는 **조직 상태에 대한 오류**였고, 세션을 새로 연결해도 같았습니다.
- 그래서 **역할을 더 올리거나 보안 설정을 바꾸는 방향으로 가지 않았습니다.** 원인은 확인 불가이고, "서버 쪽 상태가 아직 반영되지 않았을 가능성"은 **추정**일 뿐입니다.

#### B-4. 반복하지 않은 이유와 다음 방법

- 약 30분 사이에 4회 시도한 뒤 멈췄습니다. 같은 오류가 같은 문구로 계속될 때는 **반복해도 새 정보가 없고**, 요청만 쌓이기 때문입니다.
- 다음 방법
  1. 서버 상태가 반영될 시간을 두고 같은 명령을 다시 실행합니다(문서에는 감사 활성화 직후 반영까지 최대 60분이라는 설명이 있습니다).
  2. 계속 같은 오류면 Microsoft 365 관리 센터에서 **지원 요청**을 올립니다. 이때 오류 코드와 시각, 요청 ID를 함께 보냅니다(이 글에는 요청 ID를 싣지 않았습니다).
  3. 감사 로그가 꺼져 있는 동안의 **대체 근거**로는 Entra 감사 로그(`/auditLogs/directoryAudits`)를 씁니다. 이번에도 Graph로 계속 읽혔습니다(조회). 단, Entra 감사 로그는 디렉터리 변경 기록이고 Exchange·SharePoint 활동까지 포함하는 통합 감사 로그를 대신하지는 못합니다.
- 감사 로그가 꺼진 상태에서 조회 명령(`Search-UnifiedAuditLog`)이 **BadRequest 경고 후 0건**으로 끝난 것은 사용자 PC에서도 재현됐습니다(조회). 이 경고의 원인이 감사 꺼짐이라는 것은 **추정**이며, 켠 뒤 같은 명령을 다시 실행해 봐야 확인됩니다(확인 불가).

---

## 정리: 비어 있거나 안 켜질 때의 판단 순서

1. **응답 코드를 먼저 읽습니다.** 403이면 범위·역할, 404나 서비스 상태 오류면 데이터·조직 상태 쪽입니다.
2. **화면과 명령을 같이 봅니다.** 화면도 비어 있고 Graph도 비어 있으면 권한 문제일 가능성이 낮습니다.
3. **시각을 달리해 다시 봅니다.** 같은 요청을 몇 시간 뒤, 하루 뒤에 반복해 "지연"인지 "고정된 상태"인지 나눕니다.
4. **모순되는 응답은 모순대로 적습니다.** 안내 문구와 명령 응답이 어긋나면 하나를 원인으로 고르지 않습니다.
5. **같은 오류를 반복하지 않고** 기록 → 다음 방법(대기 후 재시도, 지원 요청, 대체 근거) 순으로 넘어갑니다.

## 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 감사 활성화·비활성화(PowerShell) | [감사 활성화·비활성화](https://learn.microsoft.com/purview/audit-log-enable-disable) |
| 문서 | 감사 시작하기 | [감사 시작하기](https://learn.microsoft.com/purview/audit-get-started) |
| 문서 | 사용자 지정 활성화 명령 | [Enable-OrganizationCustomization](https://learn.microsoft.com/powershell/module/exchange/enable-organizationcustomization) |
| 문서 | Teams 팀 활동 보고서 API | [reportRoot: getTeamsTeamActivityDetail](https://learn.microsoft.com/graph/api/reportroot-getteamsteamactivitydetail?view=graph-rest-1.0) |
| 조회 | 관리 센터 사용 현황 "데이터 없음" | 10/26 23:39 |
| 조회 | Graph 보고서 404 `UnknownTenantId` | 10/26, 10/27 10:29, 10/27 19:17 |
| 조회 | 감사 로그 켜기 4회 거부 | 10/26 22:33~23:02, 내 PC PowerShell |

관련 글: [10 실측 ④ Purview·Azure 거버넌스]({{ "/m365/measure-purview-azure/" | relative_url }}), [상황별 대처 가이드]({{ "/m365/troubleshooting/troubleshooting-playbook/" | relative_url }})
