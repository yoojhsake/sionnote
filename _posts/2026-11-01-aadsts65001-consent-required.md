---
title: "[Troubleshooting] '관리자 승인 필요'·AADSTS65001·AADSTS90094 — 앱 권한 동의가 막힐 때"
date: 2026-11-01 09:12:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 12
tags: [Troubleshooting, Entra ID, 동의, Consent, AADSTS65001, AADSTS90094, 관리자 동의 워크플로]
excerpt: "앱이 메일·파일 권한을 요청할 때 '관리자 승인 필요'가 뜨는 이유(사용자 동의 제한, 관리자 전용 권한, 위험 앱)와, 무작정 테넌트 전체 동의를 누르기 전에 확인할 것"
---

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 개념은 [Entra ID 핵심 개념 — 기초와 구조 편]({{ "/iam/what-is-entra-id/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

## 요약

- **증상**: 앱 로그인 때 "관리자 승인 필요(Need admin approval)" 화면, 또는 AADSTS65001(동의하지 않음)·AADSTS90094(관리자만 줄 수 있는 권한)·AADSTS90093
- **흔한 원인**
    - 테넌트가 **사용자 동의를 끄거나 제한**함
    - 앱이 **관리자만 동의할 수 있는 권한**을 요청
    - Microsoft가 **위험한 앱**으로 판단
    - 할당 필요 앱인데 관리자 동의가 아직 없음
- **대처**: 앱이 믿을 만한지 먼저 검토 → 필요하면 관리자가 테넌트 전체 관리자 동의 → 반복되면 관리자 동의 워크플로 켜기
- **주의**: 동의는 앱에 메일·파일 접근 권한을 주는 일입니다. 오류를 없애려고 확인 없이 동의하면 동의 피싱에 그대로 당합니다

---

## 전체 내용

### 1. 증상

직원이 업무용으로 찾은 메일 정리 앱에 회사 계정으로 로그인하자 "관리자 승인 필요 — 이 앱은 조직의 리소스에 접근하려면 관리자만 줄 수 있는 권한이 필요합니다"가 나옵니다. 개발자가 만든 사내 앱은 `AADSTS65001: The user or administrator has not consented to use the application…` 오류를 받습니다.

### 2. 먼저 확인할 것

- **AADSTS65001**: 사용자나 관리자가 이 앱 사용에 **동의한 적이 없음**
- **AADSTS90093**: 관리자가 사용자 동의를 꺼 둔 정책 때문에 막힘, 또는 사용자가 줄 수 없는 권한을 요청함
- **AADSTS90094**: **관리자만 줄 수 있는 권한**을 요청함. 또는 위험한 요청으로 판단되어 사용자 동의가 막힘
- **AADSTS900941**: 앱이 위험하다고 판단되어 관리자 동의가 필요(관리자 동의 워크플로가 꺼져 있을 때)
- **AADSTS900981**: 위험한 앱에 대한 관리자 동의 요청이 접수됨(워크플로가 켜져 있을 때)

관리자는 다음을 봅니다.

1. Entra ID > Enterprise apps > Consent and permissions(동의 및 권한) > User consent settings(사용자 동의 설정): 사용자가 어떤 앱에 동의할 수 있는지
2. 해당 앱(엔터프라이즈 앱) > Security > Permissions(권한): 앱이 요청하는 권한 목록
3. 감사 로그에서 범주 **ApplicationManagement**, 활동 **Consent to application**, 사유 Risky application detected 기록이 있는지(위험 앱으로 막힌 경우)

### 3. 원인별 대처

- **회사가 사용자 동의를 막아 둠(의도된 설정)**: 앱을 검토해 업무상 필요하고 믿을 만하면 관리자가 테넌트 전체 관리자 동의(Grant admin consent)
- **앱이 관리자 전용 권한(예: 조직 전체 메일 읽기)을 요청**: 그 권한이 정말 필요한지 개발사·개발자에게 확인. 최소 권한으로 줄일 수 있으면 줄인 뒤 동의
- **위험 앱으로 판단됨**: 사용자는 동의할 수 없음. 관리자도 게시자 확인(verified publisher) 여부, 요청 권한, 평판을 신중히 보고 결정. 의심스러우면 동의 화면에서 Microsoft에 신고
- **할당 필요 앱인데 동의 없음**: 관리자가 먼저 테넌트 전체 동의를 준 뒤 사용자·그룹 할당([AADSTS50105 글]({{ "/iam/troubleshooting/aadsts50105-app-not-assigned/" | relative_url }}))
- **요청이 자주 들어와 관리가 어려움**: 관리자 동의 워크플로 켜기(아래)

**예시 — 동의 피싱을 막은 경우**

"Office 문서 보안 검사"라는 이름의 앱이 직원들에게 링크로 돌고, 로그인하면 "메일 읽기·보내기, 모든 파일 읽기" 권한 동의를 요청합니다. 회사가 사용자 동의를 "확인된 게시자의 낮은 위험 권한만"으로 제한해 두어 직원들은 "관리자 승인 필요"를 받았고, 관리자는 게시자가 확인되지 않은 앱임을 보고 요청을 거부했습니다. 오류가 **보안 장치로 동작한 사례**입니다.

### 4. 관리자 동의 워크플로(Admin consent workflow)

사용자가 동의할 수 없는 앱을 만났을 때 **사유를 적어 승인 요청**을 보내고, 지정한 검토자가 처리하게 하는 기능입니다.

1. Entra ID > Enterprise apps > Consent and permissions > Admin consent settings(관리자 동의 설정)
2. Users can request admin consent to apps they are unable to consent to = **Yes**
3. 검토자(사용자·그룹·역할), 이메일 알림, 요청 만료 기간 설정 후 저장. 켜지기까지 최대 1시간

- 켜는 작업은 **전역 관리자**가 해야 합니다.
- 검토자로 지정해도 권한이 올라가지는 않습니다. 실제 승인은 그 앱에 관리자 동의를 줄 권한이 있어야 하고, Microsoft Graph **애플리케이션 권한**을 요청하는 앱은 **전역 관리자만** 승인할 수 있습니다.

### 5. 해결 확인

- 사용자가 다시 로그인해 동의 화면 없이 앱이 열리는지 확인합니다.
- 해당 엔터프라이즈 앱의 **Security > Permissions**에 관리자 동의가 기록됐는지 확인합니다.

### 6. 예방

- 사용자 동의는 "확인된 게시자의, 낮은 위험 권한"처럼 좁게 두고, 나머지는 관리자 동의 워크플로로 받습니다.
- 정기적으로 엔터프라이즈 앱의 권한 목록을 검토해 쓰지 않는 앱의 동의를 회수합니다.

## 근거 자료

- 65001·90093·90094·900941·900981, 위험 앱 감사 로그: [Unexpected error when performing consent to an application](https://learn.microsoft.com/entra/identity/enterprise-apps/application-sign-in-unexpected-user-consent-error)
- 동의 오류의 대표 원인: [Troubleshoot consent issues in Microsoft Entra ID](https://learn.microsoft.com/troubleshoot/entra/entra-id/app-integration/troubleshoot-consent-issues)
- 관리자 동의 워크플로 설정 경로·검토자 권한: [Configure the admin consent workflow](https://learn.microsoft.com/entra/identity/enterprise-apps/configure-admin-consent-workflow)
- 사용자 동의 설정: [Configure how users consent to applications](https://learn.microsoft.com/entra/identity/enterprise-apps/configure-user-consent)
