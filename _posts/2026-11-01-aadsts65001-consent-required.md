---
title: "[Troubleshooting] '관리자 승인 필요', AADSTS65001, AADSTS90094: 앱 권한 동의가 막힐 때"
date: 2026-11-01 09:12:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 12
tags: [Troubleshooting, Entra ID, 동의, Consent, AADSTS65001, AADSTS90094, 관리자 동의 워크플로]
excerpt: "'관리자 승인 필요'·AADSTS65001이 뜨면 동의부터 누르지 말고, 앱을 먼저 검토한 뒤 필요할 때만 관리자 동의를 합니다."
---

앱에 로그인하는데 "관리자 승인 필요" 화면이나 AADSTS65001·90094가 뜨면, 오류를 없애려고 동의 버튼부터 누르고 싶어집니다. 동의는 앱에 메일과 파일 접근 권한을 주는 일이므로, 앱이 믿을 만한지 먼저 검토한 뒤 필요할 때만 관리자 동의를 합니다.

## 요약

- 동의 설정이나 요청 권한 때문에 사용자가 동의할 수 없는 상태임
- 요청이 잦으면 관리자 동의 워크플로를 켜서 검토자가 처리하게 함
- 확인 없이 동의하면 앱에 메일과 파일 권한을 넘겨 동의 피싱에 당함

> Microsoft Learn 문서(2026-11-01 확인) 기준입니다. 오류 상황은 테넌트에서 재현하지 않았고, 설정 화면은 샌드박스 테넌트에서 직접 열어 캡처했습니다. 함께 볼 글: [Entra ID 핵심 개념: 기초와 구조 편]({{ "/iam/what-is-entra-id/" | relative_url }}), [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }}).

---

## 전체 내용

### 1. 증상

- 사례 1: 메일 정리 앱에 회사 계정으로 로그인하면 "관리자 승인 필요 — 이 앱은 조직의 리소스에 접근하려면 관리자만 줄 수 있는 권한이 필요합니다"
- 사례 2: 사내 개발 앱이 `AADSTS65001: The user or administrator has not consented to use the application…` 오류

### 2. 원인 및 분석

테넌트 동의 설정이나 앱의 요청 권한 때문에 사용자가 동의할 수 없습니다([공식 문서](https://learn.microsoft.com/entra/identity/enterprise-apps/application-sign-in-unexpected-user-consent-error)). 코드별 뜻은 아래 확인 과정에 있습니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-aadsts65001-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-aadsts65001.png" | relative_url }}" alt="사용자 동의가 막힐 때 관리자가 판단하는 순서" loading="lazy"></picture>

*그림 1. 동의가 막힐 때 판단 순서*

<details markdown="1">
<summary>원인별 대처와 실제 사례 자세히 보기 (5가지)</summary>

- 회사가 사용자 동의를 막아 둔 경우(의도된 설정): 앱을 검토해 업무상 필요하고 믿을 만하면 관리자가 테넌트 전체 관리자 동의(Grant admin consent)
- 앱이 관리자 전용 권한(예: 조직 전체 메일 읽기)을 요청하는 경우: 그 권한이 정말 필요한지 개발사나 개발자에게 확인. 최소 권한으로 줄일 수 있으면 줄인 뒤 동의
- 위험 앱으로 판단된 경우: 사용자는 동의할 수 없음
    - 관리자도 게시자 확인(verified publisher) 여부, 요청 권한, 평판을 신중히 보고 결정
    - 의심스러우면 동의 화면에서 Microsoft에 신고
- 할당 필요 앱인데 동의가 없는 경우: 관리자가 먼저 테넌트 전체 동의를 준 뒤 사용자나 그룹 할당([AADSTS50105 글]({{ "/iam/troubleshooting/aadsts50105-app-not-assigned/" | relative_url }}))
- 요청이 자주 들어와 관리가 어려운 경우: 관리자 동의 워크플로 켜기(권고방안 1)

오류가 보안 장치로 동작한 사례도 있습니다. "Office 문서 보안 검사"라는 앱이 링크로 돌며 "메일 읽기·보내기, 모든 파일 읽기" 동의를 요청했지만, 사용자 동의가 "확인된 게시자의 낮은 위험 권한만"으로 제한되어 직원들은 "관리자 승인 필요"를 받았고, 관리자는 게시자가 확인되지 않은(unverified publisher) 앱임을 보고 요청을 거부했습니다.

</details>



<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 코드와 동의 설정

- **AADSTS65001**: 사용자나 관리자가 이 앱 사용에 동의한 적이 없음
- **AADSTS90093**: 관리자가 사용자 동의를 꺼 둔 정책 때문에 막힘, 또는 사용자가 줄 수 없는 권한을 요청함
- **AADSTS90094**: 관리자만 줄 수 있는 권한을 요청함. 또는 위험한 요청으로 판단되어 사용자 동의가 막힘
- **AADSTS900941**: 앱이 위험하다고 판단되어 관리자 동의가 필요(관리자 동의 워크플로가 꺼져 있을 때)
- **AADSTS900981**: 위험한 앱에 대한 관리자 동의 요청이 접수됨(워크플로가 켜져 있을 때)

관리자는 다음을 봅니다.

1. Entra ID > Enterprise apps > Consent and permissions(동의 및 권한) > User consent settings(사용자 동의 설정): 사용자가 어떤 앱에 동의할 수 있는지
2. 해당 앱(엔터프라이즈 앱) > Security > Permissions(권한): 앱이 요청하는 권한 목록
3. 감사 로그에서 범주 **ApplicationManagement**, 활동 **Consent to application**, 사유 Risky application detected 기록이 있는지(위험 앱으로 막힌 경우)

</details>

### 3. 결론

`사용자 동의 제한 또는 관리자 전용 권한 요청 → 사용자 동의 불가 → 관리자 승인 필요, AADSTS65001·90094`

앱이 믿을 만한지 먼저 검토하고, 필요할 때만 관리자가 동의합니다.

### 4. 권고방안

1. 조치: 요청이 잦으면 관리자 동의 워크플로(Admin consent workflow)를 켜서 검토자가 처리하게 합니다. 켜는 작업은 전역 관리자가 하며, 켜지기까지 최대 1시간 걸립니다.
2. 조치 후 확인: 다시 로그인해 동의 화면 없이 앱이 열리고, 앱의 Security > Permissions에 관리자 동의가 기록되면 해결입니다.
3. 예방: 사용자 동의는 "확인된 게시자의, 낮은 위험 권한"으로 좁히고, 앱 권한 목록을 정기 검토해 안 쓰는 앱의 동의를 회수합니다.
4. 하지 말아야 할 것: 오류를 없애려고 검토 없이 동의 버튼부터 누르지 않습니다.

<details markdown="1">
<summary>관리자 동의 워크플로 설정 경로와 검토자 권한 보기</summary>

- Entra ID > Enterprise apps > Consent and permissions > Admin consent settings(관리자 동의 설정)에서 Users can request admin consent to apps they are unable to consent to = **Yes**
- 검토자(사용자, 그룹, 역할), 이메일 알림, 요청 만료 기간 설정 후 저장
- 검토자 지정으로 권한이 올라가지 않으며, 승인에는 그 앱에 관리자 동의를 줄 권한이 필요합니다. Microsoft Graph **애플리케이션 권한**을 요청하는 앱은 전역 관리자만 승인할 수 있습니다.

</details>

<details markdown="1">
<summary>화면으로 경로 따라가기: 사용자 동의 설정과 관리자 동의 요청 (그림 2장)</summary>

![동의 및 권한의 사용자 동의 설정 화면. 사용자 동의 허용 범위를 고르는 세 가지 선택지]({{ "/assets/images/2026/11/guide-consent-user.png" | relative_url }})

*그림 2. Entra ID > 엔터프라이즈 앱(Enterprise apps) > 동의 및 권한(Consent and permissions) > 사용자 동의 설정. 사용자가 어떤 앱에 스스로 동의할 수 있는지 고릅니다. 이 샌드박스는 "Microsoft에서 동의 설정을 관리하도록 허용(권장)"입니다.*

![동의 및 권한의 관리자 동의 설정 화면. 사용자가 관리자 동의를 요청할 수 있는지 예, 아니요]({{ "/assets/images/2026/11/guide-consent-admin.png" | relative_url }})

*그림 3. 같은 메뉴의 관리자 동의 설정. "사용자는 동의할 수 없는 앱의 관리자 동의를 요청할 수 있습니다"를 "예"로 켠 뒤, 같은 화면 아래에서 요청을 검토할 사용자, 그룹, 역할을 지정합니다. 이 샌드박스는 "아니요"입니다.*

화면은 설정을 바꾸지 않고 샌드박스 테넌트에서 열어 캡처했습니다. 테넌트 이름, 테넌트 ID, 계정, IP, 요청 ID는 가렸고, 사용 중인 라이선스와 정책에 따라 메뉴 이름과 값은 다를 수 있습니다.

</details>

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 65001, 90093, 90094, 900941, 900981, 위험 앱 감사 로그: [Unexpected error when performing consent to an application](https://learn.microsoft.com/entra/identity/enterprise-apps/application-sign-in-unexpected-user-consent-error)
- 동의 오류의 대표 원인: [Troubleshoot consent issues in Microsoft Entra ID](https://learn.microsoft.com/troubleshoot/entra/entra-id/app-integration/troubleshoot-consent-issues)
- 관리자 동의 워크플로 설정 경로와 검토자 권한: [Configure the admin consent workflow](https://learn.microsoft.com/entra/identity/enterprise-apps/configure-admin-consent-workflow)
- 사용자 동의 설정: [Configure how users consent to applications](https://learn.microsoft.com/entra/identity/enterprise-apps/configure-user-consent)

</details>
