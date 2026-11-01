---
title: "[Study] 모니터링과 통합: Log Analytics, KQL, Sentinel, 온보딩 시나리오"
date: 2026-10-31 10:13:00 +0900
categories: [study]
phase: 3단계 Azure
seq: 4
tags: [Study, Azure Monitor, Log Analytics, KQL, Microsoft Sentinel, Joiner]
excerpt: "Diagnostic settings를 켜지 않으면 로그는 쌓이지 않습니다. Log Analytics, KQL, Sentinel과 신규 입사자 8단계"
---

리소스 로그는 Diagnostic settings를 리소스별로 켜야 비로소 Log Analytics에 쌓입니다. 마지막 주에는 로그를 모아 KQL로 조회하고 Sentinel로 탐지하는 흐름을 익힌 뒤, 지금까지 배운 서비스를 신규 입사자 한 명의 8단계 흐름과 3분 설명 스크립트로 엮습니다.

## 요약

- 로그는 Log Analytics에 모아 KQL로 조회하고 Sentinel로 탐지함
- 신규 입사자 8단계 흐름으로 배운 서비스를 엮어 3분 안에 설명할 수 있으면 됨
- Sentinel은 2027-03-31 이후 Defender portal에서만 쓸 수 있음

12주 학습 로드맵의 12주차(마지막 주)입니다. 이전 글은 [Azure 보안과 거버넌스]({{ "/study/azure-security-governance/" | relative_url }}), 다음은 부록 [온프레미스↔클라우드 대응표]({{ "/study/onprem-cloud-mapping/" | relative_url }})와 [클라우드 학습 용어집]({{ "/study/cloud-study-glossary/" | relative_url }})입니다. 전체 로드맵: [클라우드 학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 이번 주 용어

Azure Monitor, Metrics, Logs, Log Analytics workspace, KQL(Kusto Query Language), Diagnostic settings, Activity log, Alert rule, Action group, Application Insights, Workbook, Entra sign-in logs, audit logs, Microsoft Sentinel, SIEM, SOAR, Data connector, Analytics rule, Incident, Playbook, Microsoft Defender XDR, Defender for Identity, Microsoft Purview Audit

### 2. 개념 설명

#### 로그가 쌓이는 곳

Metrics는 가볍고 거의 실시간인 시계열 수치, Logs는 Log Analytics workspace에 쌓여 KQL로 조회하는 상세 이벤트입니다. Activity log는 구독 수준에서 누가 어떤 리소스에 무슨 작업(control plane)을 했는지 남깁니다.

Diagnostic settings는 리소스의 플랫폼 로그를 Log Analytics workspace, 스토리지 계정, Event Hub로 보내는 설정입니다.

Alert는 조건을 만족하면 Action group(메일, SMS, 웹훅, 자동화)을 실행합니다.

Entra Sign-in logs와 Audit logs도 workspace로 내보내면 KQL로 분석할 수 있습니다. 보존 기간과 내보내기 가능 여부는 라이선스마다 다릅니다([하이브리드·라이선스·로그]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}) 글도 참고).

#### Sentinel

Sentinel은 클라우드 네이티브 SIEM이자 SOAR입니다. Data connector로 모으고, Analytics rule로 탐지해 Incident를 만들고, Playbook(Logic Apps 기반)으로 대응을 자동화합니다.

2027-03-31 이후 Azure portal의 Sentinel은 지원되지 않습니다. 2025년 7월부터 테넌트에서 처음 Sentinel을 켜는 신규 고객(구독 Owner 또는 User Access Administrator)은 workspace가 Defender portal에 자동 온보딩됩니다. Defender XDR이나 E5 license가 없어도 Defender portal에서 Sentinel을 쓸 수 있습니다([Sentinel의 Azure portal 은퇴 일정](https://learn.microsoft.com/azure/sentinel/overview#microsoft-sentinel-in-the-azure-portal-retirement-timeline), [Defender portal의 Microsoft Sentinel](https://learn.microsoft.com/azure/sentinel/microsoft-sentinel-defender-portal)).

#### AD 운영자에게 중요한 연결

온프레미스 AD 신호는 Defender for Identity(DC에 센서 설치)로 수집해 Defender XDR에서 확인합니다. Entra 쪽 위험 신호는 Identity Protection이 제공합니다([ID Protection 설명]({{ "/iam/entra-id-access-control/" | relative_url }})).

#### KQL 맛보기

```kusto
// 최근 24시간 로그인 결과 코드별 건수 (Entra sign-in logs를 workspace로 내보낸 경우)
SigninLogs
| where TimeGenerated > ago(1d)
| summarize SignIns = count() by ResultType
| order by SignIns desc

// 최근 7일 디렉터리 변경 이력
AuditLogs
| where TimeGenerated > ago(7d)
| project TimeGenerated, OperationName, Result, InitiatedBy
| take 20
```

### 3. 통합 시나리오: 신규 입사자 한 명의 흐름 (Joiner)

| 단계 | 전문 용어 | 확인 위치 |
|---|---|---|
| 1. HR 요청으로 계정 생성 | Source of authority(온프레미스 AD 또는 Entra) | AD DS 또는 Entra 관리 센터 |
| 2. Entra ID로 동기화 | Entra Connect delta sync (기본 30분) | Entra Connect 화면 |
| 3. 그룹 편입과 license 부여 | Dynamic group, Group-based licensing | Entra 그룹, M365 관리 센터 |
| 4. 사서함, Teams 구성원 생성 | Exchange Online mailbox, Microsoft 365 group | Exchange 관리 센터, Teams 관리 센터 |
| 5. PC 프로비저닝 | Autopilot, Entra join, Intune enrollment | Intune 관리 센터 |
| 6. 첫 로그인 | MFA 등록(TAP), Conditional Access, compliant device | Entra Sign-in logs |
| 7. Azure 접근 | RBAC role assignment via group, PIM eligible | Azure 포털 IAM |
| 8. 감사 | Sign-in logs, Audit logs, Sentinel | Log Analytics, Microsoft Defender portal(Sentinel) |

퇴사(Leaver)는 반대로 계정 비활성화, 세션과 토큰 폐기, license 회수, 디바이스 retire 또는 wipe, 접근 권한 회수 순입니다.

### 4. 3분 설명 스크립트 (빈칸을 채워 외우기)

1. 신원은 \_\_\_\_\_\_ 가 기준이고, 온프레미스와는 \_\_\_\_\_\_ 로 동기화합니다.
2. 로그인은 \_\_\_\_\_\_ 방식으로 처리하고, 접근 통제는 \_\_\_\_\_\_ 로 합니다.
3. 서비스는 \_\_\_\_\_\_ 를 license로 할당해 켜고, 디바이스는 \_\_\_\_\_\_ 로 관리합니다.
4. Azure 리소스는 \_\_\_\_\_\_ 계층에 배포하고, 권한은 \_\_\_\_\_\_, 표준은 \_\_\_\_\_\_ 로 통제합니다.
5. 로그는 \_\_\_\_\_\_ 에 모아 \_\_\_\_\_\_ 로 조회하고 위협은 \_\_\_\_\_\_ 로 탐지합니다.

<details markdown="1">
<summary>빈칸 정답 펼쳐 보기 (5문장)</summary>

1. Entra ID tenant, Entra Connect
2. PHS 또는 PTA, Conditional Access
3. service plan, Intune
4. Tenant-Subscription-Resource group, RBAC, Policy
5. Log Analytics, KQL, Sentinel

</details>

### 5. 전문가처럼 말하기

> "온프레미스 AD는 Defender for Identity 센서로, 클라우드 신원은 Entra 로그와 Identity Protection으로 보고, Sentinel에서 상관 분석합니다."
>
> "Joiner는 source of authority에서 계정 생성과 동기화, group-based licensing, Autopilot으로 Entra join과 Intune 등록, Conditional Access의 compliant device 요구 순입니다."

### 6. 자가 점검

- [ ] Metrics와 Logs의 차이를 말할 수 있다.
- [ ] Activity log와 Entra sign-in logs가 각각 무엇을 기록하는지 말할 수 있다.
- [ ] Diagnostic settings가 필요한 이유를 설명할 수 있다.
- [ ] Sentinel을 SIEM과 SOAR로 나눠 설명할 수 있다.
- [ ] 신규 입사자 흐름 여덟 단계를 보지 않고 말할 수 있다.
- [ ] 3분 설명 스크립트의 빈칸을 모두 채울 수 있다.

<details markdown="1">
<summary>답 펼쳐 보기 (6문항)</summary>

- **Metrics와 Logs**: Metrics는 가볍고 거의 실시간인 시계열 수치, Logs는 workspace에 쌓이는 상세 이벤트로 KQL로 조회합니다.
- **Activity log와 sign-in logs**: Activity log는 구독 수준에서 누가 어떤 리소스에 무슨 작업(control plane)을 했는지 남깁니다. Entra sign-in logs는 로그인 기록으로, workspace로 내보내면 로그인 이상을 분석할 수 있습니다.
- **Diagnostic settings**: 리소스의 플랫폼 로그는 리소스별로 이 설정을 켜야 workspace, 스토리지 계정, Event Hub로 쌓입니다.
- **SIEM과 SOAR**: SIEM 쪽은 Data connector로 모으고 Analytics rule로 탐지해 Incident를 만드는 부분입니다. SOAR 쪽은 Playbook(Logic Apps 기반)으로 대응을 자동화하는 부분입니다.
- **여덟 단계**: 계정 생성 → Entra ID 동기화 → 그룹 편입과 license → 사서함과 Teams 구성원 → PC 프로비저닝 → 첫 로그인 → Azure 접근 → 감사입니다.
- **빈칸**: 위 4장의 "빈칸 정답 펼쳐 보기"로 확인합니다.

</details>

### 7. 영상과 자료 (한글 우선)

- 한글: Microsoft Korea의 [Azure 교육·웨비나 페이지](https://www.microsoft.com/ko-kr/azureall)에서 모니터링, 보안 주제를 찾아 보세요. Log Analytics와 KQL 한글 유튜브는 확인 불가입니다(유튜브 검색으로 찾지 못함).
- 영문 보완: AZ-104 공식 시리즈(Microsoft Learn, 전 29편)의 [27편 Introduction to Azure Monitor](https://www.youtube.com/watch?v=p7Kw1YJl2S4), [28편 alerting](https://www.youtube.com/watch?v=AGkyh3jlaw8), [29편 Azure Monitor logs 분석](https://www.youtube.com/watch?v=Spf9SMfK000). [AZ-104 Full Course - 12 Hours](https://www.youtube.com/watch?v=qXk8_0z_HsU)는 모니터링 모듈이 7:15:25부터입니다.
