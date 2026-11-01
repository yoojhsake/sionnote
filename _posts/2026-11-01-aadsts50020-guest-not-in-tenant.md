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

- 게스트가 우리 리소스에 로그인할 때 "ID 공급자의 사용자 계정이 이 테넌트에 없습니다"와 AADSTS50020. 게스트 쪽 홈 테넌트 로그에는 90072로 남음
- 가장 흔한 원인은 브라우저에 **다른 계정**(개인 계정, 자기 회사 계정)이 이미 로그인된 경우
- 그 밖에 초대되지 않음, 앱이 단일 테넌트로 등록됨, 게스트 원래 계정이 상대 회사에서 지워졌다가 같은 이름으로 다시 만들어짐, 앱이 사용자 할당 필요인데 게스트가 할당되지 않음
- 원인별로 InPrivate 창에서 재로그인, 게스트 초대, 앱 로그인 대상·URL 수정, 초대 수락 상태 초기화(Reset redemption status), 앱에 게스트(또는 그룹) 할당

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 개념은 [Entra ID 핵심 개념: 하이브리드 편]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

---

## 전체 내용

### 1. 증상

협력사 담당자를 게스트로 초대했는데, 담당자가 우리 회사 Teams나 SharePoint 링크를 열자 다음 취지의 오류가 납니다.

> AADSTS50020: ID 공급자 {idp}의 사용자 계정 'user@partner.com'이 테넌트 {우리 회사}에 없습니다.

### 2. 원인과 해결

가장 흔한 원인은 브라우저에 다른 계정이 이미 로그인된 경우입니다. InPrivate 창에서 초대받은 계정으로 다시 로그인하면 풀립니다. 오류 메시지의 계정과 ID 공급자로 원인을 가르는 법은 아래 '오류 메시지에서 먼저 볼 것'에 있습니다.

- **다른 계정으로 로그인됨**
    - 확인: 메시지의 계정이나 IdP가 초대한 것과 다름
    - 대처: 모두 로그아웃 후 InPrivate(시크릿) 창이나 다른 브라우저에서 초대받은 계정으로 다시 로그인
- 초대되지 않음
    - 확인: 사용자 목록에 게스트가 없음
    - 대처: 게스트로 초대(B2B). 외부 협업 설정이 초대를 막고 있지 않은지 확인
- 앱이 단일 테넌트
    - 확인: 앱 등록 > Manifest의 `signInAudience`
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

흔한 장면은 이렇습니다. 협력사 담당자가 평소 쓰는 브라우저에는 자기 회사 M365 계정이 로그인돼 있습니다. 우리 Teams 링크를 열면 그 계정이 자동으로 쓰이고, 그 계정으로 우리 테넌트에 들어가려다 50020이 납니다. InPrivate 창에서 초대 메일의 링크를 다시 열고 초대받은 주소로 로그인하면 정상적으로 들어옵니다.

### 3. 비슷하지만 다른 경우: 90071

Teams 공유 채널처럼 게스트 계정 없이 들어오는 **B2B direct connect**에서는 AADSTS90071이 나기도 합니다. 이때는 공유 채널을 호스팅하는(리소스) 조직이 테넌트 간 액세스 설정 > Inbound access > Trust settings에서 "Trust multifactor authentication from Microsoft Entra tenants"를 켜야 합니다. 우리가 채널 호스트라면 우리 쪽 설정입니다(문서).

### 4. 확인 과정

#### 오류 메시지에서 먼저 볼 것

- 오류 메시지의 **사용자 계정**과 **ID 공급자** 값이 기대한 조합인지 봅니다. 초대한 주소는 회사 계정인데 `live.com`(개인 Microsoft 계정)으로 로그인한 것은 아닌지 같은 경우입니다.
- Entra ID > Users(사용자)에서 그 게스트가 존재하는지, 초대 수락 상태가 어떤지 봅니다.
- 앱 문제라면 앱 등록의 지원 계정 유형(단일 테넌트, 다중 테넌트)을 봅니다.

#### 풀렸는지 확인

게스트가 InPrivate 창에서 초대받은 계정으로 로그인해 리소스가 열리는지 보고, 우리 테넌트 로그인 로그에서 해당 게스트의 성공 기록을 확인합니다.

### 5. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 50020 원인과 해결(다른 계정, 초대 안 됨, 단일 테넌트, 재생성 계정, 할당 필요 등. 이 글은 실무에서 자주 겹치는 원인만 추림): [Error AADSTS50020: User account from identity provider does not exist in tenant](https://learn.microsoft.com/troubleshoot/entra/entra-id/app-integration/error-code-aadsts50020-user-account-identity-provider-does-not-exist)
- B2B 공통 문제, 90071: [Troubleshoot common issues with Microsoft Entra B2B collaboration](https://learn.microsoft.com/entra/external-id/troubleshoot)
- 오류 코드 정의: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
- B2B direct connect 신뢰 설정: [Configure cross-tenant access settings for B2B direct connect](https://learn.microsoft.com/entra/external-id/cross-tenant-access-settings-b2b-direct-connect)

</details>
