---
title: "[IAM] Microsoft Entra ID 핵심 개념: 하이브리드와 외부 사용자"
date: 2026-11-01 08:57:00 +0900
categories: [iam]
tags: [IAM, Entra ID, 하이브리드 ID, PHS, PTA, Federation, Connect Sync, Cloud Sync, External ID, B2B]
excerpt: "Cloud Sync 전환 통지가 시작됐다. PHS, PTA, Federation과 동기화 도구, B2B와 External ID 외부 테넌트를 고르는 기준"
---

하이브리드 ID는 어떤 인증 방식을 쓰든 PHS를 함께 켜 두는 것이 문서 권장이고, 2026년 7월부터 Connect Sync에서 Cloud Sync로의 전환 통지가 시작됐습니다. 외부 사용자는 협력사면 B2B, 고객이면 External ID 외부 테넌트로 나눠 관리합니다.

## 요약

- PHS는 사내 장애 때 백업과 유출 자격 증명 탐지용으로 켜 둠
- 전환 통지 전에 비교표로 Cloud Sync 요구 사항을 점검하면 됨
- B2C는 신규 판매가 끝나 새 고객용 서비스는 외부 테넌트로 시작함

> Entra ID 핵심 개념 시리즈: [기초]({{ "/iam/what-is-entra-id/" | relative_url }}) · [오류 코드]({{ "/iam/entra-id-error-codes/" | relative_url }}) · [인증]({{ "/iam/entra-id-authentication/" | relative_url }}) · [접근 제어]({{ "/iam/entra-id-access-control/" | relative_url }}) · **하이브리드·외부 사용자**(지금 글) · [라이선스·운영]({{ "/iam/entra-id-licensing-operations/" | relative_url }}) · [용어집]({{ "/study/cloud-study-glossary/" | relative_url }})

> 근거: Microsoft Learn 공식 문서(2026-11-01 확인). 날짜나 라이선스처럼 바뀔 수 있는 내용은 문서로 다시 확인했습니다. 낯선 용어는 [용어집]({{ "/study/cloud-study-glossary/" | relative_url }})을 함께 보세요.

---

## 전체 내용

### 1. 하이브리드 인증 방식: PHS, PTA, Federation

하이브리드 ID는 온-프레미스 AD 계정을 Entra ID로 동기화해 한 계정으로 사내와 클라우드를 쓰는 구성이고, 로그인 검증 위치에 따라 세 방식으로 나뉩니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-hybrid-auth-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-hybrid-auth.png" | relative_url }}" alt="PHS, PTA, Federation 비교" loading="lazy"></picture>

*그림 1. 하이브리드 인증 방식 비교*

- **PHS(Password Hash Synchronization, 암호 해시 동기화)**: 암호 해시를 약 2분 주기로 Entra ID에 동기화합니다. 가장 단순하고 장애에 강합니다.
- **PTA(Pass-through Authentication, 통과 인증)**: 로그인할 때마다 사내 에이전트가 DC에 확인하므로 계정 상태가 즉시 반영됩니다. 에이전트는 3대 이상을 권장합니다.
- **Federation(페더레이션, 인증 위임. AD FS 등)**: 인증을 외부 IdP(Identity Provider, ID 공급자)에 맡기며 운영 복잡도가 가장 높습니다.

<details markdown="1">
<summary>방식별 세부 동작과 Federation이 필요한 경우</summary>

- PHS
    - 암호는 평문이나 되돌릴 수 있는 형태로 저장되지 않습니다.
    - 계정 사용 안 함 같은 상태는 일반 동기화 주기(Connect Sync 기본 30분)를 따르고, 암호 만료나 잠금 상태는 동기화되지 않습니다.
- PTA: 계정 사용 안 함, 잠금, 만료, 로그온 시간이 즉시 반영됩니다.
- Federation
    - 문서가 드는 필요 사례는 페더레이션 IdP가 꼭 있어야 하는 타사 MFA·인증 솔루션, DOMAIN\user(sAMAccountName) 로그인, 여러 사이트에 걸친 저지연 인증입니다.
    - 스마트카드나 인증서 로그인은 이제 PHS, PTA에서도 Entra 인증서 기반 인증(CBA)으로 되고, 타사 MFA도 외부 인증 방법(External MFA)으로 페더레이션 없이 붙일 수 있습니다.

</details>

실무 기준: PTA나 Federation을 쓰더라도 PHS를 함께 켜 둡니다.

- Microsoft 문서에 따르면 랜섬웨어로 사내 서버가 멈췄을 때 PHS를 미리 켜 둔 조직은 PHS로 전환해 **몇 시간 안에** 메일과 클라우드를 다시 썼고, 그렇지 않은 조직은 복구에 **몇 주**가 걸렸습니다.
- PHS는 유출 자격 증명 탐지에도 쓰입니다.
- 장애 때 PHS 전환은 자동이 아니라 관리자가 직접 바꿔야 합니다.

관련 오류: [통과 인증(PTA) 환경에서 전원이 로그인하지 못할 때]({{ "/iam/troubleshooting/pta-agent-sign-in-fails/" | relative_url }})

### 2. 동기화 도구: Connect Sync와 Cloud Sync

Entra Connect Sync는 동기화 엔진을 사내 서버에 두고, Entra Cloud Sync는 엔진을 클라우드에 두고 사내에는 경량 에이전트만 둡니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-sync-tools-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-sync-tools.png" | relative_url }}" alt="Entra Connect Sync와 Cloud Sync 구조 비교" loading="lazy"></picture>

*그림 2. 동기화 도구 비교*

Cloud Sync는 단절된 포리스트(인수합병)를 지원하지만, 고급 동기화 규칙과 대규모 구성은 Connect Sync 쪽이 넓습니다.

<details markdown="1">
<summary>Connect Sync와 Cloud Sync 비교표 펼쳐 보기</summary>

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

</details>

**2026년 7월부터** 메시지 센터, Connect Health, 이메일로 테넌트별 Connect Sync → Cloud Sync 전환 일정을 단계적으로 통지하고 있습니다.

<details markdown="1">
<summary>전환 대상 순서와 통지를 받았을 때 할 일</summary>

- Cloud Sync로 이미 요구 사항을 충족하는 단순한 구성부터 대상이고, 고급 기능을 쓰거나 대규모인 조직은 나중 단계입니다.
- 통지를 받으면 Connect Sync의 가이드 마이그레이션 도구를 쓰거나 문서의 수동 절차를 따릅니다.
- 기한을 맞출 수 없는 확인된 사유가 있을 때만 지원 요청으로 예외를 신청합니다(보장되지 않음).

</details>

실무 기준: 통지 전에 위 비교표에서 지금 쓰는 기능(고급 규칙, 디바이스 쓰기 저장, 규모)이 Cloud Sync에 있는지 점검해 둡니다.

### 3. 외부 사용자: External ID

External ID는 회사 밖 사람(협력사, 고객)의 계정과 로그인을 다루는 Entra 기능입니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-external-id-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-external-id.png" | relative_url }}" alt="워크포스 테넌트의 B2B와 외부 테넌트의 고객 CIAM" loading="lazy"></picture>

*그림 3. External ID의 두 가지 구성*

- **B2B 협업**: 협력사 직원을 회사(워크포스) 테넌트에 게스트로 초대합니다. 예: 프로젝트 Teams에 참여
- **B2B direct connect**: 다른 회사 사용자가 회사 테넌트에서 게스트 계정 없이 씁니다. 예: Teams 공유 채널
- **고객용(CIAM, Customer Identity and Access Management)**: 일반 고객의 가입·로그인을 별도의 외부(External) 테넌트에서 다룹니다. 예: 쇼핑몰 회원가입, Google·Facebook 로그인, 브랜딩된 로그인 화면

실무 기준: 새 고객용 프로젝트는 External ID 외부 테넌트로 시작합니다. **2025-05-01부터** Azure AD B2C는 신규 고객에게 판매되지 않습니다.

<details markdown="1">
<summary>기존 Azure AD B2C 고객의 지원 일정</summary>

- 기존 고객은 계속 쓸 수 있고 최소 2030년 5월까지 지원됩니다.
- B2C P2는 2026-03-15에 단종되어 B2C 테넌트의 ID Protection 기능이 빠졌습니다.

</details>

관련 오류: [AADSTS50020: 게스트가 이 테넌트에 없는 계정으로 막힐 때]({{ "/iam/troubleshooting/aadsts50020-guest-not-in-tenant/" | relative_url }})

라이선스 단계, 로그, Graph PowerShell, 처음 테넌트를 맡았을 때 확인 순서는 [라이선스와 운영]({{ "/iam/entra-id-licensing-operations/" | relative_url }}) 글에 있습니다.

### 4. 확인 문제

<details markdown="1">
<summary>1. PTA를 쓰는 회사에 PHS도 켜 두라고 하는 이유 두 가지는?</summary>

① 사내 인프라 장애(예: 랜섬웨어) 때 PHS로 **수동 전환**해 클라우드 로그인을 살릴 수 있고, ② ID Protection이 **사내 사용자의 유출 자격 증명**을 탐지할 수 있습니다.

</details>

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- PHS·PTA·Federation 선택, PHS 권장 이유, 상태 반영 지연: [Choose the right authentication method](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn)
- Connect Sync와 Cloud Sync 비교: [Connect Sync → Cloud Sync decision guide](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/connect-to-cloud-sync-decision-guide)
- Cloud Sync 전환 통지, 기한, 예외: [Migrate to Cloud Sync with the migration tool](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/migrate-connect-sync-cloud-sync-tool)
- Entra 새 소식(Cloud Sync 전환 공지): [Microsoft Entra releases and announcements](https://learn.microsoft.com/entra/fundamentals/whats-new)
- B2C 판매 중단, External ID: [External ID FAQ](https://learn.microsoft.com/entra/external-id/customers/faq-customers)
- B2C P2 단종: [Azure AD B2C FAQ](https://learn.microsoft.com/azure/active-directory-b2c/faq)

</details>
