---
title: "[Study] 클라우드 구조: Tenant, Subscription, Resource group"
date: 2026-10-31 10:02:00 +0900
categories: [study]
phase: 1단계 구조와 신원
seq: 1
tags: [Study, Azure, Tenant, Subscription, Resource group]
excerpt: "권한은 어디서 내려올까요? Tenant부터 Resource까지 다섯 층 계층과 RBAC, Policy 상속을 익힙니다"
---

구독, 리소스 그룹, 관리 그룹이 어떤 순서로 겹쳐 있는지 알면 Azure 권한이 어디서 내려오는지 바로 보입니다. 이번 주에는 Tenant → Management group → Subscription → Resource group → Resource 다섯 층과, RBAC와 Policy가 위에서 아래로 상속되는 규칙을 익힙니다.

## 요약

- 권한과 표준은 다섯 층 계층을 따라 위에서 아래로 상속됨
- 포털에서 계층을 위에서부터 차례로 열어 보고 PowerShell로도 확인함
- Resource group을 지우면 안의 리소스도 함께 삭제됨

12주 학습 로드맵의 1주차입니다. 이전 글은 [0주차 클라우드 기초 용어]({{ "/study/cloud-basics-key-terms/" | relative_url }}), 다음 글은 [2주차 Entra ID 기본]({{ "/study/entra-id-directory-basics/" | relative_url }})이고, 전체 계획은 [학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})에 있습니다.

---

## 전체 내용

### 1. 이번 주 용어

Tenant, Subscription, Management group, Resource group, Resource, ARM(Azure Resource Manager), Region, Availability Zone, IaaS, PaaS, SaaS, Shared responsibility model

IaaS, PaaS, SaaS와 Shared responsibility model은 [0주차]({{ "/study/cloud-basics-key-terms/" | relative_url }})에서 다뤘습니다.

### 2. 개념 설명

Tenant는 Entra ID 디렉터리의 인스턴스이고, Microsoft 365와 Azure 구독이 같은 Tenant의 신원을 씁니다.

Subscription은 청구(billing), 접근 관리(access management), 한도(quota)의 경계입니다. 구독은 하나의 Tenant를 신뢰하고, 한 Tenant에 여러 구독을 둘 수 있습니다. 여러 구독을 묶어 정책과 권한을 한 번에 적용하는 단위가 Management group입니다.

Resource group은 같은 수명주기를 가진 리소스를 담는 논리적 컨테이너이고, 리소스는 정확히 하나의 Resource group에 속합니다.

ARM(Azure Resource Manager)은 포털, CLI, PowerShell, SDK, 템플릿이 모두 거치는 공통 관리 계층이라, 포털 작업과 PowerShell 결과가 같습니다.

Region은 지리적 지역이고, Availability Zone(AZ)은 한 Region 안에서 전원과 네트워크가 분리된 데이터센터입니다.

### 3. 온프레미스로 번역하면

| Azure | 온프레미스에서 비슷한 것 | 다른 점 |
|---|---|---|
| Tenant | AD 포리스트 | 프로토콜이 Kerberos가 아니라 OAuth 2.0, OIDC |
| Subscription | 부서별 예산, 계약 단위 | 접근, 한도 경계를 겸함 |
| Management group | 최상위 OU | 정책(Policy)과 RBAC가 상속됨 |
| Resource group | 서버 그룹 폴더 | 삭제하면 내용물이 같이 삭제됨 |
| ARM | 단일 관리 API | 모든 도구가 같은 API를 호출 |

### 4. 실습 (GUI 우선)

1. Entra 관리 센터(entra.microsoft.com) 개요(Overview)에서 Tenant ID와 기본 도메인(primary domain)을 확인하고 캡처합니다.
2. Azure 포털(portal.azure.com) 구독(Subscriptions) 개요에서 Subscription ID와 디렉터리(Directory)를 확인합니다.
3. 리소스 그룹(Resource groups) 목록과 한 그룹 안의 리소스를 봅니다.
4. 관리 그룹(Management groups) 화면에서 Tenant Root Group을 확인합니다. 루트 관리 그룹 권한이 없으면 전역 관리자라도 화면 위에 "디렉터리 관리자로 등록되었지만 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다" 안내가 뜨고, Tenant Root Group을 누르면 "이 관리 그룹을 볼 수 있는 권한이 없습니다"가 나옵니다(실제 화면은 아래 실습 기록의 Elevate 전 캡처).
    - 문서에 따르면 루트 관리 그룹에는 기본 접근 권한을 가진 사람이 없고, 전역 관리자만 Elevate access로 자신을 올려 접근할 수 있습니다.

PowerShell로도 확인합니다. 구독이 없으면 포털 화면 구성만 보고 문서로 대체합니다.

```powershell
# 모듈 설치 (한 번만)
Install-Module Az -Scope CurrentUser

Connect-AzAccount
Get-AzTenant | Format-List
Get-AzSubscription | Select-Object Name, Id, TenantId, State
Get-AzResourceGroup | Select-Object ResourceGroupName, Location
```

실제 테넌트에서 확인한 결과(상위 범위 역할 상속 비교, 관리 그룹 권한 안내, Elevate access 전·후)는 [Azure 구조 실습 기록]({{ "/m365/d4-azure-structure/" | relative_url }})에 있습니다.

<details markdown="1">
<summary>화면으로 경로 따라가기: Tenant, 구독, 리소스 그룹, 관리 그룹 (그림 5장)</summary>

![Entra 관리 센터의 개요 화면. 기본 정보와 Microsoft Entra Connect 카드]({{ "/assets/images/2026/11/guide-entra-overview.png" | relative_url }})

*그림 1. Entra 관리 센터 > Entra ID > 개요(Overview). 기본 정보에 이름, 테넌트 ID, 주 도메인, 라이선스(Microsoft Entra ID P2)와 사용자, 그룹, 애플리케이션, 디바이스 수가 나옵니다. 오른쪽 아래 Microsoft Entra Connect 카드는 "사용 안 함, 동기화 실행된 적 없음"입니다. 이름, 테넌트 ID, 주 도메인, 로그인한 사용자는 가렸습니다.*

![Azure 포털의 구독 목록]({{ "/assets/images/2026/11/guide-azure-subscriptions.png" | relative_url }})

*그림 2. Azure 포털 > 구독. 구독 이름, 구독 ID, 내 역할(소유자), 현재 비용, 부모 관리 그룹(Tenant Root Group)이 나옵니다. 안내문이 현재 디렉터리의 구독만 보인다고 알리고, 다른 디렉터리의 구독은 "디렉터리 전환"으로 봅니다. 구독 이름과 ID, 디렉터리 이름은 가렸습니다.*

![구독 개요 화면. 구독 ID, 디렉터리, 부모 관리 그룹]({{ "/assets/images/2026/11/guide-azure-subscription-overview.png" | relative_url }})

*그림 3. 구독 > 개요. 기본 정보에 구독 ID, 디렉터리, 상태, 부모 관리 그룹이 있고, 오른쪽에 내 역할(소유자)과 플랜이 있습니다. 부모 관리 그룹이 테넌트 루트 그룹이고 그 ID는 테넌트 ID와 같습니다. 이름과 ID 값은 가렸습니다.*

![Azure 포털의 리소스 그룹 목록]({{ "/assets/images/2026/11/guide-azure-resource-groups.png" | relative_url }})

*그림 4. Azure 포털 > 리소스 그룹. 이름, 구독, 위치가 나옵니다. 이 샌드박스에는 그룹이 3개 있습니다. 그룹 이름을 누르면 그 안의 리소스를 봅니다. 구독 이름은 가렸습니다.*

![관리 그룹 화면. Tenant Root Group과 구독, 루트 관리 그룹 접근 권한 안내]({{ "/assets/images/2026/11/guide-azure-management-groups.png" | relative_url }})

*그림 5. Azure 포털 > 관리 그룹. Tenant Root Group 아래에 구독이 놓인 구조가 보입니다. 파란 안내가 "디렉터리 관리자로 등록되었지만, 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다"라고 알립니다. 본문 4번에서 말한 바로 그 화면입니다. ID와 구독 이름은 가렸습니다.*

화면은 설정을 바꾸지 않고 샌드박스 테넌트에서 열어 캡처했습니다. 테넌트 이름과 ID, 계정, 구독 이름과 ID는 가렸고, 라이선스와 지역에 따라 메뉴 이름과 값은 다를 수 있습니다.

</details>

### 5. 전문가처럼 말하기

> "Subscription은 billing boundary이자 access boundary라서, 환경(개발·운영)이나 부서 단위로 나누는 경우가 많습니다."

### 6. 자가 점검

<details markdown="1">
<summary>자가 점검 문제와 답 펼쳐 보기 (4문항)</summary>

- [ ] 한 Tenant에 구독이 여러 개일 수 있는 이유를 설명할 수 있다.
    - 답: 구독은 청구, 접근 관리, 한도의 경계라서, 같은 Tenant의 신원을 쓰면서 환경(개발·운영)이나 부서 단위로 나눌 수 있습니다.
- [ ] 리소스가 정확히 하나의 Resource group에 속한다는 것의 의미를 말할 수 있다.
    - 답: Resource group은 같은 수명주기를 가진 리소스의 컨테이너라서, 그룹을 지우면 안의 리소스도 함께 지워집니다.
- [ ] 포털에서 한 작업이 PowerShell과 결과가 같은 이유(ARM)를 설명할 수 있다.
    - 답: 포털, CLI, PowerShell, SDK, 템플릿이 모두 ARM이라는 같은 관리 계층(API)을 거치기 때문입니다.
- [ ] Region과 Availability Zone의 차이를 말할 수 있다.
    - 답: Region은 지리적 지역이고, Availability Zone은 한 Region 안에서 전원과 네트워크가 분리된 데이터센터입니다.

</details>

### 7. 영상 (한글 우선)

- 한글: [Az-900 Azure Fundamentals 1주차](https://www.youtube.com/watch?v=GgKAkAWLnPw) (Microsoft Developer Korea, 1시간 38분, 2021년). 클라우드 개념(IaaS·PaaS·SaaS, 리전, 가용성, 소비 기반 요금). 서비스 이름과 화면이 지금과 다를 수 있습니다.
- 한글: [마이크로소프트 Azure 900 자격증, 함께 공부해 볼까요?](https://www.youtube.com/watch?v=iFWMKPnXMbo) (투마일스, 25분, 2022년). 클라우드 컴퓨팅이란, Azure란, 핵심 Azure 서비스, Azure 계정 순서입니다.
- 영문 보완: [AZ-900 Course introduction](https://www.youtube.com/watch?v=orwWx0_KEcA) (Microsoft Learn, 3분, 과정 소개), AZ-104 공식 시리즈의 [4편 Describe the core architectural components of Azure](https://www.youtube.com/watch?v=9dZK_d-nZp8) (40분)

### 8. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (1건)</summary>

- 문서: [What are Azure management groups? (Root management group for each directory)](https://learn.microsoft.com/azure/governance/management-groups/overview#root-management-group-for-each-directory). 루트 관리 그룹의 기본 접근 권한과 Elevate access

</details>
