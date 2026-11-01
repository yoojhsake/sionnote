---
title: "[Troubleshooting] AADSTS50105: 앱에 할당되지 않은 사용자라서 로그인이 막힐 때"
date: 2026-11-01 09:11:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 11
tags: [Troubleshooting, Entra ID, AADSTS50105, 엔터프라이즈 앱, 할당 필요, SSO]
excerpt: "SaaS 앱 로그인이 AADSTS50105로 막히면 앱의 '할당 필요'가 원인입니다. 사용자나 그룹을 할당하고, 전역 관리자로 테스트하지 마세요."
---

SaaS 앱에 로그인하자 "관리자가 할당한 사용자만 접근하도록 설정했다"는 안내와 AADSTS50105가 뜬다면, 앱의 할당 필요가 켜져 있는데 그 사용자가 할당되지 않은 경우입니다. 사용자나 그룹을 앱에 할당하면 되고, 확인은 전역 관리자가 아니라 영향받은 그 사용자 계정으로 합니다.

## 요약

- SaaS 앱(SAML, OIDC) 로그인 때 "관리자가 할당한 사용자만 접근하도록 설정했다"는 안내와 AADSTS50105
- 엔터프라이즈 앱의 할당 필요(Assignment required?)가 예인데, 사용자가 직접 할당되지 않았고 할당된 그룹의 직접 구성원도 아님
- 앱의 사용자 및 그룹(Users and groups)에 사용자나 그룹을 할당하면 해결. 모두에게 열 앱이라면 할당 필요를 아니요로
- 중첩 그룹은 인정되지 않음(직접 구성원만). 그룹 할당은 P1 이상
- 확인은 영향받은 사용자 계정으로. 전역 관리자는 할당 검사를 건너뜀

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 개념은 [Entra ID 핵심 개념: 기초와 구조 편]({{ "/iam/what-is-entra-id/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

---

## 전체 내용

### 1. 증상

인사팀 직원이 회사가 연결해 둔 SaaS 앱에 처음 로그인하자, Entra 화면에 다음 취지의 오류가 나옵니다.

> AADSTS50105: 관리자가 이 앱을 할당된 사용자만 쓰도록 설정했습니다. 로그인한 사용자는 접근 권한이 있는 그룹의 직접 구성원이 아니고, 직접 할당되지도 않았습니다.

같은 팀 다른 직원은 잘 들어갑니다.

### 2. 원인과 해결

엔터프라이즈 앱의 Assignment required?(할당 필요)가 예인데, 사용자가 직접 할당되지도 않았고 할당된 그룹의 직접 구성원도 아닌 상황입니다. 어떤 경우냐에 따라 손대는 곳이 다릅니다.

할당이 아예 없다면 Users and groups > Add user/group에서 사용자나 그룹을 고르고 역할(앱이 역할을 정의하지 않았으면 Default Access)을 지정한 뒤 Assign을 누릅니다.

그룹은 할당됐는데 사용자가 중첩 그룹의 구성원이라면, 문서는 중첩 그룹 구성원을 믿지 말라고 안내합니다. 사용자를 직접 할당하거나 할당된 그룹에 직접 넣습니다. 그룹 할당 메뉴 자체가 없다면 라이선스 문제입니다. 그룹 기반 할당에는 Entra ID P1 이상이 필요합니다.

원래 모두가 써도 되는 앱이라면 Properties > Assignment required? = No로 저장합니다. 이때 사라지는 것은 할당 검사뿐이고, 조건부 액세스 등 다른 통제는 그대로 적용됩니다. 다만 접근 범위가 넓어지므로 회사 정책에 맞을 때만 그렇게 합니다.

#### 흔한 사례: 신규 입사자만 못 들어가는 급여 앱

급여 앱에 "인사팀" 그룹이 할당돼 있고, 인사팀 그룹 안에 "인사팀-신규" 그룹을 넣어 관리하고 있습니다. 신규 입사자는 "인사팀-신규"에만 들어 있어 할당된 "인사팀"의 **직접** 구성원이 아니므로 50105가 납니다. "인사팀-신규" 그룹도 앱에 직접 할당하면 해결됩니다.

### 3. 예방

앱마다 "누가 써야 하는가"를 정해 두고, 할당 필요를 켜는 앱은 **직접 할당 그룹**으로 관리합니다. 동적 그룹(예: `user.department -eq "HR"`)을 앱에 할당하면 입·퇴사 때 접근이 자동으로 따라갑니다(P1).

### 4. 확인 과정

#### 설정 확인

1. Entra ID > Enterprise apps(엔터프라이즈 앱) > All applications에서 해당 앱을 엽니다.
2. Properties(속성)에서 Assignment required?(할당 필요) 값을 봅니다.
3. Users and groups(사용자 및 그룹)에서 이 사용자가 직접 있는지, 또는 할당된 그룹의 **직접 구성원**인지 확인합니다.

필요한 역할: 클라우드 애플리케이션 관리자, 애플리케이션 관리자, 또는 그 앱(서비스 주체)의 소유자.

#### 해결됐는지 확인

**영향받은 그 사용자 계정으로** 다시 로그인해 봅니다. 전역 관리자는 할당 검사를 건너뛰기 때문에, 관리자 계정으로 성공했다고 해결된 것은 아닙니다(문서). 그다음 로그인 로그(Entra ID > Monitoring & health > Sign-in logs)에서 같은 사용자의 해당 앱 로그인이 성공인지 봅니다.

### 5. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (2건)</summary>

- 50105 원인과 해결, 중첩 그룹, 전역 관리자 테스트 주의, 그룹 할당 P1: [Error AADSTS50105: user isn't assigned to a role for the application](https://learn.microsoft.com/troubleshoot/entra/entra-id/app-integration/error-code-aadsts50105-user-not-assigned-role)
- 오류 코드 목록: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)

</details>
