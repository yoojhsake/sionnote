---
title: "[Troubleshooting] 보안 기본값을 켜려는데 '보안 기본값 관리'가 보이지 않을 때"
date: 2026-11-01 09:07:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 7
tags: [Troubleshooting, Entra ID, 보안 기본값, 조건부 액세스, 사용자별 MFA]
excerpt: "'보안 기본값 관리' 버튼이 없다면 조건부 액세스 정책이 있기 때문입니다. 둘 중 하나만 쓰므로 P1 이상이면 CA 유지가 일반적."
---

보안 기본값을 켜려고 Properties로 갔는데 Manage security defaults 버튼은 없고 "조건부 액세스 정책을 사용 중"이라는 안내만 보인다면, 테넌트에 조건부 액세스 정책이 있기 때문입니다. 둘은 하나만 쓰는 구조이므로, P1 이상이 있으면 조건부 액세스를 유지하는 것이 일반적입니다.

## 요약

- Entra ID > Overview > Properties 아래쪽에 "조건부 액세스 정책을 사용 중이어서 보안 기본값을 켤 수 없다"는 안내만 있고 Manage security defaults 버튼이 없음
- 테넌트에 조건부 액세스 정책이 있어서임. 보안 기본값과 조건부 액세스는 둘 중 하나만 쓰는 구조
- P1 이상이 있으면 조건부 액세스 유지가 일반적. P1이 없거나 정책을 정리할 계획이면 보안 기본값으로 복귀
- 사용자별(레거시) MFA는 어느 쪽을 쓰든 꺼야 함

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 개념은 [Entra ID 핵심 개념: 인증 편]({{ "/iam/entra-id-authentication/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

---

## 전체 내용

### 1. 증상과 화면 상태

Entra ID > Overview > Properties 맨 아래 **Security defaults** 영역은 상태에 따라 세 가지로 보입니다(문서).

| 화면 문구(요지) | 상태 | 버튼 |
|---|---|---|
| 조직이 보안 기본값으로 보호되고 있음 | 보안 기본값 **켜짐** | Manage security defaults 있음 |
| 조건부 액세스 정책을 사용 중이라 보안 기본값을 켤 수 없음 | **조건부 액세스 정책 존재** | 없음(대신 Manage Conditional Access) |
| 조직이 보안 기본값으로 보호되고 있지 않음 | 보안 기본값 **꺼짐**, 정책 없음 | Manage security defaults 있음 |

### 2. 원인과 해결

테넌트에 조건부 액세스 정책이 하나라도 있으면 보안 기본값을 켤 수 없습니다. 그러니 둘 중 무엇을 쓸지부터 정하고(아래 "무엇을 쓸지 고르는 기준"), 보안 기본값으로 가기로 했다면 정책을 기록한 뒤 삭제합니다(아래 "보안 기본값으로 돌아가는 순서").

#### 무엇을 쓸지 고르는 기준

Entra ID P1 이상(예: M365 E3, Business Premium)이 있다면 조건부 액세스를 씁니다. 대상, 예외, 조건을 세밀하게 조정할 수 있습니다.

Free만 있다면 보안 기본값입니다. 스위치 하나로 전원 MFA 등록, 관리자 MFA, 레거시 인증 차단, 디바이스 코드 흐름 차단이 켜집니다(실제 사례: [AADSTS530035]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})).

정책을 만들어 봤지만 관리가 안 되는 경우라면, Microsoft가 만든 Microsoft-managed 정책을 함께 검토하거나 정리한 뒤 보안 기본값으로 돌아갑니다.

보안 기본값이 하는 일을 조건부 액세스로 똑같이 만들 수도 있습니다. 문서에는 보안 기본값을 끌 때 같은 효과를 내는 Microsoft-managed 조건부 액세스 정책이 안내되어 있습니다.

#### 보안 기본값으로 돌아가는 순서

> 운영 테넌트에서는 영향이 큽니다. 먼저 정책 목록과 대상을 기록해 두세요.

1. Entra ID > Conditional Access > Policies에서 정책 목록과 상태를 기록합니다(캡처 또는 내보내기).
2. 모든 정책을 **삭제**합니다.
    - 정책이 **어떤 상태(Off, On, 보고서 전용)로든** 하나라도 남아 있으면 보안 기본값을 켤 수 없습니다(문서).
    - 그래서 1단계의 설정 기록은 삭제 전에 반드시 해야 합니다. 삭제한 정책은 30일 안에는 복원할 수 있습니다.
3. Entra ID > Overview > Properties > Manage security defaults에서 Enabled로 바꾸고 저장합니다. 최소 조건부 액세스 관리자 역할이 필요합니다.
4. 문서 권장대로, 이미 로그인해 있는 사용자도 MFA 등록을 하도록 세션 해지를 고려합니다.

#### 사용자별(레거시) MFA도 함께 정리

사용자별 MFA는 모든 Microsoft 365 조직에서 Entra ID Free로 쓸 수 있지만 **권장하지 않는** 방식입니다. 보안 기본값이나 조건부 액세스를 쓰려면 사용자별 MFA는 꺼야 합니다(문서). 2019년 이후 시작한 조직이라면 대부분 꺼져 있습니다.

헷갈리기 쉬운 점이 하나 있습니다. 조건부 액세스로 MFA를 요구해도 사용자별 MFA 상태 값은 바뀌지 않습니다. 화면에 "사용 안 함"으로 보여도 정상입니다.

#### 흔한 사례: 연습용 정책 하나 때문에 안 켜지는 경우

조건부 액세스를 연습하려고 "MFA 파일럿" 정책을 하나 만들어 **보고서 전용**으로 둔 테넌트에서, 나중에 보안 기본값을 켜려 하자 버튼이 없습니다. 문서상 보고서 전용·Off 정책도 "정책이 있는 상태"로 취급되기 때문입니다.

정책 설정을 기록한 뒤 **삭제**해야 보안 기본값을 켤 수 있습니다. (이 글은 문서 기준이며, 삭제 작업이라 테넌트에서 직접 재현하지는 않았습니다.)

### 3. 해결 확인

Properties 화면이 "조직이 보안 기본값으로 보호되고 있음"으로 바뀌었는지 봅니다. 그리고 다음 로그인 때 MFA 등록 안내가 나오는지 시험 사용자로 확인합니다.

24시간 유예는 테넌트를 **새로 만들 때** 자동으로 켜진 보안 기본값에만 해당합니다. 이 글처럼 기존 테넌트에서 다시 켜는 경우에는 해당하지 않습니다.

### 4. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- 화면 상태 3가지, 사용자별 MFA를 꺼야 함, 2019년 이후 조직: [Set up multifactor authentication for Microsoft 365](https://learn.microsoft.com/microsoft-365/admin/security-and-compliance/set-up-multi-factor-authentication)
- 정책이 어떤 상태로든 있으면 켤 수 없어 삭제 필요: [Set up multifactor authentication for Microsoft 365: Revert to security defaults](https://learn.microsoft.com/microsoft-365/admin/security-and-compliance/set-up-multi-factor-authentication)
- 보안 기본값 켜는 경로, 필요 역할, 24시간 유예, 세션 해지 권장: [Security defaults in Microsoft Entra ID](https://learn.microsoft.com/entra/fundamentals/security-defaults)
- 삭제한 정책 30일 안 복원: [Recover from deletions: Conditional Access policies](https://learn.microsoft.com/entra/architecture/recover-from-deletions)
- Microsoft-managed 정책: [Microsoft-managed Conditional Access policies](https://learn.microsoft.com/entra/identity/conditional-access/managed-policies)
- 사용자별 MFA 비권장, 조건부 액세스는 상태 값을 바꾸지 않음: [사용자별 다단계 인증 사용](https://learn.microsoft.com/ko-kr/entra/identity/authentication/howto-mfa-userstates)

</details>
