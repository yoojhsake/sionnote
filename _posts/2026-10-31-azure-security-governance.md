---
title: "[Study] Azure 보안과 거버넌스: RBAC, Policy, Defender"
date: 2026-10-31 10:12:00 +0900
categories: [study]
phase: 3단계 Azure
seq: 3
tags: [Study, Azure, RBAC, Azure Policy, Defender for Cloud, Key Vault, Managed identity]
excerpt: "Owner라도 Deny policy가 걸리면 리소스를 못 만듭니다. RBAC와 Policy, Lock, Key Vault, Managed identity 정리"
---

구독 Owner인데도 리소스가 만들어지지 않는다면 Deny policy를 먼저 의심해야 합니다. RBAC는 행위자를, Policy는 리소스 상태를 보기 때문입니다. 이번 주를 마치면 두 통제의 차이와 상속, Resource lock, Key Vault, Managed identity를 AD의 위임·GPO에 빗대어 설명할 수 있습니다.

## 요약

- 리소스가 안 만들어지면 역할보다 Deny policy를 먼저 확인함
- 역할은 하위로 상속되므로 가능한 한 좁은 scope에 할당함
- Key Vault 접근 제어는 레거시인 access policy보다 Azure RBAC가 권장됨

12주 학습 로드맵의 11주차입니다. 이전 글: [Azure 네트워크 기초]({{ "/study/azure-network-basics/" | relative_url }}), 다음 글: [모니터링과 통합·온보딩 시나리오]({{ "/study/azure-monitoring-onboarding/" | relative_url }}), 전체 로드맵: [클라우드 학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 이번 주 용어

Azure RBAC(Role definition·Role assignment·Scope), Owner·Contributor·Reader·User Access Administrator, Azure Policy(Definition·Initiative·Assignment·Effect), Audit·Deny·Modify·DeployIfNotExists, Resource lock(CanNotDelete·ReadOnly), Tags, Microsoft Defender for Cloud(CSPM·CWPP·Secure Score), Key Vault, Managed identity(System-assigned·User-assigned), Cost Management(Budget), Azure Advisor, Cloud Adoption Framework(CAF), Well-Architected Framework(WAF), Landing zone

### 2. 개념 설명

테넌트 실측 기록은 [Azure 구조 실습]({{ "/m365/d4-azure-structure/" | relative_url }}), PIM은 [조건부 액세스·PIM·ID Protection]({{ "/iam/entra-id-access-control/" | relative_url }})에 있습니다.

#### 권한과 표준

Azure RBAC는 보안 주체(user, group, service principal, managed identity)에게 role definition(역할)을 scope에 assignment(할당)합니다. 포털에서는 각 scope의 Access control (IAM) 화면입니다.

- 기본 역할: Owner(전체 권한 + 역할 할당), Contributor(전체 권한, 역할 할당 불가), Reader(보기만), User Access Administrator(접근 권한 관리)

Entra role과는 다른 체계입니다([2주차 글]({{ "/study/entra-id-directory-basics/" | relative_url }})의 표). Global Administrator가 구독 권한을 얻으려면 "Access management for Azure resources"로 상승(elevate)해야 합니다.

Azure Policy는 리소스가 조직 표준을 지키는지 평가하고 강제합니다. 여러 policy의 묶음이 Initiative이고, Effect는 Audit(감사만), Deny(생성 차단), Modify(속성 자동 수정), DeployIfNotExists(없으면 배포)가 있습니다.

Resource lock은 CanNotDelete(삭제 방지)와 ReadOnly(수정 방지)를 리소스, Resource group, 구독에 걸어 실수로 인한 삭제를 막습니다.

#### 보안 서비스와 신원

Defender for Cloud는 보안 상태 점검(CSPM)과 워크로드 보호(CWPP)를 제공하고, 점검 결과를 Secure Score와 권장 사항으로 보여 줍니다.

Key Vault는 비밀(secrets), 키(keys), 인증서(certificates)를 보관하고 인증서 수명주기 관리를 지원합니다.

- 문서: API 버전 2026-02-01부터는 새 key vault의 기본값도 Azure RBAC입니다([Azure RBAC vs. access policies](https://learn.microsoft.com/azure/key-vault/general/rbac-access-policy#data-plane-access-control-recommendation)).

비교(저자 의견): AD CS의 자동 등록(autoenrollment)과 비교하며 읽으면 이해가 빠릅니다.

Managed identity는 VM이나 앱이 비밀번호 없이 Entra ID 토큰으로 다른 Azure 리소스에 접근하는 신원입니다. System-assigned는 리소스 수명을 따르고, User-assigned는 따로 만들어 여러 리소스에 붙입니다.

#### 비용과 설계 프레임워크

비용은 Cost Management에서 Budget과 알림을 설정하고, Azure Advisor로 비용, 보안, 성능 권고를 받습니다. 설계 프레임워크는 셋입니다.

- CAF: 클라우드 도입 전반
- Well-Architected Framework: 워크로드 설계 품질(Reliability, Security, Cost Optimization, Operational Excellence, Performance Efficiency의 5개 pillar)
    - [10주차]({{ "/study/azure-network-basics/" | relative_url }})의 WAF(Web Application Firewall)와 다릅니다(문서: [What is the Azure Well-Architected Framework?](https://learn.microsoft.com/azure/well-architected/what-is-well-architected-framework)).
- Landing zone: 구독, 네트워크, 거버넌스를 미리 갖춘 기반 환경

### 3. 온프레미스로 번역하면

| Azure | 온프레미스 |
|---|---|
| RBAC | AD의 위임된 관리 권한 |
| Policy | GPO와 컴플라이언스 점검을 합친 개념 |
| Resource lock | "삭제 금지" 보호 설정 |
| Key Vault | HSM과 키 관리 서버의 클라우드 버전 |
| Managed identity | gMSA와 비슷한 역할 |

### 4. 실습 (GUI 우선)

1. Azure 포털 > 구독 > 액세스 제어(IAM) > 역할 할당 탭에서 역할 보유자와 상속 여부를 확인합니다.
2. 같은 화면의 역할(Roles) 탭에서 Owner, Contributor, Reader의 권한을 읽습니다.
3. 정책(Policy) > 정의(Definitions)에서 정책 목록과 effect를 보고, 준수(Compliance) 화면의 구성을 확인합니다.
4. Cost Management와 Defender for Cloud 개요(Secure Score)에 보이는 항목을 확인합니다.

### 5. 전문가처럼 말하기

> "RBAC는 who can do what, Policy는 what state is allowed입니다."
>
> "Landing zone으로 subscription, network, policy 기반을 먼저 갖추고, 워크로드는 Well-Architected Framework로 점검합니다."

### 6. 자가 점검

- [ ] RBAC의 role definition, role assignment, scope를 구분해서 설명할 수 있다.
- [ ] Owner와 Contributor의 차이를 말할 수 있다.
- [ ] RBAC와 Policy의 차이를 예와 함께 말할 수 있다.
- [ ] Policy effect 네 가지를 말할 수 있다.
- [ ] Managed identity를 쓰는 이유를 말할 수 있다.

<details markdown="1">
<summary>답 펼쳐 보기 (5문항)</summary>

- role definition·assignment·scope: role definition은 역할, scope는 적용 범위, role assignment는 보안 주체에게 역할을 scope에 붙인 것입니다.
- Owner와 Contributor: 둘 다 전체 권한이지만 Owner만 역할 할당을 할 수 있습니다.
- RBAC와 Policy: RBAC는 행위자를, Policy는 리소스 상태를 봅니다. 예: Owner라도 Deny policy가 걸린 리소스는 만들 수 없습니다.
- Policy effect 네 가지: Audit, Deny, Modify, DeployIfNotExists입니다.
- Managed identity: 비밀번호 없이 Entra ID 토큰으로 다른 Azure 리소스에 접근하기 위해 씁니다.

</details>

### 7. 영상·자료 (한글 우선)

- 한글: Microsoft Korea의 [Azure 교육·웨비나 페이지](https://www.microsoft.com/ko-kr/azureall)에서 보안, 거버넌스 주제를 찾아 보세요. Azure RBAC와 Policy 한글 유튜브는 확인 불가입니다(유튜브 검색으로 찾지 못함).
- 영문 보완: AZ-104 공식 시리즈(Microsoft Learn, 전 29편)의 [5편 Azure Policy initiatives](https://www.youtube.com/watch?v=XGL-8ZaBU4s), [6편 Azure RBAC](https://www.youtube.com/watch?v=uk8xwyudb1k). [AZ-104 Full Course - 12 Hours](https://www.youtube.com/watch?v=qXk8_0z_HsU)는 첫 모듈(Manage Azure identities and governance)이 0:27부터입니다.
