---
title: "[Troubleshooting] AADSTS50076·50079 — MFA가 필요하다거나 MFA를 등록하라고 막힐 때"
date: 2026-11-01 09:02:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 2
tags: [Troubleshooting, Entra ID, MFA, AADSTS50076, AADSTS50079, 필수 MFA, Azure CLI, Azure PowerShell, 관리 ID]
excerpt: "50076(MFA 필요)과 50079(MFA 등록 필요)를 구분하고, 사람 사용자·자동화 스크립트·Azure CLI 필수 MFA 상황별로 대처하는 가이드"
---

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 개념은 [Entra ID 핵심 개념 — 인증 편]({{ "/iam/entra-id-authentication/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

## 요약

- **증상**: 로그인 중 MFA를 요구받거나 "보안 정보를 등록하세요" 화면에서 멈춤. 스크립트·앱은 50076·50079 오류로 실패
- **코드 뜻**: 50076 = MFA를 해야 함 / 50079 = MFA를 하려면 먼저 등록해야 함 / 50074 = MFA 요구를 통과하지 못함
- **흔한 원인**: 조건부 액세스·보안 기본값·사용자별 MFA로 새로 MFA가 걸림, 위치가 바뀜, Azure 관리 작업의 필수 MFA
- **대처**: 사람: 등록 안내 / 자동화: 사람 계정 대신 관리 ID·서비스 주체 / CLI·PowerShell: 최신 버전 + 대화형 로그인
- **주의**: 오류를 없애려고 MFA를 끄는 것은 해결이 아님. Azure 필수 MFA는 계정 단위 예외가 없음(2단계는 전역 관리자가 지원 요청으로 일시 해제할 수 있으나 권장하지 않음)

---

## 전체 내용

### 1. 증상

- 사용자: 어제까지 암호만으로 되던 로그인이 오늘부터 Authenticator 승인을 요구하거나, "추가 정보가 필요합니다" 등록 화면이 나옵니다.
- 스크립트: 예약 작업으로 돌던 Azure PowerShell·CLI 스크립트가 리소스를 만들거나 바꾸는 단계에서 실패합니다.

### 2. 먼저 확인할 것

- **50076**
    - 이름(문서): UserStrongAuthClientAuthNRequired
    - 의미: 관리자 설정(조건부 액세스, 사용자별 MFA 등)이나 위치 변경 때문에 **MFA를 해야** 리소스에 접근 가능
- **50079**
    - 이름(문서): UserStrongAuthEnrollmentRequired
    - 의미: MFA를 해야 하는데 **등록된 방법이 없음**. 관리형 사용자는 보안 정보를 등록해야 하고, 페더레이션 사용자는 IdP에서 MFA 클레임을 받아와야 함
- **50074**
    - 이름(문서): UserStrongAuthClientAuthNRequiredInterrupt
    - 의미: MFA가 요구됐지만 통과하지 못함
- **50072**
    - 이름(문서): UserStrongAuthEnrollmentRequiredInterrupt
    - 의미: 2단계 인증 등록이 필요함(대화형)

로그인 로그(Entra ID > Monitoring & health > Sign-in logs)에서 해당 항목을 열고 **Conditional Access** 탭을 보면, 어떤 정책이 MFA를 요구했는지 확인할 수 있습니다. 정책이 보이지 않는데 MFA가 요구됐다면 **보안 기본값**, 사용자별 MFA(레거시), Azure 필수 MFA 중 하나일 가능성이 큽니다. 필수 MFA는 로그인 로그에 MFA를 요구한 애플리케이션이 출처로 표시됩니다.

### 3. 상황별 대처

#### (1) 사람 사용자 — 등록 화면에서 멈춤(50079)

- 사용자에게 `https://myprofile.microsoft.com`의 **보안 정보(Security info)**에서 Authenticator나 패스키를 등록하도록 안내합니다.
- 휴대폰을 바꿨거나 분실해서 등록할 방법이 없으면, 관리자가 임시 액세스 패스(TAP, Temporary Access Pass)를 발급해 첫 등록을 돕습니다.
- 새로 등록하는 사용자는 **SMS보다 패스키·Authenticator**를 우선 안내합니다. Microsoft 제공 SMS·음성 인증은 2027년에 종료될 예정입니다([SMS·음성 MFA 종료 대비]({{ "/iam/troubleshooting/sms-voice-mfa-retirement/" | relative_url }}) 참고).

#### (2) Azure CLI·PowerShell에서 생성·변경·삭제가 실패함

2025-10-01부터 **Azure 필수 MFA 2단계**가 적용되어, Azure CLI·Azure PowerShell·Azure SDK·REST API로 리소스를 **만들거나 바꾸거나 지우는** 사용자 계정은 MFA를 해야 합니다. 읽기 작업은 대상이 아닙니다. 테넌트별로 2026-07-01까지 연기할 수 있었으므로 적용 시점이 조직마다 다를 수 있습니다.

- **클라이언트 버전**: 문서 권장: Azure CLI 2.76 이상, Azure PowerShell 14.3 이상
- **로그인 방식**: MFA를 하지 않은 토큰으로 변경 작업을 하면 클레임 챌린지 오류가 남. 대화형 로그인으로 MFA를 거친 뒤 다시 실행
- **사람 계정을 자동화에 쓰는 중인가**: 관리 ID(Managed Identity) 또는 서비스 주체(Service principal)로 바꾸면 필수 MFA 대상이 아님(서비스 주체는 보안상 인증서 자격 증명 권장)

**예시 — 야간 백업 스크립트가 갑자기 실패**

`svc-backup@contoso.com`처럼 **서비스용으로 만든 일반 사용자 계정**의 ID·암호로 매일 밤 스냅샷을 만드는 스크립트가, 필수 MFA 적용 이후 생성 단계에서 실패합니다. 이 계정을 MFA 예외로 빼는 방법은 없습니다(문서: 모든 사용자 계정에 적용). 스크립트가 Azure VM이나 Automation에서 돈다면 **관리 ID**로 바꾸고, 그 관리 ID에 필요한 최소 Azure 역할만 줍니다.

#### (3) 위치가 바뀌거나 정책이 새로 생김(50076)

- 의도한 정책이라면 사용자에게 MFA를 완료하라고 안내하면 끝납니다.
- 의도하지 않았다면 **What If** 도구(Entra ID > Conditional Access > Policies > What If)로 어떤 정책이 걸리는지 확인합니다. 자세한 방법은 [AADSTS53003 글]({{ "/iam/troubleshooting/aadsts53003-blocked-by-ca/" | relative_url }})에 정리했습니다.

### 4. 해결 확인

- 로그인 로그에서 같은 사용자의 다음 로그인이 **성공**이고, Authentication Details에 MFA 방법이 기록됐는지 봅니다.
- 자동화는 관리 ID로 바꾼 뒤 Service principal sign-ins(서비스 주체 로그인) 탭에서 성공 기록을 확인합니다.

### 5. 하지 말아야 할 것

- **MFA를 끄거나 정책을 지워서 오류를 없애는 것**은 해결이 아닙니다. 특히 관리자 계정은 Microsoft가 피싱 저항 MFA를 권장하는 대상입니다.
- 공용 계정 하나를 여러 사람이 MFA 없이 쓰는 구조는 필수 MFA 적용 이후 계속 문제를 일으킵니다. 개인 계정 + 역할 할당 구조로 바꿉니다.

## 근거 자료

- 50072·50074·50076·50079 정의: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
- Azure 필수 MFA 1·2단계, 권장 클라이언트 버전, 관리 ID·서비스 주체 제외: [Mandatory MFA for Azure and admin portals](https://learn.microsoft.com/entra/identity/authentication/concept-mandatory-multifactor-authentication)
- 조건부 액세스로 MFA 요구: [자습서: Microsoft Entra 다단계 인증 사용](https://learn.microsoft.com/ko-kr/entra/identity/authentication/tutorial-enable-azure-mfa)
- 로그인 로그의 조건부 액세스 탭: [Troubleshoot sign-in problems with Conditional Access](https://learn.microsoft.com/entra/identity/conditional-access/troubleshoot-conditional-access)
