---
title: "[Troubleshooting] AADSTS50076·50079: MFA가 필요하다거나 MFA를 등록하라고 막힐 때"
date: 2026-11-01 09:02:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 2
tags: [Troubleshooting, Entra ID, MFA, AADSTS50076, AADSTS50079, 필수 MFA, Azure CLI, Azure PowerShell, 관리 ID]
excerpt: "50076은 MFA를 해야 함, 50079는 먼저 등록해야 함. 사람 사용자, 자동화 스크립트, Azure CLI 필수 MFA마다 대처가 다릅니다"
---

스크립트가 AADSTS50076으로 실패하거나, 로그인 중 "보안 정보를 등록하세요" 화면에서 멈췄나요? 50076은 MFA를 해야 한다는 뜻, 50079는 먼저 등록하라는 뜻이고, 사람 사용자, 자동화 스크립트, Azure CLI 필수 MFA마다 대처가 다르며 MFA를 끄는 것은 해결이 아닙니다.

## 요약

- 정책이 MFA를 요구한 것이며 끄거나 지우는 것은 해결이 아님
- 사람은 등록을 안내하고 자동화는 관리 ID나 서비스 주체로 옮김
- Azure 필수 MFA는 사용자 계정 단위 예외가 없음

> Microsoft Learn 문서(2026-11-01 확인) 기준입니다. 오류 상황은 테넌트에서 재현하지 않았고, 설정 화면은 샌드박스 테넌트에서 직접 열어 캡처했습니다. 함께 볼 글: [Entra ID 핵심 개념: 인증 편]({{ "/iam/entra-id-authentication/" | relative_url }}), [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }}).

---

## 전체 내용

### 1. 증상

- 사례 1(사람): 암호만으로 되던 로그인에 Authenticator 승인이나 "추가 정보가 필요합니다" 등록 화면이 나옵니다.
- 사례 2(스크립트): 서비스용 일반 사용자 계정(`svc-backup@contoso.com`)으로 도는 야간 스냅샷 스크립트가 생성 단계에서 실패합니다.

### 2. 원인 및 분석

조건부 액세스, 보안 기본값, 사용자별 MFA, Azure 필수 MFA 중 하나가 MFA를 요구했습니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-aadsts50076-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-aadsts50076.png" | relative_url }}" alt="MFA 오류를 사람 사용자와 자동화로 나눠 대처하는 표" loading="lazy"></picture>

*그림 1. 누구에게 나는 오류인지에 따른 대처*

사례 2는 Azure 필수 MFA 2단계입니다([문서](https://learn.microsoft.com/entra/identity/authentication/concept-mandatory-multifactor-authentication)).

- 2025-10-01부터 Azure CLI·PowerShell·SDK·REST API로 리소스를 생성·변경·삭제하는 모든 사용자 계정은 MFA가 필요합니다(읽기 제외, 계정 예외 없음). 테넌트별로 2026-07-01까지 연기 가능했습니다.
- MFA 없는 토큰으로 변경하면 클레임 챌린지 오류가 납니다. 관리 ID(Managed Identity)와 서비스 주체(Service principal)는 제외입니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 코드 뜻과 정책 출처

- **50076**
    - 이름(문서): UserStrongAuthClientAuthNRequired
    - 의미: 관리자 설정(조건부 액세스, 사용자별 MFA 등)이나 위치 변경 때문에 MFA를 해야 리소스에 접근 가능
- **50079**
    - 이름(문서): UserStrongAuthEnrollmentRequired
    - 의미: MFA를 해야 하는데 등록된 방법이 없음. 관리형 사용자는 보안 정보를 등록해야 하고, 페더레이션 사용자는 IdP에서 MFA 클레임을 받아와야 함
- **50074**
    - 이름(문서): UserStrongAuthClientAuthNRequiredInterrupt
    - 의미: MFA가 요구됐지만 통과하지 못함
- **50072**
    - 이름(문서): UserStrongAuthEnrollmentRequiredInterrupt
    - 의미: 2단계 인증 등록이 필요함(대화형)

로그인 로그(Entra ID > Monitoring & health > Sign-in logs)에서 해당 항목을 열고 **Conditional Access** 탭을 보면 어떤 정책이 MFA를 요구했는지 나옵니다. 정책이 보이지 않는데 MFA가 요구됐다면 보안 기본값, 사용자별 MFA(레거시), Azure 필수 MFA 중 하나일 가능성이 큽니다. 필수 MFA는 로그인 로그에 MFA를 요구한 애플리케이션이 출처로 표시됩니다.

</details>

### 3. 결론

`정책이 MFA 요구 → 등록 방법 없음(50079) 또는 MFA 미완료(50076) → 로그인·변경 작업 실패`

### 4. 권고방안

1. 조치
    - 사람(50079): `https://myprofile.microsoft.com`의 보안 정보(Security info)에서 Authenticator나 패스키를 등록합니다. 기기가 없으면 관리자가 TAP(Temporary Access Pass)를 발급합니다. Microsoft 제공 SMS·음성 인증은 2027년 종료 예정입니다([SMS·음성 MFA 종료 대비]({{ "/iam/troubleshooting/sms-voice-mfa-retirement/" | relative_url }})).
    - 자동화: 관리 ID(Azure VM, Automation) 또는 서비스 주체(인증서 권장)로 바꾸고 최소 Azure 역할만 줍니다. 클라이언트는 Azure CLI 2.76, Azure PowerShell 14.3 이상(문서 권장). 사람의 변경 작업은 대화형 MFA 후 재실행합니다.
    - 50076: 의도하지 않은 정책이면 What If(Entra ID > Conditional Access > Policies > What If)로 찾습니다([AADSTS53003 글]({{ "/iam/troubleshooting/aadsts53003-blocked-by-ca/" | relative_url }})).
2. 확인: 로그인 로그의 다음 로그인이 성공이고 Authentication Details에 MFA 방법이 있으면 해결입니다(자동화는 Service principal sign-ins 탭).
3. 하지 말 것
    - MFA를 끄거나 정책을 지우기(관리자 계정은 피싱 저항 MFA 권장 대상)
    - 공용 계정을 여럿이 MFA 없이 쓰기(개인 계정 + 역할 할당으로 전환)

<details markdown="1">
<summary>화면으로 경로 따라가기: 로그인 로그의 조건부 액세스 탭과 What If (그림 2장)</summary>

![로그인 세부 정보의 조건부 액세스 탭. 적용된 정책이 없어 해당 없음 표시]({{ "/assets/images/2026/11/guide-signin-ca-tab.png" | relative_url }})

*그림 2. Entra ID > 로그인 로그에서 해당 항목을 열고 조건부 액세스 탭을 봅니다. 어떤 정책이 MFA를 요구했는지 여기에 나옵니다. 이 샌드박스는 정책이 없어 "해당 없음"입니다. 정책이 안 보이는데 MFA가 요구됐다면 본문의 보안 기본값, 사용자별 MFA, Azure 필수 MFA를 의심합니다. 이 화면은 다른 오류(50126) 항목으로, 탭 위치를 보여 주는 용도입니다.*

![가상(What If) 화면. 사용자, 클라우드 앱, 로그인 조건을 입력하는 양식]({{ "/assets/images/2026/11/guide-ca-whatif.png" | relative_url }})

*그림 3. Entra ID > 조건부 액세스 > 정책 > 가상(What If). 의도하지 않은 MFA 요구의 원인 정책을 찾을 때 사용자, 앱, 로그인 조건을 넣어 평가합니다. 이번 캡처에서는 평가는 돌리지 않았습니다.*

화면은 설정을 바꾸지 않고 샌드박스 테넌트에서 열어 캡처했습니다. 테넌트 이름, 테넌트 ID, 계정, IP, 요청 ID는 가렸고, 사용 중인 라이선스와 정책에 따라 메뉴 이름과 값은 다를 수 있습니다.

</details>

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 50072, 50074, 50076, 50079 정의: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
- Azure 필수 MFA 1단계와 2단계, 권장 클라이언트 버전, 관리 ID와 서비스 주체 제외: [Mandatory MFA for Azure and admin portals](https://learn.microsoft.com/entra/identity/authentication/concept-mandatory-multifactor-authentication)
- 조건부 액세스로 MFA 요구: [자습서: Microsoft Entra 다단계 인증 사용](https://learn.microsoft.com/ko-kr/entra/identity/authentication/tutorial-enable-azure-mfa)
- 로그인 로그의 조건부 액세스 탭: [Troubleshoot sign-in problems with Conditional Access](https://learn.microsoft.com/entra/identity/conditional-access/troubleshoot-conditional-access)

</details>
