---
title: "[IAM] Microsoft Entra ID 핵심 개념: 인증(MFA, 패스키, SSPR, SSO)"
date: 2026-11-01 08:59:00 +0900
categories: [iam]
tags: [IAM, Entra ID, MFA, 패스키, SMS 종료, 보안 기본값, 필수 MFA, SSPR, SSO, CAE]
excerpt: "SMS·음성 MFA는 2027-02-01부터 종료(전역 관리자·외부 사용자는 2027-07-01), 패스키는 이미 기본값. MFA, 패스키, SSPR, SSO를 예시로 정리"
---

Microsoft 제공 SMS·음성 MFA는 2027-02-01부터 종료되고(전역 관리자·외부 사용자는 2027-07-01), 2026-09-01부터는 패스키가 기본값이 됐습니다. 지금 쓰는 MFA 방식이 얼마나 강한지, 무엇으로 어떻게 켜야 하는지 이 글로 판단할 수 있습니다.

## 요약

- SMS·음성은 피싱에 약하고 곧 종료되므로 패스키로 옮겨야 함
- P1이 없으면 보안 기본값, 있으면 조건부 액세스로 MFA를 켬
- Azure 생성·변경 작업은 필수 MFA 대상이라 사람 계정 자동화가 실패할 수 있음

> Entra ID 핵심 개념 시리즈: [기초]({{ "/iam/what-is-entra-id/" | relative_url }}) · [오류 코드]({{ "/iam/entra-id-error-codes/" | relative_url }}) · **인증**(지금 글) · [접근 제어]({{ "/iam/entra-id-access-control/" | relative_url }}) · [하이브리드·외부 사용자]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}) · [라이선스·운영]({{ "/iam/entra-id-licensing-operations/" | relative_url }}) · [용어집]({{ "/study/cloud-study-glossary/" | relative_url }})

> 근거: Microsoft Learn 공식 문서(2026-11-01 확인). 날짜나 라이선스처럼 바뀔 수 있는 내용은 문서로 다시 확인했습니다. 낯선 용어는 [용어집]({{ "/study/cloud-study-glossary/" | relative_url }})을 함께 보세요.

---

## 전체 내용

### 1. 다단계 인증(MFA)과 패스키

MFA(Multi-Factor Authentication)는 서로 다른 종류의 인증 요소를 2개 이상 조합하는 방식입니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-mfa-factors-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-mfa-factors.png" | relative_url }}" alt="MFA 세 가지 요소와 인증 방식의 강도" loading="lazy"></picture>

*그림 1. MFA 요소와 인증 방식의 강도*

암호 + 보안 질문은 둘 다 "아는 것"이라 MFA가 아니고, 암호 + Authenticator 승인은 "아는 것 + 가진 것"이라 MFA입니다.

#### 피싱 저항(Phishing-resistant) 인증

SMS 코드나 Authenticator 푸시는 가짜 로그인 페이지가 코드와 세션을 실시간으로 가로채는 AiTM(Adversary-in-the-Middle, 중간자 피싱)에 뚫릴 수 있습니다. Microsoft가 권장하는 피싱 저항 방식은 다음과 같습니다.

- 패스키(FIDO2): 동기화된 패스키, Microsoft Authenticator의 패스키, FIDO2 보안 키
- Windows Hello for Business, macOS용 Platform Credential
- 인증서 기반 인증(CBA, 스마트카드)

패스키는 등록한 사이트(도메인)에만 응답하므로 철자 하나를 바꾼 가짜 도메인에서는 동작하지 않습니다. 기기 바인딩 패스키는 개인 키가 그 기기(보안 키, 휴대폰의 Authenticator) 밖으로 나가지 않고, 동기화된 패스키는 iCloud 키체인, Google 암호 관리자 같은 자격 증명 관리자를 통해 여러 기기로 동기화됩니다.

#### SMS·음성 MFA 종료와 패스키 기본값

SMS·음성만 등록된 사용자는 종료 이후 로그인할 때 패스키를 등록해야 계속 쓸 수 있습니다. SSPR(2장)의 SMS·음성에도 같은 기준이 적용됩니다.

<details markdown="1">
<summary>종료 일정과 전화 사업자 예외</summary>

- 2026-09-01: SMS·음성이 켜져 있는 사용자에게 패스키가 자동 활성화되고, MFA 로그인 때 패스키 등록 안내가 나옴
- 2027-02-01 (예정): Microsoft가 제공하는 SMS·음성 인증 종료(전역 관리자와 외부 사용자 제외, 내부 게스트는 포함)
- 2027-07-01 (예정): 전역 관리자와 외부 사용자의 Microsoft 제공 SMS·음성 종료

규정상 SMS·음성이 꼭 필요하면 Microsoft Security Store의 전화 사업자(telephony provider)를 따로 계약해서 계속 쓸 수 있습니다(별도 비용, 2026-10-30부터 구성 가능).

</details>

#### MFA를 켜는 방법과 관리 위치

- 인증 방법은 2025-09-30부터 인증 방법 정책(Authentication methods policy) 한 곳에서 관리합니다(레거시 MFA, SSPR 정책에서는 불가). 경로는 Microsoft Entra 관리 센터 > Entra ID > Authentication methods(인증 방법) > Policies(정책)이고, 같은 화면의 마이그레이션 가이드로 기존 설정을 옮깁니다. 예외로 보안 질문은 아직 레거시 SSPR 정책에서 관리합니다.
- P1이 없으면 보안 기본값(Security defaults, Free), P1 이상이면 조건부 액세스로 켭니다. 조건부 액세스 정책이 있으면 보안 기본값은 켤 수 없습니다. 사용자별 MFA(레거시, 모든 M365 조직 Free)는 권장하지 않으며 위 두 방법을 쓸 수 없을 때만 씁니다.
- 보안 기본값 경로: Entra ID > Overview(개요) > Properties(속성) > Manage security defaults(보안 기본값 관리)

<details markdown="1">
<summary>보안 기본값을 켜면 적용되는 것</summary>

- 모든 사용자 MFA 등록, 관리자는 항상 MFA, 일반 사용자는 필요할 때 MFA
- 레거시 인증 차단: IMAP, POP3, SMTP 기본 인증이나 오래된 Office처럼 MFA를 지원하지 않아 우회 통로가 되는 방식
- Azure 관리(포털, Entra 관리 센터, PowerShell, CLI) 접근 시 MFA
- 디바이스 코드 흐름 차단: 2026-07-01부터 새로 만드는 테넌트에는 기본으로 포함됩니다. 디바이스 코드 흐름은 브라우저 없는 기기에서 화면의 코드를 다른 기기에 입력해 로그인하는 방식으로, 피싱에 악용될 수 있습니다.
- 2019-10-22 이후 만든 테넌트는 켜져 있을 수 있고, 새 테넌트는 24시간 유예 후 적용됩니다.

</details>

#### Azure 관리에는 MFA가 필수

Azure 포털과 관리 포털 로그인, Azure 도구의 생성·변경·삭제 작업에는 MFA가 필수이며 테스트 테넌트라도 예외가 없습니다.

<details markdown="1">
<summary>필수 MFA 1·2단계 일정과 대상</summary>

- 1단계
    - 시작: 2024-10부터(M365 관리 센터는 2025-02부터)
    - 대상: Azure 포털, Entra 관리 센터, Intune 관리 센터 로그인
- 2단계
    - 시작: 2025-10-01부터 점진 적용(테넌트별로 2026-07-01까지 연기 가능했음)
    - 대상: Azure CLI, Azure PowerShell, 모바일 앱, IaC, Azure SDK, REST API의 생성, 변경, 삭제 작업. 읽기는 대상 아님

</details>

- 사람 계정(ID와 암호)으로 Azure PowerShell을 돌리는 예약 작업은 2단계 이후 생성, 변경 작업에서 실패할 수 있습니다.
- 관리 ID(Managed Identity, Azure 리소스에 자동으로 주어지는 자격 증명 없는 ID)나 서비스 주체(Service principal, 인증서 자격 증명 권장)로 바꾸면 필수 MFA 대상에서 빠집니다.
- 적용 대상은 `management.azure.com`으로 가는 요청이고, Microsoft Graph API는 일반적으로 대상이 아닙니다.

관련 오류: [AADSTS50126: 사용자 이름 또는 암호가 잘못됨]({{ "/iam/troubleshooting/aadsts50126-wrong-password/" | relative_url }}) · [AADSTS50076·50079: MFA가 필요하거나 등록하라고 막힐 때]({{ "/iam/troubleshooting/aadsts50076-mfa-required/" | relative_url }}) · [SMS·음성으로만 MFA를 하는 사용자가 있을 때]({{ "/iam/troubleshooting/sms-voice-mfa-retirement/" | relative_url }}) · [보안 기본값 관리가 보이지 않을 때]({{ "/iam/troubleshooting/security-defaults-cannot-enable/" | relative_url }}) · [Exchange Online 장치 코드 로그인이 AADSTS530035로 막힘]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})(디바이스 코드 차단 실제 사례)

### 2. 셀프 서비스 암호 재설정(SSPR)

사용자가 등록해 둔 인증 방법으로 본인 확인을 한 뒤 직접 암호를 재설정하는 기능입니다.

예: 금요일 밤에 암호를 잊은 직원이 `https://aka.ms/sspr`에 접속해 Authenticator 승인과 이메일 코드로 본인 확인 → 새 암호 설정 → 하이브리드 사용자라면 쓰기 저장(Writeback)으로 사내 AD 암호도 같이 바뀝니다. 쓰기 저장은 Entra Connect Sync 또는 Cloud Sync에서 켭니다.

라이선스는 "변경"과 "재설정"이 다릅니다. Free는 변경만, 클라우드 사용자 재설정은 M365 Business Standard 이상, 하이브리드 쓰기 저장은 M365 Business Premium 또는 Entra ID P1/P2부터입니다.

<details markdown="1">
<summary>SSPR 라이선스 구분</summary>

- 클라우드 사용자 암호 변경(현재 암호를 앎): Free, M365 Business Standard, M365 Business Premium, Entra ID P1/P2 모두 가능
- 클라우드 사용자 암호 재설정(잊어버림): M365 Business Standard, M365 Business Premium, Entra ID P1/P2 (Free는 불가)
- 하이브리드 사용자 변경·재설정 + 온-프레미스 쓰기 저장: M365 Business Premium, Entra ID P1/P2 (Free와 Business Standard는 불가)

</details>

관련 오류: [SSPR이 되지 않을 때: 오류 코드와 쓰기 저장]({{ "/iam/troubleshooting/sspr-cannot-reset/" | relative_url }})

### 3. Single Sign-On(SSO)

한 번 로그인으로 연결된 여러 앱을 쓰는 기능으로, Entra ID가 앱마다 OIDC/OAuth 2.0 또는 SAML 토큰을 발급해 줍니다. 앱 갤러리에는 SAML이나 OIDC로 바로 연결할 수 있는 SaaS 앱이 많습니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-sso-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-sso.png" | relative_url }}" alt="한 번 로그인으로 여러 앱에 토큰 발급" loading="lazy"></picture>

*그림 2. 한 번 로그인으로 여러 앱에 토큰이 발급되는 SSO 구조*

- 퇴사자 계정을 사용 안 함으로 바꾸면 새 토큰 발급은 막히지만, 이미 발급된 액세스 토큰(보통 60~90분)이나 앱 자체 세션은 만료될 때까지 남을 수 있습니다.
- 바로 끊어야 하면 사용자 화면에서 세션 해지(Revoke sessions)를 함께 실행합니다. Exchange, SharePoint, Teams는 CAE(Continuous Access Evaluation, 연속 액세스 평가)를 지원해 몇 분 안에(문서상 최대 15분 지연 가능) 반영합니다.

관련 오류: [계정을 막았는데 퇴사자가 여전히 메일·파일에 접근할 때]({{ "/iam/troubleshooting/disabled-user-still-signed-in/" | relative_url }})

### 4. 확인 문제

<details markdown="1">
<summary>1. 암호 + 보안 질문이 MFA가 아닌 이유는?</summary>

둘 다 "아는 것(Knowledge)"이라서입니다. MFA는 아는 것, 가진 것, 나 자신 중 **서로 다른 종류**를 2개 이상 조합해야 합니다.

</details>

<details markdown="1">
<summary>2. 2027-02-01 이후 SMS로만 MFA를 등록한 일반 사용자는 어떻게 되나요?</summary>

Microsoft 제공 SMS·음성이 종료되어, 로그인 중 **패스키 등록을 마쳐야** 계속 쓸 수 있습니다(전화 사업자를 따로 구성한 테넌트 제외). 전역 관리자와 외부 사용자는 2027-07-01이 기준입니다.

</details>

<details markdown="1">
<summary>3. 퇴사자를 즉시 차단하려면 "계정 사용 안 함" 외에 무엇을 더 해야 하나요?</summary>

**세션 해지(Revoke sessions)**와 등록 기기 사용 안 함입니다. 하이브리드라면 사내 AD에서 계정을 막고 **암호를 두 번 재설정**한 뒤(pass-the-hash 대비), 동기화를 기다리지 말고 Entra에서도 바로 사용 안 함과 세션 해지를 합니다.

</details>

### 5. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (7건)</summary>

- SMS·음성 종료, 패스키 기본값 일정: [Passkeys by default and retirement of Microsoft-provided SMS and voice authentication](https://learn.microsoft.com/entra/identity/authentication/concept-sms-voice-retirement)
- 피싱 저항 인증 방법 목록: [Microsoft Entra authentication overview](https://learn.microsoft.com/entra/identity/authentication/overview-authentication)
- 레거시 MFA, SSPR 정책에서 인증 방법 정책으로: [Manage authentication methods](https://learn.microsoft.com/entra/identity/authentication/concept-authentication-methods-manage)
- 보안 기본값, 24시간 유예, 디바이스 코드 흐름 차단: [Security defaults in Microsoft Entra ID](https://learn.microsoft.com/entra/fundamentals/security-defaults)
- MFA 라이선스(사용자별 MFA 포함): [Features and licenses for Microsoft Entra MFA](https://learn.microsoft.com/entra/identity/authentication/concept-mfa-licensing)
- Azure 필수 MFA 1·2단계: [Mandatory MFA for Azure and admin portals](https://learn.microsoft.com/entra/identity/authentication/concept-mandatory-multifactor-authentication)
- SSPR 라이선스 구분: [Licensing requirements for Microsoft Entra SSPR](https://learn.microsoft.com/entra/identity/authentication/concept-sspr-licensing)

</details>
