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

- 할당 필요 앱에 사용자나 그룹을 할당하면 해결됨
- 중첩 그룹 구성원은 인정되지 않으니 직접 할당하거나 그룹에 직접 넣음
- 전역 관리자는 할당 검사를 건너뛰므로 확인은 영향받은 계정으로 함

> Microsoft Learn 문서(2026-11-01 확인) 기준입니다. 샌드박스 테넌트에서 직접 재현해 캡처한 화면(5장)을 '2. 원인 및 분석'에 접어 두었습니다. 함께 볼 글: [Entra ID 핵심 개념: 기초와 구조 편]({{ "/iam/what-is-entra-id/" | relative_url }}), [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }}).

---

## 전체 내용

### 1. 증상

- 인사팀 직원이 SaaS 앱 첫 로그인에서 다음 취지의 오류를 받습니다(같은 팀 다른 직원은 정상).

> AADSTS50105: 관리자가 이 앱을 할당된 사용자만 쓰도록 설정했습니다. 로그인한 사용자는 접근 권한이 있는 그룹의 직접 구성원이 아니고, 직접 할당되지도 않았습니다.

### 2. 원인 및 분석

엔터프라이즈 앱의 Assignment required?(할당 필요)가 예이면 직접 할당과 할당 그룹의 직접 구성원만 받고 중첩 그룹은 인정하지 않습니다([문서](https://learn.microsoft.com/troubleshoot/entra/entra-id/app-integration/error-code-aadsts50105-user-not-assigned-role)).

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-aadsts50105-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-aadsts50105.png" | relative_url }}" alt="할당 필요 앱에서 로그인 허용과 AADSTS50105 차단이 갈리는 판정 흐름" loading="lazy"></picture>

*그림 1. 할당 필요 앱의 판정 흐름*

확인: Entra ID > Enterprise apps(엔터프라이즈 앱) > All applications > 앱 > Properties(속성)와 Users and groups(사용자 및 그룹)(역할: 클라우드 애플리케이션 관리자, 애플리케이션 관리자, 앱 소유자)

- 흔한 가상 시나리오: 급여 앱에 "인사팀" 그룹 할당 / 신규 입사자는 그 안의 "인사팀-신규"에만 있음 → 직접 구성원 아님
- 샌드박스 재현: 할당 필요 "예" / 할당은 관리자 1명 → 시험 사용자 로그인에 50105

<details markdown="1">
<summary>샌드박스에서 직접 재현한 화면 보기 (그림 5장)</summary>

앱 설정을 바꾸고, 앱에 할당되지 않은 시험 사용자로 로그인해 오류를 낸 과정입니다. 시험이 끝난 뒤 "할당이 필요합니까?"는 원래 값(아니요)으로 되돌렸고, 2026-11-04에 속성 화면을 다시 열어 "아니요"임을 확인했습니다.

![Graph Explorer 엔터프라이즈 앱 속성. 할당이 필요합니까가 아니요로 선택된 화면]({{ "/assets/images/2026/11/ts-aadsts50105-2-assign-before.png" | relative_url }})

*그림 2. 변경 전. Entra ID > 엔터프라이즈 앱 > Graph Explorer > 속성에서 "할당이 필요합니까?"가 "아니요"입니다.*

![할당이 필요합니까가 예로 바뀐 속성 화면]({{ "/assets/images/2026/11/ts-aadsts50105-3-assign-after.png" | relative_url }})

*그림 3. "예"로 바꿔 저장한 뒤. 앱 ID와 개체 ID는 가렸습니다.*

![앱의 사용자 및 그룹 목록에 관리자 1명만 할당된 화면]({{ "/assets/images/2026/11/ts-aadsts50105-4-users.png" | relative_url }})

*그림 4. 같은 앱의 "사용자 및 그룹". 관리자 1명만 할당돼 있고, 시험 사용자는 없습니다. 이름은 가렸습니다.*

![할당되지 않은 사용자가 로그인하자 나온 AADSTS50105 오류 화면]({{ "/assets/images/2026/11/ts-aadsts50105-1-error.png" | relative_url }})

*그림 5. 할당되지 않은 시험 사용자가 로그인하자 나온 화면. AADSTS50105와 함께 "직접 구성원도 아니고 직접 할당도 되지 않았다"는 설명이 나옵니다. 앱 ID, 계정, 요청 ID는 가렸습니다.*

![로그인 로그의 실패 항목 기본 정보. 로그인 오류 코드 50105와 실패 이유가 표시됨]({{ "/assets/images/2026/11/ts-aadsts50105-5-log-detail.png" | relative_url }})

*그림 6. 같은 시도를 관리자 쪽 로그인 로그에서 연 화면. 로그인 오류 코드 50105와 실패 이유가 같은 문구로 나옵니다. 요청 ID와 상관관계 ID는 가렸습니다.*

</details>

### 3. 결론

`할당 필요 = 예 → 사용자가 직접 할당도, 할당 그룹의 직접 구성원도 아님 → 50105`

### 4. 권고방안

1. 조치
    - 할당 없음: Users and groups > Add user/group에서 사용자나 그룹, 역할(정의가 없으면 Default Access)을 골라 Assign
    - 중첩 그룹: 사용자를 직접 할당하거나 그룹에 직접 넣음(예시는 "인사팀-신규"도 앱에 직접 할당). 그룹 할당 메뉴가 없으면 라이선스 문제(Entra ID P1 이상 필요)
    - 모두 써도 되는 앱: Assignment required? = No(할당 검사만 사라지고 조건부 액세스 등은 유지). 범위가 넓어지니 회사 정책에 맞을 때만
    - 예방: 직접 할당 그룹으로 관리. 동적 그룹(예: `user.department -eq "HR"`)은 입·퇴사를 자동 반영(P1)
2. 확인: 영향받은 그 사용자로 다시 로그인해 로그인 로그(Sign-in logs)에 성공이 남으면 해결입니다.
3. 하지 말 것: 전역 관리자로 테스트하기. 할당 검사를 건너뛰므로 성공해도 해결이 아닙니다(문서).

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (2건)</summary>

- 50105 원인과 해결, 중첩 그룹, 전역 관리자 테스트 주의, 그룹 할당 P1: [Error AADSTS50105: user isn't assigned to a role for the application](https://learn.microsoft.com/troubleshoot/entra/entra-id/app-integration/error-code-aadsts50105-user-not-assigned-role)
- 오류 코드 목록: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)

</details>
