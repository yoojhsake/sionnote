---
title: "[Study] 인증 보안: MFA, Conditional Access, PIM"
date: 2026-10-31 10:05:00 +0900
categories: [study]
phase: 1단계 구조와 신원
seq: 4
tags: [Study, MFA, Conditional Access, PIM, Zero Trust]
excerpt: "CA 정책 하나로 관리자까지 잠길 수 있습니다. 동작 규칙과 Report-only, PIM을 익히는 주간"
---

Conditional Access 정책 하나를 잘못 켜면 관리자까지 잠길 수 있습니다. 그래서 이번 주에는 여러 정책은 모두 충족해야 하고 Block 하나면 차단된다는 동작 규칙, Report-only로 먼저 보는 습관, 관리자 권한을 필요한 시간만 여는 PIM을 익힙니다.

## 요약

- 여러 CA 정책은 모두 충족해야 하고 Block 정책 하나면 그 시점에 차단됨
- 새 정책은 Report-only로 영향도를 본 뒤 켜고 비상 계정은 제외함
- PIM은 Entra ID P2 또는 Entra ID Governance 라이선스가 있어야 씀

12주 학습 로드맵의 4주차입니다. 이전 글: [3주차 하이브리드 ID]({{ "/study/hybrid-identity-study/" | relative_url }}), 다음 글: [5주차 M365 관리 센터]({{ "/study/m365-admin-center-basics/" | relative_url }}), 전체 계획: [학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})

---

## 전체 내용

### 1. 이번 주 용어

MFA, Authentication methods, Authentication strength, Passkey·FIDO2, Windows Hello for Business, Temporary Access Pass(TAP), Conditional Access(CA), Named location, Report-only mode, Security defaults, Legacy authentication, Emergency access(break-glass) account, Identity Protection(sign-in risk·user risk), PIM(Privileged Identity Management), Eligible·Active assignment, JIT(Just-in-time), Zero Trust

자세한 설명은 [IAM 인증 편]({{ "/iam/entra-id-authentication/" | relative_url }})(MFA, 패스키, Security defaults)과 [IAM 접근 제어 편]({{ "/iam/entra-id-access-control/" | relative_url }})(CA, PIM, ID Protection 정책 예시)에 있습니다.

### 2. 개념 설명

#### Conditional Access의 구성

Conditional Access 정책은 **Assignments**와 **Access controls**로 이루어진 if-then 문장입니다.

- Signals: 사용자·그룹, IP 위치, 디바이스(플랫폼·상태), 애플리케이션, 실시간 위험 신호(Identity Protection), Defender for Cloud Apps
- Decisions: Block access, 또는 Grant access with 조건
- Grant controls
    - MFA 요구, Authentication strength 요구
    - 규정 준수(compliant) 디바이스 요구, hybrid joined 디바이스 요구
    - 승인된 클라이언트 앱, 앱 보호 정책
    - 비밀번호 변경, 이용 약관
- Session controls: 로그인 빈도, 지속 브라우저 세션 등 (액세스를 허용한 뒤에만 의미가 있음)

#### 동작 규칙

- 여러 정책이 적용되면 모두 충족해야 합니다. 하나는 MFA, 하나는 compliant device를 요구하면 둘 다 해야 합니다.
- 한 정책 안의 assignments는 AND로 결합됩니다.
- Block 정책이 하나라도 해당되면 그 시점에서 차단됩니다.
- 첫 번째 인증(first-factor)이 끝난 뒤에 평가되므로 DoS 방어 같은 최전방 방어선이 아닙니다.
- Report-only mode는 평가만 하고 강제하지 않습니다. 결과는 Sign-in log 상세의 Conditional Access와 Report-only 탭에 남습니다.

Conditional Access는 Entra ID P1(Microsoft 365 Business Premium 포함)이 필요하고, sign-in risk·user risk 기반 정책(Identity Protection)은 P2가 필요합니다. 모든 고객이 쓸 수 있는 Security defaults는 CA 정책이 있으면 켤 수 없으니 함께 쓰지 않습니다.

Emergency access(break-glass) 계정은 전 관리자 잠김에 대비해 CA에서 제외해 두는 클라우드 전용 계정입니다. 구성과 복구 순서는 [조건부 액세스 정책 실수로 관리자까지 잠겼을 때]({{ "/iam/troubleshooting/ca-lockout-emergency-access/" | relative_url }})에 있습니다.

#### PIM

PIM은 관리자 역할을 상시(permanent) 부여하지 않고 Eligible(자격만 있음)로 두었다가 필요할 때 Active로 활성화하게 합니다. 활성화 때 MFA, 승인(approval), 사유 입력, 시간 제한을 요구할 수 있고, Entra role과 Azure RBAC role 모두 PIM과 연동됩니다.

라이선스(P2 또는 Entra ID Governance) 조건은 다음과 같습니다.

- Eligible·기간 제한 할당을 받는 사용자, 활성화 요청을 승인·거절하는 사용자, access review 대상자·검토자 수만큼 필요합니다.
- 라이선스가 만료되면 Entra role의 Eligible 할당은 제거되고, 상시(permanent) 할당은 그대로 남습니다.

AD/ADFS에는 대응 개념이 없어 시간을 가장 많이 써야 하는 영역입니다.

#### Zero Trust

세 원칙: Verify explicitly, Use least privilege, Assume breach.

### 3. 온프레미스로 번역하면

- Conditional Access는 방화벽 규칙과 GPO의 로그온 제한을 합친 느낌입니다.
- PIM은 Domain Admins에 상시 넣어 두지 않고 필요할 때만 넣었다 빼는 tiered admin 운영의 자동화입니다.

### 4. 실습 (GUI 우선)

1. Entra 관리 센터 Entra ID > 조건부 액세스(Conditional Access) > 정책(Policies)에서 기존 정책의 Assignments와 Access controls를 읽습니다.
2. 새 정책은 Report-only로, 대상은 테스트 사용자만, emergency access 계정은 제외해 만듭니다. 전체 사용자와 관리자에게 On으로 강제하지 않습니다.
3. What If 도구로 사용자, 앱, 위치 조합에 적용되는 정책을 시뮬레이션합니다.
4. 로그인 로그(Sign-in logs) 상세의 Conditional Access·Report-only 탭을 확인합니다.
5. Entra ID > 개요(Overview) > 속성(Properties)에서 Security defaults 상태를 확인합니다.

관련 사례: 정책이 걸린 이유를 로그로 읽기는 [AADSTS53003 글]({{ "/iam/troubleshooting/aadsts53003-blocked-by-ca/" | relative_url }}), Security defaults가 켜지지 않을 때는 [보안 기본값 관리가 보이지 않을 때]({{ "/iam/troubleshooting/security-defaults-cannot-enable/" | relative_url }}).

### 5. 전문가처럼 말하기

> "Conditional Access는 signals를 모아 block이나 grant를 결정하는 Zero Trust policy engine입니다."
>
> "관리자 역할은 PIM으로 eligible assignment를 두고 필요할 때만 JIT로 활성화하게 해서 standing privilege를 없앱니다."

### 6. 자가 점검

<details markdown="1">
<summary>자가 점검 문제와 답 펼쳐 보기 (5문항)</summary>

- [ ] Conditional Access가 평가하는 signals를 다섯 가지 이상 말할 수 있다.
    - 답: 사용자·그룹, IP 위치, 디바이스(플랫폼·상태), 애플리케이션, 실시간 위험 신호(Identity Protection), Defender for Cloud Apps입니다.
- [ ] 정책이 여러 개 걸릴 때의 결합 규칙과 block의 우선순위를 설명할 수 있다.
    - 답: 적용되는 모든 정책의 요구를 충족해야 하고, 한 정책 안의 assignments는 AND로 결합됩니다. Block 정책이 하나라도 해당되면 그 시점에서 차단됩니다.
- [ ] Report-only mode를 쓰는 이유와 결과 확인 위치를 말할 수 있다.
    - 답: 강제하지 않고 평가만 해서 영향도를 보기 위해서입니다. 결과는 Sign-in log 상세의 Conditional Access와 Report-only 탭에 남습니다.
- [ ] P1과 P2로 나뉘는 기능을 구분할 수 있다.
    - 답: Conditional Access는 P1(Microsoft 365 Business Premium 포함), sign-in risk·user risk 기반 정책(Identity Protection)은 P2입니다. PIM은 P2 또는 Entra ID Governance입니다.
- [ ] Eligible과 Active의 차이를 설명할 수 있다.
    - 답: Eligible은 자격만 있는 상태이고, 필요할 때 MFA·승인·사유·시간 제한을 거쳐 Active로 활성화해야 권한이 생깁니다.

</details>

### 7. 영상 (한글 우선)

- 한글: 확인 불가. CA와 PIM을 다룬 한글 유튜브 영상을 검색했지만 찾지 못했습니다. 대신 Microsoft Learn(한국어)의 "조건부 액세스란?" 문서를 먼저 읽으세요.
- 영문 보완
    - [Enforce MFA with Conditional Access (Step-by-Step Lab)](https://www.youtube.com/watch?v=MIvuAHIVTT4): CyberMax, 5분. 조건부 액세스 정책으로 MFA를 강제하고 테스트 기기로 로그인해 보는 실습
    - [Entra ID Security: Identity Perimeter, Conditional Access, MFA & PIM](https://www.youtube.com/watch?v=4mTV4nb5Ex4): m365 Show, 19분. 조건부 액세스, MFA, PIM을 개념 중심으로 설명(화면 실습은 거의 없음)
    - [Entra ID Security: MFA, Conditional Access & Risk Protection](https://www.youtube.com/watch?v=q-OkGHwXAj0): KryptoMindz, 9분. 위험 기반 보호(Identity Protection), 보고 전용(report-only) 모드, P2 필요 범위

### 8. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- 문서: [Require MFA for administrators: Create a Conditional Access policy](https://learn.microsoft.com/entra/identity/conditional-access/policy-old-require-mfa-admin#create-a-conditional-access-policy). 현재 경로 Entra ID > Conditional Access > Policies, Report-only로 만든 뒤 On
- 문서: [Security defaults in Microsoft Entra ID](https://learn.microsoft.com/entra/fundamentals/security-defaults#enabling-security-defaults). 경로 Entra ID > Overview > Properties > Manage security defaults
- 문서: [Microsoft Entra ID Governance licensing fundamentals: Privileged Identity Management](https://learn.microsoft.com/entra/id-governance/licensing-fundamentals#privileged-identity-management). PIM은 Entra ID P2 또는 Entra ID Governance, 라이선스가 필요한 사용자 범주, 만료 시 동작

</details>
