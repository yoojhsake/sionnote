---
title: "[Troubleshooting] AADSTS50020: 게스트·외부 계정이 '이 테넌트에 없는 계정'으로 막힐 때"
date: 2026-11-01 09:13:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 13
tags: [Troubleshooting, Entra ID, AADSTS50020, B2B, 게스트, External ID, 테넌트]
excerpt: "협력사 게스트가 50020으로 막힐 때. 다른 계정 로그인, 초대 안 됨, 단일 테넌트 앱 등 원인별로 나눠 푼다"
---

협력사 게스트가 우리 앱이나 Teams에 들어오려다 "ID 공급자의 사용자 계정이 이 테넌트에 없습니다"(AADSTS50020)에 막힙니다. 브라우저의 다른 계정, 초대 누락, 단일 테넌트 앱처럼 원인이 몇 갈래로 정해져 있어서, 원인을 가르면 재로그인, 초대, 앱 설정 수정 중 할 일이 정해집니다.

## 요약

- 가장 흔한 원인은 브라우저에 이미 로그인된 다른 계정임
- InPrivate 창에서 초대받은 계정으로 다시 로그인하고 안 되면 초대와 앱 설정을 봄
- 게스트 원계정이 재생성된 경우 게스트를 지우지 말고 초대 수락 상태를 초기화함

> Microsoft Learn 문서(2026-11-01 확인) 기준이며, 테넌트에서 재현하지는 않았습니다. 함께 볼 글: [Entra ID 핵심 개념: 하이브리드 편]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}), [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }}).

---

## 전체 내용

### 1. 증상

- 게스트로 초대한 협력사 담당자가 우리 Teams나 SharePoint 링크를 열면 다음 취지의 오류가 납니다.

> AADSTS50020: ID 공급자 {idp}의 사용자 계정 'user@partner.com'이 테넌트 {우리 회사}에 없습니다.

### 2. 원인 및 분석

원인은 몇 갈래로 정해져 있습니다([Error AADSTS50020](https://learn.microsoft.com/troubleshoot/entra/entra-id/app-integration/error-code-aadsts50020-user-account-identity-provider-does-not-exist)). 먼저 메시지의 계정과 ID 공급자가 초대한 조합인지 봅니다(예: 회사 계정으로 초대했는데 `live.com` 개인 Microsoft 계정으로 로그인).

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-aadsts50020-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-aadsts50020.png" | relative_url }}" alt="AADSTS50020 원인 4가지와 각 대처" loading="lazy"></picture>

*그림 1. 원인과 대처 4가지*

<details markdown="1">
<summary>원인별 확인과 대처 자세히 보기 (6가지)</summary>

- **다른 계정으로 로그인됨**
    - 확인: 메시지의 계정이나 IdP가 초대한 것과 다름
    - 대처: 모두 로그아웃 후 InPrivate(시크릿) 창이나 다른 브라우저에서 초대받은 계정으로 다시 로그인
- 초대되지 않음
    - 확인: Entra ID > Users(사용자)에 게스트가 없음. 있으면 초대 수락 상태 확인
    - 대처: 게스트로 초대(B2B). 외부 협업 설정이 초대를 막고 있지 않은지 확인
- 앱이 단일 테넌트
    - 확인: 앱 등록의 지원 계정 유형(단일·다중 테넌트), Manifest의 `signInAudience`
    - 대처: 다른 조직 사용자를 받을 앱이면 다중 테넌트 유형으로 다시 등록하고, 로그인 URL을 `/organizations`·`/common` 등 유형에 맞게 사용
    - 단일 테넌트 앱을 쓰려면 사용자를 게스트로 추가
- 게스트 원계정이 삭제 후 재생성됨
    - 확인: 우리 쪽 게스트 개체가 상대 회사의 새 계정보다 먼저 만들어짐(`createdDateTime` 비교)
    - 대처: 게스트를 지우지 말고 초대 수락 상태 초기화(Reset redemption status) 후 다시 수락
- 앱에 할당되지 않음
    - 확인: 엔터프라이즈 앱 > Properties의 Assignment required = Yes, Users and groups에 게스트 없음
    - 대처: 게스트나 게스트가 속한 그룹을 할당. 자세한 절차는 [AADSTS50105 글]({{ "/iam/troubleshooting/aadsts50105-app-not-assigned/" | relative_url }})
- 개인 Microsoft 계정으로 관리 센터 접속
    - 확인: 개인 계정으로 Entra 관리 센터에 들어가면 기본 Microsoft 서비스 테넌트로 연결됨
    - 대처: 회사(조직) 계정으로 로그인하거나, 필요하면 Azure 계정을 만들어 자기 테넌트를 생성

</details>

게스트 계정 없이 들어오는 B2B direct connect(Teams 공유 채널)에서는 AADSTS90071이 납니다. 채널 호스트(리소스) 조직이 테넌트 간 액세스 설정 > Inbound access > Trust settings에서 "Trust multifactor authentication from Microsoft Entra tenants"를 켭니다.

### 3. 결론

`브라우저에 협력사 자기 회사 M365 계정 로그인 → 우리 Teams 링크에 그 계정 자동 사용 → 50020`

가장 흔한 경우입니다.

### 4. 권고방안

1. 조치: 로그아웃 후 InPrivate 창에서 초대 메일 링크를 열어 초대받은 계정으로 로그인합니다. 안 되면 위 6가지 원인별로 고칩니다.
2. 확인: 리소스가 열리고, 우리 테넌트 로그인 로그에 그 게스트의 성공 기록이 있으면 해결입니다.
3. 하지 말 것: 원계정이 재생성된 게스트를 지우기(초대 수락 상태 초기화로 해결)

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 50020 원인과 해결(다른 계정, 초대 안 됨, 단일 테넌트, 재생성 계정, 할당 필요 등. 이 글은 실무에서 자주 겹치는 원인만 추림): [Error AADSTS50020: User account from identity provider does not exist in tenant](https://learn.microsoft.com/troubleshoot/entra/entra-id/app-integration/error-code-aadsts50020-user-account-identity-provider-does-not-exist)
- B2B 공통 문제, 90071: [Troubleshoot common issues with Microsoft Entra B2B collaboration](https://learn.microsoft.com/entra/external-id/troubleshoot)
- 오류 코드 정의: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
- B2B direct connect 신뢰 설정: [Configure cross-tenant access settings for B2B direct connect](https://learn.microsoft.com/entra/external-id/cross-tenant-access-settings-b2b-direct-connect)

</details>
