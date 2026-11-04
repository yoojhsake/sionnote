---
title: "[IAM] Microsoft Entra ID 핵심 개념: 접근 제어(조건부 액세스, PIM, ID Protection)"
date: 2026-11-01 08:58:00 +0900
categories: [iam]
tags: [IAM, Entra ID, 조건부 액세스, 보고서 전용, PIM, ID Protection, 위험 기반 정책]
excerpt: "같은 계정도 위치, 기기, 위험에 따라 다르게 다룹니다. 조건부 액세스 결합 방식, PIM, ID Protection 대응을 그림과 예시로."
---

같은 계정이라도 어디서, 어떤 기기로, 얼마나 위험하게 들어오느냐에 따라 접근을 다르게 다뤄야 합니다. 다 읽고 나면 조건부 액세스 정책이 합쳐지는 방식, PIM으로 관리자 권한을 필요할 때만 켜는 흐름, ID Protection 위험에 대응하는 방법을 직접 설명할 수 있습니다.

읽는 데 20분 정도 걸리고, 다루는 내용은 이렇습니다.

- 조건부 액세스 정책이 평가되고 합쳐지는 방식
- PIM의 적격·활성 흐름과 쓰는 상황
- ID Protection의 탐지, 위험 수준, 대응과 필요한 라이선스

## 요약

- 해당되는 조건부 액세스 정책은 모두 적용되고 차단이 하나라도 있으면 차단됨
- 새 정책은 보고서 전용으로 먼저 켜고 관리자 권한은 PIM으로 필요할 때만 켬
- 옛 ID Protection 위험 정책은 2026-10-01에 종료되어 조건부 액세스로 옮겨야 함

> Entra ID 핵심 개념 시리즈: [기초]({{ "/iam/what-is-entra-id/" | relative_url }}) · [오류 코드]({{ "/iam/entra-id-error-codes/" | relative_url }}) · [인증]({{ "/iam/entra-id-authentication/" | relative_url }}) · **접근 제어**(지금 글) · [하이브리드·운영]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}) · [용어집]({{ "/iam/entra-id-glossary/" | relative_url }})

근거: Microsoft Learn 공식 문서(2026-11-01 확인). 날짜나 라이선스처럼 바뀔 수 있는 내용은 문서로 다시 확인했습니다. 낯선 용어는 [용어집]({{ "/iam/entra-id-glossary/" | relative_url }})을 함께 보세요.

---

## 전체 내용

### 1. 조건부 액세스(Conditional Access)

조건부 액세스는 "만약(If) 이런 조건이면, 이렇게(Then) 하라"를 정하는 Entra ID의 정책 엔진으로, **제로 트러스트(Zero Trust)**를 적용하는 도구입니다. **P1 이상**이 필요합니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-conditional-access-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-conditional-access.png" | relative_url }}" alt="신호, 정책 평가, 차단·허용 요구 조건·세션 제어" loading="lazy"></picture>

*그림 1. 조건부 액세스의 구조*

자주 나오는 말: 명명된 위치(Named location)는 회사 IP 범위나 국가처럼 이름을 붙여 둔 위치 조건입니다. 준수 기기(Compliant device)는 Intune 준수 정책을 통과한 기기입니다([기초와 구조 편]({{ "/iam/what-is-entra-id/" | relative_url }})의 디바이스). 인증 강도(Authentication strength)는 "MFA면 아무거나"가 아니라 "피싱 저항 MFA만"처럼 허용할 인증 방법을 정하는 요구 조건입니다.

정책 예시입니다.

- 관리자 보호
    - If (조건): 전역 관리자 등 관리자 역할이 모든 리소스에 로그인
    - Then (제어): 인증 강도 = 피싱 저항 MFA
- 레거시 인증 차단
    - If (조건): 클라이언트 앱 = Exchange ActiveSync, 기타 클라이언트
    - Then (제어): 차단
- 해외 접속 통제
    - If (조건): 대상 = 모든 리소스, 위치 = 허용 국가 목록 외
    - Then (제어): 차단
- 회사 기기만 허용
    - If (조건): 대상 = SharePoint, OneDrive
    - Then (제어): 준수 기기 또는 하이브리드 조인 기기 요구
- 위험 로그인 대응(P2)
    - If (조건): 로그인 위험 = 중간 이상
    - Then (제어): 인증 강도 '다단계 인증' + 로그인 빈도 '매번' (피싱 저항 MFA는 이미 그 방법을 가진 사용자 대상 정책으로 따로)

#### 여러 정책이 동시에 해당하면

해당되는 정책은 모두 평가됩니다. 차단 정책이 하나라도 걸리면 접근할 수 없고, 그렇지 않으면 각 정책이 요구하는 조건을 모두 충족해야 합니다. "가장 엄격한 정책 하나만 적용"이 아닙니다.

#### 정책을 켜기 전에

- 새 정책은 보고서 전용(Report-only)으로 켜서 로그인 로그에서 영향을 확인합니다.
- 긴급 액세스 계정은 차단·제한 정책에서 제외합니다. 하이브리드 환경이라면 문서 권장대로 디렉터리 동기화 계정(Directory Synchronization Accounts)도 제외 대상에 넣습니다.
- GUI 경로: Entra ID > Conditional Access(조건부 액세스) > Policies(정책) > New policy(새 정책)
- 정책이 왜 걸렸는지는 로그인 로그의 Conditional Access 탭과 What If 도구로 봅니다(4장 AADSTS53003 글).

### 2. PIM(Privileged Identity Management)

관리자 권한을 필요할 때만 켜는(JIT, Just-In-Time) 기능으로, **P2 또는 ID Governance**가 필요합니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-pim-flow-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-pim-flow.png" | relative_url }}" alt="적격 할당, 활성화 요청, 활성, 자동 만료 순서" loading="lazy"></picture>

*그림 2. PIM 동작 흐름*

적격(Eligible) 할당을 받으면 평소엔 권한이 없고 쓸 수 있는 자격만 가집니다. 활성화 조건으로 MFA, 사유 입력, 티켓 번호, 승인자 승인을 걸 수 있고, 최대 활성 시간이 지나면 자동 회수됩니다.

- 감사: 누가, 언제, 왜 활성화했는지 기록. 역할 할당 액세스 검토
- 적용 범위: Entra 역할, Azure 리소스 역할(Azure RBAC), PIM for Groups(그룹 멤버·소유자)

예: 한 달에 한 번 Exchange 설정을 바꾸는 담당자가 **Exchange 관리자** 역할을 적격으로 받아 두고, 작업 때 사유("변경 티켓 CHG-1234")와 MFA를 거쳐 2시간만 활성화합니다.

하루 종일 쓰는 헬프데스크 업무라면 처음부터 작은 역할([기초와 구조 편]({{ "/iam/what-is-entra-id/" | relative_url }})의 관리자 역할)을 상시로 주는 편이 현실적입니다.

### 3. ID Protection

Microsoft의 신호(signals)로 위험한 로그인과 위험한 사용자를 탐지하고, 조건부 액세스로 자동 대응하는 기능입니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-id-protection-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-id-protection.png" | relative_url }}" alt="탐지, 위험 수준, 대응 흐름" loading="lazy"></picture>

*그림 3. ID Protection: 탐지, 위험 수준, 조건부 액세스 대응*

| 탐지(공식 이름) | 의미 | 탐지 라이선스 |
|---|---|---|
| Leaked credentials(유출된 자격 증명) | 유출된 ID·암호가 실제 암호 해시와 일치(사용자 위험, 항상 높음) | Free·P1 |
| Anonymous IP address(익명 IP 주소) | Tor·익명 VPN에서 로그인 | Free·P1 |
| Atypical travel(비정상 이동) | 짧은 시간에 서로 먼 두 위치에서 로그인 | P2 |
| Unfamiliar sign-in properties(낯선 로그인 속성) | 평소와 다른 로그인 속성 | P2 |
| Password spray(암호 스프레이) | 암호 스프레이 공격으로 실제 암호가 일치 | P2 |
| Anomalous token(비정상 토큰) | 토큰 재사용이 의심되는 비정상 토큰 | P2 |

- 탐지가 되어도 위험 기반 정책, 전체 보고서, 알림은 **P2**가 필요합니다.
    - Free·P1에서는 P2 전용 탐지가 이름 없이 "Additional risk detected"로만 보이고, 위험한 사용자 보고서도 중간·높음만 제한적으로 보입니다.
- "Impossible travel"은 Defender for Cloud Apps에서 오는 별개의 탐지로, P2와 Defender for Cloud Apps 라이선스가 함께 필요합니다.
- ID Protection 화면에서 만들던 옛 사용자 위험·로그인 위험 정책은 2026-10-01에 종료됐습니다.
    - 지금은 조건부 액세스의 위험 기반 정책으로 만들고, 사용자 위험에는 위험 해결 요구(Require risk remediation) 제어를 권장합니다.
    - 이 제어는 암호 사용자에게는 안전한 암호 변경을, 암호 없는 사용자에게는 세션 해지 후 재로그인을 요구합니다.

#### 유출 자격 증명이 탐지되면

사용자 위험이 높음이 되면 사용자 위험 정책(P2, 위험 해결 요구)이 다음 로그인 때 MFA 후 안전한 암호 변경을 요구하고, 변경이 끝나면 위험이 해제됩니다. 동기화 사용자를 검사하려면 PHS가 필요하고(클라우드 전용 사용자는 PHS 없이 탐지), 하이브리드 사용자가 클라우드에서 암호를 바꿔 해결하려면 쓰기 저장도 켜져 있어야 합니다.

---

### 4. 관련 트러블슈팅

- 조건부 액세스 차단 → [AADSTS53003: 조건부 액세스 정책 때문에 차단될 때]({{ "/iam/troubleshooting/aadsts53003-blocked-by-ca/" | relative_url }})
- 정책 실수로 관리자까지 잠김 → [조건부 액세스 정책 실수로 관리자까지 잠겼을 때: 긴급 액세스 계정]({{ "/iam/troubleshooting/ca-lockout-emergency-access/" | relative_url }})
- 보안 기본값의 디바이스 코드 차단(실제 사례) → [Exchange Online 장치 코드 로그인이 AADSTS530035로 막힘]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})

### 5. 확인 문제

<details markdown="1">
<summary>1. A 정책은 MFA를, B 정책은 준수 기기를 요구합니다. 둘 다 해당되면?</summary>

**둘 다 충족**해야 합니다. 차단 정책이 하나라도 있으면 차단됩니다.

</details>

<details markdown="1">
<summary>2. 새 조건부 액세스 정책을 만들 때 처음 켜는 모드와 반드시 제외할 계정은?</summary>

**보고서 전용(Report-only)** 모드로 먼저 켜고, **긴급 액세스 계정**을 차단·제한 정책에서 제외합니다.

</details>

### 6. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 조건부 액세스 정책 결합 방식: [Build a Conditional Access policy](https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-policies)
- ID Protection 탐지와 라이선스: [What are risk detections?](https://learn.microsoft.com/entra/id-protection/concept-identity-protection-risks)
- 옛 위험 정책 종료, 위험 해결 요구: [Configure and enable risk policies](https://learn.microsoft.com/entra/id-protection/howto-identity-protection-configure-risk-policies)
- PIM, 액세스 검토 라이선스: [ID Governance licensing fundamentals](https://learn.microsoft.com/entra/id-governance/licensing-fundamentals)

</details>
