---
title: "[IAM] Microsoft Entra ID 핵심 개념: 라이선스와 운영"
date: 2026-11-01 08:58:00 +0900
categories: [iam]
tags: [IAM, Entra ID, 라이선스, P1, P2, ID Governance, Entra Suite, Agent ID, 로그인 로그, 감사 로그, Graph PowerShell]
excerpt: "라이선스는 기능을 쓰는 사용자 수만큼. Free, P1, P2, ID Governance 단계와 제품군, 로그와 Graph PowerShell, 처음 테넌트 점검 순서"
---

Entra ID 기능은 Free, P1, P2와 추가 구매인 ID Governance로 나뉘고, 장애 분석은 로그인 로그와 감사 로그에서 시작합니다. 단계별 기능과 제품군, Graph PowerShell, 처음 테넌트를 맡았을 때 확인 순서까지 정리했습니다.

## 요약

- 라이선스는 테넌트 하나가 아니라 기능을 쓰는 사용자 수만큼 필요함
- 처음 맡은 테넌트는 MFA 강제 방식과 긴급 액세스 계정부터 확인함
- 라이선스를 올려도 보존 기간이 지난 로그는 되살아나지 않음

> Entra ID 핵심 개념 시리즈: [기초]({{ "/iam/what-is-entra-id/" | relative_url }}) · [오류 코드]({{ "/iam/entra-id-error-codes/" | relative_url }}) · [인증]({{ "/iam/entra-id-authentication/" | relative_url }}) · [접근 제어]({{ "/iam/entra-id-access-control/" | relative_url }}) · [하이브리드·외부 사용자]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}) · **라이선스·운영**(지금 글) · [용어집]({{ "/study/cloud-study-glossary/" | relative_url }})

> 근거: Microsoft Learn 공식 문서(2026-11-01 확인). 날짜나 라이선스처럼 바뀔 수 있는 내용은 문서로 다시 확인했습니다. 낯선 용어는 [용어집]({{ "/study/cloud-study-glossary/" | relative_url }})을 함께 보세요.

---

## 전체 내용

### 1. 라이선스

Entra ID 라이선스는 기능 단계(Free, P1, P2)와 추가 구매(ID Governance)로 나뉘고, 테넌트 단위가 아니라 기능을 쓰는 사용자 단위로 필요합니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-license-tiers-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-license-tiers.png" | relative_url }}" alt="Free, P1, P2, ID Governance 단계별 기능" loading="lazy"></picture>

*그림 4. 라이선스 단계. P2는 P1을 포함하고, Governance는 추가 구매*

ID Governance(추가)는 P1 또는 P2에 더해서 사는 것이라, Governance만으로는 조건부 액세스나 ID Protection이 생기지 않습니다.

<details markdown="1">
<summary>기능별 필요한 라이선스 펼쳐 보기</summary>

- **사용자·그룹 관리, SSO, Connect 동기화**: Free·P1·P2
- **보안 기본값으로 MFA**: Free·P1·P2
- **로그인·감사 로그 보존**: Free 7일, P1 30일, P2 30일
- **조건부 액세스, 동적 그룹, 관리 단위, 애플리케이션 프록시**: P1·P2
- **SSPR 재설정 + 온-프레미스 쓰기 저장**: P1·P2
- **ID Protection(위험 기반 정책·전체 보고서)**: P2
- **PIM**: P2·ID Governance(추가)
- **액세스 검토(기본)**: P2·ID Governance(추가)
- **권한 패키지(Entitlement management) 기본**: P2·ID Governance(추가)
- **액세스 검토(비활성 사용자만·ML 추천·카탈로그), Lifecycle Workflows**: ID Governance(추가)

</details>

<details markdown="1">
<summary>Microsoft 365 제품에 포함된 단계 (문서 기준)</summary>

- P1: Microsoft 365 E3, E5, E7, F1, F3, EMS E3, Business Premium에 포함
- P2: Microsoft 365 E5, E7, EMS E5, Microsoft Defender Suite(구 M365 E5 Security)에 포함
- Entra Suite: Private Access + Internet Access + ID Governance + ID Protection + Verified ID. P1이 선행 조건이고 Microsoft 365 E7에 포함(E7에는 Agent 365도 포함)

</details>

> **바로잡을 점**: 액세스 검토를 "P2 기능"으로만 소개한 자료가 많지만, 현재 문서는 액세스 검토를 ID Governance(또는 Entra Suite) 기능으로 보고 **P2로는 일부 기능만** 동작한다고 설명합니다.
>
> 사용자 수 기준의 예: PIM은 적격 역할을 받은 사용자, 승인자, 검토자에게 P2 또는 Governance가 있어야 합니다.

관련 오류: [그룹 라이선스를 Entra에서 할당할 수 없다]({{ "/m365/troubleshooting/license-assignment-not-in-entra/" | relative_url }}) · [직접 라이선스와 그룹 라이선스가 겹쳤을 때]({{ "/m365/troubleshooting/direct-and-group-license-overlap/" | relative_url }}) · [라이선스 사용 수가 기록과 조회로 다르다]({{ "/m365/troubleshooting/license-seat-count-mismatch/" | relative_url }})

### 2. Microsoft Entra 제품군

Microsoft Entra는 ID와 네트워크 접근 제품의 묶음입니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-family-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-family.png" | relative_url }}" alt="Entra 제품군 지도" loading="lazy"></picture>

*그림 5. Microsoft Entra 제품군(2026-11 기준)*

Entra ID가 기반이고, 나머지 제품은 거버넌스, 위험 탐지, 외부 사용자, 사람이 아닌 ID, 네트워크 접근을 나눠 맡습니다. Agent ID는 **2026-04 정식 출시(GA)**됐고, Permissions Management는 2025-10-01에 서비스가 종료됐습니다.

<details markdown="1">
<summary>제품별 한 줄 설명 펼쳐 보기</summary>

- Entra ID: 모든 제품의 기반. 로그인, MFA, 조건부 액세스
- ID Governance: 입사·이동·퇴사 자동화, 액세스 검토, 권한 패키지, PIM
- ID Protection: 위험 탐지, 위험 기반 정책(Entra ID P2 기능이자 Suite 구성 요소)
- External ID: 외부 협력사(B2B)와 고객(CIAM)
- Verified ID: 검증 가능한 자격 증명(재직·신원 증명)
- Workload ID: 앱, 서비스 주체, 관리 ID 같은 사람이 아닌 ID
- Agent ID: AI 에이전트용 ID. **2026-04 정식 출시(GA)**로 모든 Entra 고객이 쓸 수 있고, 에이전트에 조건부 액세스와 ID Protection을 적용하려면 Microsoft Agent 365 라이선스가 필요합니다.
- Private Access / Internet Access: Global Secure Access(Microsoft의 SSE, Security Service Edge). VPN 없는 사내 앱 접근(ZTNA), 웹 필터링(SWG)
- ~~Permissions Management~~: 2025-10-01 서비스 종료(신규 판매 중단: EA·직접 고객 2025-04-01, CSP 2025-05-01)

</details>

### 3. 장애 분석은 로그에서 시작한다

Entra의 기본 로그는 로그인 로그와 감사 로그 두 가지이고, Entra ID > Monitoring & health(모니터링 및 상태)에서 Sign-in logs, Audit logs로 엽니다.

- **로그인 로그(Sign-in logs)**: 누가, 언제, 어디서, 어떤 앱에 로그인했고 성공·실패·오류 코드, 적용된 조건부 액세스 정책. 대화형·비대화형 사용자, 서비스 주체, 관리 ID 로그인을 탭으로 나눠 보여 줍니다.
- **감사 로그(Audit logs)**: 사용자, 그룹, 역할, 정책을 누가 언제 바꿨는지

실무 기준:

- 문의를 받으면 화면의 "추가 정보(More details)"에 나오는 **상관 관계 ID(Correlation ID)**와 시각을 받아 둡니다.
- 보존 기간(1장)을 넘긴 기록은 유료로 바꿔도 되살아나지 않으니, 더 오래 보관하려면 진단 설정(Diagnostic settings)으로 Log Analytics, 스토리지, SIEM에 보냅니다. 이 내보내기는 P1 이상과 Azure 구독이 필요하고 Log Analytics 비용이 따로 듭니다.

### 4. 스크립트는 Microsoft Graph PowerShell로

GUI로 하기 어려운 대량 작업은 Microsoft Graph PowerShell SDK(`Connect-MgGraph`)로 합니다. AzureAD, AzureAD Preview, MSOnline 모듈은 지원이 끝났으므로(deprecated) 옛 예제(`Get-MsolUser`, `Get-AzureADUser`)는 Graph 명령(`Get-MgUser` 등)으로 바꿉니다(Microsoft Learn에 cmdlet 매핑 표가 있음).

```powershell
# 예: 이름이 a로 시작하는 사용자 수 세기(읽기 전용)
Connect-MgGraph -Scopes "User.Read.All"
Get-MgUser -ConsistencyLevel eventual -Count userCount -Filter "startsWith(DisplayName, 'a')" -Top 1
$userCount
```

처음 쓸 때 필요한 권한(스코프)에 동의해야 하고, 최소 스코프는 `Find-MgGraphCommand`로 찾습니다.

관련 오류: [문서의 예제 명령이 '모듈 없음'이거나 환경에 따라 접속되지 않음]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }}) · [조회 스크립트 결과가 전부 실패로 나옴: 토큰 만료와 오류 유형 구분]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }})

### 5. 처음 테넌트를 맡았을 때 확인 순서

1. 보안 기본값 또는 조건부 액세스 중 무엇으로 MFA를 강제하고 있는지 확인
2. 인증 방법 정책으로 이전이 끝났는지 확인, SMS·음성만 쓰는 사용자를 찾아 패스키로 이전 계획 세우기
3. **긴급 액세스 계정** 2개 이상이 차단·제한 정책에서 제외되어 있고 패스키로 보호되는지 확인
4. 상시 전역 관리자 수를 줄이고, 작은 역할과 PIM으로 전환
5. 옛 ID Protection 위험 정책을 쓰던 테넌트라면 조건부 액세스 위험 기반 정책으로 옮겼는지 확인(P2)
6. 하이브리드라면 PHS가 켜져 있는지(백업 + 유출 탐지), 동기화 도구 버전과 Cloud Sync 전환 통지 여부 확인
7. 로그인 로그에서 레거시 인증과 반복 실패 로그인 확인, 필요하면 로그를 장기 보관 위치로 내보내기
8. 라이선스가 기능을 쓰는 사용자 수만큼 있는지 확인

하이브리드 인증 방식, 동기화 도구, 외부 사용자(External ID)는 [하이브리드와 외부 사용자]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}) 글에 있습니다.

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- 라이선스 포함 관계: [Microsoft Entra licensing](https://learn.microsoft.com/entra/fundamentals/licensing)
- Entra 새 소식(2026-04 Agent ID GA): [Microsoft Entra releases and announcements](https://learn.microsoft.com/entra/fundamentals/whats-new)
- Agent ID: [What is Microsoft Entra Agent ID?](https://learn.microsoft.com/entra/agent-id/what-is-microsoft-entra-agent-id)
- Permissions Management 종료: [Entra releases archive: March 2025](https://learn.microsoft.com/entra/fundamentals/whats-new-archive#march-2025)
- 로그 보존 기간: [Microsoft Entra data retention](https://learn.microsoft.com/entra/identity/monitoring-health/reference-reports-data-retention)
- Graph PowerShell 전환: [Upgrade from Azure AD PowerShell to Microsoft Graph PowerShell](https://learn.microsoft.com/powershell/microsoftgraph/migration-steps)

</details>
