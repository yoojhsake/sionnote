---
title: "[IAM] Microsoft Entra ID 핵심 개념: 기초와 구조"
date: 2026-11-01 09:00:00 +0900
categories: [iam]
tags: [IAM, Entra ID, 테넌트, 인증, 권한 부여, 관리자 역할, 긴급 액세스 계정]
excerpt: "M365와 Azure 로그인의 출입 관리실 Entra ID. 온-프레미스 AD와의 차이, 테넌트와 역할 구조를 그림으로 잡는 첫 글"
---

M365든 Azure든 SaaS 앱이든, 로그인할 때 "누구인지 확인하고 들어가도 되는지 판단하는" 곳은 Entra ID입니다. 온-프레미스 AD를 다뤄 봤다면 이 글로 무엇이 같고 무엇이 다른지, 테넌트와 개체, 역할 구조를 한 번에 잡을 수 있습니다.

## 요약

- Entra ID는 OU 계층이 없어 대상을 위치가 아닌 속성 기반 그룹으로 정함
- AADSTS 오류면 인증 단계, 로그인 뒤 403이면 권한 부여 단계로 봄
- 옛 자료는 이름 변경과 SMS 종료 같은 최근 변경을 감안해 읽어야 함

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-changes-timeline-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-changes-timeline.png" | relative_url }}" alt="2023~2027 Entra ID 주요 변경 날짜 표" loading="lazy"></picture>

*그림 1. 오래된 자료를 볼 때 기준을 바꿔 읽어야 하는 변경 사항*

> Entra ID 핵심 개념 시리즈: **기초**(지금 글) · [오류 코드]({{ "/iam/entra-id-error-codes/" | relative_url }}) · [인증]({{ "/iam/entra-id-authentication/" | relative_url }}) · [접근 제어]({{ "/iam/entra-id-access-control/" | relative_url }}) · [하이브리드·외부 사용자]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}) · [라이선스·운영]({{ "/iam/entra-id-licensing-operations/" | relative_url }}) · [용어집]({{ "/study/cloud-study-glossary/" | relative_url }})

> 근거: Microsoft Learn 공식 문서(2026-11-01 확인). 날짜나 라이선스처럼 바뀔 수 있는 내용은 문서로 다시 확인했습니다. 낯선 용어는 [용어집]({{ "/study/cloud-study-glossary/" | relative_url }})을 함께 보세요.

---

## 전체 내용

### 1. Entra ID는 무엇인가

Microsoft Entra ID는 Microsoft가 운영하는 클라우드 기반 ID·액세스 관리(IAM, Identity and Access Management) 서비스로, "누가(Identity) 무엇에(Resource) 어떤 조건으로(Policy) 들어갈 수 있는지"를 관리합니다. M365를 쓰는 회사라면 이미 Entra ID를 쓰고 있는 셈입니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-overview-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-overview.png" | relative_url }}" alt="사람·기기·앱과 M365·Azure·SaaS 사이에 Entra ID가 있는 구조" loading="lazy"></picture>

*그림 2. Entra ID의 위치. 사람, 기기, 앱과 서비스 사이의 출입 관리실*

신입 사원의 첫 출근으로 보면 이렇게 동작합니다.

1. 인사팀이 등록하면(또는 AD에서 동기화되면) `newhire@contoso.com` 사용자가 생깁니다.
2. Outlook을 열면 로그인 창이 Entra ID로 연결됩니다.
3. Entra ID가 암호와 Authenticator(또는 패스키)로 본인을 확인하고 조건부 액세스를 평가한 뒤 토큰을 발급합니다.
4. 그 토큰으로 Teams, SharePoint, 연결된 SaaS 앱까지 다시 로그인하지 않고 씁니다(SSO).

토큰은 3장, 패스키와 SSO는 [인증 편]({{ "/iam/entra-id-authentication/" | relative_url }}), 조건부 액세스는 [접근 제어 편]({{ "/iam/entra-id-access-control/" | relative_url }})에서 다룹니다.

Azure AD에서 Microsoft Entra ID로 바뀐 것은 이름뿐이고, 기능, 라이선스, 가격, 로그인 URL, API, PowerShell cmdlet 이름은 그대로입니다. Azure AD B2C는 이름이 바뀌지 않았습니다.

<details markdown="1">
<summary>이름 변경 일정과 이유</summary>

- 2023-07-11: 이름 변경 발표
- 2023-08-15: Microsoft 제품 화면에서 이름 변경 시작
- 2023-10-01: SKU 표시 이름 변경: Azure AD Premium P1 → Microsoft Entra ID P1 등

온-프레미스 Active Directory와 구분하고 Entra 제품군으로 통일하려고 바꿨습니다.

</details>

### 2. 온-프레미스 AD와 무엇이 다른가

"클라우드 버전 AD"가 아니라 구조가 다릅니다. OU 계층 대신 평평한 구조, Kerberos·NTLM·LDAP 대신 OAuth 2.0·OpenID Connect·SAML, GPO 대신 Intune 정책과 조건부 액세스를 씁니다. 개념별 대응은 [온프레미스 ↔ 클라우드 대응표]({{ "/study/onprem-cloud-mapping/" | relative_url }})를 보세요.

<details markdown="1">
<summary>AD DS와 Entra ID 비교표 펼쳐 보기</summary>

| 구분 | 온-프레미스 Active Directory (AD DS) | Microsoft Entra ID |
|---|---|---|
| 위치 | 사내 도메인 컨트롤러(DC) | Microsoft 클라우드(서버 관리 없음) |
| 보안 경계 | 포리스트 | 테넌트 |
| 구조 | OU 계층 트리 | 평평한(flat) 구조. 범위를 나눌 때는 관리 단위(Administrative Unit) |
| 인증 프로토콜 | Kerberos, NTLM, LDAP | OAuth 2.0, OpenID Connect, SAML, WS-Federation(웹·모바일 중심) |
| 기기 관리 | 도메인 조인 + 그룹 정책(GPO) | Entra 조인 + Intune 정책, 조건부 액세스 |
| 관리 권한 | Domain Admins 같은 그룹 | 역할(Role) 기반: 헬프데스크 관리자, 조건부 액세스 관리자 등 |
| 함께 쓰는 법 | - | Entra Connect Sync 또는 Cloud Sync로 동기화(하이브리드 ID) |

</details>

- 영업팀 OU에 GPO를 걸던 일: 규칙이 `user.department -eq "Sales"`인 동적 그룹(Dynamic group)을 만들고 조건부 액세스 정책(예: 회사 관리 기기에서만 접근)이나 Intune 정책을 할당합니다. 대상은 위치(OU)가 아니라 속성(그룹 규칙)으로 정합니다.
- Kerberos, LDAP, NTLM이 꼭 필요한 오래된 앱: Entra ID가 아니라 Microsoft Entra Domain Services(관리형 도메인)를 씁니다. 하이브리드 사용자의 PHS(암호 해시 동기화, [하이브리드 편]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}))가 켜져 있어야 합니다.

### 3. 인증과 권한 부여

| 용어 | 질문 | 비유 |
|---|---|---|
| 인증(Authentication, AuthN) | 당신은 누구인가? | 출입구에서 사원증과 얼굴 확인 |
| 권한 부여(Authorization, AuthZ) | 무엇을 할 수 있는가? | 3층 서버실 출입 권한이 있는가 |

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-authn-authz-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-authn-authz.png" | relative_url }}" alt="인증과 정책 평가, 토큰 발급, 권한 부여, 결과 순서" loading="lazy"></picture>

*그림 3. 인증 → 토큰 → 권한 부여 순서*

인증이 끝나면 토큰이 발급됩니다. ID 토큰은 "이 사람이 누구인지"를 앱에 알려 주고, 액세스 토큰은 "이 리소스를 호출해도 된다"는 출입증입니다. 액세스 토큰 기본 수명은 60~90분(평균 75분)입니다.

<details markdown="1">
<summary>토큰 수명 예외</summary>

조건부 액세스를 쓰지 않는 테넌트의 Teams, M365 클라이언트는 기본 2시간, CAE 세션은 최대 28시간까지 길어지는 대신 중요 이벤트가 생기면 무효화됩니다.

</details>

- `AADSTS50126`(사용자 이름 또는 암호가 틀림), `AADSTS50076`(MFA 필요), `AADSTS53003`(조건부 액세스가 차단) 같은 AADSTS 오류: 인증과 정책 평가 단계를 봅니다.
- 로그인은 됐는데 `403 Forbidden`: 권한 부여 단계이니 역할, 그룹, 앱 권한을 확인합니다.

관련 오류: [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})(HTTP 상태 코드 401, 403과 AADSTS 번호) · [로그인은 되는데 403·AuthorizationFailed가 나올 때]({{ "/iam/troubleshooting/signed-in-but-403/" | relative_url }})

### 4. 테넌트와 개체

테넌트(Tenant)는 회사 하나를 위한 독립된 Entra ID 공간입니다. M365나 Azure를 처음 구독할 때 만들어지고, 고유한 Tenant ID(GUID)와 기본 도메인 `회사명.onmicrosoft.com`을 받습니다. 사용자 지정 도메인(`contoso.com`)은 DNS TXT 레코드로 소유권을 증명하면 추가됩니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-tenant-objects-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-tenant-objects.png" | relative_url }}" alt="테넌트 안의 사용자·그룹·디바이스·앱·역할과 다른 테넌트와의 관계" loading="lazy"></picture>

*그림 4. 테넌트와 개체*

- 사용자: 직원은 Member(내부), 협력사 담당자는 B2B Guest(외부)입니다.
- 그룹: 권한과 라이선스 대상인 보안 그룹, Teams와 메일 협업용 Microsoft 365 그룹. 구성원은 직접 넣거나 동적 그룹(P1, 2장 예시) 규칙으로 채웁니다.
- 디바이스, 애플리케이션: 아래 두 소절. 역할은 5장.
- 테넌트끼리는 기본적으로 서로 보이지 않고, B2B 초대나 테넌트 간 액세스 설정(Cross-tenant access settings)으로 필요한 만큼 명시적으로 연결합니다.

#### 기기 ID: 등록, 조인, 하이브리드 조인

개인 기기는 등록, 회사가 지급한 클라우드 중심 PC는 조인, 기존 AD 도메인 PC는 하이브리드 조인입니다.

<details markdown="1">
<summary>기기 ID 종류별 비교표</summary>

| 종류 | 언제 쓰나 | 로그인 계정 |
|---|---|---|
| Entra 등록(Registered) | 개인 휴대폰, 개인 PC로 회사 앱 사용(BYOD) | 개인 계정 + 회사 계정 추가 |
| Entra 조인(Joined) | 회사가 지급한 클라우드 중심 PC | 회사 Entra 계정 |
| 하이브리드 조인(Hybrid joined) | 기존 AD 도메인 PC를 그대로 두면서 클라우드에도 등록 | AD 계정(동기화됨) |

</details>

- 조인된 Windows PC는 로그인할 때 PRT(Primary Refresh Token, 기본 새로 고침 토큰)를 받아 브라우저와 Office 앱에 다시 로그인하지 않게 해 줍니다.
- 준수 기기(Compliant device)는 조인만으로 붙지 않습니다. 기기를 Intune에 등록하고 Intune 준수 정책(암호화, OS 버전 등)을 통과해야 합니다.

#### 앱 등록과 엔터프라이즈 앱

앱 등록(App registration)은 앱의 설계도, 엔터프라이즈 앱(Enterprise application, 서비스 주체)은 그 앱을 쓰는 테넌트마다 생기는 실제 인스턴스입니다.

- 사내 개발 앱을 등록하면 우리 테넌트에 둘 다 생깁니다. Salesforce처럼 다른 회사가 만든 앱은 엔터프라이즈 앱만 생기고, 설계도는 만든 회사의 테넌트에 있습니다.
- 앱이 메일이나 파일에 접근하려면 동의(Consent)가 필요합니다. 사용자가 아무 앱에나 동의하지 못하게 막아 두면 "가짜 앱에 권한을 주게 만드는" 동의 피싱을 줄일 수 있습니다.

관련 오류: [AADSTS50105: 앱에 할당되지 않은 사용자]({{ "/iam/troubleshooting/aadsts50105-app-not-assigned/" | relative_url }}) · [AADSTS65001·90094: 앱 권한 동의가 막힐 때]({{ "/iam/troubleshooting/aadsts65001-consent-required/" | relative_url }})

### 5. 관리자 역할과 최소 권한, 긴급 액세스 계정

필요한 일만 할 수 있는 가장 작은 역할을 줍니다(최소 권한, Least privilege).

- 일반 사용자 암호 재설정: 헬프데스크 관리자(Helpdesk Administrator) 또는 암호 관리자
- 사용자와 그룹 생성, 삭제: 사용자 관리자(User Administrator)
- 조건부 액세스 정책 관리: 조건부 액세스 관리자(Conditional Access Administrator)
- 인증 방법 정책 관리: 인증 정책 관리자(Authentication Policy Administrator)
- Exchange 설정: Exchange 관리자
- 범위 축소: 관리 단위(Administrative Unit, P1)로 "서울 지사 사용자만 암호 재설정"처럼 좁히고, 상시 관리자 수는 PIM([접근 제어 편]({{ "/iam/entra-id-access-control/" | relative_url }}))으로 줄입니다.

긴급 액세스 계정(Emergency access, Break-glass)은 정책 실수나 MFA 장애로 관리자 전원이 잠겼을 때 쓰는 비상 열쇠입니다.

- 클라우드 전용 계정 2개 이상(`*.onmicrosoft.com`, 동기화나 페더레이션 안 함), 전역 관리자 상시 할당
- 패스키(FIDO2) 또는 인증서 기반 인증으로 보호. Azure 필수 MFA는 긴급 계정에도 예외 없이 적용되므로 "MFA 없이 쓰는 계정"이 아닙니다.
- 로그인을 차단하거나 제한하는 조건부 액세스 정책에서 제외하고, 사용하면 즉시 경보가 가게 합니다.

관련 오류: [조건부 액세스 정책 실수로 관리자까지 잠겼을 때: 긴급 액세스 계정]({{ "/iam/troubleshooting/ca-lockout-emergency-access/" | relative_url }})

### 6. 확인 문제

<details markdown="1">
<summary>1. 사용자가 로그인은 되는데 SharePoint에서 403이 납니다. 인증과 권한 부여 중 어느 단계를 봐야 하나요?</summary>

**권한 부여** 단계입니다. 사이트 권한, 그룹 구성원, 역할을 확인합니다.

</details>

<details markdown="1">
<summary>2. 암호 재설정만 하는 헬프데스크 직원에게 전역 관리자 대신 줄 역할은?</summary>

헬프데스크 관리자(Helpdesk Administrator) 또는 암호 관리자입니다. 특정 지사만 담당하면 관리 단위로 범위를 좁힙니다.

</details>

### 7. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- 이름 변경 날짜, 바뀌지 않는 항목: [New name for Azure Active Directory](https://learn.microsoft.com/entra/fundamentals/new-name)
- 액세스 토큰 기본 수명 60~90분: [Access tokens in the Microsoft identity platform](https://learn.microsoft.com/entra/identity-platform/access-tokens)
- 긴급 액세스 계정: [Manage emergency access accounts](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access)

</details>
