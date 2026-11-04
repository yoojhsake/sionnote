---
title: "[Troubleshooting] 조건부 액세스 정책 실수로 관리자까지 잠겼을 때: 긴급 액세스 계정"
date: 2026-11-01 09:05:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 5
tags: [Troubleshooting, Entra ID, 조건부 액세스, 긴급 액세스 계정, Break-glass, 패스키, 잠김]
excerpt: "CA 정책 실수로 관리자까지 53003에 막혔다. 긴급 액세스 계정이 있으면 바로 풀고, 없으면 Microsoft 지원뿐이다"
---

새 조건부 액세스 정책을 켠 직후 관리자 계정까지 53003으로 막혀 관리 센터에 들어갈 수 없게 됐습니다. 긴급 액세스 계정(Break-glass)이 있으면 그 계정으로 들어가 정책을 끄면 되지만, 없으면 테넌트 안에서 풀 방법이 없고 Microsoft 지원을 거쳐야 합니다.

## 요약

- 잠김은 복구보다 준비의 문제이며 긴급 계정이 없으면 지원 요청뿐임
- 클라우드 전용 긴급 계정 2개 이상을 모든 차단 정책에서 제외해 둬야 함
- 긴급 계정도 필수 MFA 대상이므로 패스키 같은 인증을 등록해야 함

> Microsoft Learn 문서(2026-11-01 확인) 기준이며, 테넌트에서 재현하지는 않았습니다. 함께 볼 글: [Entra ID 핵심 개념: 접근 제어 편]({{ "/iam/entra-id-access-control/" | relative_url }}), [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }}).

---

## 전체 내용

### 1. 증상

※ 아래 증상은 문서 내용을 바탕으로 가정한 예시이며 실제 테넌트에서 재현한 것이 아닙니다.

- "모든 사용자 + 모든 리소스 + 허용 국가 외 차단" 정책을 바로 **켜기**로 저장했습니다.
- 저장 직후 본인을 포함한 관리자 전원이 53003으로 막혀 관리 센터에 들어갈 수 없습니다.

### 2. 원인 및 분석

차단 정책은 제외 대상이 아닌 모든 계정에 바로 적용되므로, 정책 실수에 대비해 차단 정책에서 제외한 긴급 액세스 계정을 두라고 문서는 권합니다([Manage emergency access accounts](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access)).

- 정책의 허용 국가 / 실제 로그인 위치(가정): 회사 VPN의 인터넷 출구가 **해외 데이터센터(허용 국가 외)**
- 그 IP가 명명된 위치(신뢰 위치)로 예외 처리되지 않은 채 정책이 켜짐

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-ca-lockout-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-ca-lockout.png" | relative_url }}" alt="긴급 액세스 계정으로 정책을 끄고(복구) 확인하고, 예방·배포 습관까지 이어지는 5단계" loading="lazy"></picture>

*그림 1. 복구(1~3)와 재발 방지(4~5) 5단계*

### 3. 결론

`(가정) VPN 출구 IP가 허용 국가 외 → 예외 없이 차단 정책 켜기 → 관리자 전원 53003`

긴급 계정이 있으면 그 계정으로 정책을 끄고, 없거나 그 계정마저 정책에 걸려 있으면 테넌트 안에서 풀 방법이 없어 소유권 확인 절차 때문에 오래 걸리는 Microsoft 지원을 거쳐야 합니다.

### 4. 권고방안

1. 조치: **긴급 액세스 계정**으로 Entra 관리 센터에 로그인해 Entra ID > Conditional Access > Policies에서 방금 바꾼 정책을 Off(사용 안 함) 또는 Report-only(보고서 전용)로 바꿉니다. 정책을 고친 뒤(예: VPN 출구 IP를 명명된 위치에 추가) 보고서 전용으로 며칠 운영하며 로그인 로그로 영향을 봅니다.
2. 조치 후 확인: 일반 관리자 계정으로 다시 로그인되는지 봅니다. 긴급 계정 사용은 보안 사고처럼 기록하고, 사용 후 자격 증명을 점검합니다.
3. 예방: 클라우드 전용 긴급 계정 2개 이상을 모든 차단 정책에서 제외하고 패스키(FIDO2)를 등록합니다. 필수 MFA는 긴급 계정에도 예외 없이 적용됩니다. 전체 권장 구성은 아래 표에 있습니다.
4. 배포 습관: 새 정책은 **보고서 전용 → 로그 확인 → 켜기** 순서로만 배포하고, 보고서 전용으로 저장한 뒤 What If로 긴급 계정과 내 관리자 계정의 평가 결과를 봅니다(What If는 켜기·보고서 전용 정책만 평가합니다). 정책 변경에 추가 인증을 요구하는 보호된 작업(Protected actions)도 걸어 둡니다.
5. 하지 말아야 할 것: 긴급 계정을 "MFA 없는 계정"이나 PIM 적격으로 두지 않습니다.

<details markdown="1">
<summary>긴급 액세스 계정의 공식 권장 구성과 예시 보기 (10항목)</summary>

| 항목 | 권장(문서) | 이유 |
|---|---|---|
| 개수 | 2개 이상 | 하나가 문제가 생겨도 다른 하나로 접근 |
| 계정 종류 | 클라우드 전용, `*.onmicrosoft.com` 도메인, 페더레이션이나 온-프레미스 동기화 안 함 | AD FS나 동기화 장애와 무관하게 로그인 |
| 역할 | 전역 관리자 상시(Active) 할당. PIM 적격으로 두지 않음 | 활성화 절차 자체가 막힐 수 있음 |
| 인증 | 패스키(FIDO2) 권장, PKI가 있으면 인증서 기반 인증 | 피싱 저항 + Azure 필수 MFA 충족. 필수 MFA는 긴급 계정에도 예외 없이 적용되므로 "MFA 없는 계정"으로 두면 안 됨 |
| 개인 기기 의존 | MFA를 개인 휴대폰이나 개인 이메일에 묶지 않음 | 담당자 퇴사, 분실 대비 |
| 조건부 액세스 | 로그인을 차단하거나 제한하는 모든 정책에서 제외. 보고서 전용 정책은 지금은 차단하지 않아 문서상 제외가 필수는 아니지만, 나중에 켜게 되므로 만들 때부터 제외해 두는 것이 안전 | 정책 실수가 곧 영구 잠김이 되지 않게 |
| 이름 | "break glass"처럼 티 나는 이름 피하기 | 공격 대상이 되기 쉬움 |
| 보관 | 보안 키와 자격 증명을 분리 보관(예: 서로 다른 금고) | 한 곳 사고로 둘 다 잃지 않게 |
| 모니터링 | 긴급 계정 로그인이나 역할 변경 시 경보 | 사전 승인 없는 사용은 사고로 취급 |
| 점검 | 정기적으로 실제 로그인 테스트 | 막상 필요할 때 안 되는 일 방지 |

구성 예: `ops-k7q2@contoso.onmicrosoft.com`에는 FIDO2 보안 키를 등록해 본사 금고에, `ops-m3x9@...`에는 다른 보안 키를 등록해 재해 복구 센터 금고에 둡니다. 이름에는 "긴급", "관리자" 같은 용도를 드러내지 않습니다. 두 계정 모두 차단 정책에서 제외하고, Log Analytics(로그 내보내기에 P1 이상과 Azure 구독 필요)에서 두 계정의 로그인을 감지하면 보안 담당자에게 즉시 알림이 가도록 합니다.

</details>

관련 글: [AADSTS53003: 조건부 액세스 정책 때문에 접근이 차단될 때]({{ "/iam/troubleshooting/aadsts53003-blocked-by-ca/" | relative_url }}) · [Entra ID 핵심 개념: 접근 제어 편]({{ "/iam/entra-id-access-control/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 긴급 액세스 계정의 생성, 인증, 제외, 보관, 모니터링, 점검: [Manage emergency access accounts in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access)
- PIM 적격으로 두지 않기, 티 나는 이름 피하기, 개인 기기에 묶지 않기: [Zero Trust: Configure emergency accounts](https://learn.microsoft.com/security/zero-trust/adopt/implement-privileged-access-identity#step-7-configure-emergency-accounts)
- 정책 사용자 제외 권장: [Require phishing-resistant MFA for administrators](https://learn.microsoft.com/entra/identity/conditional-access/policy-admin-phish-resistant-mfa)
- 보고서 전용 배포, 보호된 작업: [Plan a Conditional Access deployment](https://learn.microsoft.com/entra/identity/conditional-access/plan-conditional-access)

</details>
