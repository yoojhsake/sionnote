---
title: "[Study] Entra ID 기본: Directory, User, Group, Role"
date: 2026-10-31 10:03:00 +0900
categories: [study]
phase: 1단계 구조와 신원
seq: 2
tags: [Study, Entra ID, User, Group, Administrative unit, Entra role]
excerpt: "Entra ID에는 OU도 GPO도 없습니다. 위임은 AU와 Entra role로, Azure 권한은 RBAC로 따로 갑니다"
---

AD DS를 오래 다뤘다면 Entra ID에서도 OU와 GPO부터 찾게 됩니다. Entra ID에는 둘 다 없고 위임은 Administrative unit과 Entra role로 하며, Global Administrator라도 기본값으로는 Azure 리소스 권한이 없다는 점까지 이번 주에 구분합니다.

## 요약

- Entra ID는 계층 없는 flat directory이며 AU는 정책이 아닌 위임 범위임
- 동기화된 계정의 주요 속성은 원본인 온프레미스에서 바꿔야 함
- Entra role과 Azure RBAC는 별개라 Global Administrator도 기본값으론 Azure 권한이 없음

12주 학습 로드맵의 2주차입니다. 이전 글은 [1주차 클라우드 구조]({{ "/study/cloud-structure-tenant-subscription/" | relative_url }}), 다음 글은 [3주차 하이브리드 ID]({{ "/study/hybrid-identity-study/" | relative_url }})이고, 전체 계획은 [학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})에 있습니다.

---

## 전체 내용

### 1. 이번 주 용어

Microsoft Entra ID, Directory, User(Member, Guest), Cloud-only user, Synced user, Source of authority, Group(Security, Microsoft 365), Assigned/Dynamic membership, Administrative unit(AU), Entra role, Global Administrator, Initial domain, Custom domain, UPN, Object ID, Device identity

### 2. 개념 설명

테넌트, 개체, 디바이스, 앱 등록의 자세한 설명과 예시는 [IAM 기초와 구조 편]({{ "/iam/what-is-entra-id/" | relative_url }})에 있습니다.

User는 Member와 Guest로 나뉩니다. 온프레미스에서 동기화된 계정은 Synced user, 클라우드에서 직접 만든 계정은 Cloud-only user입니다. Synced user는 온프레미스가 Source of authority(객체를 관리하는 곳)라서 주요 속성을 클라우드에서 바꿀 수 없습니다.

Group은 Security group과 Microsoft 365 group(협업용: 메일, Teams, SharePoint)으로 나뉩니다. 멤버십 유형은 Assigned(직접 지정)와 Dynamic(규칙 기반, Entra ID P1 필요)입니다.

Administrative unit(AU)은 관리 권한을 일부 객체에만 위임하는 범위이고, OU와 달리 GPO가 연결되지 않습니다.

도메인은 처음 만들어지는 `*.onmicrosoft.com`(initial domain)과, DNS TXT로 소유를 확인해 추가하는 custom domain이 있습니다. Device identity는 세 가지입니다.

- Entra registered: BYOD
- Entra joined: 조직 소유 클라우드 네이티브
- Entra hybrid joined: 온프레미스 AD 도메인 가입 + Entra 등록

#### Entra role과 Azure RBAC

- **Entra role**
    - 관리 대상: Entra 리소스(사용자, 그룹, 앱), M365 서비스
    - Scope: Tenant, Administrative unit, 개별 객체
    - 확인 위치: Entra 관리 센터, M365 관리 센터, Microsoft Graph
- **Azure RBAC role**
    - 관리 대상: Azure 리소스(VM·Storage 등)
    - Scope: Management group, Subscription, Resource group, Resource
    - 확인 위치: Azure 포털의 Access control (IAM), ARM

두 체계는 기본적으로 겹치지 않습니다. 예외로 Global Administrator가 "Access management for Azure resources"를 켜면 Azure의 루트 범위(`/`)에서 User Access Administrator 역할을 얻어, 테넌트의 모든 구독과 관리 그룹에서 역할을 할당할 수 있습니다(구독 접근 복구용). 이 설정은 켠 사용자 본인에게만 적용되고, 작업을 마치면 다시 끄라고 문서는 권고합니다. 이 토글(Elevate access)을 실제로 켜고 끈 전·후 비교는 [Azure 구조 실습 기록]({{ "/m365/d4-azure-structure/" | relative_url }})에 있습니다.

### 3. 온프레미스로 번역하면

| 항목 | AD DS | Entra ID |
|---|---|---|
| 구조 | 계층 (Forest, Domain, OU) | Flat. 하나의 Tenant 안에 객체가 평면으로 존재 |
| 프로토콜 | Kerberos, NTLM, LDAP | OAuth 2.0, OIDC, SAML, WS-Federation, 관리는 REST (Microsoft Graph) |
| 정책 | GPO | Conditional Access, Intune 정책 |
| 위임 | OU 위임 | Administrative Unit + Entra role |
| 외부 연동 | Trust | B2B collaboration, cross-tenant access |
| 디바이스 | Domain join | Entra registered, joined, hybrid joined |

Administrative unit은 위임용 OU와 비슷하지만 정책 상속이 없습니다. 앱 등록(App registration)은 서비스 계정과 SPN을 등록하는 일과 비슷한 개념입니다.

### 4. 실습 (GUI 우선)

1. Entra 관리 센터 왼쪽 메뉴의 ID(또는 Entra ID) > 사용자 > 모든 사용자에서 목록을 보고, 사용자 한 명의 속성(Object ID, UPN, 사용자 유형)을 확인합니다. 메뉴 이름은 업데이트로 조금씩 바뀔 수 있습니다.
2. 테스트용 사용자 `lab-user01`과 보안 그룹을 만들어 봅니다. 삭제는 하지 않습니다.
3. 그룹에서 멤버십 유형(Assigned, Dynamic)을 확인합니다. Dynamic은 P1이 없으면 선택이 제한될 수 있습니다.
4. 역할 및 관리자(Roles & admins)에서 Global Administrator 목록과 역할 수를 봅니다.
5. 도메인 이름(Domain names)에서 initial domain과 custom domain을 구분합니다.
6. 장치(Devices) 화면에서 Join type 열을 확인합니다.

```powershell
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","Domain.Read.All"
Get-MgOrganization | Select-Object DisplayName, Id
Get-MgDomain | Select-Object Id, IsDefault, IsVerified
Get-MgUser -Top 5 -Property DisplayName,UserPrincipalName,OnPremisesSyncEnabled | Select-Object DisplayName, UserPrincipalName, OnPremisesSyncEnabled
```

사용자와 그룹을 실제 테넌트에서 만들고 확인한 기록은 [Entra 사용자·그룹 실습]({{ "/m365/d2-identity-groups/" | relative_url }})에 있습니다.

### 5. 전문가처럼 말하기

> "Entra ID는 AD DS의 클라우드 버전이 아니라 OAuth 2.0과 OIDC 기반의 flat directory라서 OU나 GPO가 없고, 위임은 administrative unit과 Entra role로 합니다."
>
> "Entra role은 디렉터리와 M365를, Azure RBAC은 Azure 리소스를 다루는 별개의 권한 체계입니다. Global Administrator라도 기본값으로는 Azure 구독 권한이 없습니다."

### 6. 자가 점검

<details markdown="1">
<summary>자가 점검 문제와 답 펼쳐 보기 (4문항)</summary>

- [ ] Synced user의 속성을 클라우드에서 못 바꾸는 이유(source of authority)를 설명할 수 있다.
    - 답: 동기화된 계정은 온프레미스가 source of authority라서, 주요 속성은 온프레미스에서 바꿔야 합니다.
- [ ] Administrative unit과 OU의 차이를 말할 수 있다.
    - 답: AU는 관리 권한을 위임하는 범위일 뿐 정책 적용 단위가 아닙니다. OU와 달리 GPO가 연결되지 않고 정책 상속이 없습니다.
- [ ] Entra role과 Azure RBAC role을 구분해서 예를 들 수 있다.
    - 답: Entra role은 사용자, 그룹, 앱과 M365 서비스를(예: Global Administrator), Azure RBAC role은 VM, Storage 같은 Azure 리소스를(예: User Access Administrator) 다룹니다.
- [ ] Entra registered, joined, hybrid joined의 차이를 표 없이 말할 수 있다.
    - 답: registered는 BYOD, joined는 조직 소유 클라우드 네이티브 기기, hybrid joined는 온프레미스 AD 도메인에 가입한 기기를 Entra에도 등록한 것입니다.

</details>

### 7. 영상 (한글 우선)

- 한글: 확인 불가(시도: 유튜브 검색, 사유: Entra ID 기초를 다룬 한글 영상을 찾지 못함). 대신 [Microsoft Entra 도입(Adoption) 허브(한국어)](https://adoption.microsoft.com/ko-kr/microsoft-security/entra/)와 Microsoft Learn의 [Manage identity and access in Microsoft Entra ID 학습 경로](https://learn.microsoft.com/training/paths/manage-identity-and-access/)를 먼저 읽으세요.
- 영문 보완: [Understand Microsoft Entra ID (AZ-104 공식 시리즈 2편)](https://www.youtube.com/watch?v=iQfhi0712bM) (Microsoft Learn, 42분). 테넌트, 사용자, 그룹, 라이선스, Free·P1·P2 차이를 다룹니다.

### 8. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (1건)</summary>

- 문서: [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin): 토글을 켜면 루트 범위(`/`)에 User Access Administrator가 할당됨, 사용자별 설정, 작업 후 제거 권고

</details>
