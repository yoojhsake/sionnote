---
title: "[IAM] Microsoft Entra ID 핵심 개념: 하이브리드, 외부 사용자, 라이선스, 운영"
date: 2026-11-01 08:57:00 +0900
categories: [iam]
tags: [IAM, Entra ID, 하이브리드 ID, PHS, PTA, Federation, Cloud Sync, External ID, 라이선스, 로그, Graph PowerShell]
excerpt: "Cloud Sync 전환 통지가 시작됐다. PHS, PTA, Federation과 B2B, External ID, 라이선스 단계를 고르는 기준"
---

AD 계정을 클라우드와 이어 쓰는 회사라면, 2026년 7월부터 Connect Sync에서 Cloud Sync로의 전환 통지가 시작됐다는 점부터 챙겨야 합니다. 다 읽으면 하이브리드 인증 방식과 동기화 도구, 외부 사용자 관리 방식, 필요한 라이선스 단계를 상황에 맞게 고를 수 있습니다.

읽는 데 30분 정도 걸리고, 다루는 내용은 이렇습니다.

- PHS, PTA, Federation과 Connect Sync, Cloud Sync를 상황에 맞게 고르는 기준
- B2B와 External ID 외부 테넌트의 차이
- 라이선스 단계와 제품군, 로그와 Graph PowerShell 같은 운영 기본기

## 요약

- 하이브리드 인증은 PHS, PTA, Federation 중 선택. 어떤 방식이든 **PHS를 함께 켜 두는 것**이 Microsoft 권장
- 동기화 도구는 Connect Sync와 Cloud Sync. 2026년 7월부터 Cloud Sync로의 **전환 통지** 시작
- 외부 협력사는 회사 테넌트의 B2B, 일반 고객은 External ID 외부 테넌트로 관리. B2C는 신규 판매 종료
- 라이선스는 Free → P1(조건부 액세스) → P2(ID Protection·PIM), ID Governance와 Entra Suite는 추가 구매
- 장애 분석은 로그인·감사 로그에서 시작, 스크립트는 Microsoft Graph PowerShell

> **시리즈: Microsoft Entra ID 핵심 개념**
>
> 1. [기초와 구조]({{ "/iam/what-is-entra-id/" | relative_url }})
> 2. [오류 코드 읽는 법(HTTP 상태 코드와 AADSTS)]({{ "/iam/entra-id-error-codes/" | relative_url }})
> 3. [인증(MFA, 패스키, SSPR, SSO)]({{ "/iam/entra-id-authentication/" | relative_url }})
> 4. [접근 제어(조건부 액세스, PIM, ID Protection)]({{ "/iam/entra-id-access-control/" | relative_url }})
> 5. **하이브리드, 외부 사용자, 라이선스, 운영** (지금 보는 글)
> 6. [용어집과 학습 자료]({{ "/iam/entra-id-glossary/" | relative_url }})

근거: Microsoft Learn 공식 문서(2026-11-01 확인). 날짜나 라이선스처럼 바뀔 수 있는 내용은 문서로 다시 확인했습니다. 낯선 용어는 [용어집]({{ "/iam/entra-id-glossary/" | relative_url }})을 함께 보세요.

---

## 전체 내용

### 1. 하이브리드 ID

온-프레미스 AD 계정을 Entra ID로 동기화해 하나의 계정으로 사내와 클라우드를 모두 쓰게 하는 구성입니다.

#### 인증 방식 3가지

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-hybrid-auth-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-hybrid-auth.png" | relative_url }}" alt="PHS, PTA, Federation 비교" loading="lazy"></picture>

*그림 1. 하이브리드 인증 방식 비교*

- **PHS(Password Hash Synchronization, 암호 해시 동기화)**는 가장 단순하고 장애에 강합니다.
    - 암호는 평문이나 되돌릴 수 있는 형태로 저장되지 않습니다.
    - 암호 해시는 약 2분 주기로 동기화되지만, 계정 사용 안 함 같은 상태는 일반 동기화 주기(Connect Sync 기본 30분)를 따르고 암호 만료나 잠금 상태는 동기화되지 않습니다.
- PTA(Pass-through Authentication, 통과 인증)는 로그인할 때마다 사내 에이전트가 DC에 확인합니다.
    - 계정 사용 안 함, 잠금, 만료, 로그온 시간이 즉시 반영됩니다.
    - 고가용성을 위해 에이전트 3대 이상을 권장합니다.
- Federation(페더레이션, 인증 위임. AD FS 등)은 인증을 외부 IdP(Identity Provider, ID 공급자)에 맡깁니다.
    - 문서가 드는 필요 사례는 페더레이션 IdP가 꼭 있어야 하는 타사 MFA·인증 솔루션, DOMAIN\user(sAMAccountName) 로그인, 여러 사이트에 걸친 저지연 인증입니다.
    - 스마트카드나 인증서 로그인은 이제 PHS, PTA에서도 Entra 인증서 기반 인증(CBA)으로 되고, 타사 MFA도 외부 인증 방법(External MFA)으로 페더레이션 없이 붙일 수 있습니다.
    - 운영 복잡도가 가장 높습니다.

#### 왜 PHS를 같이 켜 두라고 하나

Microsoft 문서에 따르면, 랜섬웨어로 사내 서버가 멈췄을 때 PHS를 미리 켜 둔 조직은 PHS로 전환해 **몇 시간 안에** 메일과 클라우드를 다시 썼고, 그렇지 않은 조직은 복구에 **몇 주**가 걸렸습니다. 그래서 PTA나 Federation을 쓰더라도 PHS는 백업 겸 유출 자격 증명 탐지용으로 켜 두라고 권합니다.

단, 전환은 자동이 아니라 관리자가 직접 바꿔야 합니다([PTA 장애 글]({{ "/iam/troubleshooting/pta-agent-sign-in-fails/" | relative_url }})).

#### 동기화 도구 2가지

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-sync-tools-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-sync-tools.png" | relative_url }}" alt="Entra Connect Sync와 Cloud Sync 구조 비교" loading="lazy"></picture>

*그림 2. 동기화 도구 비교*

| 항목 | Entra Connect Sync | Entra Cloud Sync |
|---|---|---|
| 엔진 위치 | 사내 서버(동기화 엔진·설정) | 클라우드(사내에는 경량 에이전트) |
| 고가용성 | 활성 서버 1대 + 스테이징 서버 | 에이전트 여러 대가 동시에 활성 |
| 단절된 포리스트(인수합병) | ✗ | ✓ |
| 규모(문서 비교표) | 도메인당 제한 없음, 그룹 25만 명 | 도메인당 15만 개체, 그룹 5만 명 |
| 고급 동기화 규칙 | ✓ | ✗(식 작성기만) |
| 교차 포리스트 참조, 여러 도메인 속성 병합, 재조정 | ✓ | ✗ |
| 속성 기반 필터링 | ✓ | 제한적 |
| 디바이스 쓰기 저장 | ✓ | ✗(Cloud Kerberos Trust로 대체) |
| PTA·AD FS 구성 마법사 | ✓ | ✗(별도 구성, 전환 후에도 PTA·Seamless SSO는 계속 동작) |
| 그룹을 AD로 프로비저닝 | ✗ | ✓ |

현재 Microsoft는 Connect Sync에서 Cloud Sync로의 전환을 시작했습니다. **2026년 7월부터** 메시지 센터, Connect Health, 이메일로 테넌트별 전환 일정을 단계적으로 통지하고 있습니다. Cloud Sync로 이미 요구 사항을 충족하는 단순한 구성부터 대상이고, 고급 기능을 쓰거나 대규모인 조직은 나중 단계입니다.

통지를 받으면 Connect Sync의 가이드 마이그레이션 도구를 쓰거나 문서의 수동 절차를 따르고, 기한을 맞출 수 없는 확인된 사유가 있을 때만 지원 요청으로 예외를 신청합니다(보장되지 않음). 통지 전이라도 비교표로 요구 사항을 미리 점검해 두면 덜 급합니다.

### 2. 외부 사용자: External ID

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-external-id-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-external-id.png" | relative_url }}" alt="워크포스 테넌트의 B2B와 외부 테넌트의 고객 CIAM" loading="lazy"></picture>

*그림 3. External ID의 두 가지 구성*

- **B2B 협업**
    - 대상: 협력사 직원
    - 어디서: 회사(워크포스) 테넌트
    - 예시: 협력사 직원을 게스트로 초대해 프로젝트 Teams에 참여
- **B2B direct connect**
    - 대상: 다른 회사 사용자
    - 어디서: 회사 테넌트
    - 예시: 게스트 계정 없이 Teams 공유 채널 사용
- **고객용(CIAM)**
    - 대상: 일반 고객
    - 어디서: 별도의 외부(External) 테넌트
    - 예시: 쇼핑몰 회원가입, Google·Facebook 로그인, 브랜딩된 로그인 화면

CIAM(Customer Identity and Access Management)은 직원이 아니라 고객의 가입·로그인을 다루는 ID 관리입니다.

예전에는 고객 로그인을 Azure AD B2C로 설명했지만, **2025-05-01부터** B2C는 신규 고객에게 판매되지 않습니다. 기존 고객은 계속 쓸 수 있고 최소 2030년 5월까지 지원되며, B2C P2는 2026-03-15에 단종되어 B2C 테넌트의 ID Protection 기능이 빠졌습니다.

새 고객용 프로젝트는 External ID 외부 테넌트로 시작하는 것이 현재 기준입니다. 게스트 로그인 오류는 [AADSTS50020 글]({{ "/iam/troubleshooting/aadsts50020-guest-not-in-tenant/" | relative_url }})에 정리했습니다.

### 3. 라이선스

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-license-tiers-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-license-tiers.png" | relative_url }}" alt="Free, P1, P2, ID Governance 단계별 기능" loading="lazy"></picture>

*그림 4. 라이선스 단계. P2는 P1을 포함하고, Governance는 추가 구매*

기능별로 쓸 수 있는 라이선스는 다음과 같습니다.

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

ID Governance(추가)는 P1 또는 P2에 더해서 사는 기능에만 적었습니다. Governance만으로는 조건부 액세스나 ID Protection이 생기지 않습니다.

어느 제품에 포함되는지도 알아 두면 견적 볼 때 편합니다(문서 기준).

- P1: Microsoft 365 E3, E5, E7, F1, F3, EMS E3, Business Premium에 포함
- P2: Microsoft 365 E5, E7, EMS E5, Microsoft Defender Suite(구 M365 E5 Security)에 포함
- Entra Suite: Private Access + Internet Access + ID Governance + ID Protection + Verified ID. P1이 선행 조건이고 Microsoft 365 E7에 포함(E7에는 Agent 365도 포함)

> **바로잡을 점**: 액세스 검토를 "P2 기능"으로만 소개한 자료가 많지만, 현재 문서는 액세스 검토를 ID Governance(또는 Entra Suite) 기능으로 보고 **P2로는 일부 기능만** 동작한다고 설명합니다.
>
> 또 라이선스는 테넌트에 하나가 아니라 기능을 쓰는 사용자 수만큼 필요합니다. 예를 들어 PIM은 적격 역할을 받은 사용자, 승인자, 검토자에게 P2 또는 Governance가 있어야 합니다.

### 4. Microsoft Entra 제품군

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-family-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-family.png" | relative_url }}" alt="Entra 제품군 지도" loading="lazy"></picture>

*그림 5. Microsoft Entra 제품군(2026-11 기준)*

- Entra ID: 모든 제품의 기반. 로그인, MFA, 조건부 액세스
- ID Governance: 입사·이동·퇴사 자동화, 액세스 검토, 권한 패키지, PIM
- ID Protection: 위험 탐지, 위험 기반 정책(Entra ID P2 기능이자 Suite 구성 요소)
- External ID: 외부 협력사(B2B)와 고객(CIAM)
- Verified ID: 검증 가능한 자격 증명(재직·신원 증명)
- Workload ID: 앱, 서비스 주체, 관리 ID 같은 사람이 아닌 ID
- Agent ID: AI 에이전트용 ID
    - **2026-04 정식 출시(GA)**, 모든 Entra 고객이 사용 가능
    - 에이전트에 조건부 액세스와 ID Protection을 적용하려면 Microsoft Agent 365 라이선스 필요
- Private Access / Internet Access: Global Secure Access(Microsoft의 SSE, Security Service Edge). VPN 없는 사내 앱 접근(ZTNA), 웹 필터링(SWG)
- ~~Permissions Management~~: 2025-10-01 서비스 종료(신규 판매 중단: EA·직접 고객 2025-04-01, CSP 2025-05-01)

### 5. 장애 분석은 로그에서 시작한다

- 로그인 로그(Sign-in logs)
    - 무엇이 남나: 누가, 언제, 어디서, 어떤 앱에 로그인했고 성공·실패·오류 코드, 적용된 조건부 액세스 정책
    - GUI 경로: Entra ID > Monitoring & health(모니터링 및 상태) > Sign-in logs
- 감사 로그(Audit logs)
    - 무엇이 남나: 사용자, 그룹, 역할, 정책을 누가 언제 바꿨는지
    - GUI 경로: Entra ID > Monitoring & health > Audit logs

로그인 로그는 대화형 사용자, 비대화형 사용자, 서비스 주체, 관리 ID 로그인을 탭으로 나눠 보여 줍니다.

보존 기간은 **Free 7일, P1·P2 30일**입니다. 무료에서 유료로 바꿔도 이미 지난 기록은 되살아나지 않습니다. 더 오래 보관하려면 진단 설정(Diagnostic settings)으로 Log Analytics, 스토리지, SIEM에 보냅니다. 이 내보내기는 P1 이상과 Azure 구독이 필요하고 Log Analytics 비용이 따로 듭니다.

문의를 받으면 사용자에게 화면의 "추가 정보(More details)"에 나오는 **상관 관계 ID(Correlation ID)**와 시각을 받아 두면 로그를 빨리 찾을 수 있습니다.

### 6. 스크립트는 Microsoft Graph PowerShell로

화면(GUI)으로 하기 어려운 대량 작업은 Microsoft Graph PowerShell SDK(`Connect-MgGraph`)로 합니다. 예전 AzureAD, AzureAD Preview, MSOnline 모듈은 지원이 끝났으므로(deprecated), 인터넷의 옛 예제(`Get-MsolUser`, `Get-AzureADUser`)는 Graph 명령(`Get-MgUser` 등)으로 바꿔 써야 합니다.

Microsoft Learn에 옛 cmdlet과 새 cmdlet을 짝지은 cmdlet 매핑 표가 있습니다.

```powershell
# 예: 이름이 a로 시작하는 사용자 수 세기(읽기 전용)
Connect-MgGraph -Scopes "User.Read.All"
Get-MgUser -ConsistencyLevel eventual -Count userCount -Filter "startsWith(DisplayName, 'a')" -Top 1
$userCount
```

Graph PowerShell은 권한이 미리 주어지지 않아, 처음 쓸 때 필요한 권한(스코프)에 동의해야 합니다. 스크립트에 필요한 최소 스코프는 `Find-MgGraphCommand`로 찾을 수 있습니다.

### 7. 처음 테넌트를 맡았을 때 확인 순서

1. 보안 기본값 또는 조건부 액세스 중 무엇으로 MFA를 강제하고 있는지 확인
2. 인증 방법 정책으로 이전이 끝났는지 확인, SMS·음성만 쓰는 사용자를 찾아 패스키로 이전 계획 세우기
3. **긴급 액세스 계정** 2개 이상이 차단·제한 정책에서 제외되어 있고 패스키로 보호되는지 확인
4. 상시 전역 관리자 수를 줄이고, 작은 역할과 PIM으로 전환
5. 옛 ID Protection 위험 정책을 쓰던 테넌트라면 조건부 액세스 위험 기반 정책으로 옮겼는지 확인(P2)
6. 하이브리드라면 PHS가 켜져 있는지(백업 + 유출 탐지), 동기화 도구 버전과 Cloud Sync 전환 통지 여부 확인
7. 로그인 로그에서 레거시 인증과 반복 실패 로그인 확인, 필요하면 로그를 장기 보관 위치로 내보내기
8. 라이선스가 기능을 쓰는 사용자 수만큼 있는지 확인

---

### 8. 관련 트러블슈팅

오류와 상황별 대처는 별도 글로 나눴습니다.

- PTA 환경 전원 로그인 실패 → [통과 인증(PTA) 환경에서 전원이 로그인하지 못할 때]({{ "/iam/troubleshooting/pta-agent-sign-in-fails/" | relative_url }})
- 게스트·외부 계정 로그인 실패 → [AADSTS50020: 게스트가 이 테넌트에 없는 계정으로 막힐 때]({{ "/iam/troubleshooting/aadsts50020-guest-not-in-tenant/" | relative_url }})

### 9. 확인 문제

<details markdown="1">
<summary>1. PTA를 쓰는 회사에 PHS도 켜 두라고 하는 이유 두 가지는?</summary>

① 사내 인프라 장애(예: 랜섬웨어) 때 PHS로 **수동 전환**해 클라우드 로그인을 살릴 수 있고, ② ID Protection이 **사내 사용자의 유출 자격 증명**을 탐지할 수 있습니다.

</details>

### 10. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (11건)</summary>

- PHS·PTA·Federation 선택, PHS 권장 이유, 상태 반영 지연: [Choose the right authentication method](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn)
- Connect Sync와 Cloud Sync 비교: [Connect Sync → Cloud Sync decision guide](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/connect-to-cloud-sync-decision-guide)
- Cloud Sync 전환 통지, 기한, 예외: [Migrate to Cloud Sync with the migration tool](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/migrate-connect-sync-cloud-sync-tool)
- Entra 새 소식(2026-04 Agent ID GA, Cloud Sync 전환 공지): [Microsoft Entra releases and announcements](https://learn.microsoft.com/entra/fundamentals/whats-new)
- B2C 판매 중단, External ID: [External ID FAQ](https://learn.microsoft.com/entra/external-id/customers/faq-customers)
- B2C P2 단종: [Azure AD B2C FAQ](https://learn.microsoft.com/azure/active-directory-b2c/faq)
- 라이선스 포함 관계: [Microsoft Entra licensing](https://learn.microsoft.com/entra/fundamentals/licensing)
- Permissions Management 종료: [Entra releases archive: March 2025](https://learn.microsoft.com/entra/fundamentals/whats-new-archive#march-2025)
- Agent ID: [What is Microsoft Entra Agent ID?](https://learn.microsoft.com/entra/agent-id/what-is-microsoft-entra-agent-id)
- 로그 보존 기간: [Microsoft Entra data retention](https://learn.microsoft.com/entra/identity/monitoring-health/reference-reports-data-retention)
- Graph PowerShell 전환: [Upgrade from Azure AD PowerShell to Microsoft Graph PowerShell](https://learn.microsoft.com/powershell/microsoftgraph/migration-steps)

</details>
