---
title: "[트러블슈팅] 감사 로그를 켜는 명령이 InvalidOperationInDehydratedContextException으로 거부됨"
date: 2026-10-26 23:10:00 +0900
categories: [m365, troubleshooting]
area: 보고서·감사·청구
seq: 2
tags: [트러블슈팅, 감사 로그, Purview, Exchange Online PowerShell, Set-AdminAuditLogConfig, BadRequest]
excerpt: "통합 감사 로그 수집이 꺼져 있고 켜는 명령이 서버 오류로 거부될 때, 권한 부족과 조직 상태 문제를 나눠 보고 어디까지 확인했는지 정리한 기록"
toc: true
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell·Graph에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유·다음 방법 병기). 테넌트·요청 ID, 계정은 게시하지 않았고 캡처에서는 가렸다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | Purview 감사 검색에 "기록 시작" 버튼이 보이고, `UnifiedAuditLogIngestionEnabled`가 `False`. 켜는 명령은 BadRequest로 거부 |
| 먼저 나눈 것 | 내 권한 부족인가, 조직 상태 문제인가 |
| 원인 | **확인 불가**. 오류 안내와 다른 명령의 응답이 서로 어긋남 |
| 대처 | 같은 명령을 세션을 다시 연결해 가며 4회 실행하고 관련 상태값을 읽음 |
| 결과 | **조회**: 10/26 22:33~23:02 동안 켜지지 않음. 대기 후 재시도, 지원 요청, 대체 근거 순으로 정리 |

---

## 전체 기록

### 1. 증상

- Microsoft Purview 포털 > 감사 > 검색 화면에 "활동을 기록 중인지 파악하는 데 문제가 있습니다"라는 안내와 **"사용자 및 관리자 활동 기록 시작"** 버튼이 표시됩니다(조회).
- Exchange Online PowerShell로 상태를 읽으면 `UnifiedAuditLogIngestionEnabled`가 **False**입니다(조회). 즉 통합 감사 로그 수집이 꺼져 있습니다.

![Purview 감사 검색 화면의 기록 시작 버튼과 상태 확인 오류]({{ "/assets/images/2026/10/m23-3-purview-audit-not-recording.png" | relative_url }})
*그림 1. 감사 검색 화면. 상단에 상태 확인 오류 안내와 "사용자 및 관리자 활동 기록 시작" 버튼이 보이고, 아래 검색 목록은 불러오지 못한다.*

### 2. 먼저 확인할 것

실행 환경은 **내 PC의 Windows PowerShell**(Exchange Online PowerShell 모듈, 브라우저 로그인)입니다. Cloud Shell에서는 장치 코드 로그인이 막혀 쓰지 못했습니다([Exchange 장치 코드 로그인이 AADSTS530035로 막힘]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})).

이 작업은 조직 설정을 바꾸는 일이므로, 실행 전에 현재 상태를 읽어 두었습니다.

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

### 3. 시도와 결과

| 시각(10/26) | 한 일 | 결과(조회) |
|---|---|---|
| 22:31 | 상태 읽기 | `UnifiedAuditLogIngestionEnabled : False` |
| 22:33 | 켜기 | **BadRequest, `InvalidOperationInDehydratedContextException`**. "이 명령을 실행하려면 먼저 Enable-OrganizationCustomization 명령을 실행해야 합니다." |
| 22:33 | `Enable-OrganizationCustomization` | "이 작업은 필수가 아닙니다. 조직이 사용자 지정을 위해 이미 활성화되었습니다." |
| 22:35 | 켜기 재시도 | 같은 오류 |
| 22:37 | **세션을 다시 연결** 후 `IsDehydrated` 읽기, 켜기 재시도 | `IsDehydrated : False`, 켜기는 같은 오류 |
| 23:00 | Purview 화면 다시 열기 | 기록 시작 버튼과 상태 확인 오류 안내가 그대로 |
| 23:02 | 켜기 재시도 | 같은 오류, 상태는 계속 False |

**권한 문제가 아니라고 본 이유**

- 오류 문구가 **"먼저 Enable-OrganizationCustomization을 실행하라"**고 안내했는데, 그 명령은 **"이미 활성화되어 있어 필요 없다"**고 응답했습니다. 두 응답이 서로 모순됩니다(조회).
- `IsDehydrated`도 False였습니다. 이 값이 True인 조직에서 사용자 지정이 필요하다는 설명과 맞지 않습니다(문서: [Enable-OrganizationCustomization](https://learn.microsoft.com/powershell/module/exchange/enable-organizationcustomization)).
- 권한 부족이라면 보통 권한 오류(Access denied 계열)가 납니다. 이번 오류는 **조직 상태에 대한 오류**였고, 세션을 새로 연결해도 같았습니다.
- 그래서 **역할을 더 올리거나 보안 설정을 바꾸는 방향으로 가지 않았습니다.** 원인은 확인 불가이고, "서버 쪽 상태가 아직 반영되지 않았을 가능성"은 **추정**일 뿐입니다.

### 4. 대처와 원복

- 약 30분 사이에 4회 시도한 뒤 멈췄습니다. 같은 오류가 같은 문구로 계속될 때는 **반복해도 새 정보가 없고**, 요청만 쌓이기 때문입니다.
- 켜는 명령이 모두 거부되어 조직 설정은 바뀌지 않았습니다. 원복할 변경은 없습니다(조회: 23:02에도 상태 False).
- 다음 방법
  1. 서버 상태가 반영될 시간을 두고 같은 명령을 다시 실행합니다(문서에는 감사 활성화 직후 반영까지 최대 60분이라는 설명이 있습니다).
  2. 계속 같은 오류면 Microsoft 365 관리 센터에서 **지원 요청**을 올립니다. 이때 오류 코드와 시각, 요청 ID를 함께 보냅니다(이 글에는 요청 ID를 싣지 않았습니다).
  3. 감사 로그가 꺼져 있는 동안의 **대체 근거**로는 Entra 감사 로그(`/auditLogs/directoryAudits`)를 씁니다. 이 로그는 계속 Graph로 읽혔습니다(조회). 단, Entra 감사 로그는 디렉터리 변경 기록이고 Exchange·SharePoint 활동까지 포함하는 통합 감사 로그를 대신하지는 못합니다.
- 감사 로그가 꺼진 상태에서 조회 명령(`Search-UnifiedAuditLog`)은 **BadRequest 경고 후 0건**으로 끝났고, 사용자 PC에서도 같은 결과였습니다(조회). 이 경고의 원인이 감사 꺼짐이라는 것은 **추정**입니다. 켠 뒤 같은 명령을 실행해 봐야 알 수 있어 지금은 **확인 불가**입니다(시도: 꺼진 상태에서 조회 / 막힌 이유: 켜지지 않음 / 다음 방법: 켜진 뒤 같은 명령 재실행).

### 5. 운영에서는 이렇게 판단한다

1. **오류 유형을 먼저 읽습니다.** 권한 오류(Access denied 계열)면 역할·범위, 조직 상태 오류면 서비스 쪽 상태입니다.
2. **모순되는 응답은 모순대로 적습니다.** 안내 문구와 명령 응답이 어긋나면 하나를 원인으로 고르지 않습니다.
3. **같은 오류를 반복하지 않습니다.** 기록한 뒤 대기 후 재시도, 지원 요청, 대체 근거 순으로 넘어갑니다.
4. **감사가 꺼진 기간은 기록이 없는 기간입니다.** 대체 근거를 쓰더라도 포함 범위가 다르다는 점을 함께 적습니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 감사 활성화·비활성화(PowerShell) | [감사 활성화·비활성화](https://learn.microsoft.com/purview/audit-log-enable-disable) |
| 문서 | 감사 시작하기 | [감사 시작하기](https://learn.microsoft.com/purview/audit-get-started) |
| 문서 | 사용자 지정 활성화 명령 | [Enable-OrganizationCustomization](https://learn.microsoft.com/powershell/module/exchange/enable-organizationcustomization) |
| 조회 | 감사 로그 켜기 4회 거부 | 10/26 22:33~23:02, 내 PC PowerShell |
| 확인 불가 | 거부의 원인 | 시도: 명령 4회, 세션 재연결, `IsDehydrated`·`Enable-OrganizationCustomization` 조회. 막힌 이유: 오류 안내와 명령 응답이 모순. 다음 방법: 대기 후 재시도, 지원 요청 |

관련 글: [사용 현황 보고서가 비어 있을 때]({{ "/m365/troubleshooting/usage-report-no-data/" | relative_url }}), [실측 Purview·Azure 거버넌스]({{ "/m365/measure-purview-azure/" | relative_url }})
