---
title: "[Study] Azure·M365 클라우드 입문: 학습 로드맵과 사용법"
date: 2026-10-31 10:00:00 +0900
categories: [study]
phase: 학습 로드맵
seq: 1
tags: [Study, Azure, Microsoft 365, Entra ID, 학습 로드맵]
excerpt: "AD는 익숙한데 클라우드는 낯설다면, 하루 30분 12주로 Entra ID·M365·Azure 구조를 전문 용어로 설명하게 됩니다"
---

온프레미스 AD·PKI 경험을 발판으로 하루 30분씩 12주를 따라가면, Microsoft Entra ID, Microsoft 365, Azure의 구조를 이해하고 전문 용어로 설명할 수 있게 됩니다. 시험 합격보다 "왜 이렇게 생겼는지" 말할 수 있는 것이 목표입니다.

## 요약

- Entra ID 테넌트가 신원의 경계. M365는 그 위의 SaaS, Azure는 같은 테넌트에 연결된 구독 아래의 플랫폼
- 목표는 시험 합격이 아니라 구조를 이해하고 전문 용어로 설명하기
- 하루 30분, 12주. 0주차(기초) → 1단계 구조와 신원 → 2단계 Microsoft 365 → 3단계 Azure 순
- 아래 글 목록을 순서대로 읽고 매주 끝에 진도 체크리스트 채우기

> 원문: 직접 만든 "Azure·M365 클라우드 입문 학습서" v1.0(2026-10-31)을 블로그 글로 옮긴 것입니다. 이 글은 12주 학습 로드맵의 시작 글이고, 다음 글은 [기초 개념과 핵심 용어 (0주차)]({{ "/study/cloud-basics-key-terms/" | relative_url }})입니다.

---

## 전체 내용

### 1. 시리즈 글 목록

16편을 위에서부터 순서대로 읽습니다.

**학습 로드맵**

- **학습 로드맵과 사용법** (지금 보는 글)
- [기초 개념과 핵심 용어 (0주차)]({{ "/study/cloud-basics-key-terms/" | relative_url }})

**1단계 구조와 신원**

- [클라우드 구조: Tenant, Subscription, Resource group (1주차)]({{ "/study/cloud-structure-tenant-subscription/" | relative_url }})
- [Entra ID 기본 (2주차)]({{ "/study/entra-id-directory-basics/" | relative_url }})
- [하이브리드 ID (3주차)]({{ "/study/hybrid-identity-study/" | relative_url }})
- [인증 보안: MFA, Conditional Access, PIM (4주차)]({{ "/study/auth-security-mfa-ca-pim/" | relative_url }})

**2단계 Microsoft 365**

- [M365 관리 센터 (5주차)]({{ "/study/m365-admin-center-basics/" | relative_url }})
- [Exchange Online (6주차)]({{ "/study/exchange-online-basics/" | relative_url }})
- [SharePoint·OneDrive·Teams 구조 (7주차)]({{ "/study/sharepoint-onedrive-teams-structure/" | relative_url }})
- [Intune 디바이스 관리 (8주차)]({{ "/study/intune-device-management/" | relative_url }})

**3단계 Azure**

- [컴퓨팅·스토리지 (9주차)]({{ "/study/azure-compute-storage/" | relative_url }})
- [네트워크 (10주차)]({{ "/study/azure-network-basics/" | relative_url }})
- [보안·거버넌스 (11주차)]({{ "/study/azure-security-governance/" | relative_url }})
- [모니터링·통합 (12주차)]({{ "/study/azure-monitoring-onboarding/" | relative_url }})

**부록**

- [온프레미스 ↔ 클라우드 대응표, 옛 이름 ↔ 새 이름]({{ "/study/onprem-cloud-mapping/" | relative_url }})
- [용어 전집과 영상·자료]({{ "/study/cloud-study-glossary/" | relative_url }})

Entra ID를 더 깊게 보려면 [IAM 시리즈: Microsoft Entra ID 핵심 개념]({{ "/iam/what-is-entra-id/" | relative_url }})을 함께 보세요. 신원 용어는 [IAM 용어집]({{ "/iam/entra-id-glossary/" | relative_url }})에도 정리돼 있습니다.

### 2. 큰 그림

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/10/study-big-picture-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/10/study-big-picture.png" | relative_url }}" alt="구조도: Tenant가 신원의 경계이고 M365와 Azure가 그 위에 올라탄다" loading="lazy"></picture>

*그림 1. 구조도: Tenant가 신원의 경계이고 M365와 Azure가 그 위에 올라탄다*

한 문장으로 줄이면 이렇습니다.

> Entra ID 테넌트가 신원의 경계이고, M365는 그 위에서 구독하는 SaaS, Azure는 같은 테넌트에 연결된 구독 아래에서 리소스를 배포하는 플랫폼입니다.

Tenant(Microsoft Entra ID 디렉터리)는 신원의 경계입니다. 사용자, 그룹, 디바이스, 앱 같은 객체와 MFA, Conditional Access 같은 보호 기능이 여기에 있습니다.

Microsoft 365는 SaaS입니다. 구독(license)을 사서 테넌트의 사용자에게 service plan 단위로 할당합니다. Azure는 IaaS·PaaS입니다. Subscription이 하나의 Tenant를 신뢰(trust)하고, 그 아래에 Resource group과 Resource를 만듭니다.

온프레미스 AD DS는 Entra Connect Sync 또는 Cloud Sync로 Tenant와 동기화합니다. 이것이 hybrid identity입니다.

### 3. 12주 로드맵

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/10/study-roadmap-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/10/study-roadmap.png" | relative_url }}" alt="12주 로드맵" loading="lazy"></picture>

*그림 2. 12주 로드맵*

#### 기초 (0주차)

| 주차 | 주제 | 주차 끝에 만들 것 |
|---|---|---|
| 0 | 기초 개념과 핵심 용어 | 핵심 용어 30개를 뜻으로 말하기 |

#### 1단계 구조와 신원 (1~4주차)

| 주차 | 주제 | 주차 끝에 만들 것 |
|---|---|---|
| 1 | 클라우드 구조 | Tenant → Subscription → Resource group 계층 그림 |
| 2 | Entra ID 기본 | AD DS와 Entra ID 비교표 |
| 3 | 하이브리드 ID | PHS·PTA·Federation 비교 설명 |
| 4 | 인증 보안 | Conditional Access 정책 설계 한 장 |

#### 2단계 Microsoft 365 (5~8주차)

| 주차 | 주제 | 주차 끝에 만들 것 |
|---|---|---|
| 5 | M365 관리 센터 | 라이선스·도메인·관리자 역할 정리 |
| 6 | Exchange Online | 메일 흐름 그림 (MX → EOP → 사서함) |
| 7 | SharePoint·OneDrive·Teams | Team 구성요소 지도 |
| 8 | Intune | GPO ↔ Intune 대응표 |

#### 3단계 Azure (9~12주차)

| 주차 | 주제 | 주차 끝에 만들 것 |
|---|---|---|
| 9 | 컴퓨팅·스토리지 | Redundancy 선택 기준표 |
| 10 | 네트워크 | Hub-and-spoke 그림 |
| 11 | 보안·거버넌스 | RBAC vs Policy 구분 설명 |
| 12 | 모니터링·통합 | 신규 입사자 온보딩 3분 설명 |

### 4. 이 시리즈 사용법

#### 무엇을 목표로 하나

시험 합격이 아니라 **구조를 이해하고 전문 용어로 설명하는 것**이 목표입니다. 그래서 용어는 쉬운 말로 풀지 않고 영어 원어와 약어를 그대로 익힙니다. 한글 풀이는 이해용 보조입니다. 한 번에 다 알 수는 없으니 하루 30분을 12주 동안 이어 가는 것을 기본 규칙으로 합니다.

#### 하루 30분 루틴

- 10분 읽기: 이번 주 용어와 개념 설명 읽기
- 15분 보기 또는 실습: 영상 한 편, 포털 화면 열어 보기, 캡처 남기기
- 5분 한 줄 정리: 온프레미스 말로 번역해 적기
    - 예: "Entra ID의 Group은 AD의 Security Group에 해당하지만 OU 계층은 없다"

지치지 않으려고 정한 규칙도 있습니다. 주 3일은 평일 30분, 주말에 1시간 복습합니다. 빠진 날은 따라잡지 않고 다음 날 이어서 합니다.

- 15분 넘게 막히면 모르는 용어를 [용어 전집]({{ "/study/cloud-study-glossary/" | relative_url }})에 표시하고 넘어갑니다. 같은 용어를 다시 만나면 풀립니다.

#### 전문가처럼 말하기 5가지 규칙

1. 약어는 처음 한 번 풀네임과 함께, 이후에는 약어로 말합니다.
    - "Password Hash Synchronization, 줄여서 PHS는 ... 이므로 PHS 환경에서는 ..."
2. 영어 원어를 기억하고 한글은 설명용으로 씁니다.
    - 한글 번역은 문서마다 다릅니다. 예를 들어 Conditional Access는 "조건부 액세스", "조건부 접근"으로 혼용됩니다.
3. 옛 이름과 새 이름을 구분해서 말합니다.
    - Azure AD는 Microsoft Entra ID로 바뀌었습니다. [옛 이름 ↔ 새 이름 매핑표]({{ "/study/onprem-cloud-mapping/" | relative_url }})가 있습니다.
4. 구조는 계층 순서로 말합니다.
    - "Tenant 아래에 Subscription, 그 아래에 Resource group, 그 안에 Resource가 있습니다."
5. 선택지는 **trade-off**로 말합니다.
    - "PHS는 단순하고 온프레미스 장애에도 로그인이 되지만, 비밀번호 해시는 약 2분마다 동기화되는 반면 비활성화 같은 계정 상태는 정기 동기화 주기(기본 30분)를 따라 최대 30분 늦게 반영됩니다. 즉시 반영이 필요하면 PTA를 검토합니다."

문장 틀을 하나 외워 두면 편합니다.

> X는 Y 용도로 쓰고, 온프레미스의 Z에 해당합니다. 다만 W가 다르기 때문에 ~할 때는 ~를 선택합니다.

#### 실습 안전 원칙

- 샌드박스(개발자 프로그램 테넌트)에서는 **변경은 가능하지만 삭제와 비용이 생기는 작업은 하지 않습니다.** 비용이 생기는 실습은 강의와 문서로 대체합니다.
- 보안 정책은 항상 보기부터, 만들 때는 report-only부터 시작합니다.
    - 관리자 계정이 잠기지 않도록 emergency access 계정은 제외합니다.
- 화면 캡처는 확대해도 선명한 고해상도로 남기고, 외부에 공개할 때만 개인·비공개 정보를 가립니다.
- GUI로 먼저 확인하고, GUI로 안 되는 것만 PowerShell을 씁니다.
    - 스크립트는 전체를 그대로 기록하고 결과는 직접 실행해서 캡처합니다.

#### 글 구성

0주차와 12주 커리큘럼으로 이루어지고, 원문 학습서의 매 주차는 같은 순서로 구성됩니다.

- "핵심 한 줄" → 이번 주 용어 → 개념 설명 → 온프레미스로 번역하면 → 실습 → 영상 → 전문가처럼 말하기 → 자가 점검

블로그에서는 원문의 "핵심 한 줄"을 요약 맨 앞에 두고, 영상과 자료를 글 끝으로 옮겼습니다.

### 5. 진도 체크리스트

각 주차의 자가 점검을 모두 체크하면 그 주차를 마친 것입니다. 시작일과 완료일은 직접 적으세요.

- [ ] 0주차 기초 개념과 핵심 용어. 산출물: 용어 카드 30장, 시작일: ____, 완료일: ____
- [ ] 1주차 클라우드 구조. 산출물: 계층 그림, 시작일: ____, 완료일: ____
- [ ] 2주차 Entra ID 기본. 산출물: AD DS vs Entra ID 비교표, 시작일: ____, 완료일: ____
- [ ] 3주차 하이브리드 ID. 산출물: PHS·PTA·Federation 비교, 시작일: ____, 완료일: ____
- [ ] 4주차 인증 보안. 산출물: CA 정책 설계 한 장, 시작일: ____, 완료일: ____
- [ ] 5주차 M365 관리 센터. 산출물: 라이선스·도메인·역할 정리, 시작일: ____, 완료일: ____
- [ ] 6주차 Exchange Online. 산출물: 메일 흐름 그림, 시작일: ____, 완료일: ____
- [ ] 7주차 SharePoint·OneDrive·Teams. 산출물: Team 구성요소 지도, 시작일: ____, 완료일: ____
- [ ] 8주차 Intune. 산출물: GPO ↔ Intune 대응표, 시작일: ____, 완료일: ____
- [ ] 9주차 컴퓨팅·스토리지. 산출물: Redundancy 선택표, 시작일: ____, 완료일: ____
- [ ] 10주차 네트워크. 산출물: Hub-and-spoke 그림, 시작일: ____, 완료일: ____
- [ ] 11주차 보안·거버넌스. 산출물: RBAC vs Policy 설명, 시작일: ____, 완료일: ____
- [ ] 12주차 모니터링·통합. 산출물: 3분 설명, 시작일: ____, 완료일: ____

매주 체크할 것도 있습니다.

- [ ] 이번 주 용어를 용어 전집에서 한 번씩 소리 내어 설명했다.
- [ ] 실습 화면을 고해상도로 캡처해서 기록했다.
- [ ] "온프레미스로 번역하면" 한 줄을 직접 적었다.
- [ ] 전문가처럼 말하기 문장을 소리 내어 읽고 내 말로 바꿔 보았다.

### 6. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (2건)</summary>

- 문서: [Choose the right authentication method: Cloud authentication, Password hash synchronization](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn). PHS는 2분마다 실행, 계정 상태는 동기화될 때까지 반영되지 않음, 비활성화 계정 최대 30분 지연
- 문서: [Microsoft Entra Connect Sync: Scheduler](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-sync-feature-scheduler). 기본 동기화 주기 30분

</details>
