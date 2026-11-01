---
title: "[Study] 기초 개념과 핵심 용어: IaaS·PaaS·SaaS와 공동 책임 모델"
date: 2026-10-31 10:01:00 +0900
categories: [study]
phase: 학습 로드맵
seq: 2
tags: [Study, Cloud, IaaS, PaaS, SaaS, Shared responsibility model]
excerpt: "SaaS인 M365에서도 데이터, 설정, 계정은 고객 책임입니다. 먼저 외울 용어 10개와 공동 책임 모델"
---

Microsoft 365를 쓰면 보안도 Microsoft가 다 맡아 줄까요? 어떤 서비스 유형이든 데이터, 설정, 계정과 사용자는 고객 책임이고, 이 글의 용어 10개를 익히면 이후 12주를 설명 없이 따라갈 수 있습니다.

## 요약

- 공동 책임 모델에서 데이터, 설정, 계정과 사용자는 서비스 유형과 상관없이 항상 고객 책임
- 그래서 클라우드에서도 **Identity가 가장 중요한 보안 경계**. 이 학습서가 Entra ID부터 시작하는 이유
- 먼저 외울 10개: IaaS·PaaS·SaaS, Tenant, Subscription, AuthN, AuthZ, SSO, MFA, Token, RBAC, Hybrid identity
- 3~4일 동안 이 개념을 먼저 읽음. 이후 모든 주차에서 설명 없이 씀

12주 학습 로드맵의 0주차입니다. 이전 글은 [학습 로드맵과 사용법]({{ "/study/cloud-study-roadmap/" | relative_url }}), 다음 글은 [클라우드 구조: Tenant, Subscription, Resource group]({{ "/study/cloud-structure-tenant-subscription/" | relative_url }})입니다. [전체 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})도 함께 두었습니다.

---

## 전체 내용

전체 용어는 [용어 전집]({{ "/study/cloud-study-glossary/" | relative_url }})에 있습니다.

### 1. 먼저 외울 10개

- **IaaS, PaaS, SaaS**: 클라우드 서비스를 빌리는 깊이. IaaS는 VM 수준, PaaS는 런타임 수준, SaaS는 완성된 앱
    - 온프레미스로 보면: 서버 임대, DB 서비스, 메일 서비스
- **Tenant**: 한 조직 전용 Entra ID 디렉터리. identity boundary
    - 온프레미스로 보면: AD 포리스트 하나
- **Subscription**: Azure 리소스의 청구, 접근, 한도 경계
    - 온프레미스로 보면: 부서별 예산 계약
- **Authentication (AuthN)**: 누구인지 확인
    - 온프레미스로 보면: 로그온
- **Authorization (AuthZ)**: 무엇을 할 수 있는지 결정
    - 온프레미스로 보면: 파일 서버 ACL
- **SSO**: 한 번 로그인으로 여러 앱 사용
    - 온프레미스로 보면: 도메인 로그온 후 Kerberos 티켓
- **MFA**: 두 가지 이상의 요소로 확인
    - 온프레미스로 보면: 스마트카드, OTP
- **Token**: 로그인 결과로 받는 입장권 (access, ID, refresh)
    - 온프레미스로 보면: Kerberos 티켓과 비슷한 역할
- **RBAC**: 역할 기반 권한 부여
    - 온프레미스로 보면: 위임된 관리 권한
- **Hybrid identity**: 온프레미스 AD와 Entra ID를 연결해 같은 계정으로 쓰는 구성
    - 온프레미스로 보면: 포리스트 간 연계

인증, 토큰, SSO를 더 자세히 보려면 [IAM 시리즈: 기초와 구조]({{ "/iam/what-is-entra-id/" | relative_url }})와 [인증: MFA, 패스키, SSPR, SSO]({{ "/iam/entra-id-authentication/" | relative_url }})를 함께 보세요.

### 2. 공동 책임 모델 (Shared responsibility model)

클라우드 서비스 유형에 따라 책임 영역이 달라집니다. 아래는 Microsoft 공식 문서의 책임 매트릭스를 책임 영역별로 풀어 쓴 것입니다(비교 대상: On-premises, IaaS, PaaS, SaaS).

- **항상 고객 책임**(On-premises/IaaS/PaaS/SaaS 모두): Customer data, Configurations and settings, Identities and users
- **Client devices**: On-premises/IaaS/PaaS는 고객, SaaS는 공유
- **Applications**: On-premises/IaaS는 고객, PaaS/SaaS는 공유
- **Network controls**: On-premises/IaaS는 고객, PaaS는 공유, SaaS는 Microsoft
- **Operating system**: On-premises/IaaS는 고객, PaaS/SaaS는 Microsoft
- **Physical hosts, Physical network, Physical datacenter**: On-premises는 고객, IaaS/PaaS/SaaS는 Microsoft

표를 내려 읽다 보면 맨 윗줄이 눈에 들어옵니다. 어떤 서비스 유형이든 **데이터, 설정, 계정과 사용자는 항상 고객 책임**입니다. 그래서 클라우드에서도 Identity가 가장 중요한 보안 경계가 되고, 이 학습서가 Entra ID부터 시작합니다.

### 3. 0주차 루틴

1. 1일: 1번의 10개 용어를 읽고 용어 전집의 "클라우드 일반" 구간 훑기
2. 2일: 용어 전집의 "Entra ID와 신원" 구간 중 AuthN, AuthZ, SSO, MFA, Token, OAuth 2.0, OIDC, SAML 읽기
3. 3일: 종이 카드에 용어 30개를 한 장씩 적기 (앞면 영어 원어, 뒷면 온프레미스로 보면)
4. 4일: 카드를 보고 30초씩 소리 내어 설명하기. 막히는 카드는 따로 모으기

### 4. 전문가처럼 말하기

> "SaaS인 Microsoft 365에서도 data, identities, devices는 고객 책임입니다. 그래서 Conditional Access와 Intune으로 identity와 endpoint를 통제합니다."

### 5. 자가 점검

<details markdown="1">
<summary>자가 점검 펼쳐 보기 (4문항)</summary>

- [ ] IaaS, PaaS, SaaS의 예를 각각 하나씩 들 수 있다.
    - 답: VM, Azure SQL Database, Microsoft 365
- [ ] AuthN과 AuthZ를 구분해서 설명할 수 있다.
    - 답: AuthN은 누구인지 확인, AuthZ는 무엇을 할 수 있는지 결정
- [ ] Tenant와 Subscription의 차이를 한 문장으로 말할 수 있다.
    - 답: Tenant는 한 조직 전용 Entra ID 디렉터리(identity boundary), Subscription은 Azure 리소스의 청구, 접근, 한도 경계
- [ ] 공동 책임 모델에서 항상 고객 책임인 영역 세 가지를 말할 수 있다.
    - 답: 데이터, 설정, 계정과 사용자

</details>
