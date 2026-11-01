---
title: "[Troubleshooting] SMS·음성으로만 MFA를 하는 사용자가 있을 때: 2027년 종료 전에 패스키로 옮기기"
date: 2026-11-01 09:09:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 9
tags: [Troubleshooting, Entra ID, MFA, SMS, 음성, 패스키, 등록 캠페인, 인증 방법 정책]
excerpt: "2027-02-01 SMS·음성 MFA 종료(전역 관리자·외부 사용자 2027-07-01) 전에, 대상자를 찾아 패스키로 미리 옮기는 순서"
---

SMS·음성으로만 MFA를 하는 사용자는 지금은 로그인되지만, 2027-02-01 Microsoft 제공 SMS·음성이 종료되면 로그인 중 패스키 등록을 마쳐야 계속 진행할 수 있습니다. 이 강제에는 opt-out이 없으니, 대상자를 찾아 등록 캠페인으로 미리 패스키로 옮기는 순서를 담았습니다.

## 요약

- SMS·음성으로만 MFA를 하는 사용자가 남아 있음. 지금은 되지만 정해진 날짜 이후 로그인 때 패스키 등록이 강제됨
- 2026-09-01 패스키 자동 활성화·등록 안내 시작, 2027-02-01 Microsoft 제공 SMS·음성 종료, 2027-07-01 전역 관리자·외부 사용자 종료
- 2027-02-01 이후 강제(enforcement)에는 **opt-out이 없음**. 미리 옮기지 않으면 SMS만 등록된 사용자는 로그인 중 패스키 등록을 마쳐야 계속 진행 가능
- 대상자 찾기, 패스키 사용 설정, 등록 캠페인, 사용자 안내 순으로 진행. 꼭 필요한 집단만 전화 사업자 검토

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 일정은 공용 클라우드 기준이고 바뀔 수 있으니 실행 전에 문서를 다시 확인하세요. 개념은 [Entra ID 핵심 개념: 인증 편]({{ "/iam/entra-id-authentication/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

---

## 전체 내용

### 1. 상황

조직에 Authenticator 설치를 꺼려 문자(SMS)로만 MFA를 하는 사용자가 꽤 있습니다. SSPR도 휴대폰 문자로 하고 있습니다. Microsoft는 SMS·음성을 더 이상 안전한 인증 방법으로 보지 않고, 패스키를 기본값으로 바꾸는 중입니다.

### 2. 일정(문서)

- **2026-09-01**
    - 변화: SMS·음성이 켜진 사용자에게 패스키 자동 활성화, MFA 로그인 때 등록 안내(기본은 무제한 미루기 가능)
    - 할 일: 사용자 공지, 패스키 배포 준비
- **2026-10-30**
    - 변화: Microsoft Security Store에서 전화 사업자(telephony provider) 구성 가능
    - 할 일: 규정상 SMS가 꼭 필요한 집단만 검토
- **2027-02-01**
    - 변화: Microsoft 제공 SMS·음성 **종료**(전역 관리자·외부 사용자 제외. 내부 게스트는 이 날짜 대상)
    - SMS·음성만 있는 사용자는 로그인 중 **패스키 등록이 강제**됨
    - 할 일: 이 날짜 전에 이전 완료
- **2027-07-01**
    - 변화: 전역 관리자·외부 사용자도 종료
    - 할 일: 관리자 계정 이전 완료

SSPR의 SMS·음성에도 같은 기준이 적용됩니다.

패스키나 Windows Hello for Business 등을 이미 쓰는 사용자는 그대로 쓸 수 있습니다. 강제로 바꿔야 하는 대상은 **쓸 수 있는 MFA 방법이 SMS·음성뿐인** 사용자입니다. SMS·음성이 켜져 있으면 다른 사용자도 건너뛸 수 있는 패스키 등록 안내를 받을 수 있습니다.

2026-09-01~2027-02-01 사이의 자동 활성화·등록 캠페인은 Graph로 임시 opt-out할 수 있지만, 2027-02-01 이후 강제에는 opt-out이 없습니다.

### 3. 대응 순서

#### 3-1. 대상자 찾기

- 문서가 안내하는 분석 PowerShell 스크립트(GitHub `microsoft/entra-sms-voice-usage-analyzer`)를 실행합니다.
    - 전역 읽기 권한자, 인증 정책 관리자, 보안 읽기 권한자 중 하나가 필요합니다.
    - 결과가 0이 아니면 대상 테넌트입니다.
- GUI로는 Entra ID > Authentication methods > Activity > Registration 탭에서 방법별 등록 현황을 봅니다(P1 이상).
- 인증 방법 정책 마이그레이션 상태(Authentication methods > Policies > Manage migration)가 "Migration complete"가 아니면 레거시 MFA 설정에만 SMS가 켜진 사용자도 있을 수 있으니 함께 확인합니다.
- 대상자를 보안 그룹으로 묶어 두면 이후 캠페인과 공지를 그 그룹에만 보낼 수 있습니다.

#### 3-2. 패스키 사용 설정

Entra ID > Authentication methods > Policies > Passkey (FIDO2)를 켜고 대상 그룹을 지정합니다. 패스키는 동기화 패스키(iCloud 키체인, Google 암호 관리자 등)와 기기 바인딩 패스키(Authenticator 앱의 패스키, Windows의 Entra 패스키, FIDO2 보안 키)로 나뉩니다.

#### 3-3. 등록 캠페인

Entra ID > Authentication methods > Registration campaign에서 상태를 Microsoft Managed로 하고, 3-1에서 만든 그룹을 대상으로 지정합니다. 사용자가 다음에 MFA를 완료하면 패스키 등록 안내가 나옵니다.

#### 3-4. 사용자 공지 3단계(문서 권장)

1. 알림: SMS·음성이 종료되는 이유와 날짜, 무엇으로 바뀌는지
2. 행동: 기기별(Windows Hello, iOS, Android) 패스키 등록 방법
3. 재알림: 아직 등록하지 않은 사람에게 다시 안내

#### 3-5. 꼭 SMS가 필요한 집단만 전화 사업자 검토

규제나 업무상 SMS가 반드시 필요한 집단만 근거(규정 이름 등)를 문서로 남기고, Microsoft Security Store의 전화 사업자를 계약합니다. **별도 비용**이 듭니다. 나머지 사용자는 모두 패스키로 옮기는 것이 기본입니다.

#### 현장 근무자 300명이라면

공유 PC를 쓰는 현장 근무자 300명이 SMS로만 MFA를 하고 있다고 해 봅시다. 개인 휴대폰에 앱 설치를 원하지 않는 사람이 많으니, 공유 PC에서는 **FIDO2 보안 키**를 지급하고 개인 휴대폰을 쓰는 사람은 Authenticator 패스키를 등록하게 합니다. 2027년 1월 말까지 Registration 탭으로 진행률을 매주 확인합니다.

### 4. 해결 확인

분석 스크립트를 다시 실행해 SMS·음성 전용 사용자가 0명인지 확인하고, Activity > Usage 탭에서 SMS 사용량이 줄고 패스키 사용량이 늘었는지 봅니다.

### 5. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 일정, 대상 범위, 등록 캠페인, opt-out, 전화 사업자: [Passkeys by default and retirement of Microsoft-provided SMS and voice authentication](https://learn.microsoft.com/entra/identity/authentication/concept-sms-voice-retirement)
- SSPR 포함, 비용, B2C·External ID 영향: [FAQ about SMS and voice retirement](https://learn.microsoft.com/entra/identity/authentication/concept-sms-voice-retirement-faq)
- 인증 방법 활동 보고서 위치와 라이선스: [Authentication Methods Activity](https://learn.microsoft.com/entra/identity/authentication/howto-authentication-methods-activity)
- 패스키 배포 계획: [Plan a phishing-resistant passwordless authentication deployment](https://learn.microsoft.com/entra/identity/authentication/how-to-deploy-phishing-resistant-passwordless-authentication)

</details>
