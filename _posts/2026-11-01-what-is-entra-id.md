---
title: "[IAM] Microsoft Entra ID 핵심 개념: 기초와 구조"
date: 2026-11-01 09:00:00 +0900
categories: [iam]
tags: [IAM, Entra ID, 테넌트, 인증, 권한 부여, 관리자 역할, 긴급 액세스 계정]
excerpt: "M365와 Azure 로그인의 출입 관리실 Entra ID. 온-프레미스 AD와의 차이, 테넌트와 역할 구조를 그림으로 잡는 첫 글"
---

M365든 Azure든 SaaS 앱이든, 로그인할 때 "누구인지 확인하고 들어가도 되는지 판단하는" 곳은 Entra ID입니다. 온-프레미스 AD를 다뤄 봤다면 이 글로 무엇이 같고 무엇이 다른지, 테넌트와 개체, 역할 구조를 한 번에 잡을 수 있습니다.

## 요약

- 2023-07-11 발표로 Azure AD가 Microsoft Entra ID로 이름만 바뀜. 기능, 라이선스, 로그인 URL, API는 그대로
- 회사마다 독립된 테넌트가 있고, 그 안에 사용자, 그룹, 디바이스, 앱, 역할 개체가 있음
- 로그인 보안은 MFA에서 피싱 저항 방식(패스키 등)으로, 여기에 조건부 액세스, SSO, PIM, ID Protection
- 운영 기본기는 최소 권한 역할, 긴급 액세스 계정, 로그인·감사 로그
- 하이브리드는 Connect Sync 또는 Cloud Sync로 AD 계정 동기화. 인증은 PHS, PTA, Federation 중 선택하되 PHS는 항상 함께 켜 두는 것이 권장
- 라이선스는 Free → P1(조건부 액세스) → P2(ID Protection, PIM). ID Governance와 Entra Suite는 그 위에 추가 구매
- 최근 바뀌었거나 바뀔 것
    - Microsoft 제공 SMS·음성 MFA 2027-02-01 종료(전역 관리자·외부 사용자는 2027-07-01)
    - 2026-09-01 패스키 기본값
    - Azure 관리 필수 MFA
    - 옛 ID Protection 위험 정책 2026-10-01 종료
    - Azure AD B2C 신규 판매 중단
    - Connect Sync → Cloud Sync 전환 통지

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-changes-timeline-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-changes-timeline.png" | relative_url }}" alt="2023~2027 Entra ID 주요 변경 날짜 표" loading="lazy"></picture>

*그림 1. 오래된 자료를 볼 때 기준을 바꿔 읽어야 하는 변경 사항*

> **시리즈: Microsoft Entra ID 핵심 개념**
>
> 1. **기초와 구조** (지금 보는 글)
> 2. [오류 코드 읽는 법(HTTP 상태 코드와 AADSTS)]({{ "/iam/entra-id-error-codes/" | relative_url }})
> 3. [인증(MFA, 패스키, SSPR, SSO)]({{ "/iam/entra-id-authentication/" | relative_url }})
> 4. [접근 제어(조건부 액세스, PIM, ID Protection)]({{ "/iam/entra-id-access-control/" | relative_url }})
> 5. [하이브리드, 외부 사용자, 라이선스, 운영]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }})
> 6. [용어집과 학습 자료]({{ "/iam/entra-id-glossary/" | relative_url }})

> 근거: Microsoft Learn 공식 문서(2026-11-01 확인). 날짜나 라이선스처럼 바뀔 수 있는 내용은 문서로 다시 확인했습니다. 낯선 용어는 [용어집]({{ "/iam/entra-id-glossary/" | relative_url }})을 함께 보세요.

---

## 전체 내용

### 1. Entra ID는 무엇인가

Microsoft Entra ID는 Microsoft가 운영하는 클라우드 기반 ID·액세스 관리(IAM, Identity and Access Management) 서비스입니다. 사내에 서버를 두지 않고 Microsoft 데이터센터에서 동작합니다.

한 문장으로 줄이면 "누가(Identity) 무엇에(Resource) 어떤 조건으로(Policy) 들어갈 수 있는지 관리하는 곳"입니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-overview-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-overview.png" | relative_url }}" alt="사람·기기·앱과 M365·Azure·SaaS 사이에 Entra ID가 있는 구조" loading="lazy"></picture>

*그림 2. Entra ID의 위치. 사람, 기기, 앱과 서비스 사이의 출입 관리실*

#### 신입 사원의 첫 출근으로 보면

1. 인사팀이 등록하면(또는 AD에서 동기화되면) Entra ID에 `newhire@contoso.com` 사용자가 생깁니다.
2. 신입 사원이 노트북에서 Outlook을 열면 로그인 창이 Entra ID로 연결됩니다.
3. Entra ID가 암호와 Authenticator(또는 패스키)로 본인을 확인하고, 회사 정책(조건부 액세스)을 평가한 뒤 토큰을 발급합니다.
4. 그 토큰 덕분에 Teams, SharePoint, 회사가 연결해 둔 SaaS 앱까지 다시 로그인하지 않고 씁니다(SSO).

토큰은 아래 3장, 패스키와 SSO는 [인증 편]({{ "/iam/entra-id-authentication/" | relative_url }}), 조건부 액세스는 [접근 제어 편]({{ "/iam/entra-id-access-control/" | relative_url }})에서 자세히 다룹니다.

Microsoft 365와 Azure 구독은 모두 Entra 테넌트를 통해 로그인합니다. M365를 쓰는 회사라면 이미 Entra ID를 쓰고 있는 셈입니다.

#### 이름 변경: Azure AD에서 Microsoft Entra ID로

- **2023-07-11**: 이름 변경 발표
- **2023-08-15**: Microsoft 제품 화면에서 이름 변경 시작
- **2023-10-01**: SKU 표시 이름 변경: Azure AD Premium P1 → Microsoft Entra ID P1 등

이름만 바뀌었고 기능, 라이선스, 가격, 로그인 URL, API, PowerShell cmdlet 이름은 그대로입니다. 바꾼 이유는 온-프레미스 Active Directory와 헷갈리지 않게 하고 Entra 제품군으로 이름을 통일하기 위해서입니다. 예외로 Azure AD B2C는 이름이 바뀌지 않았습니다.

### 2. 온-프레미스 AD와 무엇이 다른가

AD를 운영해 본 입장에서는 "클라우드 버전 AD"로 이해하기 쉽지만, 구조가 다릅니다. OU, GPO, Kerberos 같은 개념이 클라우드에서 무엇에 해당하는지는 [온프레미스 ↔ 클라우드 대응표]({{ "/study/onprem-cloud-mapping/" | relative_url }})에 한 장으로 정리했습니다.

| 구분 | 온-프레미스 Active Directory (AD DS) | Microsoft Entra ID |
|---|---|---|
| 위치 | 사내 도메인 컨트롤러(DC) | Microsoft 클라우드(서버 관리 없음) |
| 보안 경계 | 포리스트 | 테넌트 |
| 구조 | OU 계층 트리 | 평평한(flat) 구조. 범위를 나눌 때는 관리 단위(Administrative Unit) |
| 인증 프로토콜 | Kerberos, NTLM, LDAP | OAuth 2.0, OpenID Connect, SAML, WS-Federation(웹·모바일 중심) |
| 기기 관리 | 도메인 조인 + 그룹 정책(GPO) | Entra 조인 + Intune 정책, 조건부 액세스 |
| 관리 권한 | Domain Admins 같은 그룹 | 역할(Role) 기반: 헬프데스크 관리자, 조건부 액세스 관리자 등 |
| 함께 쓰는 법 | - | Entra Connect Sync 또는 Cloud Sync로 동기화(하이브리드 ID) |

Kerberos, LDAP, NTLM이 꼭 필요한 오래된 앱을 클라우드로 옮길 때는 Entra ID가 아니라 Microsoft Entra Domain Services(관리형 도메인)가 그 역할을 맡습니다. Domain Services를 쓰려면 하이브리드 사용자의 PHS(암호 해시 동기화, [하이브리드 편]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}))가 켜져 있어야 합니다.

#### "영업팀 OU에 GPO를 걸던 일"을 Entra ID에서 하려면

OU 대신 규칙이 `user.department -eq "Sales"`인 동적 그룹(Dynamic group)을 만들고, 그 그룹에 조건부 액세스 정책(예: 회사 관리 기기에서만 접근)이나 Intune 정책을 할당합니다. "어디에 들어 있느냐(OU)"가 아니라 "어떤 속성을 가졌느냐(그룹 규칙)"로 대상을 정한다는 점이 가장 큰 차이입니다. 동적 그룹은 4장에서 다시 설명합니다.

### 3. 인증과 권한 부여

| 용어 | 질문 | 비유 |
|---|---|---|
| 인증(Authentication, AuthN) | 당신은 누구인가? | 출입구에서 사원증과 얼굴 확인 |
| 권한 부여(Authorization, AuthZ) | 무엇을 할 수 있는가? | 3층 서버실 출입 권한이 있는가 |

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-authn-authz-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-authn-authz.png" | relative_url }}" alt="인증과 정책 평가, 토큰 발급, 권한 부여, 결과 순서" loading="lazy"></picture>

*그림 3. 인증 → 토큰 → 권한 부여 순서*

인증이 끝나면 Entra ID는 토큰(Token)을 발급합니다. ID 토큰은 "이 사람이 누구인지"를 앱에 알려 주고, 액세스 토큰은 "이 리소스를 호출해도 된다"는 출입증입니다. 액세스 토큰의 기본 수명은 60~90분(평균 75분) 사이에서 정해집니다.

예외도 있습니다. 조건부 액세스를 쓰지 않는 테넌트의 Teams, M365 클라이언트는 기본 2시간, CAE 세션은 최대 28시간까지 길어지는 대신 중요 이벤트가 생기면 무효화됩니다.

순서는 항상 **인증이 먼저, 권한 부여가 나중**입니다. 장애를 볼 때 이 구분이 바로 쓸모가 있습니다. `AADSTS50126`(사용자 이름 또는 암호가 틀림), `AADSTS50076`(MFA 필요), `AADSTS53003`(조건부 액세스가 차단) 같은 AADSTS 오류가 나면 인증과 정책 평가 단계입니다. 로그인은 됐는데 `403 Forbidden`이 나면 권한 부여 단계이니 역할, 그룹, 앱 권한을 확인합니다.

HTTP 상태 코드(401, 403 등)와 AADSTS 번호를 읽는 법은 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})에, 각 오류의 대처 방법은 맨 아래 "관련 트러블슈팅"에 모은 글에 정리했습니다.

### 4. 테넌트와 개체

테넌트(Tenant)는 회사 하나를 위한 독립된 Entra ID 공간입니다. M365나 Azure를 처음 구독할 때 만들어지고, 고유한 Tenant ID(GUID)와 기본 도메인 `회사명.onmicrosoft.com`을 받습니다. 사용자 지정 도메인(`contoso.com`)은 DNS TXT 레코드로 소유권을 증명하면 추가됩니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-tenant-objects-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-tenant-objects.png" | relative_url }}" alt="테넌트 안의 사용자·그룹·디바이스·앱·역할과 다른 테넌트와의 관계" loading="lazy"></picture>

*그림 4. 테넌트와 개체*

- **사용자**: Member(내부)와 Guest(외부)로 나뉩니다. 직원은 Member, 협력사 담당자는 B2B Guest입니다.
- **그룹**: 권한과 라이선스 대상이 되는 보안 그룹, Teams와 메일 협업용 Microsoft 365 그룹이 있습니다. 구성원은 직접 넣거나, 동적 그룹(P1) 규칙 `user.department -eq "Sales"`처럼 자동으로 채울 수 있습니다.
- **디바이스**: 개인 기기는 Entra 등록, 회사 기기는 Entra 조인, AD와 함께 쓰면 하이브리드 조인입니다(아래 "기기 ID" 참고).
- **애플리케이션**: 앱 등록(App registration)은 앱의 설계도이고, 엔터프라이즈 앱(Enterprise application, 서비스 주체)은 그 앱을 쓰는 테넌트마다 생기는 실제 인스턴스입니다(아래 "앱 등록과 엔터프라이즈 앱" 참고).
- **역할**: 관리 권한 묶음입니다. 암호 재설정만 하는 헬프데스크라면 전역 관리자 대신 헬프데스크 관리자(Helpdesk Administrator)를 줍니다.

테넌트끼리는 기본적으로 서로 보이지 않습니다. 다만 B2B 초대나 테넌트 간 액세스 설정(Cross-tenant access settings)으로 필요한 만큼 연결할 수 있습니다. "완전히 분리"라기보다 **"기본은 분리, 연결은 명시적으로"**가 맞는 표현입니다.

#### 기기 ID: 등록, 조인, 하이브리드 조인

| 종류 | 언제 쓰나 | 로그인 계정 |
|---|---|---|
| Entra 등록(Registered) | 개인 휴대폰, 개인 PC로 회사 앱 사용(BYOD) | 개인 계정 + 회사 계정 추가 |
| Entra 조인(Joined) | 회사가 지급한 클라우드 중심 PC | 회사 Entra 계정 |
| 하이브리드 조인(Hybrid joined) | 기존 AD 도메인 PC를 그대로 두면서 클라우드에도 등록 | AD 계정(동기화됨) |

조인된 Windows PC는 로그인할 때 PRT(Primary Refresh Token, 기본 새로 고침 토큰)를 받아, 브라우저와 Office 앱에 다시 로그인하지 않게 해 줍니다. 조건부 액세스의 준수 기기(Compliant device)는 조인만으로 되는 것이 아니라, 기기를 Intune에 등록하고 Intune 준수 정책(암호화, OS 버전 등)을 통과해야 붙는 표시입니다.

#### 앱 등록과 엔터프라이즈 앱

사내 개발 앱을 등록하면 우리 테넌트에 앱 등록(설계도)과 엔터프라이즈 앱(인스턴스)이 둘 다 생깁니다. Salesforce처럼 다른 회사가 만든 앱을 추가하면 우리 테넌트에는 엔터프라이즈 앱만 생기고, 설계도는 만든 회사의 테넌트에 있습니다.

앱이 메일이나 파일 같은 데이터에 접근하려면 **동의(Consent)**가 필요합니다. 사용자가 아무 앱에나 동의하지 못하게 막아 두면 "가짜 앱에 권한을 주게 만드는" 동의 피싱을 줄일 수 있습니다. 관련 오류: [AADSTS65001·90094]({{ "/iam/troubleshooting/aadsts65001-consent-required/" | relative_url }}), 할당 필요 앱의 [AADSTS50105]({{ "/iam/troubleshooting/aadsts50105-app-not-assigned/" | relative_url }}).

### 5. 관리자 역할과 최소 권한, 긴급 액세스 계정

AD 관리자가 클라우드로 넘어올 때 가장 많이 실수하는 부분입니다. 원칙은 **필요한 일만 할 수 있는 가장 작은 역할**을 주는 것입니다(최소 권한, Least privilege).

- **일반 사용자 암호 재설정**: 헬프데스크 관리자(Helpdesk Administrator) 또는 암호 관리자
- **사용자와 그룹 생성, 삭제**: 사용자 관리자(User Administrator)
- **조건부 액세스 정책 관리**: 조건부 액세스 관리자(Conditional Access Administrator)
- **인증 방법 정책 관리**: 인증 정책 관리자(Authentication Policy Administrator)
- **Exchange 설정**: Exchange 관리자

관리 단위(Administrative Unit)로 범위를 더 좁힐 수 있습니다. 예를 들어 "서울 지사 사용자만 암호 재설정"할 수 있는 헬프데스크 관리자를 만들 수 있고, 관리 단위를 쓰려면 P1이 필요합니다. 상시 관리자 수를 줄이려면 PIM([접근 제어 편]({{ "/iam/entra-id-access-control/" | relative_url }}))을 씁니다.

긴급 액세스 계정(Emergency access, Break-glass)은 정책 실수나 MFA 장애로 관리자 전원이 잠겼을 때 쓰는 비상 열쇠입니다.

- 클라우드 전용 계정 2개 이상(`*.onmicrosoft.com`, 동기화나 페더레이션 안 함), 전역 관리자 상시 할당
- 패스키(FIDO2) 또는 인증서 기반 인증으로 보호. Azure 필수 MFA는 긴급 계정에도 예외 없이 적용되므로 "MFA 없이 쓰는 계정"이 아닙니다.
- 로그인을 차단하거나 제한하는 조건부 액세스 정책에서 제외하고, 사용하면 즉시 경보가 가게 합니다.

자세한 구성과 복구 순서는 [조건부 액세스 정책 실수로 관리자까지 잠겼을 때: 긴급 액세스 계정]({{ "/iam/troubleshooting/ca-lockout-emergency-access/" | relative_url }})에 정리했습니다.

### 6. 관련 트러블슈팅

오류와 상황별 대처는 별도 글로 나눴습니다.

- 로그인은 되는데 권한이 없을 때: [로그인은 되는데 403·AuthorizationFailed가 나올 때]({{ "/iam/troubleshooting/signed-in-but-403/" | relative_url }})
- 정책 실수로 관리자까지 잠겼을 때: [조건부 액세스 정책 실수로 관리자까지 잠겼을 때: 긴급 액세스 계정]({{ "/iam/troubleshooting/ca-lockout-emergency-access/" | relative_url }})
- 앱에 할당되지 않아 SSO가 실패할 때: [AADSTS50105: 앱에 할당되지 않은 사용자]({{ "/iam/troubleshooting/aadsts50105-app-not-assigned/" | relative_url }})
- 앱 권한 동의가 막히거나 관리자 승인이 필요할 때: [AADSTS65001·90094: 앱 권한 동의가 막힐 때]({{ "/iam/troubleshooting/aadsts65001-consent-required/" | relative_url }})

### 7. 확인 문제

<details markdown="1">
<summary>1. 사용자가 로그인은 되는데 SharePoint에서 403이 납니다. 인증과 권한 부여 중 어느 단계를 봐야 하나요?</summary>

**권한 부여** 단계입니다. 로그인(인증)은 끝났으므로 사이트 권한, 그룹 구성원, 역할을 확인합니다. 로그인 자체가 안 되고 AADSTS 오류가 나면 인증과 정책 평가 단계입니다.

</details>

<details markdown="1">
<summary>2. 암호 재설정만 하는 헬프데스크 직원에게 전역 관리자 대신 줄 역할은?</summary>

헬프데스크 관리자(Helpdesk Administrator) 또는 암호 관리자입니다. 특정 지사만 담당하면 관리 단위로 범위를 좁힙니다.

</details>

### 8. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- 이름 변경 날짜, 바뀌지 않는 항목: [New name for Azure Active Directory](https://learn.microsoft.com/entra/fundamentals/new-name)
- 액세스 토큰 기본 수명 60~90분: [Access tokens in the Microsoft identity platform](https://learn.microsoft.com/entra/identity-platform/access-tokens)
- 긴급 액세스 계정: [Manage emergency access accounts](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access)

</details>
