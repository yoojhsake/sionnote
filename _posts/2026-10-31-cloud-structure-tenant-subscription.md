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
4. 관리 그룹(Management groups) 화면에서 Tenant Root Group을 확인합니다. 루트 관리 그룹 권한이 없으면 전역 관리자라도 화면 위에 "디렉터리 관리자로 등록되었지만 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다" 안내가 뜨고, Tenant Root Group을 누르면 "이 관리 그룹을 볼 수 있는 권한이 없습니다"가 나옵니다(실제 화면은 [Azure 구조 실습 기록]({{ "/m365/d4-azure-structure/" | relative_url }})의 그림 3, Elevate 전 상태).
    - 문서에 따르면 루트 관리 그룹에는 기본 접근 권한을 가진 사람이 없고, 전역 관리자만 Elevate access로 자신을 올려 접근할 수 있습니다.

PowerShell로도 확인합니다. 구독이 없으면 포털 화면 구성만 보고 문서로 대체합니다.

```powershell
# 모듈 설치 (한 번만). 회사 PC에서 사용자 폴더 모듈이 정책에 막히면 관리자 창에서 -Scope AllUsers로 설치합니다(사례: 회사 PC 모듈 글)
Install-Module Az -Scope CurrentUser

Connect-AzAccount
Get-AzTenant | Format-List
Get-AzSubscription | Select-Object Name, Id, TenantId, State
Get-AzResourceGroup | Select-Object ResourceGroupName, Location
```

실제 테넌트에서 확인한 결과(상위 범위 역할 상속 비교, 관리 그룹 권한 안내, Elevate access 전·후)는 [Azure 구조 실습 기록]({{ "/m365/d4-azure-structure/" | relative_url }})에 있습니다.

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
